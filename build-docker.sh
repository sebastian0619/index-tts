#!/bin/bash

# IndexTTS2 Docker 构建脚本

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 显示帮助信息
show_help() {
    echo "IndexTTS2 Docker 构建脚本"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示帮助信息"
    echo "  -t, --tag      指定镜像标签 (默认: indextts:latest)"
    echo "  -p, --push     构建后推送到注册表"
    echo "  -r, --registry 指定注册表地址 (默认: ghcr.io)"
    echo "  --no-cache     不使用构建缓存"
    echo "  --gpu-test     构建后测试 GPU 支持"
    echo "  --cpu-test     构建后测试 CPU 模式"
    echo ""
    echo "示例:"
    echo "  $0                          # 基本构建"
    echo "  $0 -t myimage:v1.0         # 指定标签"
    echo "  $0 -p -r ghcr.io/user      # 构建并推送"
    echo "  $0 --gpu-test              # 构建并测试 GPU"
}

# 默认参数
IMAGE_TAG="indextts:latest"
PUSH_IMAGE=false
REGISTRY=""
NO_CACHE=false
GPU_TEST=false
CPU_TEST=false

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -t|--tag)
            IMAGE_TAG="$2"
            shift 2
            ;;
        -p|--push)
            PUSH_IMAGE=true
            shift
            ;;
        -r|--registry)
            REGISTRY="$2"
            shift 2
            ;;
        --no-cache)
            NO_CACHE=true
            shift
            ;;
        --gpu-test)
            GPU_TEST=true
            shift
            ;;
        --cpu-test)
            CPU_TEST=true
            shift
            ;;
        *)
            print_error "未知参数: $1"
            show_help
            exit 1
            ;;
    esac
done

# 检查 Docker 是否安装
if ! command -v docker &> /dev/null; then
    print_error "Docker 未安装或不在 PATH 中"
    exit 1
fi

# 检查 Docker 是否运行
if ! docker info &> /dev/null; then
    print_error "Docker 服务未运行"
    exit 1
fi

print_info "开始构建 IndexTTS2 Docker 镜像..."

# 构建参数
BUILD_ARGS=""
if [ "$NO_CACHE" = true ]; then
    BUILD_ARGS="--no-cache"
fi

# 如果指定了注册表，更新镜像标签
if [ -n "$REGISTRY" ]; then
    if [[ "$IMAGE_TAG" != *"/"* ]]; then
        IMAGE_TAG="${REGISTRY}/${IMAGE_TAG}"
    fi
fi

print_info "构建镜像: $IMAGE_TAG"

# 构建镜像
if docker build $BUILD_ARGS -t "$IMAGE_TAG" .; then
    print_success "镜像构建成功: $IMAGE_TAG"
else
    print_error "镜像构建失败"
    exit 1
fi

# 推送镜像
if [ "$PUSH_IMAGE" = true ]; then
    print_info "推送镜像到注册表..."
    if docker push "$IMAGE_TAG"; then
        print_success "镜像推送成功"
    else
        print_error "镜像推送失败"
        exit 1
    fi
fi

# GPU 测试
if [ "$GPU_TEST" = true ]; then
    print_info "测试 GPU 支持..."
    
    # 检查是否有 GPU 支持
    if command -v nvidia-smi &> /dev/null; then
        print_info "检测到 NVIDIA GPU，启动测试容器..."
        
        # 启动测试容器
        CONTAINER_ID=$(docker run -d --gpus all -p 7861:7860 "$IMAGE_TAG" bash -c "sleep 60")
        
        # 等待容器启动
        sleep 10
        
        # 检查容器状态
        if docker ps | grep -q "$CONTAINER_ID"; then
            print_success "GPU 测试容器启动成功"
            
            # 检查 GPU 是否可用
            if docker exec "$CONTAINER_ID" nvidia-smi &> /dev/null; then
                print_success "GPU 支持正常"
            else
                print_warning "GPU 可能不可用"
            fi
            
            # 清理测试容器
            docker stop "$CONTAINER_ID" &> /dev/null
            docker rm "$CONTAINER_ID" &> /dev/null
        else
            print_error "GPU 测试容器启动失败"
        fi
    else
        print_warning "未检测到 NVIDIA GPU，跳过 GPU 测试"
    fi
fi

# CPU 测试
if [ "$CPU_TEST" = true ]; then
    print_info "测试 CPU 模式..."
    
    # 启动 CPU 测试容器
    CONTAINER_ID=$(docker run -d -e CUDA_VISIBLE_DEVICES="" -p 7862:7860 "$IMAGE_TAG" bash -c "sleep 60")
    
    # 等待容器启动
    sleep 10
    
    # 检查容器状态
    if docker ps | grep -q "$CONTAINER_ID"; then
        print_success "CPU 测试容器启动成功"
        
        # 清理测试容器
        docker stop "$CONTAINER_ID" &> /dev/null
        docker rm "$CONTAINER_ID" &> /dev/null
    else
        print_error "CPU 测试容器启动失败"
    fi
fi

print_success "所有任务完成！"

# 显示使用说明
echo ""
print_info "使用方法:"
echo "  docker run -p 7860:7860 --gpus all $IMAGE_TAG"
echo ""
print_info "Web 界面地址:"
echo "  http://localhost:7860"
echo ""
print_info "查看帮助:"
echo "  docker run --rm $IMAGE_TAG --help"
