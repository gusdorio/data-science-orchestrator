# Minimal Data Science Base Image
FROM continuumio/miniconda3:latest

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    vim \
    curl \
    build-essential \
    # Node.js and npm for Claude Code
    nodejs \
    npm \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install UV for fast Python package management
RUN curl -LsSf https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.cargo/bin:${PATH}"

# Install Claude Code CLI
RUN npm install -g @anthropic-ai/claude-code

# Set working directory
WORKDIR /workspace

# Copy environment file
COPY environment.yml ./environment.yml

# Create conda environment with core packages
RUN conda env create -f environment.yml && \
    conda clean -afy

# Initialize conda for bash (system-wide)
RUN conda init bash

# Set the default environment
ENV PATH=/opt/conda/envs/ds-minimal/bin:$PATH

# Create a non-root user for development
RUN useradd -ms /bin/bash developer && \
    chown -R developer:developer /workspace

# Create directory for shared libraries cache
RUN mkdir -p /opt/shared-libs && \
    chown -R developer:developer /opt/shared-libs

# Set up conda for developer user
RUN mkdir -p /home/developer && \
    chown -R developer:developer /home/developer

USER developer

# Copy conda initialization to developer user and set up environment activation
RUN conda init bash && \
    echo "conda activate ds-minimal" >> ~/.bashrc

# Create Jupyter configuration for no authentication
RUN mkdir -p /home/developer/.jupyter && \
    echo "# Jupyter Server 2.x authentication settings" > /home/developer/.jupyter/jupyter_server_config.py && \
    echo "c.IdentityProvider.token = ''" >> /home/developer/.jupyter/jupyter_server_config.py && \
    echo "c.IdentityProvider.password = ''" >> /home/developer/.jupyter/jupyter_server_config.py && \
    echo "" >> /home/developer/.jupyter/jupyter_server_config.py && \
    echo "# Server configuration" >> /home/developer/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.open_browser = False" >> /home/developer/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.ip = '0.0.0.0'" >> /home/developer/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.allow_origin = '*'" >> /home/developer/.jupyter/jupyter_server_config.py && \
    echo "c.ServerApp.disable_check_xsrf = True" >> /home/developer/.jupyter/jupyter_server_config.py && \
    echo "" >> /home/developer/.jupyter/jupyter_server_config.py && \
    echo "# Kernel management" >> /home/developer/.jupyter/jupyter_server_config.py && \
    echo "c.MappingKernelManager.cull_idle_timeout = 3600" >> /home/developer/.jupyter/jupyter_server_config.py && \
    echo "c.MappingKernelManager.cull_interval = 300" >> /home/developer/.jupyter/jupyter_server_config.py

# Ensure conda environment is available
ENV CONDA_DEFAULT_ENV=ds-minimal

# Ensure Claude Code is accessible to developer user
ENV PATH="/usr/local/bin:${PATH}"

# Set UV cache directory for faster package installs
ENV UV_CACHE_DIR=/opt/shared-libs/uv-cache

# Expose Jupyter port
EXPOSE 8888

# Default command
CMD ["bash"]