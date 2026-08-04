# syntax=docker/dockerfile:1.7

# ---- Base image (CUDA + cuDNN runtime) ----
FROM nvidia/cuda:12.4.1-cudnn-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    HF_HUB_ENABLE_HF_TRANSFER=1

# ---- System dependencies ----
RUN apt-get update && apt-get install -y --no-install-recommends \
        git wget curl ca-certificates \
        python3 python3-pip python3-venv \
        libgl1 libglib2.0-0 \
        openssh-server \
    && ln -sf /usr/bin/python3 /usr/bin/python \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# ---- ComfyUI ----
ARG COMFYUI_REF=master
RUN git clone https://github.com/comfyanonymous/ComfyUI.git && \
    cd ComfyUI && git checkout ${COMFYUI_REF}

# ---- PyTorch (cu124) + ComfyUI requirements + HF CLI ----
RUN pip install --upgrade pip && \
    pip install torch torchvision torchaudio \
        --index-url https://download.pytorch.org/whl/cu124 && \
    pip install -r ComfyUI/requirements.txt && \
    pip install "huggingface_hub[cli]" hf_transfer

# ---- Custom nodes ----
WORKDIR /workspace/ComfyUI/custom_nodes
RUN git clone https://github.com/ltdrdata/ComfyUI-Manager.git && \
    git clone https://github.com/ltdrdata/ComfyUI-Impact-Pack.git && \
    git clone https://github.com/rgthree/rgthree-comfy && \
    git clone https://github.com/chflame163/ComfyUI_LayerStyle && \
RUN for d in */ ; do \
        if [ -f "${d}requirements.txt" ]; then \
            pip install -r "${d}requirements.txt" ; \
        fi ; \
    done

# ---- Startup script ----
WORKDIR /workspace
COPY start.sh /workspace/start.sh
RUN chmod +x /workspace/start.sh

EXPOSE 8188

CMD ["/workspace/start.sh"]