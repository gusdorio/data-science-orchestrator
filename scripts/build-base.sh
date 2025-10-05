#!/bin/bash

# Build script for data science base images
# Usage: ./build-base.sh [minimal|extended|all]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Get host user UID and GID
HOST_UID=$(id -u)
HOST_GID=$(id -g)

# Function to print colored output
print_status() {
    echo -e "${GREEN}[BUILD]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to build an image
build_image() {
    local tier=$1
    local tag=$2
    local dockerfile_dir="${BASE_DIR}/base/${tier}"
    
    if [ ! -f "${dockerfile_dir}/Dockerfile" ]; then
        print_error "Dockerfile not found at ${dockerfile_dir}/Dockerfile"
        return 1
    fi
    
    print_status "Building ${tag} from ${dockerfile_dir}..."
    
    # Use BuildKit for better caching and performance
    DOCKER_BUILDKIT=1 docker build \
        --tag "${tag}" \
        --cache-from "${tag}" \
        --build-arg BUILDKIT_INLINE_CACHE=1 \
        --build-arg USER_ID=${HOST_UID} \
        --build-arg GROUP_ID=${HOST_GID} \
        "${dockerfile_dir}"
    
    if [ $? -eq 0 ]; then
        print_status "Successfully built ${tag}"
    else
        print_error "Failed to build ${tag}"
        return 1
    fi
}

# Parse command line arguments
TIER=${1:-all}

case $TIER in
    minimal)
        print_status "Building minimal base image..."
        build_image "minimal" "ds-minimal:latest"
        ;;
    extended)
        print_status "Building extended base image..."
        # First ensure minimal is built
        if ! docker image inspect ds-minimal:latest &> /dev/null; then
            print_warning "Minimal image not found, building it first..."
            build_image "minimal" "ds-minimal:latest"
        fi
        build_image "extended" "ds-extended:latest"
        ;;
    all)
        print_status "Building all base images..."
        build_image "minimal" "ds-minimal:latest"
        build_image "extended" "ds-extended:latest"
        ;;
    *)
        print_error "Unknown tier: $TIER"
        echo "Usage: $0 [minimal|extended|all]"
        exit 1
        ;;
esac

# Show built images
print_status "Available base images:"
docker images | grep -E "^ds-(minimal|extended)" || true

# Create volumes if they don't exist
print_status "Creating shared volumes..."
docker volume create ds-conda-cache &> /dev/null || true
docker volume create ds-pip-cache &> /dev/null || true
docker volume create ds-uv-cache &> /dev/null || true
docker volume create ds-jupyter-config &> /dev/null || true

print_status "Build complete!"