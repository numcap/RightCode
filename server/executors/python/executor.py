import os
import json
import subprocess
import tempfile
import time
import logging
import boto3
import redis

# Configure logging
logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)

# Env Variables
redisURL = os.getenv("REDIS_URL_OCR")
executionQueueURL = os.getenv("EXECUTION_QUEUE_URL")
awsRegion = os.getenv("AWS_REGION")

# Initialize services
redis_client = redis.from_url(redisURL)
sqs = boto3.client('sqs', region_name=awsRegion)

class CodeExecutor:
    def __init__(self):
        self.timeout = 10 # seconds
        self.memory_limit = 128 * 1024 * 1024 #128MB
        
    def execute_python(self, code: str):
        try:
            dangerous_imports = ['os', 'subprocess', 'sys', 'importlib', '__builtin__']
            
            for imp in dangerous_imports:
                if f"import {imp}" in code or f"from {imp}" in code:
                    return {
                        "success": False,
                        "output": None,
                        "errors": f"Import '{imp}' is not allowed for security reasons",
                        "stage": "security_check"
                    }
            
            with tempfile.NamedTemporaryFile(mode="w", suffix=".py", delete=False) as tf:
                tf.write(code)
                python_file = tf.name
                
            try:
                env = os.environ.copy()
                env['PYTHONDONTWRITEBYTECODE'] = '1'
                result = subprocess.run(
                    ["python3", f"{python_file}"],
                    capture_output=True,
                    text=True,
                    timeout=self.timeout,
                    env=env
                )
                
                return {
                    "success": result.returncode == 0,
                    "output": result.stdout,
                    "errors": result.stderr if result.returncode != 0 else None,
                    "stage": "execution",
                    "exit_code": result.returncode
                }
            
            finally:
                os.unlink(python_file)
            
        except subprocess.TimeoutExpired:
            return {
                "success": False,
                "output": None,
                "errors": "Code execution timed out",
                "stage": "execution"
            }
        except Exception as e:
            return {
                "success": False,
                "output": None,
                "errors": str(e),
                "stage": "setup"
            }
    
def process_execution_messages(): 
    logger.info("initializing the executor class")
    executor = CodeExecutor()
    
    while True:
        try: 
            logger.info("about to receive sqs messages")
            res = sqs.receive_message(
                QueueUrl=executionQueueURL,
                MaxNumberOfMessages=1,
                WaitTimeSeconds=20
            )
            logger.info("received these as messages: \n" + json.dumps(res, indent=2))
            
            messages = res.get("Messages", [])
            
            for message in messages:
                try:
                    body = json.loads(message["Body"])
                    code = body["code"]
                    language: str = body["language"]
                    
                    if language.lower() != "python":
                        continue
                    
                    logger.info(f"Executing Python Code")
                    
                    start_time = time.time()
                    result = executor.execute_python(code)
                    execution_time = time.time() - start_time
                    
                    result["execution_time"] = execution_time
                    result["language"] = language
                    result['worker'] = "python-executor"
                    
                    result_key = f"execution:{message['MessageId']}"
                    redis_client.setex(result_key, 600, json.dumps(result))
                    
                    logger.info(f"Execution completed in {execution_time:.2f}s")
                    
                    sqs.delete_message(
                        QueueUrl=executionQueueURL,
                        ReceiptHandle=message['ReceiptHandle']
                    )
                    
                except Exception as e:
                    logger.error(f"Failed to process message: {e}")
                    result = {
                        "success": False,
                        "output": "There was a problem with our servers or formatting of the code, please try again later",
                        "errors": str(e),
                        "stage": "execution",
                        "exit_code": 500
                    }
                    result_key = f"execution:{message['MessageId']}"
                    redis_client.setex(result_key, 600, json.dumps(result))
                    sqs.delete_message(
                        QueueUrl=executionQueueURL,
                        ReceiptHandle=message['ReceiptHandle']
                    )
            
                except KeyboardInterrupt:
                    logger.info("Shutting down executor")
                    break
        except Exception as e:
            logger.error(f"Error in main loop: {e}")
            time.sleep(5)  # Wait before retrying

if __name__ == "__main__":
    logger.info(f"Starting python code executor")
    process_execution_messages()
