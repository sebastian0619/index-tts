# IndexTTS2 Docker Image
# 基于 NVIDIA CUDA 的官方镜像，支持 PyTorch GPU 加速
FROM nvidia/cuda:12.1.1-devel-ubuntu22.04

# 设置环境变量
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PIP_NO_CACHE_DIR=1
ENV MODELSCOPE_CACHE="/app/modelscope_cache"
ENV CUDA_VISIBLE_DEVICES=0

# 设置工作目录
WORKDIR /app

# 安装系统依赖
RUN apt-get update && apt-get install -y \
    python3.11 \
    python3.11-dev \
    python3.11-venv \
    python3-pip \
    git \
    git-lfs \
    curl \
    wget \
    ffmpeg \
    libsndfile1 \
    libgl1-mesa-glx \
    libglib2.0-0 \
    libsm6 \
    libxext6 \
    libxrender-dev \
    libgomp1 \
    && rm -rf /var/lib/apt/lists/*

# 设置 Python 3.11 为默认 python3
RUN update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.11 1
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3.11 1

# 安装 uv 包管理器
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.cargo/bin:$PATH"

# 启用 Git LFS
RUN git lfs install

# 复制项目文件
COPY . .

# 安装 Python 依赖
RUN uv sync --all-extras

# 创建模型目录和缓存目录
RUN mkdir -p checkpoints modelscope_cache

# 下载模型文件的脚本（在容器启动时执行）
COPY docker-entrypoint.sh /docker-entrypoint.sh
RUN chmod +x /docker-entrypoint.sh

# 暴露端口
EXPOSE 7860

# 设置健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5m --retries=3 \
    CMD curl -f http://localhost:7860/ || exit 1

# 启动脚本
ENTRYPOINT ["/docker-entrypoint.sh"]
CMD ["webui"]
