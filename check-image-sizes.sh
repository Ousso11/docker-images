#!/bin/bash

# Check sizes of Docker images on GitHub Container Registry
# Usage: ./check-image-sizes.sh
# Requires: GITHUB_TOKEN in .env file for authentication

# Load environment variables from .env
if [ -f .env ]; then
    export $(cat .env | grep -v '^#' | xargs)
else
    echo "⚠️  Warning: .env file not found. Authentication may fail."
fi

OWNER="ousso11"
REPO="docker-images"

echo "=====> Checking Docker image sizes for $OWNER/$REPO"
echo ""

# Array of image names
images=("base" "pytorch" "rs")

for image in "${images[@]}"; do
    echo "📦 Image: $image"
    
    full_image="ghcr.io/$OWNER/$REPO/$image:main"
    
    # Authenticate with GitHub token if available
    if [ -n "$GITHUB_TOKEN" ]; then
        echo "$GITHUB_TOKEN" | docker login ghcr.io -u "$OWNER" --password-stdin >/dev/null 2>&1
    fi
    
    # Get the multi-platform manifest
    manifest=$(docker manifest inspect "$full_image" 2>/dev/null)
    
    if [ $? -eq 0 ]; then
        # Check if it's a manifest list (multi-platform)
        manifests_count=$(echo "$manifest" | jq -r '.manifests | length' 2>/dev/null)
        
        if [ -n "$manifests_count" ] && [ "$manifests_count" -gt 0 ]; then
            # Multi-platform image - get digest for amd64
            amd64_digest=$(echo "$manifest" | jq -r '.manifests[] | select(.platform.architecture=="amd64") | .digest' | head -1)
            
            if [ -n "$amd64_digest" ]; then
                # Inspect the specific platform image
                platform_manifest=$(docker buildx imagetools inspect --raw "$full_image@$amd64_digest" 2>/dev/null)
                
                if [ -n "$platform_manifest" ]; then
                    config_size=$(echo "$platform_manifest" | jq -r '.config.size // 0')
                    layers_size=$(echo "$platform_manifest" | jq -r '[.layers[]?.size // 0] | add // 0')
                    total_bytes=$((config_size + layers_size))
                else
                    total_bytes=0
                fi
            else
                total_bytes=0
            fi
        else
            # Single platform image
            config_size=$(echo "$manifest" | jq -r '.config.size // 0')
            layers_size=$(echo "$manifest" | jq -r '[.layers[]?.size // 0] | add // 0')
            total_bytes=$((config_size + layers_size))
        fi
        
        if [ "$total_bytes" -gt 0 ]; then
            # Convert to human readable
            size_gb=$(echo "scale=2; $total_bytes / 1073741824" | bc)
            
            if (( $(echo "$size_gb >= 1" | bc -l) )); then
                echo "   Size: ${size_gb} GB"
            else
                size_mb=$(echo "scale=2; $total_bytes / 1048576" | bc)
                echo "   Size: ${size_mb} MB"
            fi
        else
            echo "   ⚠️  Could not determine size"
        fi
    else
        echo "   ⚠️  Image not found or not accessible"
    fi
    echo ""
done

echo "=====> Done!"
