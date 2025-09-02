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
executionQueueURL = os.getenv("EXECUTION_QUEUE_JAVA_URL")
awsRegion = os.getenv("AWS_REGION")

# Initialize services
redis_client = redis.from_url(redisURL)
sqs = boto3.client('sqs', region_name=awsRegion)

class CodeExecutor:
    def __init__(self):
        self.timeout = 10 # seconds
        self.memory_limit = 128 * 1024 * 1024 #128MB
        
    def execute_java(self, code: str): 
        try: 
            with tempfile.TemporaryDirectory() as temp_dir:
                class_name = self.extract_java_classname(code)
                java_file = os.path.join(temp_dir, f"{class_name}.java")
                
                with open(java_file, "w") as f:
                    f.write(code)
                    
                compile_result = subprocess.run(
                    ["javac", java_file],
                    capture_output=True,
                    text=True,
                    timeout=self.timeout,
                    cwd=temp_dir
                )
                
                if compile_result.returncode != 0:
                    return {
                        "success": False,
                        "output": None,
                        "errors": compile_result.stderr,
                        "stage": "compilation"
                    }
                    
                security_policy = self.create_security_fallback(temp_dir)
                
                execute_result = subprocess.run(
                    [
                        'java',
                        f'-Djava.security.manager',
                        f'-Djava.security.policy={security_policy}',
                        f'-Xmx{self.memory_limit // (1024*1024)}m',
                        '-cp', temp_dir,
                        class_name
                    ],
                    capture_output=True,
                    text=True, 
                    timeout=self.timeout,
                    cwd=temp_dir
                )
                
                return {
                    "success": execute_result.returncode == 0,
                    "output": execute_result.stdout,
                    "errors": execute_result.stderr if execute_result.returncode != 0 else None,
                    "stage": "execution",
                    "exit_code": execute_result.returncode
                }

                
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

    
    def extract_java_classname(self, code: str) -> str:
        import re
        match = re.search(r'public\s+class\s+(\w+)', code)
        if match:
            return match.group(1)
        
        # Fallback to finding any class
        match = re.search(r'class\s+(\w+)', code)
        if match:
            return match.group(1)
        
        return "Main"  # Default fallback
    
    def create_security_fallback(self, temp_dir: str) -> str:
        policy_content = f""" 
        grant {{
            permission java.io.FilePermission "{temp_dir}/-", "read,write";
            permission java.lang.RuntimePermission "exitVM";
            permission java.util.PropertyPermission "*", "read";
        }};
        """
        policy_file = os.path.join(temp_dir, "security.policy")
        with open(policy_file, 'w') as f:
            f.write(policy_content)
        return policy_file

def process_execution_messages(): 
    logger.info("initializing the executor class")
    executor = CodeExecutor()

    while True:
        try: 
            if not executionQueueURL:
                logger.error("Execution URL cannot be None")
                break
            logger.info("about to receive sqs messages")
            res = sqs.receive_message(
                QueueUrl=executionQueueURL,
                MaxNumberOfMessages=5,
                WaitTimeSeconds=5,
                VisibilityTimeout=60,
            )
            logger.info("received these as messages: \n" + json.dumps(res, indent=2))

            messages = res.get("Messages", [])

            for message in messages:
                try:
                    body = json.loads(message["Body"])
                    code = body["code"]
                    language: str = body["language"]

                    if language.lower() != "java":
                        continue

                    logger.info(f"Executing Java Code")

                    start_time = time.time()
                    result = executor.execute_java(code)
                    execution_time = time.time() - start_time

                    result["execution_time"] = execution_time
                    result["language"] = language
                    result['worker'] = "java-executor"

                    result_key = f"execution:{body['task_id']}"
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
                    result_key = f"execution:{body['task_id']}"
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
    logger.info(f"Starting java code executor")
    process_execution_messages()
