# ===========================
# RS Relation Search - Full Image
# Extends rs_base and installs all requirements
# ===========================

# Use the rs_base image as foundation
ARG REGISTRY=ghcr.io
ARG REPO=ousso11/docker-images
ARG BASE_TAG=latest
FROM ${REGISTRY}/ousso11/docker-images/rs_base:${BASE_TAG}

# Set working directory
WORKDIR /app

# Copy requirements file
COPY requirements.txt .

# Install all requirements with optimized chunking
RUN pip install --no-cache-dir -r requirements.txt && pip cache purge

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}'); print(f'CUDA devices: {torch.cuda.device_count()}')" || exit 1

# Default command
CMD ["bash"]

# ===========================
# Build Instructions:
# docker build -t rs-full:latest .
# 
# Run Instructions:
# docker run --gpus all -it --rm \
#   -v $(pwd)/data:/app/data \
#   -v $(pwd)/outputs:/app/outputs \
#   -p 8000:8000 -p 7860:7860 \
#   rs-full:latest
# ===========================