# ===========================
# RS Relation Search - Complete Image
# Built directly from PyTorch with CUDA and all requirements
# ===========================

# Use official PyTorch image with CUDA support directly - Latest version
FROM pytorch/pytorch:2.9.0-cuda12.6-cudnn8-runtime

# Set working directory
WORKDIR /app

# Copy disk space cleanup script first
COPY free_disk_space.sh /app/free_disk_space.sh
RUN chmod +x /app/free_disk_space.sh

# Aggressive cleanup of PyTorch cache to free space
RUN conda clean -all -f -y && \
    pip cache purge && \
    rm -rf /opt/conda/pkgs/* && \
    rm -rf /tmp/* /var/tmp/* && \
    find /opt/conda -name "*.pyc" -delete && \
    find /opt/conda -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Free space before installations
RUN /app/free_disk_space.sh

# Copy requirements and install directly with pip
COPY rs/requirements.txt /app/requirements.txt

# Install requirements with space management
RUN /app/free_disk_space.sh && \
    pip install --no-cache-dir -r /app/requirements.txt && \
    pip cache purge && \
    /app/free_disk_space.sh && \
    rm /app/requirements.txt

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