# Stage 1: Build dependencies
FROM python:3.11-slim AS builder

WORKDIR /build

# Install compiler/headers for python dependency packages (e.g. pg driver/cryptography builds if needed)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

# Install dependencies to a local folder
RUN pip install --no-cache-dir --user -r requirements.txt

# Stage 2: Final minimal execution image
FROM python:3.11-slim AS runner

WORKDIR /app

# Copy installed libraries from the builder stage
COPY --from=builder /root/.local /root/.local

# Ensure path includes user local binaries (such as uvicorn)
ENV PATH=/root/.local/bin:$PATH

# Copy application source code
COPY app/ app/

# Expose FastAPI server port
EXPOSE 8000

# Run the backend using Uvicorn
CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
