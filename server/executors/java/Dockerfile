# executors/java/Dockerfile
FROM amazoncorretto:17

# Install Python for the executor script
RUN yum install -y python3 python3-pip \
    && yum clean all

WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip3 install --no-cache-dir -r requirements.txt

# Copy executor script
COPY executor.py .

# Create non-root user
RUN adduser --uid 1000 --disabled-password --gecos "" executor && chown -R executor:executor /app
USER executor

# Create directories for code execution
RUN mkdir -p /app/temp /app/output

CMD ["python3", "executor.py"]