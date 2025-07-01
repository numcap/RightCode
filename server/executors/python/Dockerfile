# executors/python3/Dockerfile
FROM python:3.14-rc-bookworm

WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy executor script
COPY executor.py .

# Create non-root user
RUN useradd -m -u 1000 executor && chown -R executor:executor /app
USER executor

# Create directories for code execution
RUN mkdir -p /app/temp /app/output

CMD ["python3", "executor.py"]