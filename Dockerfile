#######################
#### Builder stage ####

FROM library/ubuntu:22.04 AS builder

ARG DEBIAN_FRONTEND=noninteractive

# Create workspace working directory
RUN mkdir /build
WORKDIR /build

RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update && apt-get install -y \
        git wget \
        python3-venv \
        python3-pip \
        apt-transport-https ca-certificates \
        build-essential \
    && update-ca-certificates

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-keyring_1.0-1_all.deb && \
    dpkg -i cuda-keyring_1.0-1_all.deb && \
    apt update && apt-get install -y cuda

ENV VIRTUAL_ENV=/workspace/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"

ADD requirements.txt /build
RUN --mount=type=cache,target=/root/.cache/pip \
    python3 -m venv ${VIRTUAL_ENV} && \
    pip install -U -I torch==1.13.1+cu117 torchvision==0.14.1+cu117 --extra-index-url "https://download.pytorch.org/whl/cu117" && \
    pip install --pre --no-deps -U xformers && \
    pip install -U triton && \
    pip install -r requirements.txt && \
    pip install -U jupyterlab ipywidgets jupyter-archive ipyevents


#######################
#### Runtime stage ####

FROM library/ubuntu:22.04 as runtime

# Use bash shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]
ENV DEBIAN_FRONTEND noninteractive\
    SHELL=/bin/bash

# Python logs go strait to stdout/stderr w/o buffering
ENV PYTHONUNBUFFERED=1

# Don't write .pyc bytecode
ENV PYTHONDONTWRITEBYTECODE=1

COPY --from=builder /build/cuda-keyring_1.0-1_all.deb cuda-keyring_1.0-1_all.deb
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt update && apt install -y --no-install-recommends \
        wget bash curl git git-lfs vim \
        apt-transport-https ca-certificates \
        python3-distutils && \
    update-ca-certificates && \
    dpkg -i cuda-keyring_1.0-1_all.deb && \
    apt update && apt install -y --no-install-recommends cuda-libraries-11-7 && \
    apt-get clean && \
    apt-get autoclean && \
    rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

ENV VIRTUAL_ENV=/workspace/venv
ENV PATH="$VIRTUAL_ENV/bin:$PATH"
COPY --from=builder ${VIRTUAL_ENV} ${VIRTUAL_ENV}

WORKDIR /workspace
RUN git clone https://github.com/victorchall/EveryDream2trainer
WORKDIR /workspace/EveryDream2trainer

ADD start.sh /
RUN chmod +x /start.sh
CMD [ "/start.sh" ]
