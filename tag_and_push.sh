#!/bin/bash

# Script to tag and push version tags for Docker images
# Usage: ./tag_and_push.sh <image_name>
# Example: ./tag_and_push.sh base
#          ./tag_and_push.sh pytorch  
#          ./tag_and_push.sh rs

set -e  # Exit on any error

# Check if image name is provided
if [ $# -eq 0 ]; then
    echo "❌ Error: Please provide an image name"
    echo "Usage: $0 <image_name>"
    echo "Examples:"
    echo "  $0 base"
    echo "  $0 pytorch"
    echo "  $0 rs"
    exit 1
fi

IMAGE_NAME="$1"
VERSION="v2.0.0"
TAG_NAME="${IMAGE_NAME}-${VERSION}"

echo "🏷️  Creating and pushing tag for: ${IMAGE_NAME}"
echo "📝 Tag name: ${TAG_NAME}"

# Create the tag with message
case $IMAGE_NAME in
    "base")
        MESSAGE="Base image ${VERSION} with CUDA 12.4 and Miniforge support"
        ;;
    "pytorch")
        MESSAGE="PyTorch image ${VERSION} with Unsloth and CUDA 12.4 support"
        ;;
    "rs")
        MESSAGE="RS image ${VERSION} with PyTorch 2.4.1 and CUDA 12.4 support"
        ;;
    *)
        MESSAGE="${IMAGE_NAME} image ${VERSION}"
        ;;
esac

echo "💬 Message: ${MESSAGE}"

# Delete existing tag locally if it exists
echo "🗑️  Deleting existing local tag (if exists)..."
git tag -d "${TAG_NAME}" 2>/dev/null || echo "   (No local tag to delete)"

# Delete existing tag remotely if it exists
echo "🗑️  Deleting existing remote tag (if exists)..."
git push origin ":refs/tags/${TAG_NAME}" 2>/dev/null || echo "   (No remote tag to delete)"

# Create annotated tag
echo "🏷️  Creating new tag..."
git tag -a "${TAG_NAME}" -m "${MESSAGE}"

# Push tag to remote
echo "⬆️  Pushing tag to remote..."
git push origin "${TAG_NAME}"

echo "✅ Successfully created and pushed tag: ${TAG_NAME}"
echo "🚀 GitHub Actions will now build: ghcr.io/ousso11/docker-images/${IMAGE_NAME}:main"
echo "🚀 GitHub Actions will now build: ghcr.io/ousso11/docker-images/${IMAGE_NAME}:${VERSION}"