from fastapi import FastAPI, UploadFile, File, Form, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import StreamingResponse
import asyncio
from pydantic import BaseModel
from PIL import Image
from io import BytesIO
from transformers import AutoProcessor, AutoModelForImageTextToText, AutoTokenizer
import torch
from io import BytesIO
from typing import Annotated, Optional
import logging
from dotenv import load_dotenv
from os import getenv
import redis
from celery import Celery
from celery.signals import worker_process_init
import json
import boto3
from botocore.exceptions import ClientError
import time
from contextlib import asynccontextmanager

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Env Variables
load_dotenv()
redisOcrURL = getenv("REDIS_URL_OCR")
redisCeleryURL = getenv("REDIS_URL_CELERY")
executionQueuePythonURL = getenv("EXECUTION_QUEUE_PYTHON_URL")
executionQueueJavaScriptURL = getenv("EXECUTION_QUEUE_JAVASCRIPT_URL")
executionQueueJavaURL = getenv("EXECUTION_QUEUE_JAVA_URL")
awsRegion = getenv("AWS_REGION")

# initializing services
redis_client = redis.from_url(redisOcrURL)
celeryApp = Celery(
    "ocr_service", broker=redisCeleryURL, backend=redisCeleryURL, include=["main"]
)
celeryApp.conf.update(
    task_serializer="json",
    accept_content=["json"],
    result_serializer="json",
    timezone="UTC",
    enable_utc=True,
    result_expires=3600,
    task_track_started=True,
    task_time_limit=300,  # 5 minutes
    task_soft_time_limit=240,  # 4 minutes
    worker_prefetch_multiplier=1,
    worker_max_tasks_per_child=1000,
)
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
    cached: Optional[bool] = None
    execution_time: Optional[float] = None


class ExecutionRequest(BaseModel):
    code: str
    language: str


# Global model variables (will be loaded in workers)
model = None
tokenizer = None
processor = None
device = None


def load_model():
    global model, tokenizer, processor, device

    device = "cpu"
    if torch.backends.mps.is_available():
        device = "mps"
    elif torch.cuda.is_available():
        device = "cuda"

    # Configure precision and quantization based on device
    if device == "cuda":
        torch_dtype = torch.float16
        device_map = "auto"
    elif device == "mps":
        bnb_config = None
        torch_dtype = torch.float32
        device_map = {"": "mps"}
    else:
        bnb_config = None
        torch_dtype = torch.float32
        device_map = {"": "cpu"}

    # Loading model
    logger.info(f"Loading model using {device}")
    try:
        # local_model_dir = snapshot_download(model_path, cache_dir="/tmp/hf_cache")
        model = AutoModelForImageTextToText.from_pretrained(
            model_path,
            device_map=device_map,
            offload_folder="/tmp/offload",
            offload_state_dict=True,
            torch_dtype=torch_dtype,  # or float32 if you must
            low_cpu_mem_usage=True,
            trust_remote_code=True,
            quantization_config=bnb_config,
            # torch_dtype=torch.float16, #torch_dtype,
            # cache_dir="/tmp/hf_cache",
            # use_cache=False,
            # offload_folder="/tmp/offload",
        )
        # model = model.half()
        # model = torch.quantization.quantize_dynamic(
        #     model,
        #     {torch.nn.Linear},
        #     dtype=torch.qint8
        # )

        model.eval()
        tokenizer = AutoTokenizer.from_pretrained(model_path, cache_dir="/tmp/hf_cache")
        processor = AutoProcessor.from_pretrained(model_path, cache_dir="/tmp/hf_cache")

        logger.info(f"Model loaded successfully on {device}")

    except Exception as e:
        logger.error(f"Failed to load model: {e}")
        raise


# ======================== Celery Tasks ========================


@worker_process_init.connect
def load_model_on_worker_start(**kwargs):
    load_model()


# OCR function for scanning images using Nanonets ML model
@celeryApp.task(bind=True, name="ocr_service.process_ocr")
def process_ocr_task(self, image_bytes: bytes, maxNewTokens=256):
    """
    Celery Task for OCR Processing
    """
    try:
        self.update_state(state="PROGRESS", meta={"status": "Loading model..."})

        # Decode base64 image
        import base64

        image_bytes = base64.b64decode(image_bytes)
        self.update_state(state="PROGRESS", meta={"status": "Processing image..."})

        start_time = time.time()

        from hashlib import md5

        cacheKey = f"ocr:{md5(image_bytes).hexdigest()}"
        # checks if image_bytes is already in the redis cache as a key
        cachedResult = redis_client.get(cacheKey)
        if cachedResult:
            logger.info("Cache hit for OCR request")
            return {
                "status": "SUCCESS",
                "result": cachedResult.decode("utf-8"),  # type: ignore
                "execution_time": 0.0,
                "cached": True,
            }

        prompt = """Extract the code in the image exactly as it appears, but return it as raw source code with no extra characters. Do not format the code using markdown (e.g., no triple backticks). Do not include escape characters like \\n or \\t. Output must be plain text exactly how it would appear in a .java file. Remove all surrounding quotes, line breaks, or markup."""

        image = Image.open(BytesIO(image_bytes))
        max_size = 1024 if len(image_bytes) > 1024 * 1024 else 512
        image = image.resize((max_size, max_size))

        messages = [
            {"role": "system", "content": "You are a helpful assistant."},
            {
                "role": "user",
                "content": [
                    {"type": "image", "image": f"{image_bytes}"},
                    {"type": "text", "text": prompt},
                ],
            },
        ]

        if processor is None:
            logger.error("processor is not defined")
            raise RuntimeError("processor is not defined")

        text = processor.apply_chat_template(
            messages, tokenize=False, add_generation_prompt=True
        )
        inputs = processor(
            text=[text], images=[image], padding=True, return_tensors="pt"
        )
        inputs = inputs.to(device)

        if tokenizer is None:
            logger.error("tokenizer is not defined")
            raise RuntimeError("tokenizer is not defined")

        if model is None:
            logger.error("model is not defined")
            raise RuntimeError("model is not defined")

        with torch.no_grad():
            output_ids = model.generate(
                **inputs,
                max_new_tokens=maxNewTokens,
                do_sample=False,
                temperature=0.1,
                pad_token_id=tokenizer.eos_token_id,
            )

        generate_ids = [
            output_ids[len(input_ids) :]
            for input_ids, output_ids in zip(inputs.input_ids, output_ids)
        ]
        output_text = processor.batch_decode(
            generate_ids, skip_special_tokens=True, clean_up_tokenization_spaces=True
        )
        clean_result = output_text[0].replace("```", "").replace("\\n", "\n").strip()

        redis_client.setex(cacheKey, 3600, clean_result)

        processing_time = time.time() - start_time
        logger.info(f"OCR completed in {processing_time:.2f}s")

        return {
            "status": "SUCCESS",
            "result": clean_result,
            "execution_time": processing_time,
            "cached": False,
        }
    except Exception as e:
        logger.error(f"OCR processing failed: {e}")
        return {"status": "FAILURE", "error": str(e)}


@celeryApp.task(bind=True, name="ocr_service.execute_code")
def execute_code_task(self, code: str, language: str):
    try:
        self.update_state(
            state="PROGRESS", meta={"status": "Queuing code execution..."}
        )

        language = language.lower()

        message = {"code": code, "language": language, "task_id": self.request.id}

        if (
            not executionQueuePythonURL
            or not executionQueueJavaScriptURL
            or not executionQueueJavaURL
        ):
            logger.error(
                "EXECUTION URLs Cannot be None, there is a problem with env vars"
            )
            return {
                "status": "FAILURE",
                "error": "EXECUTION URLs Cannot be None, there is a problem with env vars",
            }

        def sendMessage(url: str, message: dict[str, str]):
            sqs.send_message(
                QueueUrl=url,
                MessageBody=json.dumps(message),
            )

        match language:
            case "python":
                sendMessage(executionQueuePythonURL, message)
            case "javascript":
                sendMessage(executionQueueJavaScriptURL, message)
            case "java":
                sendMessage(executionQueueJavaURL, message)
            case _:
                logger.error(f"Failed to queue execution: Invalid language passed")
                return {"status": "FAILURE", "error": "Invalid Language Passed"}

        return {
            "status": "SUCCESS",
            "task_id": message["task_id"],
            "queued_at": time.time(),
        }

    except ClientError as e:
        logger.error(f"Failed to queue execution: {e}")
        return {"status": "FAILURE", "error": str(e)}


# ======================== FASTAPI Endpoints ========================


@asynccontextmanager
async def lifespan(app: FastAPI):
    logger.info("Starting OCR service")

    yield

    logger.info("Shutting down OCR service")
    redis_client.close()


# FastAPI app setup
app = FastAPI(
    title="Code Recognition & Execution API",
    description="Production-ready OCR and code execution service",
    version="1.0.0",
    lifespan=lifespan,
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
    try:
        celery_inspect = celeryApp.control.inspect()
        active_workers = celery_inspect.active()
        worker_count = len(active_workers) if active_workers else 0
    except Exception as e:
        worker_count = 0
        logger.warning(f"Could not check worker status: {e}")

    return {
        "status": "healthy",
        "timestamp": time.time(),
        "device": device,
        "celery_workers": worker_count,
        "model_loaded": model is not None,
    }


@app.post("/ocr", response_model=OCRResponse)
async def recognize_code(
    title: Annotated[str, Form()],
    language: Annotated[str, Form()],
    max_tokens: Annotated[int, Form()] = 256,
    drawing: UploadFile = File(),
):

    try:
        if not drawing.content_type or not drawing.content_type.startswith("image/"):
            raise HTTPException(400, "File must be an image")

        contents = await drawing.read()

        # Encode image as base64 for Celery serialization
        import base64

        image_b64 = base64.b64encode(contents).decode("utf-8")

        task = process_ocr_task.delay(image_b64, max_tokens)

        task_metadata = {
            "title": title,
            "language": language,
            "created_at": time.time(),
            "celery_task_id": task.id,
        }

        redis_client.setex(f"task_meta:{task.id}", 600, json.dumps(task_metadata))

        return OCRResponse(task_id=task.id, status="processing")

    except Exception as e:
        logger.error(f"OCR request failed: {e}")
        raise HTTPException(status_code=500, detail=str(e))


@app.get("/ocr/{task_id}", response_model=OCRResponse)
def get_task_status(task_id: str):
    try:
        task_result = celeryApp.AsyncResult(task_id)

        if task_result.state == "PENDING":
            return OCRResponse(task_id=task_id, status="pending")
        elif task_result.state == "PROGRESS":
            return OCRResponse(
                task_id=task_id,
                status="processing",
                result=task_result.info.get("status", "Processing..."),
            )
        elif task_result.state == "SUCCESS":
            result_data = task_result.result
            return OCRResponse(
                task_id=task_id,
                status="completed",
                result=result_data.get("result"),
                execution_time=result_data.get("execution_time"),
                cached=result_data.get("cached"),
            )
        elif task_result.state == "FAILURE":
            result_data = (
                task_result.result
                if isinstance(task_result.result, dict)
                else {"error": str(task_result.result)}
            )
            return OCRResponse(
                task_id=task_id,
                status="failed",
                error=result_data.get("error", "Unknown error"),
            )
        else:
            return OCRResponse(task_id=task_id, status=task_result.state.lower())
    except Exception as e:
        logger.error(f"Error getting task status: {e}")
        raise HTTPException(status_code=500, detail="Error retrieving task status")


@app.get("/ocr/stream/{task_id}")
async def get_streamed_task_status(task_id: str, wait: int = 35):
    async def eventgen():
        deadline = asyncio.get_event_loop().time() + wait
        while asyncio.get_event_loop().time() < deadline:
            r = celeryApp.AsyncResult(task_id)
            state = r.state
            if state == "PROGRESS":
                yield f"data:{json.dumps({'status': 'processing', 'task_id': task_id, 'result': r.info})}\n\n"
            elif state == "SUCCESS":
                yield f"data:{json.dumps({'status': 'completed', 'task_id': task_id, 'result': r.result})}\n\n"
                break
            elif state == "FAILURE":
                err = r.result if isinstance(r.result, str) else str(r.result)
                yield f"data:{json.dumps({'status': 'failed', 'task_id': task_id,  'result': err})}\n\n"
                break
            else:
                yield f"data:{json.dumps({'status': state.lower(), 'task_id': task_id, 'result': None})}\n\n"
            await asyncio.sleep(0.8)
        else:
            yield f"data:{json.dumps({'status':'timeout', 'task_id': task_id, 'result': None})}\n\n"

    return StreamingResponse(content=eventgen(), media_type="text/event-stream")


@app.post("/execute")
async def execute_code(request: ExecutionRequest):
    try:
        task = execute_code_task.delay(request.code, request.language)

        return {"status": "queued", "task_id": task.id}

    except Exception as e:
        logger.error(f"Failed to queue execution: {e}")
        raise HTTPException(status_code=500, detail="Failed to queue execution")


@app.get("/execute/{task_id}")
async def get_execution_status(task_id: str):
    try:
        # task_result = celeryApp.AsyncResult(task_id)
        raw_result = redis_client.get(f"execution:{task_id}")

        if raw_result:
            try:
                result = json.loads(raw_result.decode("utf-8"))  # type:ignore
            except:
                result = raw_result.decode("utf-8")  # type:ignore

            payload = {
                "status": "success",
                "task_id": task_id,
                "result": result,
            }

            return f"data:{json.dumps(payload)}"
        else:
            payload = {
                "status": "pending",
                "task_id": task_id,
                "result": None,
            }

            return f"data:{json.dumps(payload)}"

    except Exception as e:
        logger.error(f"Error getting execution status: {e}")
        payload = {
                "status": "error",
                "task_id": task_id,
                "result": e,
            }

        return f"data:{json.dumps(payload)}"


@app.get("/execute/stream/{task_id}")
async def get_streamed_execution_status(task_id: str, wait: int = 35):
    async def eventgen():
        deadline = asyncio.get_event_loop().time() + wait
        while asyncio.get_event_loop().time() < deadline:
            try:
                raw_result = redis_client.get(f"execution:{task_id}")
                # print(raw_result)
                if raw_result:
                    try:
                        parsed = json.loads(raw_result.decode("utf-8"))  # type:ignore
                    except:
                        parsed = raw_result.decode("utf-8")  # type:ignore
                    payload = {
                        "status": "success",
                        "task_id": task_id,
                        "result": parsed,
                    }
                    yield f"data:{json.dumps(payload)}\n\n"
                    break
                else:
                    yield f"data: {json.dumps({'status': 'pending', 'task_id': task_id, 'result': None})}\n\n"
            except Exception as e:
                logger.exception(f"Error reading execution status for {task_id}: {e}")
                yield f"data: {json.dumps({'status': 'pending in except (error occurred)', 'task_id': task_id, 'result': None})}\n\n"
            await asyncio.sleep(0.8)
        else:
            yield f"data: {json.dumps({'status': 'timed out', 'task_id': task_id, 'result': None})}\n\n"

    return StreamingResponse(content=eventgen(), media_type="text/event-stream")


# Add endpoint to get all active tasks
@app.get("/tasks/active")
async def get_active_tasks():
    try:
        celery_inspect = celeryApp.control.inspect()
        active_tasks = celery_inspect.active()
        return {"active_tasks": active_tasks or {}}
    except Exception as e:
        logger.error(f"Error getting active tasks: {e}")
        raise HTTPException(status_code=500, detail="Error retrieving active tasks")


@app.delete("/task/{task_id}")
async def cancel_task(task_id: str):
    try:
        celeryApp.control.revoke(task_id, terminate=True)
        return {"message": f"Task {task_id} cancelled"}
    except Exception as e:
        logger.error(f"Error cancelling task: {e}")
        raise HTTPException(status_code=500, detail="Error cancelling task")


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=8000, reload=False)
