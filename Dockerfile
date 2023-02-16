FROM continuumio/miniconda3

# Use bash shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND noninteractive\
    SHELL=/bin/bash

# Create workspace working directory
RUN mkdir /workspace
WORKDIR /workspace

# Build with some basic utilities
RUN apt-get update && apt-get install -y \
    wget bash curl git git-lfs vim &&\
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

ADD environment.yml /workspace
RUN conda env create -f environment.yml

#RUN jupyter nbextension enable --py widgetsnbextension && \
#    git lfs install && \
#    git config --global credential.helper store

RUN git clone https://github.com/victorchall/EveryDream2trainer && \
    mkdir -p /workspace/EveryDream2trainer/input && \
    mkdir -p /workspace/EveryDream2trainer/logs && \
    cd EveryDream2trainer && python3 utils/get_yamls.py

WORKDIR /workspace/EveryDream2trainer

ADD start.sh /
RUN chmod +x /start.sh
CMD [ "/start.sh" ]
