# ==========================================
# STAGE 1: Build Environment (The "Builder")
# ==========================================
# 1. Pin to a specific OS release (bookworm) to guarantee deterministic builds.
FROM python:3.10.14-slim-bookworm AS builder

# 2. Set environment variables to optimize Python execution.
# PYTHONDONTWRITEBYTECODE: Prevents Python from writing useless .pyc files to disk.
# PYTHONUNBUFFERED: Ensures logs are piped directly to the terminal (critical for Datadog/Prometheus).
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

# 3. Install OS-level build dependencies (often needed to compile C-extensions in Pandas/Numpy).
# The apt cache is immediately cleared to save space.
RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential gcc && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /build

# 4. Create an isolated virtual environment. 
# This prevents conflicts with the container's system-level Python packages.
RUN python -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

# 5. Install Python dependencies.
COPY requirements.txt .
RUN pip install --no-cache-dir --upgrade pip && \
    pip install --no-cache-dir -r requirements.txt


# ==========================================
# STAGE 2: Production Environment (The "Runner")
# ==========================================
# 6. Start fresh from the base image. This drops all the heavy build tools (like gcc) 
# used in Stage 1, drastically reducing the final image size and attack surface.
FROM python:3.10.14-slim-bookworm

# 7. Add enterprise metadata for your container registry.
LABEL maintainer="infrastructure-team" \
      org.opencontainers.image.title="Python Metrics Processor" \
      org.opencontainers.image.version="1.0.0"

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PATH="/opt/venv/bin:$PATH"

# 8. Security: Create a dedicated non-root user. 
# Running as root inside a container is a major security vulnerability.
RUN groupadd -r appgroup && useradd -r -g appgroup appuser

WORKDIR /app

# 9. Copy ONLY the compiled virtual environment from the builder stage.
# We also change ownership of these files to our non-root user.
COPY --from=builder --chown=appuser:appgroup /opt/venv /opt/venv

# 10. Copy the actual application code.
COPY --chown=appuser:appgroup . .

# 11. Switch to the non-root user before executing any code.
USER appuser

# 12. Define the exact command to run.
CMD ["python", "app.py"]