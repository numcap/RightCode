# executors/javascript/Dockerfile
FROM node:latest

# Install Python for the executor script
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN python3 -m venv /venv \
    && /venv/bin/pip install --no-cache-dir -r requirements.txt \
    && ln -s /venv/bin/python /usr/local/bin/python \
    && ln -s /venv/bin/pip /usr/local/bin/pip

# Copy executor script
COPY executor.py .

# Create non-root user
RUN useradd -m executor && chown -R executor:executor /app
USER executor

# Create directories for code execution
RUN mkdir -p /app/temp /app/output

CMD ["/venv/bin/python", "executor.py"]