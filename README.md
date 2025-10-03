# Data Science Docker Environment

Every time we want to test a new algorithm/project, we fall on the problem of setting up a entirely new enviroment in our computer. This introduces a lot of dump files in computer, degrading performance over the time. Even if you comes from the practice of using a consistent enviroment for multiple projects, you will fall on the problem of package management and cache overhead.

This project is intended to solve this problem.

You can use this as a script repository side-by-side with your projects and just follow the instructions bellow for automated setup of standard container enviroments for every time you want to execute a project. When you finish your session, the container is recycled (removed) by standard.

By using this you gain centralized library management, easy project execution, isolation and clean cache controls.

## Overview

This Docker setup provides a flexible and efficient way to run data science projects in containers. It uses a tiered approach with two base images:

1. **Minimal Base (`ds-minimal`)**: Core data science packages only
2. **Extended Base (`ds-extended`)**: Full suite including visualization, ML, and web frameworks

For library specs, take a look on the images in template folders.

### Key Features

- **Tiered Base Images**: Choose between minimal and extended environments
- **Centralized Library Cache**: Shared volumes for conda, pip, and uv packages
- **Easy Project Execution**: Simple scripts to run any project
- **Bind Mount Development**: Live code editing with bind mounts
- **Multiple Package Managers**: Conda for core packages, UV for fast pip installs
- **Project Isolation**: Each project runs in its own container
- **Efficient Storage**: Shared library cache reduces disk usage

## Directory Structure

```
docker/
├── base/
│   ├── minimal/
│   │   ├── Dockerfile      # Core packages only
│   │   └── environment.yml
│   └── extended/
│       ├── Dockerfile      # Full package suite
│       └── environment.yml
├── templates/
│   ├── docker-compose.yml  # Template for projects
│   └── Dockerfile.project  # Template for custom images
├── scripts/
│   ├── build-base.sh      # Build base images
│   └── run-project.sh     # Run projects
└── README.md              # This file
```

## Notes

This enviroment was ONLY tested with linux-based enviroments.

## Quick Start

### 1. Ensure to place it right

First things first: make sure to clone this repository in a directory where you will (or already have) leave your projects together; By this, I mean something like:

```
home/
├── data-science-orchestrator/   # Our currently project (you can change the folder name later, I use as 'docker' since is more intuitive in daily basis, for example)
│   └── .../
├── my-project/
│   └── ...
└── statistics/
    └── ...
```

This is crucially if you want to use the scripts/ built to easily workflows. Soon you will realize how much it can save from your time ;-)

### 2. Make the scripts executable

Next to it, make sure the scripts are executable.

```bash
chmod +x data-science-orchestrator/scripts/*.sh
```

### 3. Build Base Images

First, build the base images:

```bash
cd data-science-orchestrator/scripts

# Build all base images
./build-base.sh all

# Or build specific tier
./build-base.sh minimal   # Just core packages
./build-base.sh extended  # Full package suite
```

### 4. Run a Project

Run any project with a single command:

```bash
# Run with interactive bash
./run-project.sh statistics
```

## Image Tiers

### Tier 1: Minimal Base (`ds-minimal`)

Perfect for projects that need only core data science tools:

- **Core Libraries**: numpy, pandas, matplotlib, seaborn, scipy, scikit-learn, statsmodels
- **Jupyter**: JupyterLab, notebook, ipykernel
- **File Formats**: openpyxl, xlrd, xlsxwriter (Excel support)
- **Utilities**: requests, python-dateutil, pytz, tabulate, ucimlrepo
- **Package Managers**: pip, conda, uv

### Tier 2: Extended Base (`ds-extended`)

Includes everything from minimal plus:

- **Visualization**: plotly, altair
- **Web Frameworks**: streamlit
- **Graph/Network**: networkx
- **ML Extensions**: xgboost, lightgbm
- **NLP**: nltk, spacy
- **Time Series**: prophet
- **Databases**: sqlalchemy, pymongo, redis-py
- **Development**: black, pylint
- **Performance**: numba, cython

## Script Usage

### build-base.sh

Builds the Docker base images with optimized caching.

```bash
Usage: ./build-base.sh [minimal|extended|all]

Examples:
  ./build-base.sh all        # Build both tiers
  ./build-base.sh minimal    # Build only minimal
  ./build-base.sh extended   # Build only extended
```

Features:
- Uses Docker BuildKit for faster builds
- Automatic image caching
- Creates shared volumes automatically
- Shows available images after build

### run-project.sh

Runs a project in a Docker container with proper mounts and configuration.

```bash
Usage: ./run-project.sh <project-path> [options]

Options:
  -i, --image     Docker image to use (default: ds-minimal:latest)
  -c, --command   Command to run in container (default: bash)
  -j, --jupyter   Start Jupyter Lab instead of bash
  -s, --streamlit Run streamlit app (requires app file path)
  -p, --port      Additional port to expose (can be used multiple times)
  -e, --env       Environment variable (can be used multiple times)
  -n, --name      Container name (default: project directory name)
  -h, --help      Show help message

Examples:
  # Interactive bash session
  ./run-project.sh my-project

  # Start Jupyter Lab
  ./run-project.sh my-project --jupyter

  # Run Streamlit app
  ./run-project.sh my-project --streamlit app.py

  # Use extended image for additional services
  ./run-project.sh my-project --image ds-extended:latest

  # Custom command
  ./run-project.sh my-project --command "python train.py"

  # Expose additional ports
  ./run-project.sh my-project --port 5000:5000 --port 8080:8080
```

The project (folder path) you define will be the root inside the container, working in bind mode. Its useful to keep it in mind for when you want not only to use notebooks, but also to make imports from inside the project (for like when you build your own libraries). 

#### Running a Subfolder as the Project Context

You can pass a subfolder (not just the repository root) to run-project.sh when a project is organized into multiple topics or submodules.

Example:
```bash
# Run a nested subfolder
./run-project.sh graph-theory/graphing_color_algorithm

# Override the container name (default: basename of the path)
./run-project.sh graph-theory/graphing_color_algorithm --name graph-color-dev
```

## Working with Projects

### Option 1: Direct Execution

For simple projects, just run them directly:

```bash
./docker/scripts/run-project.sh my-project
```

The script will:
- Mount your project at `/workspace/project`
- Use bind mounts for live development
- Share library caches across containers
- Expose standard ports (8888 for Jupyter, 8501 for Streamlit)

### Option 2: Docker Compose

For more complex setups, copy the template docker-compose.yml to your project:

```bash
cp docker/templates/docker-compose.yml my-project/
cd my-project
docker-compose up -d
docker-compose exec dev bash
```

### Option 3: Custom Dockerfile

For projects with special dependencies:

1. Copy the template:
```bash
cp docker/templates/Dockerfile.project my-project/Dockerfile
```

2. Edit to add your dependencies
3. Build and run:
```bash
cd my-project
docker build -t my-project:latest .
docker run -it -v $(pwd):/workspace/project my-project:latest
```

## Volume Management

The system uses named volumes for efficient storage:

- `ds-conda-cache`: Conda package cache
- `ds-pip-cache`: Pip package cache  
- `ds-uv-cache`: UV package cache
- `ds-jupyter-config`: Jupyter configuration

These volumes are shared across all containers, reducing download time and disk usage.

To manage volumes:

```bash
# List volumes
docker volume ls | grep ds-

# Inspect a volume
docker volume inspect ds-conda-cache

# Clean up volumes (WARNING: removes all cached packages)
docker volume rm ds-conda-cache ds-pip-cache ds-uv-cache ds-jupyter-config
```

## Package Management

When you need more management than default image instalation, you can enter on the container to execute the commands (or just execute directly via 'docker exec' guidelines). I will assume to enter, so you repeat yourself less:
```bash
sudo docker exec -it -u root <container_name_or_id> bash
```
We use two package managers for different purposes:

### Conda (Primary for Scientific Packages)

Conda excels at managing complex scientific packages with compiled dependencies. Use it for:
- Core scientific libraries (numpy, scipy, pandas)
- Packages with C/C++ extensions
- GPU-accelerated libraries (CUDA dependencies)
- Packages requiring specific system libraries

**Inside Container Usage:**
```bash
# Install a package
conda install numpy scipy

# Install from conda-forge channel
conda install -c conda-forge prophet

# Search for packages
conda search matplotlib

# List installed packages
conda list

# Export environment
conda env export > environment.yml

# Create new environment (for testing)
conda create -n test-env python=3.11 pandas
conda activate test-env
```

### UV (Fast pip replacement)

UV is a blazing-fast Python package installer. Use it for:
- Pure Python packages
- Quick installations
- Development tools
- Packages not available in conda

**Inside Container Usage:**
```bash
# Install packages (much faster than pip)
uv pip install requests flask

# Install from requirements file
uv pip install -r requirements.txt

# Install with extras
uv pip install "pandas[excel,parquet]"

# Install development dependencies
uv pip install pytest black flake8

# Show installed packages
uv pip list

# Generate requirements file
uv pip freeze > requirements.txt
```

### Package Management Best Practices

#### 1. Choosing the Right Manager

```bash
# Use Conda for these types of packages:
conda install numpy pandas scikit-learn tensorflow pytorch

# Use UV for these types of packages:
uv pip install requests click flask streamlit plotly
```

#### 2. Handling Conflicts

If you encounter dependency conflicts:

```bash
# Option 1: Let conda solve complex dependencies
conda install package1 package2 package3

# Option 2: Create isolated environment
conda create -n project-env python=3.11
conda activate project-env

# Option 3: Use UV for pip-only packages
uv pip install conflicting-package --force-reinstall
```

#### 3. Saving Dependencies

**For Base Images (Permanent):**
```bash
# Add to environment.yml files in base/minimal or base/extended
# Then rebuild: ./scripts/build-base.sh all
```

**For Projects (Temporary):**
```bash
# Method 1: Export current environment
conda env export --from-history > environment-project.yml
uv pip freeze > requirements.txt

# Method 2: Manual tracking
echo "pandas==2.2.0" >> requirements.txt
echo "  - pandas=2.2.*" >> environment.yml
```

#### 4. Performance Tips

```bash
# UV is much faster for pip packages
time pip install pandas  # ~30 seconds
time uv pip install pandas  # ~2 seconds

# Conda channel priority (faster resolution)
conda config --add channels conda-forge
conda config --set channel_priority strict

# Use mamba for faster conda installs (if needed)
conda install mamba -n base -c conda-forge
mamba install large-package
```

#### 5. Package Persistence

**Important:** Packages installed inside a container are temporary unless:
1. They're added to the base image (rebuild required)
2. They're installed in a mounted volume
3. You commit the container (not recommended)

**Temporary Installation (lost on container restart):**
```bash
# These installations exist only during container session
uv pip install requests
conda install matplotlib
```

**Persistent Installation Options:**

Option 1 - Add to base image (for commonly used packages):
```bash
# Edit base/extended/environment.yml
# Add: - requests
# Then rebuild: ./scripts/build-base.sh extended
```

Option 2 - Use requirements.txt workflow:
```bash
# Inside container
uv pip install requests pandas
uv pip freeze > requirements.txt  # Save in project directory

# Next time you start container
uv pip install -r requirements.txt  # Reinstall from saved list
```

Option 3 - Create project-specific Dockerfile:
```bash
# Copy templates/Dockerfile.project to your project
# Add your dependencies
# Build: docker build -t my-project:latest .
```

#### 6. Common Workflows

**Starting a New Project:**
```bash
# 1. Run project with base image
./run-project.sh my-project

# 2. Inside container, install what you need
uv pip install flask pymongo redisdb

# 3. Develop and test

# 4. Export dependencies before exiting
uv pip freeze > requirements.txt
```

**Updating Project Dependencies:**
```bash
# Inside container
uv pip install -r requirements.txt  # Install existing
uv pip install new-package          # Add new
uv pip freeze > requirements.txt    # Save updated list
```

**Complex Scientific Stack:**
```bash
# Use conda for the heavy lifting
conda install pytorch torchvision torchaudio cudatoolkit=11.8 -c pytorch
conda install -c conda-forge transformers datasets

# Use UV for additional tools
uv pip install wandb tensorboard
```

### Adding Dependencies

## Troubleshooting

### Container Won't Start

Check if ports are already in use:
```bash
# Check port 8888
lsof -i :8888

# Use different port
./run-project.sh my-project --port 8889:8888
```

### Permission Issues

The containers run as non-root user `developer`. If you encounter permission issues:

1. Check file ownership on host
2. Ensure directories are writable
3. Use `docker exec -u root` for admin tasks

### Package Installation Fails

1. Check internet connection
2. Clear package caches:
```bash
docker volume rm ds-conda-cache ds-pip-cache
```
3. Try using different package manager (conda vs pip vs uv)

### Out of Disk Space

Clean up Docker resources:
```bash
# Remove unused containers
docker container prune

# Remove unused images
docker image prune

# Remove unused volumes (careful!)
docker volume prune
```

## Advanced Usage

### Custom Base Images

Create specialized base images for specific domains:

```dockerfile
# bioinformatics-base
FROM ds-extended:latest
RUN conda install -c bioconda biopython samtools
```

### Multi-Project Development

Run multiple projects simultaneously:
```bash
# Terminal 1
./run-project.sh project1 --name project1-dev

# Terminal 2  
./run-project.sh project2 --name project2-dev --port 8889:8888
```

## Contributing

To improve this Docker setup:

1. Create new tiers, for specific workflows in data science
2. Test thoroughly with multiple projects
3. Update documentation if you find errors or something cool to add
4. Consider backward compatibility

## Support

For issues or questions:
1. Check troubleshooting section
2. Review Docker logs: `docker logs <container-name>`
3. Verify base images are built: `docker images | grep ds-`
4. Ensure scripts are executable: `chmod +x scripts/*.sh`