FROM runpod/stable-diffusion:web-automatic-2.1.14 as build

WORKDIR /workspace
RUN rm -rf /workspace/stable-diffusion-webui

# Add EveryDream repo
RUN git clone https://github.com/victorchall/EveryDream2trainer && \
    mkdir -p /workspace/EveryDream2trainer/input && \
    mkdir -p /workspace/EveryDream2trainer/logs
WORKDIR /workspace/EveryDream2trainer

SHELL ["/bin/bash", "-c"]
ENV PATH="${PATH}:/venv/bin"

# !export TORCH_CUDA_ARCH_LIST=8.6 && pip install git+https://github.com/facebookresearch/xformers.git@48a77cc#egg=xformers
RUN pip uninstall -y xformers; \
    pip uninstall -y tb-nightly tensorboard; \
    pip install --no-cache-dir -U -I torch==1.13.1+cu117 torchvision==0.14.1+cu117 --extra-index-url "https://download.pytorch.org/whl/cu117"; \
    pip install --no-cache-dir --pre --no-deps -U xformers; \
    pip install --no-cache-dir -U triton; \
    pip install --no-cache-dir -r requirements.txt; \
    pip install --no-cache-dir -U jupyterlab ipywidgets jupyter-archive ipyevents; \
    jupyter nbextension enable --py widgetsnbextension;

RUN git pull && python3 utils/get_yamls.py
ADD start.sh /
RUN chmod +x /start.sh

CMD [ "/start.sh" ]
