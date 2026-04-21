FROM python:3.11-slim

WORKDIR /app

# ติดตั้ง system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libpq-dev \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copy และติดตั้ง Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY . .

# Expose port
EXPOSE 8000

# รันด้วย uvicorn (รับ PORT จาก environment)
CMD uvicorn main:app --host 0.0.0.0 --port ${PORT:-8000}