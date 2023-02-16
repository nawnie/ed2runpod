FROM runpod/stable-diffusion:web-automatic-2.1.15

# Build with some basic utilities
RUN apt-get update --yes && \
    apt-get install --yes --no-install-recommends \
        git-lfs vim && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Add EveryDream repo
WORKDIR /workspace
RUN rm -rf /workspace/stable-diffusion-webui
RUN git clone https://github.com/victorchall/EveryDream2trainer && \
    mkdir -p /workspace/EveryDream2trainer/input && \
    mkdir -p /workspace/EveryDream2trainer/logs
WORKDIR /workspace/EveryDream2trainer

SHELL ["/bin/bash", "-c"]
ENV PATH="${PATH}:/venv/bin"

# !export TORCH_CUDA_ARCH_LIST=8.6 && pip install git+https://github.com/facebookresearch/xformers.git@48a77cc#egg=xformers
RUN pip install -U -I torch==1.13.1+cu117 torchvision==0.14.1+cu117 --extra-index-url "https://download.pytorch.org/whl/cu117"; \
    pip install --pre --no-deps -U xformers; \
    pip install -U diffusers[torch]; \
    pip install -U triton; \
    pip install -r requirements.txt; \
    pip install -U jupyterlab ipywidgets jupyter-archive ipyevents; \
    jupyter nbextension enable --py widgetsnbextension

RUN git pull && python3 utils/get_yamls.py
ADD start.sh /
RUN chmod +x /start.sh

CMD [ "/start.sh" ]
