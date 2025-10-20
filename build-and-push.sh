#!/bin/bash

# ===========================
# Local Docker Build & Push Script for macOS
# Builds and pushes to GitHub Container Registry (ghcr.io)
# Uses .env file for credentials
# ===========================

set -e  # Exit on any error

# Load environment variables from .env file
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "❌ .env file not found! Please create it with your GitHub credentials."
    echo "Example .env file:"
    echo "GITHUB_USERNAME=your_username"
    echo "GITHUB_TOKEN=your_token_here"
    exit 1
fi

# Configuration (can be overridden by .env)
REGISTRY="${REGISTRY:-ghcr.io}"
REPO="${REPO:-ousso11/docker-images}"
PLATFORM="${PLATFORM:-linux/amd64}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
log() {
    echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
    exit 1
}

# Function to check if Docker is running and login to GitHub
check_docker_and_login() {
    if ! docker info >/dev/null 2>&1; then
        error "Docker is not running. Please start Docker Desktop and try again."
    fi
    log "Docker is running ✅"
    
    # Check if required environment variables are set
    if [ -z "$GITHUB_USERNAME" ] || [ -z "$GITHUB_TOKEN" ]; then
        error "GitHub credentials not found in .env file. Please set GITHUB_USERNAME and GITHUB_TOKEN."
    fi
    
    # Login to GitHub Container Registry
    log "🔑 Logging into GitHub Container Registry..."
    if echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$GITHUB_USERNAME" --password-stdin >/dev/null 2>&1; then
        log "GitHub Container Registry login successful ✅"
    else
        error "Failed to login to GitHub Container Registry. Please check your credentials in .env file."
    fi
}

# Function to build and push an image
build_and_push() {
    local image_name=$1
    local dockerfile_path=$2
    local tag_suffix=${3:-"macos-build"}
    
    local full_image_name="${REGISTRY}/${REPO}/${image_name}"
    local tag="${full_image_name}:${tag_suffix}"
    local latest_tag="${full_image_name}:latest"
    
    log "🏗️  Building ${image_name} image..."
    echo "   📁 Dockerfile: ${dockerfile_path}"
    echo "   🏷️  Tag: ${tag}"
    echo "   🔧 Platform: ${PLATFORM}"
    
    # Build and push with progress
    if docker buildx build \
        --platform "${PLATFORM}" \
        --push \
        -t "${tag}" \
        -t "${latest_tag}" \
        -f "${dockerfile_path}" \
        --progress=plain \
        .; then
        log "✅ Successfully built and pushed ${image_name}"
        echo "   🔗 Image: ${tag}"
        echo "   🔗 Latest: ${latest_tag}"
    else
        error "❌ Failed to build ${image_name}"
    fi
}

# Function to show usage
usage() {
    echo "Usage: $0 [OPTIONS] [IMAGES...]"
    echo ""
    echo "Build and push Docker images to GitHub Container Registry"
    echo "Requires .env file with GITHUB_USERNAME and GITHUB_TOKEN"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  -t, --tag TAG  Use custom tag suffix (default: macos-build)"
    echo ""
    echo "Images (if none specified, builds all):"
    echo "  base           Build base image"
    echo "  pytorch        Build PyTorch image"
    echo "  rs             Build RS image"
    echo ""
    echo "Examples:"
    echo "  $0                    # Build all images"
    echo "  $0 pytorch rs         # Build only PyTorch and RS"
    echo "  $0 -t v1.0.0 pytorch # Build PyTorch with custom tag"
    echo ""
    echo "Setup:"
    echo "  1. Create .env file with your GitHub credentials"
    echo "  2. Run: $0"
}

# Parse command line arguments
TAG_SUFFIX="macos-build"
IMAGES_TO_BUILD=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            usage
            exit 0
            ;;
        -t|--tag)
            TAG_SUFFIX="$2"
            shift 2
            ;;
        base|pytorch|rs)
            IMAGES_TO_BUILD+=("$1")
            shift
            ;;
        *)
            error "Unknown argument: $1. Use -h for help."
            ;;
    esac
done

# If no images specified, build all
if [ ${#IMAGES_TO_BUILD[@]} -eq 0 ]; then
    IMAGES_TO_BUILD=("base" "pytorch" "rs")
fi

# Main execution
main() {
    log "🚀 Starting Docker build and push process"
    
    # Pre-flight checks
    check_docker_and_login
    
    # Show build plan
    log "📋 Build Plan:"
    echo "   🏷️  Tag suffix: ${TAG_SUFFIX}"
    echo "   🔧 Platform: ${PLATFORM}"
    echo "   📦 Images to build: ${IMAGES_TO_BUILD[*]}"
    echo ""
    
    read -p "Continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        log "Build cancelled by user"
        exit 0
    fi
    
    # Build images in order (base first, as others depend on it)
    local start_time=$(date +%s)
    
    for image in "${IMAGES_TO_BUILD[@]}"; do
        case $image in
            base)
                build_and_push "base" "base/Dockerfile" "$TAG_SUFFIX"
                ;;
            pytorch)
                build_and_push "pytorch" "pytorch/Dockerfile" "$TAG_SUFFIX"
                ;;
            rs)
                build_and_push "rs" "rs/Dockerfile" "$TAG_SUFFIX"
                ;;
            *)
                warn "Unknown image: $image"
                ;;
        esac
        echo ""
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    log "🎉 All builds completed successfully!"
    log "⏱️  Total time: ${duration} seconds"
    echo ""
    echo "🔗 Your images are available at:"
    for image in "${IMAGES_TO_BUILD[@]}"; do
        echo "   ${REGISTRY}/${REPO}/${image}:${TAG_SUFFIX}"
    done
}

# Run main function
main "$@"