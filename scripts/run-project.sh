#!/bin/bash

# Run script for data science projects
# Usage: ./run-project.sh <project-path> [options]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOCKER_DIR="$(dirname "$SCRIPT_DIR")"
BASE_DIR="$(dirname "$DOCKER_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[RUN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# Function to check if a port is available
is_port_available() {
    local port=$1
    # Check if port is in use by any process or docker container
    if ! netstat -ln 2>/dev/null | grep -q ":${port} " && \
       ! ss -ln 2>/dev/null | grep -q ":${port} " && \
       ! docker ps --format "table {{.Ports}}" 2>/dev/null | grep -q ":${port}->" ; then
        return 0  # Port is available
    else
        return 1  # Port is in use
    fi
}

# Function to find next available port starting from given port
find_available_port() {
    local start_port=$1
    local max_attempts=${2:-50}  # Default: try 50 ports
    
    for ((i=0; i<max_attempts; i++)); do
        local port=$((start_port + i))
        if is_port_available $port; then
            echo $port
            return 0
        fi
    done
    
    # If no port found, return the original
    echo $start_port
    return 1
}

# Function to show usage
show_usage() {
    cat << EOF
Usage: $0 <project-path> [options]

Run a data science project in a Docker container.

Arguments:
    project-path    Path to the project directory (relative to puc/ or absolute)

Options:
    -i, --image     Docker image to use (default: ds-minimal:latest)
    -c, --command   Command to run in container (default: bash)
    -j, --jupyter   Start Jupyter Lab instead of bash
    -s, --streamlit Run streamlit app (requires app file path after flag)
    -p, --port      Additional port to expose (can be used multiple times)
    -e, --env       Environment variable (can be used multiple times)
    -n, --name      Container name (default: project directory name)
    -h, --help      Show this help message

Examples:
    # Run interactive bash in a project
    $0 graph-theory/graph-coloring-algorithm

    # Start Jupyter Lab
    $0 unsupervised-learning/fuzzy-c-means --jupyter

    # Run streamlit app
    $0 unsupervised-learning/projetoExtencao012025 --streamlit dashboard.py

    # Use extended image for additional services
    $0 networks/socketsRepositorio --image ds-extended:latest

    # Run with custom command
    $0 big-data --command "python main.py"

    # Expose additional ports
    $0 my-project --port 5000:5000 --port 8080:8080
EOF
}

# Parse arguments
PROJECT_PATH=""
IMAGE="ds-minimal:latest"
COMMAND="bash"
EXTRA_PORTS=""
EXTRA_ENV=""
CONTAINER_NAME=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_usage
            exit 0
            ;;
        -i|--image)
            IMAGE="$2"
            shift 2
            ;;
        -c|--command)
            COMMAND="$2"
            shift 2
            ;;
        -j|--jupyter)
            COMMAND="jupyter lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root"
            shift
            ;;
        -s|--streamlit)
            if [ -z "$2" ]; then
                print_error "Streamlit requires an app file path"
                exit 1
            fi
            COMMAND="streamlit run $2 --server.address=0.0.0.0 --server.port=8501"
            shift 2
            ;;
        -p|--port)
            EXTRA_PORTS="$EXTRA_PORTS -p $2"
            shift 2
            ;;
        -e|--env)
            EXTRA_ENV="$EXTRA_ENV -e $2"
            shift 2
            ;;
        -n|--name)
            CONTAINER_NAME="$2"
            shift 2
            ;;
        *)
            if [ -z "$PROJECT_PATH" ]; then
                PROJECT_PATH="$1"
            else
                print_error "Unknown option: $1"
                show_usage
                exit 1
            fi
            shift
            ;;
    esac
done

# Validate project path
if [ -z "$PROJECT_PATH" ]; then
    print_error "Project path is required"
    show_usage
    exit 1
fi

# Convert to absolute path
if [[ "$PROJECT_PATH" = /* ]]; then
    # Already absolute
    ABS_PROJECT_PATH="$PROJECT_PATH"
else
    # Relative to BASE_DIR
    ABS_PROJECT_PATH="${BASE_DIR}/${PROJECT_PATH}"
fi

# Check if project directory exists
if [ ! -d "$ABS_PROJECT_PATH" ]; then
    print_error "Project directory not found: $ABS_PROJECT_PATH"
    exit 1
fi

# Get project name for container
if [ -z "$CONTAINER_NAME" ]; then
    CONTAINER_NAME=$(basename "$ABS_PROJECT_PATH")
fi

# Check if docker-compose.yml exists in project
if [ -f "${ABS_PROJECT_PATH}/docker-compose.yml" ]; then
    print_info "Found docker-compose.yml in project directory"
    print_status "Starting project with docker-compose..."
    
    cd "$ABS_PROJECT_PATH"
    export PROJECT_NAME="$CONTAINER_NAME"
    export DS_IMAGE="$IMAGE"
    export CONTAINER_CMD="$COMMAND"
    
    docker-compose up -d
    docker-compose exec dev $COMMAND
else
    # Run with docker directly
    print_status "Running project in Docker container..."
    
    # Check if image exists
    if ! docker image inspect "$IMAGE" &> /dev/null; then
        print_error "Docker image not found: $IMAGE"
        print_info "Run 'build-base.sh' to build base images"
        exit 1
    fi
    
    # Smart port allocation - Jupyter always available, other services only on extended
    JUPYTER_HOST_PORT=8888
    JUPYTER_CONTAINER_PORT=8888
    
    # Check and allocate Jupyter port (available in both minimal and extended)
    if [[ "$COMMAND" == *"jupyter"* ]]; then
        JUPYTER_HOST_PORT=$(find_available_port 8888)
        if [ $JUPYTER_HOST_PORT -ne 8888 ]; then
            print_warning "Port 8888 in use, using port $JUPYTER_HOST_PORT for Jupyter"
            # Update the jupyter command with the new port
            COMMAND="${COMMAND/--port=8888/--port=$JUPYTER_CONTAINER_PORT}"
        fi
    else
        # For bash or other commands, check Jupyter port
        JUPYTER_HOST_PORT=$(find_available_port 8888)
        if [ $JUPYTER_HOST_PORT -ne 8888 ]; then
            print_info "Using alternate port for Jupyter: $JUPYTER_HOST_PORT"
        fi
    fi
    
    # Extended image services (Streamlit, etc.) - only if using extended image
    if [[ "$IMAGE" == *"extended"* ]]; then
        STREAMLIT_HOST_PORT=8501
        STREAMLIT_CONTAINER_PORT=8501
        
        if [[ "$COMMAND" == *"streamlit"* ]]; then
            STREAMLIT_HOST_PORT=$(find_available_port 8501)
            if [ $STREAMLIT_HOST_PORT -ne 8501 ]; then
                print_warning "Port 8501 in use, using port $STREAMLIT_HOST_PORT for Streamlit"
                # Update the streamlit command with the new port
                COMMAND="${COMMAND/--server.port=8501/--server.port=$STREAMLIT_CONTAINER_PORT}"
            fi
        else
            # For bash or other commands on extended image, check streamlit port
            STREAMLIT_HOST_PORT=$(find_available_port 8501)
            if [ $STREAMLIT_HOST_PORT -ne 8501 ]; then
                print_info "Using alternate port for Streamlit: $STREAMLIT_HOST_PORT"
            fi
        fi
        
        EXTRA_SERVICE_PORTS="-p 127.0.0.1:${STREAMLIT_HOST_PORT}:${STREAMLIT_CONTAINER_PORT}"
    else
        # Minimal image - no additional service ports
        STREAMLIT_HOST_PORT=""
        EXTRA_SERVICE_PORTS=""
    fi
    
    # Prepare docker run command
    DOCKER_CMD="docker run -it --rm"
    DOCKER_CMD="$DOCKER_CMD --name ${CONTAINER_NAME}"
    DOCKER_CMD="$DOCKER_CMD -v ${ABS_PROJECT_PATH}:/workspace/project:rw"
    DOCKER_CMD="$DOCKER_CMD -v ds-conda-cache:/opt/conda/pkgs"
    DOCKER_CMD="$DOCKER_CMD -v ds-pip-cache:/home/developer/.cache/pip"
    DOCKER_CMD="$DOCKER_CMD -v ds-uv-cache:/opt/shared-libs/uv-cache"
    DOCKER_CMD="$DOCKER_CMD -v ds-jupyter-config:/home/developer/.jupyter"
    DOCKER_CMD="$DOCKER_CMD -w /workspace/project"
    DOCKER_CMD="$DOCKER_CMD -p 127.0.0.1:${JUPYTER_HOST_PORT}:${JUPYTER_CONTAINER_PORT}"
    DOCKER_CMD="$DOCKER_CMD $EXTRA_SERVICE_PORTS"
    DOCKER_CMD="$DOCKER_CMD $EXTRA_PORTS"
    DOCKER_CMD="$DOCKER_CMD -e PYTHONUNBUFFERED=1"
    DOCKER_CMD="$DOCKER_CMD -e PYTHONDONTWRITEBYTECODE=1"
    DOCKER_CMD="$DOCKER_CMD -e PYTHONPATH=/workspace/project:/workspace/project/src"
    DOCKER_CMD="$DOCKER_CMD -e PROJECT_NAME=${CONTAINER_NAME}"
    DOCKER_CMD="$DOCKER_CMD $EXTRA_ENV"
    DOCKER_CMD="$DOCKER_CMD --user developer"
    DOCKER_CMD="$DOCKER_CMD $IMAGE"
    DOCKER_CMD="$DOCKER_CMD bash -c \"$COMMAND\""
    
    print_info "Container name: $CONTAINER_NAME"
    print_info "Project path: $ABS_PROJECT_PATH"
    print_info "Image: $IMAGE"
    print_info "Command: $COMMAND"
    print_info "Jupyter port: $JUPYTER_HOST_PORT"
    
    # Show additional ports only for extended image
    if [[ "$IMAGE" == *"extended"* ]] && [ -n "$STREAMLIT_HOST_PORT" ]; then
        print_info "Streamlit port: $STREAMLIT_HOST_PORT"
    fi
    
    # Show access information
    if [[ "$COMMAND" == *"jupyter"* ]]; then
        print_status "Jupyter Lab will be available at: http://localhost:$JUPYTER_HOST_PORT/lab"
    elif [[ "$COMMAND" == *"streamlit"* ]]; then
        if [[ "$IMAGE" == *"extended"* ]]; then
            print_status "Streamlit app will be available at: http://localhost:$STREAMLIT_HOST_PORT"
        else
            print_warning "Streamlit requires ds-extended image. Current image: $IMAGE"
        fi
    else
        # Show available services based on image type
        if [[ "$IMAGE" == *"extended"* ]]; then
            print_status "Services available at: Jupyter http://localhost:$JUPYTER_HOST_PORT/lab | Streamlit http://localhost:$STREAMLIT_HOST_PORT"
        else
            print_status "Services available at: Jupyter http://localhost:$JUPYTER_HOST_PORT/lab"
        fi
    fi
    
    # Execute
    eval $DOCKER_CMD
fi