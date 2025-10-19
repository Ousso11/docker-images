# ===========================
# RS Relation Search - Full Image
# Extends rs_base and installs all requirements
# ===========================

# Use the rs_base image as foundation
ARG REGISTRY=ghcr.io
ARG REPO=ousso11/docker-images
ARG BASE_TAG=latest
FROM ${REGISTRY}/${REPO}/rs_base:${BASE_TAG}

# Set working directory
WORKDIR /app

# Copy requirements file
COPY requirements.txt .

# Install all requirements with optimized chunking
RUN pip install --no-cache-dir \
    # Scientific Computing
    numpy>=1.26.0 \
    scipy>=1.10.0 \
    pandas>=1.5.0 \
    scikit-learn>=1.5.0 \
    joblib>=1.3.0 && \
    pip cache purge && \
    rm -rf /tmp/* /var/tmp/*

RUN pip install --no-cache-dir \
    # Computer Vision
    opencv-python-headless>=4.8.0 \
    open-clip-torch>=2.20.0 && \
    pip cache purge && \
    rm -rf /tmp/* /var/tmp/*

RUN pip install --no-cache-dir \
    # Deep Learning & AI Core
    torch_geometric==2.6.1 \
    transformers==4.56.2 \
    accelerate==1.10.1 \
    tokenizers==0.22.1 && \
    pip cache purge && \
    rm -rf /tmp/* /var/tmp/*

RUN pip install --no-cache-dir \
    # LLM & Language Models
    pydantic>=2.5.0 \
    langchain==0.3.27 \
    langchain-community==0.3.30 \
    langchain-litellm==0.2.3 \
    langchain_openai==0.3.34 \
    langchain-google-genai==2.1.5 && \
    pip cache purge && \
    rm -rf /tmp/* /var/tmp/*

RUN pip install --no-cache-dir \
    # Web Frameworks & API
    fastapi==0.115.12 \
    uvicorn==0.34.3 \
    python-multipart==0.0.20 \
    gradio==5.35.0 && \
    pip cache purge && \
    rm -rf /tmp/* /var/tmp/*

RUN pip install --no-cache-dir \
    # Data Processing & Utilities
    datasets==3.6.0 \
    json-repair==0.40.0 \
    jsonlines==4.0.0 \
    python-dotenv==1.0.0 \
    requests>=2.32.5 \
    tqdm>=4.64.0 \
    tabulate==0.9.0 \
    termcolor==3.0.1 && \
    pip cache purge && \
    rm -rf /tmp/* /var/tmp/*

RUN pip install --no-cache-dir \
    # Visualization & Development
    matplotlib==3.10.1 \
    seaborn>=0.11.0 \
    plotly==6.0.1 \
    pytest==8.3.5 \
    jupyter==1.1.1 \
    wandb>=0.22.1 && \
    pip cache purge && \
    rm -rf /tmp/* /var/tmp/*

# Skip very heavy packages for now
# vllm==0.10.2 - too heavy
# spacy==3.8.7 - heavy with models
# clip-benchmark==1.6.1 - causes issues

# Create necessary directories
RUN mkdir -p /app/data /app/logs /app/outputs

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