# IndexTTS2 Docker 使用指南

本文档介绍如何使用 Docker 运行 IndexTTS2 项目。

## 🚀 快速开始

### 使用 Docker Compose（推荐）

1. **GPU 版本（推荐）**：
```bash
# 启动 GPU 版本
docker-compose up -d

# 查看日志
docker-compose logs -f indextts
```

2. **CPU 版本**：
```bash
# 启动 CPU 版本
docker-compose --profile cpu-only up -d indextts-cpu

# 查看日志
docker-compose logs -f indextts-cpu
```

### 使用 Docker 命令

1. **构建镜像**：
```bash
docker build -t indextts:latest .
```

2. **运行容器**：
```bash
# GPU 版本
docker run -d \
  --name indextts-webui \
  --gpus all \
  -p 7860:7860 \
  -v ./checkpoints:/app/checkpoints \
  -v ./outputs:/app/outputs \
  -e MODELSCOPE_CACHE=/app/modelscope_cache \
  indextts:latest

# CPU 版本
docker run -d \
  --name indextts-webui-cpu \
  -p 7860:7860 \
  -v ./checkpoints:/app/checkpoints \
  -v ./outputs:/app/outputs \
  -e MODELSCOPE_CACHE=/app/modelscope_cache \
  -e CUDA_VISIBLE_DEVICES="" \
  indextts:latest
```

## 📋 系统要求

### GPU 版本
- **NVIDIA GPU**：支持 CUDA 12.6+
- **显存要求**：建议 8GB+ VRAM
- **Docker**：支持 GPU 的 Docker 环境
- **NVIDIA Container Toolkit**：用于 GPU 支持

### CPU 版本
- **内存要求**：建议 16GB+ RAM
- **性能**：CPU 推理速度较慢，仅用于测试

## 🛠️ 配置说明

### 环境变量

| 变量名 | 默认值 | 说明 |
|--------|--------|------|
| `MODELSCOPE_CACHE` | `/app/modelscope_cache` | ModelScope 模型缓存目录 |
| `CUDA_VISIBLE_DEVICES` | `0` | 指定使用的 GPU 设备 |

### 目录挂载

| 容器路径 | 宿主机路径 | 说明 |
|----------|------------|------|
| `/app/checkpoints` | `./checkpoints` | 模型文件目录 |
| `/app/outputs` | `./outputs` | 输出音频文件目录 |
| `/app/examples` | `./examples` | 示例音频文件目录（只读） |

### 端口映射

| 容器端口 | 宿主机端口 | 服务 |
|----------|------------|------|
| `7860` | `7860` | Web UI 界面 |

## 🎯 使用方式

### Web 界面
启动容器后，在浏览器中访问：
```
http://localhost:7860
```

### 命令行模式
```bash
# 进入容器
docker exec -it indextts-webui bash

# 使用命令行工具
uv run python3 -m indextts.cli "你好世界" -v examples/voice_01.wav -o output.wav
```

### Python 脚本
```bash
# 运行 Python 脚本
docker exec -it indextts-webui uv run python3 your_script.py
```

## 📦 GitHub Actions 自动构建

项目包含三个 GitHub Actions 工作流：

1. **docker-simple.yml**：简单快速构建（推荐）
2. **docker-build.yml**：标准构建流程
3. **docker-multi-platform.yml**：多平台构建

### 触发条件
- 推送到 `main`、`master`、`develop` 分支
- 推送标签（`v*`）
- 手动触发

### 使用预构建镜像
```bash
# 从 GitHub Container Registry 拉取
docker pull ghcr.io/your-username/index-tts:latest

# 运行预构建镜像
docker run -p 7860:7860 --gpus all ghcr.io/your-username/index-tts:latest
```

## 🔧 故障排除

### 常见问题

1. **GPU 不可用**：
```bash
# 检查 GPU 支持
docker run --rm --gpus all nvidia/cuda:12.6-base nvidia-smi
```

2. **模型下载失败**：
```bash
# 检查网络连接
docker exec -it indextts-webui curl -I https://www.modelscope.cn

# 手动下载模型
docker exec -it indextts-webui modelscope download --model IndexTeam/IndexTTS-2 --local_dir checkpoints
```

3. **内存不足**：
```bash
# 查看容器资源使用
docker stats indextts-webui

# 限制内存使用
docker run --memory=8g --gpus all indextts:latest
```

### 日志查看
```bash
# 查看容器日志
docker logs indextts-webui

# 实时查看日志
docker logs -f indextts-webui

# 查看最近 100 行日志
docker logs --tail 100 indextts-webui
```

## 🎵 音频文件管理

### 输入音频
- 将参考音频放在 `examples/` 目录
- 支持格式：WAV、MP3、FLAC

### 输出音频
- 生成的音频保存在 `outputs/` 目录
- 默认格式：WAV

## 📝 开发模式

如需修改代码并实时调试：

```bash
# 挂载源代码目录
docker run -it \
  --gpus all \
  -p 7860:7860 \
  -v $(pwd):/app \
  -v ./checkpoints:/app/checkpoints \
  indextts:latest bash

# 在容器内运行开发服务器
uv run webui.py --host 0.0.0.0 --port 7860
```

## 🆘 获取帮助

如遇到问题，请：

1. 查看 [项目 README](README.md)
2. 检查 [Issues](https://github.com/index-tts/index-tts/issues)
3. 加入 QQ 群：553460296
4. 发送邮件：indexspeech@bilibili.com

---

**注意**：首次运行时会自动从 ModelScope 下载模型文件（约 2-3GB），请确保网络连接稳定。
