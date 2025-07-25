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
redisURL = os.getenv("REDIS_URL")
executionQueueURL = os.getenv("EXECUTION_QUEUE_URL")
awsRegion = os.getenv("AWS_REGION")

# Initialize services
redis_client = redis.from_url(redisURL)
sqs = boto3.client('sqs', region_name=awsRegion)

class CodeExecutor:
    def __init__(self):
        self.timeout = 10 # seconds
        self.memory_limit = 128 * 1024 * 1024 #128MB
        
    def execute_javascript(self, code: str):
        try:
            with tempfile.NamedTemporaryFile(mode="w", suffix=".js", delete=False) as tf:
                tf.write(code)
                js_file = tf.name
            
            try:
                result = subprocess.run(
                    ["node", f"{js_file}"],
                    capture_output=True,
                    text=True,
                    timeout=self.timeout
                )
                
                return {
                    "success": result.returncode == 0,
                    "output": result.stdout,
                    "errors": result.stderr if result.returncode != 0 else None,
                    "stage": "execution",
                    "exit_code": result.returncode
                }
                
            finally:
                os.unlink(js_file)
                
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
    executor = CodeExecutor()
    
    while True:
        try: 
            res = sqs.receive_message(
                QueueUrl=executionQueueURL,
                MaxNumberOfMessages=1,
                WaitTimeSeconds=20
            )
            
            messages = res.get("Messages", [])
            
            for message in messages:
                try:
                    body = json.loads(message["body"])
                    code = body["code"]
                    language: str = body["language"]
                    
                    if language.lower() != "javascript":
                        continue
                    
                    logger.info(f"Executing JavaScript Code")
                    
                    start_time = time.time()
                    result = executor.execute_javascript(code)
                    execution_time = time.time() - start_time
                    
                    result["execution_time"] = execution_time
                    result["language"] = language
                    result['worker'] = "javascript-executor"
                    
                    result_key = f"execution: {message['MessageId']}"
                    redis_client.setex(result_key, 600, json.dumps(result))
                    
                    logger.info(f"Execution completed in {execution_time:.2f}s")
                    
                    sqs.delete_message(
                        QueueUrl=executionQueueURL,
                        ReceiptHandle=message['ReceiptHandle']
                    )
                    
                except Exception as e:
                    logger.error(f"Failed to process message: {e}")
            
                except KeyboardInterrupt:
                    logger.info("Shutting down executor")
                    break
        except Exception as e:
            logger.error(f"Error in main loop: {e}")
            time.sleep(5)  # Wait before retrying

if __name__ == "__main__":
    logger.info(f"Starting java code executor")
    process_execution_messages()
