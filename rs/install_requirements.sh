#!/bin/bash
# Install requirements.txt by chunks based on comments

set -e  # Exit on error

echo "Installing Python packages by chunks to manage disk space..."

# Function to install a chunk and clean cache
install_chunk() {
    local chunk_name="$1"
    shift
    local packages="$@"
    
    echo "Installing $chunk_name..."
    pip install --no-cache-dir $packages
    pip cache purge
    echo "$chunk_name installed successfully!"
}

# Read requirements.txt and extract packages by sections
cd /app

# DEEP LEARNING & AI CORE (skip torch as it's already installed)
install_chunk "DEEP LEARNING & AI CORE" \
    "torch_geometric==2.6.1" \
    "transformers==4.56.2" \
    "accelerate==1.10.1" \
    "tokenizers==0.22.1"

# SCIENTIFIC COMPUTING
install_chunk "SCIENTIFIC COMPUTING" \
    "numpy>=1.26.0,<3.0.0" \
    "scipy>=1.10.0" \
    "pandas>=1.5.0" \
    "scikit-learn>=1.5.0" \
    "joblib>=1.3.0"

# COMPUTER VISION
install_chunk "COMPUTER VISION" \
    "opencv-python>=4.8.0" \
    "opencv-python-headless>=4.8.0" \
    "open-clip-torch>=2.20.0" \
    "clip-benchmark==1.6.1" \
    "torch-linear-assignment==0.0.5"

# LLM & LANGUAGE MODELS
install_chunk "LLM & LANGUAGE MODELS" \
    "pydantic>=2.5.0" \
    "langchain==0.3.27" \
    "langchain-community==0.3.30" \
    "langchain-litellm==0.2.3" \
    "langchain_openai==0.3.34" \
    "langchain-google-genai==2.1.5" \
    "spacy==3.8.7"

# WEB FRAMEWORKS & API
install_chunk "WEB FRAMEWORKS & API" \
    "fastapi==0.115.12" \
    "uvicorn==0.34.3" \
    "python-multipart==0.0.20" \
    "gradio==5.35.0"

# DATA PROCESSING
install_chunk "DATA PROCESSING" \
    "datasets==3.6.0" \
    "json-repair==0.40.0" \
    "jsonlines==4.0.0" \
    "python-dotenv==1.0.0" \
    "requests>=2.32.5"

# VISUALIZATION & PLOTTING
install_chunk "VISUALIZATION & PLOTTING" \
    "matplotlib==3.10.1" \
    "seaborn>=0.11.0" \
    "plotly==6.0.1"

# DEVELOPMENT & UTILITIES
install_chunk "DEVELOPMENT & UTILITIES" \
    "tqdm>=4.64.0" \
    "tabulate==0.9.0" \
    "shapely==2.0.7" \
    "termcolor==3.0.1" \
    "image==1.5.33" \
    "openpyxl>=3.0.0" \
    "aria2p>=0.11.3"

# GRAPH PROCESSING
install_chunk "GRAPH PROCESSING" \
    "pydot==3.0.0"

# JUPYTER & NOTEBOOKS
install_chunk "JUPYTER & NOTEBOOKS" \
    "jupyter==1.1.1" \
    "ipywidgets==8.1.5"

# TRAINING UTILITIES
install_chunk "TRAINING UTILITIES" \
    "wandb>=0.22.1" \
    "torch_lr_finder==0.2.2" \
    "torchinfo==1.8.0"

# DEVELOPMENT & TESTING
install_chunk "DEVELOPMENT & TESTING" \
    "pytest==8.3.5" \
    "black==25.1.0"

# Skip vllm for now (very heavy package)
echo "Skipping vllm==0.10.2 (too heavy for current build)"

echo "All packages installed successfully!"