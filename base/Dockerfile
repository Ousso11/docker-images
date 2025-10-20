ARG BASE_IMAGE="nvidia/cuda:12.4.0-devel-ubuntu22.04"

FROM ${BASE_IMAGE}

# Link this image to the GitHub repository
LABEL org.opencontainers.image.source="https://github.com/Ousso11/docker-images"
LABEL org.opencontainers.image.description="Base image with CUDA 12.4 and development tools"
LABEL org.opencontainers.image.licenses="MIT"

# Copy disk space cleanup script
COPY free_disk_space.sh /app/free_disk_space.sh
RUN chmod +x /app/free_disk_space.sh

# Free space before heavy installations
RUN /app/free_disk_space.sh

USER root
RUN apt-get update && \
   apt-get install -y  --no-install-recommends  \
    curl \
    gcc \
    git \
    gosu \
    git-lfs \
    htop \
    libgl1 \
    libglib2.0-0 \
    ncdu \
    tree \
    openssh-client \
    openssh-server \
    psmisc \
    rsync \
    screen \
    sudo \
    tmux \
    unzip \
    vim \
    ldap-utils \
    nvtop \
    wget && \
    wget -q  https://github.com/justjanne/powerline-go/releases/download/v1.24/powerline-go-linux-"$(dpkg --print-architecture)" -O /usr/local/bin/powerline-shell && \
    chmod a+x /usr/local/bin/powerline-shell

# install Miniforge
RUN wget -O /tmp/Miniforge3.sh "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-$(uname)-$(uname -m).sh" && \
    bash /tmp/Miniforge3.sh -b -p "/opt/conda" &&  rm /tmp/Miniforge3.sh
    
RUN . /opt/conda/etc/profile.d/conda.sh
# make conda install writable
RUN chmod -R 777 /opt/conda

# setup ssh
RUN ssh-keygen -A
EXPOSE 22

# Copy entrypoint and config to permanent locations (NOT /tmp!)
COPY base/user-entrypoint.sh /usr/local/bin/user-entrypoint.sh
COPY base/.bashrc /etc/skel/.bashrc
RUN chmod +x /usr/local/bin/user-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/user-entrypoint.sh"]
CMD ["/bin/bash"]
