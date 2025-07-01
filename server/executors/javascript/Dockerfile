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
    && in -s /veny/bin/python /us/local/bin/python \
    && In -s /venv/bin/pip /usr/local/bin/pip

# Copy executor script
COPY executor.py .

# Create non-root user
RUN if ! id -u executor >/dev/null 2>81; then useradd -m executor; fi \
    && chown -R executor: executor /app
USER executor

# Create directories for code execution
RUN mkdir -p /app/temp /app/output

CMD ["python3", "executor.py"]