from fastapi import FastAPI, UploadFile, File, Form, HTTPException, BackgroundTasks
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from pydantic import BaseModel
from PIL import Image
from io import BytesIO
from transformers import AutoProcessor, AutoModel, AutoTokenizer
from PIL import Image
import torch
from io import BytesIO
from typing import Annotated, Optional
import logging
from dotenv import load_dotenv
from os import getenv
import redis
from celery import Celery
import json
import boto3
from botocore.exceptions import ClientError
import time
import uuid
from contextlib import asynccontextmanager

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Env Variables
load_dotenv()
redisURL = getenv("REDIS_URL")
executionQueueURL = getenv("EXECUTION_QUEUE_URL")
awsRegion = getenv("AWS_REGION")

# initializing services
redis_client = redis.from_url(redisURL)
celeryApp = Celery('ocr_service', broker=redisURL, backend=redisURL)
sqs = boto3.client("sqs", region_name=awsRegion)


# Model Setup
model_path = "nanonets/Nanonets-OCR-s"


# pydantic models
class OCRRequest(BaseModel):
    title: str
    language: str
    max_tokens: int = 256

class OCRResponse(BaseModel):
    task_id: str
    status: str
    result: Optional[str] = None
    error: Optional[str] = None
    execution_time: Optional[float] = None

class ExecutionRequest(BaseModel):
    code: str
    language: str

@asynccontextmanager
async def lifespan(app: FastAPI):
    device = ""
    if torch.backends.mps.is_available() :
        device = "mps"
    elif torch.cuda.is_available(): 
        device = "cuda"
    else:
        device = "cpu"

    # Loading model
    try: 
        model = AutoModel.from_pretrained(
            model_path,
            torch_dtype=torch.float16 if device == "cuda" else torch.float32,
            device_map={"": device},
            trust_remote_code=True,
        )
        model.eval()
        tokenizer = AutoTokenizer.from_pretrained(model_path)
        processor = AutoProcessor.from_pretrained(model_path)
        
        app.state.model = model
        app.state.tokenizer = tokenizer
        app.state.processor = processor
        app.state.device = device
        
        logger.info(f"Model loaded successfully on {device}")
    except Exception as e:
        logger.error(f"Failed to load model: {e}")
        raise

    yield
    
    logger.info("Shutting down OCR service")
    redis_client.close()

# FastAPI app setup
app = FastAPI(
    title="Code Recognition & Execution API",
    description="Production-ready OCR and code execution service",
    version="1.0.0",
    lifespan=lifespan
)

# COORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # Configure this properly for production
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Health check
@app.get("/health")
async def health_check():
    return {
        "status": "healthy",
        "timestamp": time.time(),
        "device": app.state.device,
        "model_loaded": app.state.model is not None
    }

# OCR function for scanning images using Nanonets ML model
async def ocr_page(image_bytes: bytes, model, processor, maxNewTokens=256) -> str:
    
    try: 
        # creating the cache key
        import hashlib
        cacheKey = f"ocr:{hashlib.md5(image_bytes).hexdigest()}"
        
        # checks if image_bytes is already in the redis cache as a key
        cachedResult = redis_client.get(cacheKey)
        if (cachedResult): 
            logger.info("Cache hit for OCR request")
            return cachedResult.decode("utf-8") # type: ignore
        
        prompt = """Extract the code in the image exactly as it appears, but return it as raw source code with no extra characters. Do not format the code using markdown (e.g., no triple backticks). Do not include escape characters like \\n or \\t. Output must be plain text exactly how it would appear in a .java file. Remove all surrounding quotes, line breaks, or markup."""

        image = Image.open(BytesIO(image_bytes))
        max_size = 1024 if len(image_bytes) > 1024 * 1024 else 512
        image = image.resize((max_size, max_size))
        
        messages = [
            {"role": "system", "content": "You are a helpful assistant."},
            {"role": "user", "content": [
                {"type": "image", "image": f"{image_bytes}"},
                {"type": "text", "text": prompt},
            ]},
        ]
    
        start_time = time.time()
    
        text = processor.apply_chat_template(messages, tokenize=False, add_generation_prompt=True)
        inputs = processor(text=[text], images=[image], padding=True, return_tensors="pt")
        inputs = inputs.to(app.state.device)
        
        with torch.no_grad():
            output_ids = model.generate(**inputs, max_new_tokens=maxNewTokens, do_sample=False,temperature=0.1, pad_token_id=app.state.tokenizer.eos_token_id)
            
        generate_ids = [output_ids[len(input_ids):] for input_ids, output_ids in zip(inputs.input_ids, output_ids)]
        output_text = processor.batch_decode(generate_ids, skip_special_tokens=True,                            clean_up_tokenization_spaces=True)
        clean_result = output_text[0].replace('```', '').replace('\\n', '\n').strip()
    
        redis_client.setex(cacheKey, 3600, clean_result)
        
        processing_time = time.time() - start_time
        logger.info(f"OCR completed in {processing_time:.2f}s")
        
        return clean_result
    except Exception as e: 
        logger.error(f"OCR processing failed: {e}")
        raise HTTPException(500, f"OCR processing failed: {str(e)}")


async def process_ocr_task(task_id: str, image_bytes: bytes, max_tokens: int):
    try:
        start_time = time.time()
        result = await ocr_page(image_bytes, app.state.model, app.state.processor, max_tokens)
        
        task_data = {
            "status": "completed",
            "result": result,
            "execution_time": time.time() - start_time
        }
        
        redis_client.setex(f"task: {task_id}", 600, json.dumps(task_data))
        
    except Exception as e:
        logger.error(f"OCR task {task_id} failed: {e}")
        task_data = {
            "status": "failed",
            "error": str(e)
        }
        redis_client.setex(f"task: {task_id}", 600, json.dumps(task_data))
        
@app.post("/ocr", response_model=OCRResponse)
async def recognize_code(
    background_tasks: BackgroundTasks,
    title: Annotated[str, Form()],
    language: Annotated[str, Form()],
    max_tokens: Annotated[int, Form()] = 256,
    drawing: UploadFile = File()
):
    
    try: 
        if not drawing.content_type or not drawing.content_type.startswith("image/"):
            raise HTTPException(400, "File must be an image")
        
        task_id = str(uuid.uuid4())
        
        task_data = {
            "status": "processing",
            "title": title,
            "language": language,
            "created_at": time.time()
        }
        
        redis_client.setex(f"task: {task_id}", 600, json.dumps(task_data))
        
        contents = await drawing.read()
        
        import asyncio
        background_tasks.add_task(lambda: asyncio.create_task(process_ocr_task(task_id, contents, max_tokens)))
        
        return OCRResponse(task_id=task_id, status="processing")
        
    except Exception as e:
        logger.error(f"OCR request failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/task/{task_id}", response_model=OCRResponse)
async def get_task_status(task_id: str):
    task_data = redis_client.get(f"task: {task_id}")
    
    if not task_data: 
        raise HTTPException(404, "Task not found")
    
    data = json.loads(task_data.decode("utf-8")) # type: ignore
    return OCRResponse(task_id=task_id, **data)


@app.post("/execute")
async def execute_code(request: ExecutionRequest):
    try:
        message = {
            "code": request.code,
            "language": request.language
        }
        
        response = sqs.send_message(
            QueueUrl=executionQueueURL,
            MessageBody=json.dumps(message)
        )
        
        return {
            "status": "queued",
            "message_id": response["MessageId"]
        }
        
    except ClientError as e:
        logger.error(f"Failed to queue execution: {e}")
        raise HTTPException(status_code=500, detail="Failed to queue execution")


if __name__ == "__main__" :
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)