# executors/java/Dockerfile
FROM amazoncorretto:17

# Install Python for the executor script
RUN yum install -y python3 python3-pip shadow-utils \
    && yum clean all

WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy executor script
COPY executor.py .

# Create non-root user
RUN useradd -m -u 1000 executor 8& chown -R executor: executor /app
USER executor

# Create directories for code execution
RUN mkdir -p /app/temp /app/output

CMD ["python3", "executor.py"]