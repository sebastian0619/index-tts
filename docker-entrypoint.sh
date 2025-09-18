#!/bin/bash
set -e

# IndexTTS2 Docker 启动脚本

echo "=== IndexTTS2 Docker 容器启动 ==="

# 检查是否有 GPU 支持
if command -v nvidia-smi &> /dev/null; then
    if nvidia-smi &> /dev/null; then
        echo "检测到 NVIDIA GPU:"
        nvidia-smi --query-gpu=name,memory.total,memory.free --format=csv,noheader,nounits 2>/dev/null || echo "GPU 信息获取失败，但 GPU 可用"
        export USE_GPU=true
    else
        echo "警告: nvidia-smi 不可用，可能是驱动或容器配置问题"
        echo "将尝试使用 CPU 模式"
        export USE_GPU=false
    fi
else
    echo "警告: 未检测到 NVIDIA GPU 工具，将使用 CPU 模式"
    export USE_GPU=false
fi

# 检查模型文件是否存在
MODEL_FILES=("bpe.model" "gpt.pth" "config.yaml" "s2mel.pth" "wav2vec2bert_stats.pt")
MISSING_FILES=()

echo "检查模型文件..."
echo "当前目录: $(pwd)"
echo "checkpoints 目录内容:"
ls -la checkpoints/ 2>/dev/null || echo "checkpoints 目录不存在"

for file in "${MODEL_FILES[@]}"; do
    if [ ! -f "checkpoints/$file" ]; then
        echo "缺少文件: checkpoints/$file"
        MISSING_FILES+=("$file")
    else
        echo "找到文件: checkpoints/$file"
    fi
done

# 如果缺少模型文件，尝试下载
if [ ${#MISSING_FILES[@]} -ne 0 ]; then
    echo "检测到缺少模型文件: ${MISSING_FILES[*]}"
    echo "正在从 ModelScope 下载 IndexTTS-2 模型..."
    
    # 尝试使用 ModelScope
    if command -v modelscope &> /dev/null; then
        echo "使用 ModelScope 下载模型..."
        modelscope download --model IndexTeam/IndexTTS-2 --local_dir checkpoints
    else
        # 安装并使用 ModelScope
        echo "安装 ModelScope..."
        uv tool install "modelscope"
        echo "下载模型文件..."
        /root/.local/bin/modelscope download --model IndexTeam/IndexTTS-2 --local_dir checkpoints
    fi
    
    # 再次检查文件是否下载成功
    echo "下载完成，重新检查文件..."
    echo "checkpoints 目录内容:"
    ls -la checkpoints/ 2>/dev/null || echo "checkpoints 目录不存在"
    
    STILL_MISSING=()
    for file in "${MODEL_FILES[@]}"; do
        if [ ! -f "checkpoints/$file" ]; then
            echo "仍然缺少: checkpoints/$file"
            STILL_MISSING+=("$file")
        else
            echo "已下载: checkpoints/$file"
        fi
    done
    
    if [ ${#STILL_MISSING[@]} -ne 0 ]; then
        echo "警告: 以下文件仍然缺少: ${STILL_MISSING[*]}"
        echo "尝试继续启动，某些功能可能不可用"
        # 不退出，继续尝试启动
    else
        echo "所有模型文件下载完成！"
    fi
else
    echo "模型文件已存在，跳过下载"
fi

# 检查 PyTorch GPU 支持
echo "检查 PyTorch 安装..."
uv run python3 -c "
import torch
print(f'PyTorch 版本: {torch.__version__}')
print(f'CUDA 可用: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'CUDA 版本: {torch.version.cuda}')
    print(f'GPU 数量: {torch.cuda.device_count()}')
    for i in range(torch.cuda.device_count()):
        print(f'GPU {i}: {torch.cuda.get_device_name(i)}')
"

# 根据启动参数执行不同命令
case "$1" in
    "webui")
        echo "启动 IndexTTS2 Web 界面..."
        if [ "$USE_GPU" = "true" ]; then
            exec uv run webui.py --host 0.0.0.0 --port 7860 --fp16 --cuda_kernel
        else
            exec uv run webui.py --host 0.0.0.0 --port 7860
        fi
        ;;
    "cli")
        shift
        echo "运行 IndexTTS2 命令行..."
        exec uv run python3 -m indextts.cli "$@"
        ;;
    "bash")
        echo "启动交互式 bash shell..."
        exec /bin/bash
        ;;
    "python")
        shift
        echo "运行 Python 脚本..."
        exec uv run python3 "$@"
        ;;
    *)
        echo "使用方法:"
        echo "  docker run ... webui          # 启动 Web 界面 (默认)"
        echo "  docker run ... cli <args>     # 运行命令行工具"
        echo "  docker run ... python <file>  # 运行 Python 脚本"
        echo "  docker run ... bash           # 启动 bash shell"
        echo ""
        echo "启动 Web 界面..."
        if [ "$USE_GPU" = "true" ]; then
            exec uv run webui.py --host 0.0.0.0 --port 7860 --fp16 --cuda_kernel
        else
            exec uv run webui.py --host 0.0.0.0 --port 7860
        fi
        ;;
esac
