# Docker Images

Multi-stage Docker images for ML/AI workloads with PyTorch and CUDA support.

## 📦 Images

- **base** - Base image with common utilities
- **pytorch** - PyTorch with CUDA 12.1 and cuDNN 8
- **rs** - Relation Search image with SSH support

## 🚀 Quick Start

### Build & Push to GitHub Container Registry

```bash
# Create .env file with your credentials
cat > .env << EOF
GITHUB_USERNAME=your_username
GITHUB_TOKEN=your_personal_access_token
EOF

# Build and push images
./build-and-push.sh
```

### Docker Cleanup

Free up disk space when Docker runs out:

```bash
# Quick cleanup (safe)
./cleanup-docker.sh light

# Deep cleanup (frees most space)
./cleanup-docker.sh aggressive

# Check disk usage
./cleanup-docker.sh status
```

## 🛠️ Scripts

- `build-and-push.sh` - Build and push images to GHCR
- `cleanup-docker.sh` - Clean up Docker disk space
- `tag_and_push.sh` - Tag and push existing images
- `free_disk_space.sh` - CI/CD disk cleanup

## 📝 Configuration

Edit `.env` file:
```bash
GITHUB_USERNAME=your_username
GITHUB_TOKEN=ghp_xxxxx
REGISTRY=ghcr.io
REPO=your_org/docker-images
TAG_SUFFIX=latest
```

## 🔧 Requirements

- Docker Desktop
- GitHub Personal Access Token with `write:packages` permission
- macOS/Linux

---

**Registry:** `ghcr.io/ousso11/docker-images`
