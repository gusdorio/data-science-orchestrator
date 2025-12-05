#!/bin/bash

# Build script for data science base image
# Usage: ./build-base.sh

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

# Function to build the image
build_image() {
    local dockerfile_dir="${BASE_DIR}/base/unified"
    local tag="ds-base:latest"
    
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

# Show usage if help flag
if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
    cat << EOF
Usage: $0

Build the unified data science base image (ds-base:latest).

This script builds a single comprehensive image that includes:
- Core data science: numpy, pandas, matplotlib, scipy, scikit-learn, seaborn
- Time series: pmdarima, prophet
- Visualization: plotly, altair
- Web/Dashboard: streamlit
- Graph/Network: networkx
- SQL support: sqlalchemy
- Jupyter ecosystem: jupyterlab, notebook
- Development tools: black, ipython
- PDF export: pandoc, texlive

For project-specific dependencies (databases, ML libraries, NLP, etc.),
create a project-specific docker-compose.yml and Dockerfile.

EOF
    exit 0
fi

print_status "Building data science base image..."
build_image

# Show built images
print_status "Available base image:"
docker images | grep -E "^ds-base" || true

# Create volumes if they don't exist
print_status "Creating shared volumes..."
docker volume create ds-conda-cache &> /dev/null || true
docker volume create ds-pip-cache &> /dev/null || true
docker volume create ds-uv-cache &> /dev/null || true
docker volume create ds-jupyter-config &> /dev/null || true

print_status "Build complete!"
print_status ""
print_status "Next steps:"
print_status "  Run a project:  ./run-project.sh <project-path>"
print_status "  Start Jupyter:  ./run-project.sh <project-path> --jupyter"
print_status "  Run Streamlit:  ./run-project.sh <project-path> --streamlit app.py"