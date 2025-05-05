ARG BASE_IMAGE="ghcr.io/ousso11/docker-images/base:main"

FROM ${BASE_IMAGE}

# install conda environment
COPY working_vllm/environment.yml /tmp/environment.yml
COPY working_vllm/requirements.txt /tmp/requirements.txt
RUN /opt/conda/bin/mamba env create -f /tmp/environment.yml -n default && \
    /opt/conda/bin/mamba clean -y --all
RUN rm /tmp/environment.yml

RUN apt install -y libopenmpi-dev

# install requirements
RUN . /opt/conda/etc/profile.d/conda.sh && \
    conda activate default && \
    mamba clean -y --all && \
    pip install "unsloth[colab-new] @ git+https://github.com/unslothai/unsloth.git" && \
    chmod -R 777 /opt/conda/envs/default  && \
    pip install -r /tmp/requirements.txt --no-cache-dir &&\
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

