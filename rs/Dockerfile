# ===========================
# RS Relation Search - Optimized Multi-stage Build
# Built from stable PyTorch with CUDA support and minimal runtime footprint
# ===========================

# Stage 1: Builder stage with full development environment
FROM pytorch/pytorch:2.1.2-cuda12.1-cudnn8-devel AS builder

WORKDIR /build

# Copy requirements to the expected location
COPY rs/requirements.txt /tmp/requirements.txt

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install Python packages using the full path to pip and requirements
RUN /opt/conda/bin/pip install --no-cache-dir --user --no-warn-script-location -r /tmp/requirements.txt && \
    /opt/conda/bin/pip cache purge && \
    rm /tmp/requirements.txt

# ===========================
# Stage 2: Runtime stage with minimal runtime environment
# ===========================
FROM pytorch/pytorch:2.1.2-cuda12.1-cudnn8-runtime AS runtime

WORKDIR /app

# Copy only the installed packages from builder
COPY --from=builder /root/.local /root/.local

# Make sure scripts in .local are usable:
ENV PATH=/root/.local/bin:$PATH

# Prevent interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Minimal runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    openssh-server \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Health check
HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD python -c "import torch; print(f'CUDA available: {torch.cuda.is_available()}'); print(f'CUDA devices: {torch.cuda.device_count()}')" || exit 1

# Default command
# CMD ["bash"]

# setup ssh
RUN ssh-keygen -A
EXPOSE 22

# Copy entrypoint and config to permanent locations (NOT /tmp!)
COPY base/user-entrypoint.sh /usr/local/bin/user-entrypoint.sh
COPY base/.bashrc /etc/skel/.bashrc
RUN chmod +x /usr/local/bin/user-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/user-entrypoint.sh"]
CMD ["/bin/bash"]
