# Unified Data Science Base Image
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
    # PDF export support for Jupyter
    pandoc \
    texlive-xetex \
    texlive-fonts-recommended \
    texlive-plain-generic \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Install UV for fast Python package management (to /usr/local/bin for system-wide access)
RUN curl -LsSf https://astral.sh/uv/install.sh | env INSTALLER_NO_MODIFY_PATH=1 sh && \
    mv /root/.cargo/bin/uv /usr/local/bin/uv && \
    mv /root/.cargo/bin/uvx /usr/local/bin/uvx || true

# Set working directory
WORKDIR /workspace

# Copy environment file
COPY environment.yml ./environment.yml

# Create conda environment with packages
RUN conda env create -f environment.yml && \
    conda clean -afy

# Initialize conda for bash (system-wide)
RUN conda init bash

# Set the default environment
ENV PATH=/opt/conda/envs/ds-env/bin:$PATH

# Install pip-only packages with UV (using the conda environment's Python)
RUN uv pip install --python /opt/conda/envs/ds-env/bin/python ucimlrepo

# Create a non-root user for development with matching host UID/GID
# You MUST pass USER_ID and GROUP_ID as build arguments if those do not match 1000
ARG USER_ID=1000
ARG GROUP_ID=1000
RUN groupadd -g ${GROUP_ID} developer && \
    useradd -u ${USER_ID} -g ${GROUP_ID} -ms /bin/bash developer && \
    chown -R developer:developer /workspace

# Create directory for shared libraries cache
RUN mkdir -p /opt/shared-libs && \
    mkdir -p /opt/shared-libs/streamlit-cache && \
    mkdir -p /opt/shared-libs/plotly-cache && \
    chown -R developer:developer /opt/shared-libs

# Set up conda for developer user
RUN mkdir -p /home/developer && \
    chown -R developer:developer /home/developer

USER developer

# Copy conda initialization to developer user and set up environment activation
RUN conda init bash && \
    echo "conda activate ds-env" >> ~/.bashrc

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
ENV CONDA_DEFAULT_ENV=ds-env

# Set UV cache directory for faster package installs
ENV UV_CACHE_DIR=/opt/shared-libs/uv-cache

# Set cache directories for web frameworks
ENV STREAMLIT_CACHE_DIR=/opt/shared-libs/streamlit-cache
ENV PLOTLY_CACHE_DIR=/opt/shared-libs/plotly-cache

# Pre-compile Python files for faster startup
RUN python -m compileall /opt/conda/envs/ds-env/lib/python3.11/site-packages/ 2>/dev/null || true

# Expose ports
EXPOSE 8888
EXPOSE 8501

# Default command
CMD ["bash"]
