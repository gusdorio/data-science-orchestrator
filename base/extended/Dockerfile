# Extended Data Science Base Image
# Builds on top of the minimal base image
FROM ds-minimal:latest

# Switch to root to install additional packages
USER root

# Copy extended environment file
COPY environment.yml /tmp/environment-extended.yml

# Update the existing conda environment with additional packages
RUN conda env update -n ds-minimal -f /tmp/environment-extended.yml && \
    conda clean -afy && \
    rm /tmp/environment-extended.yml

# Create additional directories for caching
RUN mkdir -p /opt/shared-libs/streamlit-cache && \
    mkdir -p /opt/shared-libs/plotly-cache && \
    chown -R developer:developer /opt/shared-libs

# Switch back to developer user
USER developer

# Set environment variables for caching
ENV STREAMLIT_CACHE_DIR=/opt/shared-libs/streamlit-cache
ENV PLOTLY_CACHE_DIR=/opt/shared-libs/plotly-cache

# Verify Claude Code is still accessible
RUN claude --version

# Pre-compile Python files for faster startup
RUN python -m compileall /opt/conda/envs/ds-minimal/lib/python3.11/site-packages/

# Expose additional ports for web apps

# Streamlit
EXPOSE 8501  
# Dash/Plotly
EXPOSE 8050  

# Default command
CMD ["bash"]