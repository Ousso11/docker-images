#!/bin/bash
# install_requirements_chunked.sh - Install requirements.txt by chunks with aggressive memory cleanup

set -e  # Exit on error

echo "🚀 Installing requirements.txt by chunks with memory management..."

# Function to show available space
show_space() {
    echo "💾 Available space:"
    df -h / /tmp /var/tmp 2>/dev/null || true
    echo "🧠 Memory info:"
    free -h 2>/dev/null || true
}

# Function to aggressive cleanup
cleanup() {
    echo "🧹 Aggressive cleanup..."
    pip cache purge || true
    apt-get clean || true
    rm -rf /tmp/* /var/tmp/* /root/.cache/* || true
    find /usr -name "*.pyc" -delete 2>/dev/null || true
    find /usr -name "__pycache__" -type d -exec rm -rf {} + 2>/dev/null || true
}

# Function to free massive disk space (calls external script)
free_github_runner_space() {
    echo "🚀 Calling external disk space cleanup script..."
    if [ -f "/app/free_disk_space.sh" ]; then
        /app/free_disk_space.sh
    else
        echo "⚠️  free_disk_space.sh not found, skipping massive cleanup"
    fi
}

# Function to install a chunk with cleanup
install_chunk() {
    local chunk_packages="$1"
    local chunk_name="$2"
    
    if [ -z "$chunk_packages" ]; then
        echo "⏭️  Skipping empty chunk: $chunk_name"
        return
    fi
    
    echo "📦 Installing chunk: $chunk_name"
    echo "Packages: $chunk_packages"
    show_space
    
    # Pre-cleanup
    cleanup
    
    # Install chunk
    echo "$chunk_packages" | pip install --no-cache-dir --no-build-isolation -r /dev/stdin
    
    # Post-cleanup
    cleanup
    
    echo "✅ $chunk_name completed"
    show_space
    echo "---"
}

cd /app

if [ ! -f "requirements.txt" ]; then
    echo "❌ requirements.txt not found!"
    exit 1
fi

echo "📋 Reading requirements.txt and splitting into chunks..."

# FREE MASSIVE SPACE FIRST - GitHub Actions specific
free_github_runner_space

show_space

# Read requirements.txt and split into logical chunks based on comments
current_chunk=""
chunk_name="General"
chunk_size=0
max_chunk_size=5  # Max packages per chunk

while IFS= read -r line || [ -n "$line" ]; do
    # Skip empty lines
    if [ -z "$(echo "$line" | tr -d '[:space:]')" ]; then
        continue
    fi
    
    # Check if line is a comment (section header)
    if echo "$line" | grep -q "^[[:space:]]*#.*===="; then
        # Install current chunk if not empty
        if [ -n "$current_chunk" ]; then
            install_chunk "$current_chunk" "$chunk_name"
            current_chunk=""
            chunk_size=0
        fi
        
        # Extract new chunk name from comment
        chunk_name=$(echo "$line" | sed 's/.*===== *\([^=]*\) *====.*/\1/' | tr -d '[:space:]')
        if [ -z "$chunk_name" ]; then
            chunk_name="Unnamed Section"
        fi
        echo "🏷️  Found section: $chunk_name"
        continue
    fi
    
    # Skip regular comments
    if echo "$line" | grep -q "^[[:space:]]*#"; then
        continue
    fi
    
    # Add package to current chunk
    if [ -n "$current_chunk" ]; then
        current_chunk="$current_chunk"$'\n'"$line"
    else
        current_chunk="$line"
    fi
    chunk_size=$((chunk_size + 1))
    
    # Install chunk if it reaches max size
    if [ $chunk_size -ge $max_chunk_size ]; then
        install_chunk "$current_chunk" "$chunk_name (batch $((chunk_size)))"
        current_chunk=""
        chunk_size=0
    fi
    
done < requirements.txt

# Install remaining packages in current chunk
if [ -n "$current_chunk" ]; then
    install_chunk "$current_chunk" "$chunk_name (final)"
fi

echo "✅ All requirements.txt chunks installed successfully!"
echo "📊 Final space check:"
show_space