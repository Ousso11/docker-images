#!/bin/bash

# ===========================
# Docker Cleanup Script
# Removes unused Docker images, containers, volumes, and build cache
# to free up disk space on macOS Docker Desktop VM
# ===========================

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
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

info() {
    echo -e "${CYAN}[INFO]${NC} $1"
}

# Function to show disk usage
show_disk_usage() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}💾 Docker Disk Usage:${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    docker system df
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Check if Docker is running
check_docker() {
    if ! docker info >/dev/null 2>&1; then
        error "Docker is not running. Please start Docker Desktop and try again."
    fi
    log "Docker is running ✅"
}

# Main cleanup function
cleanup_docker() {
    local cleanup_type=$1
    
    log "🧹 Starting Docker cleanup..."
    echo ""
    
    # Show current disk usage
    info "BEFORE cleanup:"
    show_disk_usage
    
    case $cleanup_type in
        "light")
            log "🗑️  Performing LIGHT cleanup (dangling images & unused cache)..."
            docker system prune -f
            ;;
        "moderate")
            log "🗑️  Performing MODERATE cleanup (stopped containers, dangling images, unused networks & cache)..."
            docker system prune -f
            docker container prune -f
            docker network prune -f
            ;;
        "aggressive")
            warn "⚠️  Performing AGGRESSIVE cleanup (ALL unused images, containers, volumes & cache)..."
            read -r -p "This will remove ALL unused Docker data. Continue? [y/N]: " confirm
            case "$confirm" in
                [Yy]* )
                    docker system prune -a -f --volumes
                    ;;
                * )
                    info "Cleanup cancelled."
                    return 0
                    ;;
            esac
            ;;
        "nuclear")
            warn "☢️  Performing NUCLEAR cleanup (EVERYTHING including running containers)..."
            read -r -p "This will STOP and REMOVE ALL containers, images, volumes, networks & cache. Are you SURE? [y/N]: " confirm
            case "$confirm" in
                [Yy]* )
                    # Stop all running containers
                    if [ "$(docker ps -q)" ]; then
                        log "Stopping all running containers..."
                        docker stop $(docker ps -q)
                    fi
                    # Remove everything
                    docker system prune -a -f --volumes
                    ;;
                * )
                    info "Cleanup cancelled."
                    return 0
                    ;;
            esac
            ;;
        *)
            error "Unknown cleanup type: $cleanup_type"
            ;;
    esac
    
    echo ""
    log "✅ Docker cleanup complete!"
    
    # Show freed space
    info "AFTER cleanup:"
    show_disk_usage
}

# Show usage
show_usage() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo -e "${BLUE}🧹 Docker Cleanup Script${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Usage: $0 [cleanup-type]"
    echo ""
    echo "Cleanup Types:"
    echo "  light       - Remove dangling images & unused build cache (safe)"
    echo "  moderate    - Remove stopped containers, dangling images, unused networks & cache"
    echo "  aggressive  - Remove ALL unused images, containers, volumes & cache (requires confirmation)"
    echo "  nuclear     - Remove EVERYTHING including running containers (requires confirmation)"
    echo "  status      - Show current Docker disk usage (no cleanup)"
    echo ""
    echo "Examples:"
    echo "  $0 light       # Quick cleanup (safe, no confirmation needed)"
    echo "  $0 moderate    # More thorough cleanup"
    echo "  $0 aggressive  # Deep clean (frees the most space)"
    echo "  $0 status      # Just show disk usage"
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
}

# Main function
main() {
    local cleanup_type=${1:-light}
    
    if [ "$cleanup_type" = "help" ] || [ "$cleanup_type" = "-h" ] || [ "$cleanup_type" = "--help" ]; then
        show_usage
        exit 0
    fi
    
    check_docker
    
    if [ "$cleanup_type" = "status" ]; then
        show_disk_usage
        exit 0
    fi
    
    cleanup_docker "$cleanup_type"
    
    log "🎉 All done!"
}

# Run main function
main "$@"
