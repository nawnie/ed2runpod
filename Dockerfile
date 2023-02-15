# Based off https://www.runpod.io/blog/diy-deep-learning-docker-container
FROM ubuntu:22.04

# Use bash shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND noninteractive\
    SHELL=/bin/bash

RUN apt-get update --yes && \
     apt-get upgrade --yes && \
     apt install --yes --no-install-recommends \
     wget bash curl git ffmpeg openssh-server \
     gnupg2 python3-pip python3 python3.10-venv

RUN wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb
RUN dpkg -i cuda-keyring_1.0-1_all.deb

RUN apt-get update --yes && \
     apt install --yes cuda && \
     apt-get clean && rm -rf /var/lib/apt/lists/* && \
     echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# Add EveryDream repo
RUN rm -rf /workspace && mkdir /workspace
WORKDIR /workspace
RUN git clone https://github.com/victorchall/EveryDream2trainer

# Set up a Python virtual environment
RUN python3 -m venv /workspace/EveryDream2trainer/venv
ENV PATH="/workspace/EveryDream2trainer/venv/bin:$PATH"
RUN curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
RUN python get-pip.py

# Install required python modules
ADD requirements.txt .
RUN pip install torch==1.13.1+cu117 torchvision==0.14.1+cu117 --extra-index-url https://download.pytorch.org/whl/cu117
RUN pip install --pre --no-deps -U xformers
RUN pip install -r requirements.txt
RUN pip install -U jupyterlab ipywidgets jupyter-archive ipyevents
RUN jupyter nbextension enable --py widgetsnbextension

RUN cd EveryDream2trainer && python3 utils/get_yamls.py

RUN mkdir -p /workspace/EveryDream2trainer/input
RUN mkdir -p /workspace/EveryDream2trainer/logs

ADD start.sh /

RUN chmod +x /start.sh

CMD [ "/start.sh" ]
