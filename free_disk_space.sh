#!/bin/bash
# free_disk_space.sh - Universal disk space cleanup script
# Works in both CI/CD environments and Docker containers
# Combines Docker-safe and GitHub Actions specific cleanups

set -e

echo "🚀 Freeing disk space universally..."

# Detect if we're running with sudo capabilities (GitHub Actions vs Docker)
HAVE_SUDO=false
if command -v sudo >/dev/null 2>&1 && sudo -n true 2>/dev/null; then
    HAVE_SUDO=true
    echo "✅ Running with sudo capabilities (likely GitHub Actions)"
else
    echo "⚠️  Running without sudo (likely Docker container)"
fi

# Function to show disk usage
show_disk_usage() {
    echo "💾 Current disk usage:"
    df -h / 2>/dev/null || true
    echo "🗂️  Top 10 largest directories in /:"
    du -sh /* 2>/dev/null | sort -hr | head -10 2>/dev/null || true
}

echo "📊 BEFORE cleanup:"
show_disk_usage

# ================================
# PHASE 1: GitHub Actions specific cleanups (with sudo)
# ================================
if [ "$HAVE_SUDO" = true ]; then
    echo "🗑️  PHASE 1: GitHub Actions specific cleanups..."
    
    # Remove hostedtoolcache (10+ GB) - Most effective for GitHub Actions
    echo "🗑️  Removing /opt/hostedtoolcache (10+ GB)..."
    sudo rm -rf /opt/hostedtoolcache/* 2>/dev/null || true
    
    # Remove other large /opt directories (12+ GB) - PROTECT /opt/conda!
    echo "🗑️  Removing other large /opt directories..."
    sudo find /opt -maxdepth 1 -mindepth 1 \
        '!' -path /opt/containerd \
        '!' -path /opt/actionarchivecache \
        '!' -path /opt/runner \
        '!' -path /opt/runner-cache \
        '!' -path /opt/conda \
        -exec rm -rf '{}' ';' 2>/dev/null || true
    
    # Remove GitHub Actions specific packages
    echo "🗑️  Removing GitHub Actions specific packages..."
    packages_to_remove=(
        "azure-cli"
        "google-cloud-sdk"
        "hhvm"
        "google-chrome-stable" 
        "firefox"
        "powershell"
        "mono-devel"
    )
    
    for package in "${packages_to_remove[@]}"; do
        sudo apt-get remove -y "$package" 2>/dev/null || true
    done
    
    # Remove GitHub Actions specific directories
    echo "🗑️  Removing GitHub Actions specific directories..."
    directories_to_remove=(
        "/usr/share/dotnet"
        "/usr/local/lib/android"
        "/usr/local/share/powershell"
        "/usr/local/share/chromium"
        "/usr/local/lib/node_modules"
        "/opt/az"
        "/opt/microsoft"
        "/opt/google"
        "/opt/pipx"
        "/usr/lib/google-cloud-sdk"
        "/usr/lib/jvm/java-*-openjdk*"
    )
    
    for dir in "${directories_to_remove[@]}"; do
        sudo rm -rf $dir 2>/dev/null || true
    done
    
    # Remove swap file and Docker images
    echo "🗑️  Removing swap and Docker cleanup..."
    sudo swapoff -a 2>/dev/null || true
    sudo rm -f /swapfile 2>/dev/null || true
    sudo rm -f /mnt/swapfile 2>/dev/null || true
    
    # Remove GitHub Actions agent tool directory
    sudo rm -rf "$AGENT_TOOLSDIRECTORY" 2>/dev/null || true
fi

# ================================
# PHASE 2: Universal package manager cleanups
# ================================
echo "🗑️  PHASE 2: Universal package manager cleanups..."

CMD_PREFIX=""
if [ "$HAVE_SUDO" = true ]; then
    CMD_PREFIX="sudo"
fi

if command -v apt-get >/dev/null 2>&1; then
    $CMD_PREFIX apt-get clean 2>/dev/null || true
    $CMD_PREFIX apt-get autoclean 2>/dev/null || true
    $CMD_PREFIX apt-get autoremove -y 2>/dev/null || true
fi

if command -v yum >/dev/null 2>&1; then
    $CMD_PREFIX yum clean all 2>/dev/null || true
fi

# ================================
# PHASE 3: Universal large package removals
# ================================
echo "🗑️  PHASE 3: Universal large package removals..."

if command -v apt-get >/dev/null 2>&1; then
    # Remove specific package patterns (safe for most environments)
    $CMD_PREFIX apt-get remove -y '^ghc-8.*' 2>/dev/null || true
    $CMD_PREFIX apt-get remove -y '^dotnet-.*' 2>/dev/null || true  
    $CMD_PREFIX apt-get remove -y '^llvm-.*' 2>/dev/null || true
    $CMD_PREFIX apt-get remove -y 'php.*' 2>/dev/null || true

    # Remove specific large packages
    packages_to_remove=(
        "mysql-server*"
        "postgresql*"
        "microsoft-edge-stable"
    )

    for package in "${packages_to_remove[@]}"; do
        $CMD_PREFIX apt-get remove -y "$package" 2>/dev/null || true
    done

    $CMD_PREFIX apt-get autoremove -y 2>/dev/null || true
fi

# ================================
# PHASE 4: Universal directory cleanups
# ================================
echo "🗑️  PHASE 4: Universal directory cleanups..."

# Directories safe to remove in most environments
# NOTE: /opt/conda and conda-related directories are protected
directories_to_remove=(
    "/usr/share/gradle*"
    "/usr/share/maven*"
    "/usr/local/share/boost"
    "/usr/local/graalvm"
    "/usr/local/.ghcup"
    "/usr/share/swift"
    "/usr/share/rust"
    "/root/.cargo"
    "/root/.rustup"
    "/usr/lib/mono"
)

for dir in "${directories_to_remove[@]}"; do
    $CMD_PREFIX rm -rf $dir 2>/dev/null || true
done

# ================================
# PHASE 5: Universal cache cleanups
# ================================
echo "🗑️  PHASE 5: Universal cache cleanups..."

# Remove various caches
$CMD_PREFIX rm -rf /var/cache/* 2>/dev/null || true
$CMD_PREFIX rm -rf /root/.cache/* 2>/dev/null || true
$CMD_PREFIX rm -rf /home/*/.cache/* 2>/dev/null || true

# ================================
# PHASE 6: Language-specific cleanups
# ================================
echo "🗑️  PHASE 6: Language-specific cleanups..."

# Remove Python cache files
$CMD_PREFIX find /usr -name "*.pyc" -delete 2>/dev/null || true
$CMD_PREFIX find /usr -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true

# Remove gem cache
$CMD_PREFIX rm -rf /var/lib/gems/*/cache/* 2>/dev/null || true

# Remove npm cache
$CMD_PREFIX rm -rf /root/.npm 2>/dev/null || true
$CMD_PREFIX rm -rf /home/*/.npm 2>/dev/null || true

# ================================
# PHASE 7: Docker cleanup (universal)
# ================================
echo "🗑️  PHASE 7: Docker cleanup..."

# Clean Docker (if available)
if command -v docker >/dev/null 2>&1; then
    if [ "$(docker image ls -aq 2>/dev/null)" != "" ]; then
        docker rmi $(docker image ls -aq) 2>/dev/null || true
    fi
    docker system prune -af 2>/dev/null || true
fi

# ================================
# PHASE 8: Final log cleanup
# ================================
echo "🗑️  PHASE 8: Final log cleanup..."
$CMD_PREFIX find /var/log -type f -delete 2>/dev/null || true

echo "✅ Universal disk space cleanup completed!"

echo "📊 AFTER cleanup:"
show_disk_usage

echo "🎉 Disk space liberation finished!"