

FROM pytorch/conda-builder:cuda117 as build

WORKDIR /
RUN rm -rf /ed2
RUN mkdir ed2
ADD environment.yml /ed2/environment.yaml
WORKDIR /ed2
RUN conda update -n base -c defaults conda
RUN conda env create -f environment.yaml
SHELL ["conda", "run", "-n", "ldm", "/bin/bash", "-c"]

RUN conda install -c conda-forge conda-pack
RUN conda-pack --ignore-missing-files -n ldm -o /tmp/env.tar --ignore-editable-packages && \
    mkdir /venv && cd /venv && tar xf /tmp/env.tar && \
    rm /tmp/env.tar

RUN /venv/bin/conda-unpack

FROM ubuntu:22.04 AS runtime

# Build with some basic utilities
RUN apt-get update --yes && \
    apt-get upgrade --yes && \
    apt install --yes --no-install-recommends \
        wget bash curl git git-lfs vim tmux \
        libglib2.0-0 libsm6 libxrender1 libxext6 \
        ffmpeg gcc g++ openssh-server \
        python3-pip python3 python3.10-venv && \
    apt-get clean && rm -rf /var/lib/apt/lists/* && \
    echo "en_US.UTF-8 UTF-8" > /etc/locale.gen

# Add EveryDream repo
RUN rm -rf /workspace && mkdir /workspace
WORKDIR /workspace
RUN git clone https://github.com/victorchall/EveryDream2trainer && \
    mkdir -p /workspace/EveryDream2trainer/input && \
    mkdir -p /workspace/EveryDream2trainer/logs
WORKDIR /workspace/EveryDream2trainer

# Set up python venv
COPY --from=build /venv /venv
SHELL ["/bin/bash", "-c"]
ENV PATH="${PATH}:/venv/bin"

# !export TORCH_CUDA_ARCH_LIST=8.6 && pip install git+https://github.com/facebookresearch/xformers.git@48a77cc#egg=xformers
RUN pip install -U -I torch==1.13.1+cu117 torchvision==0.14.1+cu117 --extra-index-url "https://download.pytorch.org/whl/cu117"; \
    pip install --pre --no-deps -U xformers; \
    pip install -U diffusers[torch]; \
    pip install -U triton; \
    pip install wandb pynvml bitsandbytes aiohttp colorama; \
    pip install -U jupyterlab ipywidgets jupyter-archive ipyevents; \
    jupyter nbextension enable --py widgetsnbextension

RUN git pull && python3 utils/get_yamls.py
ADD start.sh /
RUN chmod +x /start.sh

CMD [ "/start.sh" ]
