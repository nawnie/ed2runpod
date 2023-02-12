# Based off https://www.runpod.io/blog/diy-deep-learning-docker-container
FROM pytorch/pytorch:1.13.1-cuda11.6-cudnn8-devel

# Use bash shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND noninteractive\
    SHELL=/bin/bash
    
RUN apt-get update --yes && \
    apt-get upgrade --yes && \
    apt install --yes --no-install-recommends \
    wget bash curl git openssh-server && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# Install required python modules
ADD requirements.txt .
RUN python3 --version && pip install -r requirements.txt

# Install transformers and upgrade requests
RUN pip install jupyterlab ipywidgets jupyter-archive ipyevents

# Install xformers
RUN pip install --pre -U xformers

# Add EveryDream repo
WORKDIR /workspace
RUN git clone https://github.com/victorchall/EveryDream2trainer && \
    cd EveryDream2trainer && \
    python3 utils/get_yamls.py

RUN mkdir -p /workspace/EveryDream2trainer/input
RUN mkdir -p /workspace/EveryDream2trainer/logs

ADD start.sh /

RUN chmod +x /start.sh

CMD [ "/start.sh" ]
