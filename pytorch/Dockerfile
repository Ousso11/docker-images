ARG BASE_IMAGE="ghcr.io/ousso11/docker-images/base:main"

FROM ${BASE_IMAGE}

# Copy disk space cleanup script
COPY free_disk_space.sh /app/free_disk_space.sh
RUN chmod +x /app/free_disk_space.sh

# install conda environment
COPY pytorch/environment.yml /tmp/environment.yml
COPY pytorch/requirements.txt /tmp/requirements.txt

# Free space before heavy installations
RUN /app/free_disk_space.sh

# Check conda installation and use conda instead of mamba
RUN /opt/conda/bin/conda env create -f /tmp/environment.yml -n default && \
    /opt/conda/bin/conda clean -y --all
RUN rm /tmp/environment.yml

RUN apt install -y libopenmpi-dev

# install requirements
RUN /opt/conda/bin/conda activate default && \
    /opt/conda/bin/conda clean -y --all && \
    /opt/conda/envs/default/bin/pip install "unsloth[colab-new] @ git+https://github.com/unslothai/unsloth.git" && \
    chmod -R 777 /opt/conda/envs/default  && \
    /opt/conda/envs/default/bin/pip install -r /tmp/requirements.txt --no-cache-dir &&\
    rm /tmp/requirements.txt
    

    # install ngrok
RUN curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc \
	| sudo tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null \
	&& echo "deb https://ngrok-agent.s3.amazonaws.com buster main" \
	| sudo tee /etc/apt/sources.list.d/ngrok.list \
	&& sudo apt update \
	&& sudo apt install ngrok

RUN . /opt/conda/etc/profile.d/conda.sh && \
     conda activate default && conda install -c nvidia -y nccl

