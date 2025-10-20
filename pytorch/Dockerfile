ARG BASE_IMAGE="ghcr.io/ousso11/docker-images/base:main"

FROM ${BASE_IMAGE}

# Link this image to the GitHub repository
LABEL org.opencontainers.image.source="https://github.com/Ousso11/docker-images"
LABEL org.opencontainers.image.description="PyTorch image with CUDA support and ML libraries"
LABEL org.opencontainers.image.licenses="MIT"

# Copy disk space cleanup script
COPY free_disk_space.sh /app/free_disk_space.sh
RUN chmod +x /app/free_disk_space.sh

# install conda environment - copy requirements to a safe location
COPY pytorch/requirements.txt /app/requirements.txt

# Free space before heavy installations
RUN /app/free_disk_space.sh

# Install MPI development libraries BEFORE pip install (needed for mpi4py)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libopenmpi-dev \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Verify conda installation and install Python packages
RUN ls -la /opt/conda/bin/ && \
    /opt/conda/bin/conda --version && \
    /opt/conda/bin/pip --version && \
    /opt/conda/bin/pip install -r /app/requirements.txt --no-cache-dir && \
    /opt/conda/bin/pip cache purge

# install requirements
RUN /opt/conda/bin/pip install "unsloth[colab-new] @ git+https://github.com/unslothai/unsloth.git" && \
    /opt/conda/bin/pip cache purge && \
    rm /app/requirements.txt
    

# install ngrok
RUN curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
	| sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
	&& echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
	| sudo tee /etc/apt/sources.list.d/ngrok.list \
	&& sudo apt update \
	&& sudo apt install ngrok

RUN . /opt/conda/etc/profile.d/conda.sh && \
     conda activate base && conda install -c nvidia -y nccl

