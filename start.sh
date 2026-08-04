#!/usr/bin/env bash
set -euo pipefail

COMFY_DIR="/ComfyUI"
MODELS_DIR="/workspace/ComfyUI/models"

# ---- Model collection helper ----
# Download a model file, skipping it if it already exists.
# Usage: dl <repo_id> <file_in_repo> <models_subdir>
dl() {
    local repo="$1" file="$2" subdir="$3"
    local dest="${MODELS_DIR}/${subdir}"
    if [ -f "${dest}/${file}" ]; then
        echo "[skip] ${subdir}/${file} already exists."
        return 0
    fi
    echo "[download] ${repo} -> ${subdir}/${file}"
    hf download "${repo}" "${file}" --local-dir "${dest}"
}

dl_civitai() {
    local version_id="$1" subdir="$2" fname="$3"
    local dest="${MODELS_DIR}/${subdir}"
    if [ -f "${dest}/${fname}" ]; then
        echo "[skip] ${subdir}/${fname} already exists."
        return 0
    fi
    mkdir -p "${dest}"
    echo "[download] civitai:${version_id} -> ${subdir}/${fname}"
    curl -L --fail \
        -H "Authorization: Bearer ${CIVITAI_TOKEN}" \
        -o "${dest}/${fname}" \
        "https://civitai.com/api/download/models/${version_id}"
}

# ---- Download models ----
dl Phr00t/Qwen-Image-Edit-Rapid-AIO v19/Qwen-Rapid-AIO-NSFW-v19.safetensors checkpoints
dl Phr00t/Qwen-Image-Edit-Rapid-AIO v23/Qwen-Rapid-AIO-NSFW-v23.safetensors checkpoints
dl Comfy-Org/HunyuanVideo_1.5_repackaged split_files/text_encoders/qwen_2.5_vl_7b_fp8_scaled.safetensors text_encoders
dl Comfy-Org/Qwen-Image_ComfyUI split_files/vae/qwen_image_vae.safetensors vae

dl_civitai 2105899 loras qwen_MCNL_v1.0.safetensors     # https://civitai.com/models/1851673/mcnl-multi-concept-nsfw-lora-qwen-image
dl_civitai 3172362 loras snofs_krea_v1_2.safetensors    # https://civitai.com/models/1972981/qwen-sex-nudes-other-fun-stuff-snofs
dl_civitai 2316696 loras Qwen4Play_v2.safetensors       # https://civitai.com/models/2004155/qwen-4-play-aio-nsfw-qwen-lora-by-dr34msc4pe?modelVersionId=2316696

# ---- Boot ComfyUI ----
cd "${COMFY_DIR}"
exec python main.py \
    --listen 0.0.0.0 \
    --port 8188 \
    ${COMFYUI_EXTRA_ARGS:-}