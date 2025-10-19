# ===========================
# RS Relation Search - Base Image
# Built from PyTorch official image with CUDA 12.1 support
# ===========================

# Use official PyTorch image with CUDA support
FROM pytorch/pytorch:2.1.2-cuda12.1-cudnn8-devel

# Copy disk space cleanup script
COPY ../free_disk_space.sh /app/free_disk_space.sh
RUN chmod +x /app/free_disk_space.sh

# Free space before heavy installations
RUN /app/free_disk_space.sh

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV CUDA_HOME=/usr/local/cuda-12.1
ENV PATH=/opt/conda/bin:${CUDA_HOME}/bin:${PATH}
ENV LD_LIBRARY_PATH=${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}

# Set working directory
WORKDIR /app

# Aggressive cleanup of PyTorch cache and unnecessary files to free space
RUN conda clean -all -f -y && \
    pip cache purge && \
    rm -rf /opt/conda/pkgs/* && \
    rm -rf /tmp/* && \
    rm -rf /var/tmp/* && \
    find /opt/conda -name "*.pyc" -delete && \
    find /opt/conda -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Free space after initial cleanup
RUN /app/free_disk_space.sh

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

# Set Python path to include the app directory
ENV PYTHONPATH=/app


# setup ssh
RUN ssh-keygen -A
EXPOSE 22

COPY base/user-entrypoint.sh /tmp/user-entrypoint.sh
COPY base/.bashrc /tmp/.bashrc
RUN chmod +x /tmp/user-entrypoint.sh

ENTRYPOINT ["/tmp/user-entrypoint.sh"]
CMD ["/bin/bash"]


