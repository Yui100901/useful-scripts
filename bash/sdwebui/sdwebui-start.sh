#!/bin/bash -ex

# 设置目标目录和 Conda 环境名
SD_DIR="stable-diffusion-webui"
CONDA_ENV="sdwebui"
PYTHON_VERSION="3.10"

# 克隆仓库（如果不存在）
if [ -d "$SD_DIR" ]; then
  echo "目录 $SD_DIR 已存在，不进行克隆操作。"
else
  git clone https://github.com/AUTOMATIC1111/stable-diffusion-webui.git "$SD_DIR"
  echo "仓库已克隆到 $SD_DIR"
fi

cd "$SD_DIR"

# 检查 Conda 环境是否存在，不存在则自动创建
if ! conda info --envs | grep -q "^$CONDA_ENV[[:space:]]"; then
  echo "Conda 环境 $CONDA_ENV 不存在，正在创建..."
  conda create -n "$CONDA_ENV" python="$PYTHON_VERSION" -y
else
  echo "Conda 环境 $CONDA_ENV 已存在。"
fi

# 使用 conda run 执行 pip 操作
conda run -n "$CONDA_ENV" python -m pip install --upgrade pip
conda run -n "$CONDA_ENV" pip config set global.index-url https://pypi.tuna.tsinghua.edu.cn/simple

# 安装 GPU 相关依赖（确保已安装 CUDA 驱动）
conda run -n "$CONDA_ENV" pip install torch==2.5.1 torchvision==0.20.1 torchaudio==2.5.1 xformers==0.0.28.post3 --index-url https://download.pytorch.org/whl/cu124
conda run -n "$CONDA_ENV" pip install torchao --index-url https://download.pytorch.org/whl/nightly/cu124

# 安装项目依赖
conda run -n "$CONDA_ENV" pip install -r requirements_versions.txt
conda run -n "$CONDA_ENV" pip install -r requirements.txt

# 启动应用，实时输出日志
conda run --live -n "$CONDA_ENV" python launch.py --listen --enable-insecure-extension-access --share
