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

# Owner (user or org) to use for GitHub Packages API. If not set, default to GITHUB_USERNAME
OWNER=${OWNER:-$GITHUB_USERNAME}

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
    local tag_suffix=${3:-$TAG_SUFFIX}
    
    local full_image_name="${REGISTRY}/${REPO}/${image_name}"
    local image_tag="${full_image_name}:${tag_suffix}"
    
    # Check if image already exists before building
    if check_image_exists "${image_name}" "${tag_suffix}"; then
        read -r -p "🔄 Image ${image_name} already exists. Override? [y/N]: " override
        case "$override" in
            [Yy]* )
                echo "✅ Proceeding with override..."
                ;;
            * )
                echo "⏭️  Skipping ${image_name}"
                return 0
                ;;
        esac
    fi
    
    log "🏗️  Building ${image_name} image..."
    echo "   📁 Dockerfile: ${dockerfile_path}"
    echo "   🏷️  Tag: ${image_tag}"
    echo "   🔧 Platform: ${PLATFORM}"
    
    # Build and push with progress
    if docker buildx build \
        --platform "${PLATFORM}" \
        --push \
        -t "${image_tag}" \
        -f "${dockerfile_path}" \
        --progress=plain \
        .; then
        log "✅ Successfully built and pushed ${image_name}"
        echo "   🔗 Image: ${image_tag}"
    else
        error "❌ Failed to build ${image_name}"
    fi
}

# Check if specific image tags exist on GHCR
check_image_exists() {
    local image_name="$1"
    local tag_suffix=${2:-$TAG_SUFFIX}
    
    if [ -z "${GITHUB_TOKEN}" ]; then
        echo "⚠️  GITHUB_TOKEN not set; cannot check if image exists. Proceeding with build..."
        return 1  # Return 1 (false) so build proceeds
    fi
    
    local full_image_name="${REGISTRY}/${REPO}/${image_name}"
    local check_tags=("${tag_suffix}")
    
    echo "🔍 Checking if image ${image_name} exists on GHCR..."
    
    # Use docker manifest inspect to check if image tags exist
    # This is more reliable than API calls for checking actual image existence
    local exists=false
    
    for check_tag in "${check_tags[@]}"; do
        local image_ref="${full_image_name}:${check_tag}"
        
        # Try to pull manifest (this checks if the image actually exists)
        if docker manifest inspect "${image_ref}" >/dev/null 2>&1; then
            echo "📦 Found existing image: ${image_ref}"
            exists=true
        fi
    done
    
    if [ "$exists" = true ]; then
        return 0  # Return 0 (true) - image exists
    else
        echo "📦 No existing images found for ${image_name}"
        return 1  # Return 1 (false) - image doesn't exist
    fi
}


# Check GitHub Container Registry package visibility and optionally set to public.
# Expects GITHUB_TOKEN in env and OWNER to be set (user or org name).
check_and_maybe_make_public() {
    local image_name="$1"
    if [ -z "${GITHUB_TOKEN}" ]; then
        echo "GITHUB_TOKEN not set; cannot check or change package visibility. Skipping."
        return 0
    fi

    # GHCR package name for container packages uses the package name equal to the repository name by default.
    # The API endpoint: PATCH /users/{username}/packages/container/{package_name}/visibility
    # or PATCH /orgs/{org}/packages/container/{package_name}/visibility
    local package_name="${REPO}-${image_name}"
    # Some projects publish package name equal to repo (without suffix). Try both: REPO-image and image.
    local endpoints=(
        "https://api.github.com/orgs/${OWNER}/packages/container/${package_name}/visibility"
        "https://api.github.com/users/${OWNER}/packages/container/${package_name}/visibility"
        "https://api.github.com/orgs/${OWNER}/packages/container/${image_name}/visibility"
        "https://api.github.com/users/${OWNER}/packages/container/${image_name}/visibility"
    )

    for ep in "${endpoints[@]}"; do
        # Check current visibility
        resp=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "Accept: application/vnd.github.v3+json" "${ep}")
        if [ "$resp" = "200" ]; then
            # Retrieve visibility field
            vis=$(curl -s -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "Accept: application/vnd.github.v3+json" "${ep}" | jq -r '.visibility // empty')
            if [ -z "${vis}" ] || [ "${vis}" = "null" ]; then
                # Some endpoints may not return visibility via GET; attempt to fetch package metadata list
                vis="unknown"
            fi
            echo "Package endpoint ${ep} found. Current visibility: ${vis}"
            if [ "${vis}" = "public" ]; then
                echo "Package ${image_name} is already public."
                return 0
            fi
            # Ask user whether to make it public
            read -r -p "Make ${OWNER}/${package_name} public? [y/N]: " yn
            case "$yn" in
                [Yy]* )
                    echo "Setting package visibility to public..."
                    patch_resp=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "Accept: application/vnd.github.v3+json" -d '{"visibility":"public"}' "${ep}")
                    if [ "$patch_resp" = "200" ]; then
                        echo "Package ${package_name} visibility set to public."
                    else
                        echo "Failed to set package visibility (HTTP ${patch_resp}). You may not have permission or package name differs."
                    fi
                    return 0
                    ;;
                * )
                    echo "Not changing visibility for ${package_name}."
                    return 0
                    ;;
            esac
        fi
    done

  echo "No package endpoint found for ${image_name} under ${OWNER}. The package may not exist yet or the name is different."
  return 0
}

# Check and optionally make public - called at the end for all images
check_and_maybe_make_public_final() {
  local image_name="$1"
  
  if [ -z "${GITHUB_TOKEN}" ]; then
    echo "⚠️  GITHUB_TOKEN not set; cannot check package visibility for ${image_name}"
    return 0
  fi

  echo "🔍 Checking visibility for ${image_name}..."
  
  # Try different package name patterns and endpoints  
  # GHCR packages can be named as repo/image (URL-encoded as repo%2Fimage)
  # Extract just the repo name (remove owner/ prefix)
  local repo_name="${REPO##*/}"
  local package_patterns=("${repo_name}%2F${image_name}" "${repo_name}" "${image_name}" "${repo_name}-${image_name}")
  local api_types=("orgs" "users")
  
  for pattern in "${package_patterns[@]}"; do
    for api_type in "${api_types[@]}"; do
      local endpoint="https://api.github.com/${api_type}/${OWNER}/packages/container/${pattern}"
      local resp=$(curl -s -o /dev/null -w "%{http_code}" -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "Accept: application/vnd.github.v3+json" "${endpoint}")
      
      if [ "$resp" = "200" ]; then
        # Get current visibility
        local vis=$(curl -s -H "Authorization: Bearer ${GITHUB_TOKEN}" -H "Accept: application/vnd.github.v3+json" "${endpoint}" | jq -r '.visibility // "unknown"')
        
        if [ "${vis}" = "public" ]; then
          echo "✅ Image ${image_name} is already public"
          return 0
        elif [ "${vis}" = "private" ]; then
          echo "🔒 Image ${image_name} is private"
          echo ""
          echo "🔄 To make it public, choose one of these methods:"
          echo "   1. Web UI: https://github.com/users/${OWNER}/packages/container/package/${repo_name}%2F${image_name}"
          echo "      → Click 'Package settings' → Change visibility to 'Public'"
          return 0
        else
          echo "❓ Image ${image_name} visibility: ${vis}"
          return 0
        fi
      fi
    done
  done
  
  echo "❓ Could not find package ${image_name} under ${OWNER}"
  return 0
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
TAG_SUFFIX="main"
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
    
    # Build images in order (base first, as others depend on it)
    local start_time=$(date +%s)
    
    # Track which images we processed (built or skipped)
    local processed_images=()
    
    for image in "${IMAGES_TO_BUILD[@]}"; do
        case $image in
            "base")
                build_and_push "base" "base/Dockerfile" "$TAG_SUFFIX"
                processed_images+=("base")
                ;;
            "pytorch")
                build_and_push "pytorch" "pytorch/Dockerfile" "$TAG_SUFFIX"
                processed_images+=("pytorch")
                ;;
            "rs")
                build_and_push "rs" "rs/Dockerfile" "$TAG_SUFFIX"
                processed_images+=("rs")
                ;;
            *)
                error "Unknown image: $image"
                ;;
        esac
        echo
    done
    
    # Check visibility for all processed images (built or skipped)
    echo
    log "🔍 Checking image visibility..."
    for image in "${processed_images[@]}"; do
        check_and_maybe_make_public_final "$image"
        echo
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