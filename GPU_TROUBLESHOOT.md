# GPU 支持故障排除指南

## 🔍 问题诊断

如果看到 `NVIDIA-SMI couldn't find libnvidia-ml.so library` 错误，请按以下步骤诊断：

### 1. 检查宿主机 NVIDIA 驱动
```bash
nvidia-smi
```
应该显示 GPU 信息。如果失败，需要安装 NVIDIA 驱动。

### 2. 检查 NVIDIA Container Toolkit
```bash
# 检查是否安装
which nvidia-container-runtime

# 如果未安装，安装 NVIDIA Container Toolkit
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
sudo systemctl restart docker
```

### 3. 检查 Docker 配置
```bash
# 检查 daemon.json
cat /etc/docker/daemon.json

# 应该包含:
{
    "runtimes": {
        "nvidia": {
            "path": "nvidia-container-runtime",
            "runtimeArgs": []
        }
    },
    "default-runtime": "nvidia"
}
```

### 4. 测试 Docker GPU 支持
```bash
# 测试基础 CUDA 容器
docker run --rm --gpus all nvidia/cuda:11.0-base nvidia-smi

# 如果成功，测试我们的镜像
docker run --rm --gpus all ghcr.io/sebastian0619/index-tts:latest nvidia-smi
```

## 🔧 快速修复

### 选项 1: 重新配置 Docker Compose
```bash
# 停止容器
docker-compose down

# 确保使用正确的 GPU 配置重启
docker-compose up -d
```

### 选项 2: 使用 CPU 模式
如果 GPU 暂时无法工作，可以使用 CPU 模式：
```bash
# 启动 CPU 版本
docker-compose --profile cpu-only up -d indextts-cpu
```

### 选项 3: 手动运行容器
```bash
# 手动测试容器
docker run --rm -it --gpus all \
  -p 7860:7860 \
  -v ./checkpoints:/app/checkpoints \
  ghcr.io/sebastian0619/index-tts:latest bash

# 在容器内测试
nvidia-smi
python -c "import torch; print(torch.cuda.is_available())"
```

## 📋 常见问题

1. **驱动版本不兼容**: CUDA 12.8 需要驱动版本 >= 535.54
2. **Container Toolkit 未安装**: 需要安装 nvidia-container-toolkit
3. **Docker 配置错误**: 需要正确配置 /etc/docker/daemon.json
4. **权限问题**: 确保 Docker 有权限访问 GPU 设备

## 🆘 如果仍有问题

1. 重启 Docker 服务: `sudo systemctl restart docker`
2. 重启系统以确保驱动正确加载
3. 检查系统日志: `dmesg | grep -i nvidia`
4. 使用 CPU 模式作为备选方案
