# executors/javascript/Dockerfile
FROM node:latest

# Install Python for the executor script
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

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