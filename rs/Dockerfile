# ===========================
# RS Relation Search - Unified Docker Image
# CUDA 12.1 + Python 3.11 + PyTorch + All Dependencies
# ===========================

# Use official PyTorch image with CUDA support
FROM pytorch/pytorch:2.1.2-cuda12.1-cudnn8-devel

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV CUDA_HOME=/usr/local/cuda
ENV PATH=${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}

# Set working directory
WORKDIR /app

# Update system packages and install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    curl \
    wget \
    vim \
    build-essential \
    cmake \
    pkg-config \
    libopencv-dev \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    graphviz \
    graphviz-dev \
    && rm -rf /var/lib/apt/lists/*

# Upgrade pip and install wheel
RUN pip install --upgrade pip setuptools wheel

# Copy requirements file
COPY rs/requirements.txt .

# Install Python dependencies with specific PyTorch CUDA version
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121

# Install remaining requirements
RUN pip install -r requirements.txt

# Create necessary directories
RUN mkdir -p /app/data /app/logs /app/outputs

# Copy application code
COPY .. /app/

# Set Python path to include the app directory
ENV PYTHONPATH=/app

# Expose ports for FastAPI and Gradio
EXPOSE 8000 7860

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}'); print(f'CUDA devices: {torch.cuda.device_count()}')" || exit 1

# Default command
CMD ["bash"]

# ===========================
# Build Instructions:
# docker build -t rs-relation-search:latest .
# 
# Run Instructions:
# docker run --gpus all -it --rm \
#   -v $(pwd)/data:/app/data \
#   -v $(pwd)/outputs:/app/outputs \
#   -p 8000:8000 -p 7860:7860 \
#   rs-relation-search:latest
# ===========================