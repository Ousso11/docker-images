# RS Docker Image Deployment Guide

## 📋 Overview
This guide explains how to commit, push and tag the RS Docker image to trigger the automated build workflow.

## 🚀 Deployment Steps

### 1. Commit Changes
```bash
# Add all changes
git add .

# Commit with descriptive message
git commit -m "feat: Add RS Docker image with minimal setup

- Add RS Dockerfile with CUDA 12.1 + PyTorch base
- Add environment.yml for conda users  
- Add GitHub workflow for RS image builds (triggered by rs-* tags)
- Remove heavy package installations to avoid space issues
- Packages can be installed manually inside container"
```

### 2. Push to Remote
```bash
# Push changes to main branch
git push origin main
```

### 3. Create and Push Tag
```bash
# Create a new tag for RS image (this triggers the workflow)
git tag -a "rs-v1.0.0" -m "RS Docker image v1.0.0

- Minimal RS image with CUDA 12.1 + PyTorch
- Base setup for relation search development
- Manual package installation for flexibility"

# Push the tag to trigger the RS workflow
git push origin rs-v1.0.0
```

## 🔧 Alternative: One-Line Commands

### Quick Deploy
```bash
git add . && git commit -m "feat: RS Docker image updates" && git push origin main && git tag rs-v1.0.0 && git push origin rs-v1.0.0
```

### Update Existing Tag
```bash
# Delete existing tag locally and remotely
git tag -d rs-v1.0.0
git push origin --delete rs-v1.0.0

# Create and push new tag
git tag -a rs-v1.0.0 -m "Updated RS Docker image"
git push origin rs-v1.0.0
```

## 📊 Monitoring

### Check Workflow Status
- **GitHub Actions**: https://github.com/Ousso11/docker-images/actions
- **Workflow**: Look for "rs" workflow triggered by `rs-*` tags

### Check Built Image
Once the workflow completes successfully:
```bash
# Pull the built image
docker pull ghcr.io/ousso11/docker-images/rs:rs-v1.0.0

# Or pull latest
docker pull ghcr.io/ousso11/docker-images/rs:latest
```

## 🎯 Tag Naming Convention

| Tag Pattern | Purpose | Example |
|-------------|---------|---------|
| `rs-v*` | Release versions | `rs-v1.0.0`, `rs-v1.1.0` |
| `rs-dev` | Development builds | `rs-dev` |
| `rs-test-*` | Test builds | `rs-test-feature` |

## 🚨 Troubleshooting

### Workflow Not Triggered
- Ensure tag starts with `rs-` (e.g., `rs-v1.0.0`)
- Check that the workflow file exists: `.github/workflows/docker-rs.yml`
- Verify tag was pushed: `git ls-remote --tags origin`

### Build Failures
- Check GitHub Actions logs
- Verify Dockerfile syntax
- Ensure all COPY paths are correct

## 📝 Next Steps After Deployment

1. **Test the image**:
   ```bash
   docker run --gpus all -it ghcr.io/ousso11/docker-images/rs:latest
   ```

2. **Install packages as needed**:
   ```bash
   # Inside the container
   pip install transformers fastapi gradio
   # Or install all requirements
   pip install -r /app/rs/requirements.txt
   ```

3. **Update documentation** with the new image tag