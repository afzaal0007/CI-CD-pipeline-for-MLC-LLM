# Multi-stage Dockerfile for MLC-LLM development and build environment
# Supports both interactive development and automated builds

FROM ubuntu:22.04 as base

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install system dependencies
RUN apt-get update && apt-get install -y \
    build-essential \
    cmake \
    git \
    git-lfs \
    curl \
    wget \
    vim \
    nano \
    htop \
    tree \
    unzip \
    software-properties-common \
    pkg-config \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Rust and Cargo
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Install Miniconda
RUN wget -q https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -O /tmp/miniconda.sh && \
    bash /tmp/miniconda.sh -b -p /opt/conda && \
    rm /tmp/miniconda.sh
ENV PATH="/opt/conda/bin:${PATH}"

# Create conda environment for MLC-LLM
RUN conda create -n mlc-llm -c conda-forge \
    "cmake>=3.24" \
    rust \
    git \
    python=3.11 \
    pip \
    numpy \
    scipy \
    && conda clean -afy

# Activate conda environment by default
RUN echo "conda activate mlc-llm" >> ~/.bashrc
SHELL ["/bin/bash", "-c"]

# Install Python dependencies
RUN source activate mlc-llm && \
    pip install --no-cache-dir \
    wheel \
    setuptools \
    build \
    twine \
    pytest \
    pytest-cov \
    black \
    flake8 \
    mypy \
    pre-commit

# Install git-lfs
RUN conda install -c conda-forge git-lfs -y

# Set working directory
WORKDIR /workspace

# Copy entrypoint script
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Development stage - for interactive development
FROM base as development

# Install additional development tools
RUN source activate mlc-llm && \
    pip install --no-cache-dir \
    jupyter \
    ipython \
    matplotlib \
    seaborn \
    pandas

# Set up development environment
RUN echo 'alias ll="ls -la"' >> ~/.bashrc && \
    echo 'alias la="ls -la"' >> ~/.bashrc && \
    echo 'export PS1="\[\033[01;32m\]mlc-dev\[\033[00m\]:\[\033[01;34m\]\w\[\033[00m\]\$ "' >> ~/.bashrc

# Create a mock MLC-LLM structure for development testing
RUN mkdir -p /workspace/mlc-llm/python/mlc_llm && \
    echo '__version__ = "0.1.0-test"' > /workspace/mlc-llm/python/mlc_llm/__init__.py && \
    echo 'print("MLC-LLM test version loaded")' >> /workspace/mlc-llm/python/mlc_llm/__init__.py

# Set environment variables for development
ENV MLC_LLM_SOURCE_DIR=/workspace/mlc-llm
ENV PYTHONPATH=${MLC_LLM_SOURCE_DIR}/python:${PYTHONPATH}

# Expose common ports
EXPOSE 8888 8000 8080

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]

# Build stage - for automated builds and CI
FROM base as build

# Copy our build and test scripts
COPY ./scripts /workspace/scripts
COPY ./tests /workspace/tests

# Create a mock MLC-LLM structure for initial testing
RUN mkdir -p /workspace/mlc-llm/python/mlc_llm && \
    echo '__version__ = "0.1.0-test"' > /workspace/mlc-llm/python/mlc_llm/__init__.py && \
    echo 'print("MLC-LLM test version loaded")' >> /workspace/mlc-llm/python/mlc_llm/__init__.py

# Set the workspace to the MLC-LLM directory
WORKDIR /workspace/mlc-llm

# Set MLC_LLM_SOURCE_DIR environment variable
ENV MLC_LLM_SOURCE_DIR=/workspace/mlc-llm
ENV PYTHONPATH=${MLC_LLM_SOURCE_DIR}/python:${PYTHONPATH}

# Mock build process for testing
RUN source activate mlc-llm && \
    cd /workspace/mlc-llm && \
    mkdir -p build && \
    cd build && \
    echo "Mock build artifacts for testing" > libmlc_llm.so && \
    echo "Mock TVM runtime" > libtvm_runtime.so

# Mock install MLC-LLM as Python package
RUN source activate mlc-llm && \
    cd /workspace/mlc-llm && \
    echo 'import sys; sys.path.insert(0, "/workspace/mlc-llm/python")' > setup_path.py

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["build"]

# Production stage - minimal runtime image
FROM ubuntu:22.04 as production

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1

# Install minimal runtime dependencies
RUN apt-get update && apt-get install -y \
    python3 \
    python3-pip \
    git \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

# Copy built artifacts from build stage
COPY --from=build /opt/conda /opt/conda
COPY --from=build /workspace/mlc-llm/build /workspace/mlc-llm/build
COPY --from=build /workspace/mlc-llm/python /workspace/mlc-llm/python

ENV PATH="/opt/conda/bin:${PATH}"
ENV MLC_LLM_SOURCE_DIR=/workspace/mlc-llm
ENV PYTHONPATH=${MLC_LLM_SOURCE_DIR}/python:${PYTHONPATH}

WORKDIR /workspace/mlc-llm

RUN echo "conda activate mlc-llm" >> ~/.bashrc

ENTRYPOINT ["/bin/bash", "-c"]
CMD ["source activate mlc-llm && python -m mlc_llm.cli.serve --help"]

