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
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && rm -rf /tmp/* /var/tmp/*

# Upgrade pip and install wheel
RUN pip install --upgrade pip setuptools wheel && pip cache purge

# Install PyTorch with CUDA support (already compatible with base image)
RUN pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121 \
    && pip cache purge \
    && rm -rf /tmp/* /var/tmp/* \
    && apt-get clean

# Set Python path to include the app directory
ENV PYTHONPATH=/app

# Default command
CMD ["bash"]

