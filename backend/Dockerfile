FROM python:3.11-slim AS base

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1

# System deps: psycopg2 needs libpq; build-essential for any wheels that miss
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential libpq-dev curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Install Python deps first (better layer cache)
COPY requirements.txt .
RUN pip install --upgrade pip && pip install -r requirements.txt gunicorn==22.0.0

# Copy source
COPY . .

# Remove build tools to slim the image
RUN apt-get purge -y --auto-remove build-essential && rm -rf /var/lib/apt/lists/*

EXPOSE 8000

# Health probe for Railway / Docker
HEALTHCHECK --interval=30s --timeout=5s --start-period=20s --retries=3 \
    CMD curl -fsS http://localhost:8000/health || exit 1

# Railway sets $PORT — use it when present, fall back to 8000 locally.
CMD gunicorn main:app -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8000 --workers 2 --timeout 60