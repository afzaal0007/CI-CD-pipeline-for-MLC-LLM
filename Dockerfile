# Optimized Multi-stage Dockerfile for MLC-LLM
# Focuses on smaller image sizes and faster build times

# Use smaller base image for the base stage
FROM python:3.11-slim-bullseye as base

# Set environment variables
ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# Install only essential system dependencies in a single layer
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    git \
    curl \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Install Rust in a more efficient way
RUN curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --default-toolchain stable --profile minimal \
    && . ~/.cargo/env \
    && rustup --version
ENV PATH="/root/.cargo/bin:${PATH}"

# Use Miniconda instead of full Anaconda for smaller size
RUN curl -sSL https://repo.anaconda.com/miniconda/Miniconda3-py311_24.9.2-0-Linux-x86_64.sh -o miniconda.sh \
    && bash miniconda.sh -b -p /opt/conda \
    && rm miniconda.sh \
    && /opt/conda/bin/conda clean -afy
ENV PATH="/opt/conda/bin:${PATH}"

# Create conda environment with minimal packages
RUN conda create -n mlc-llm python=3.11 pip -y \
    && conda clean -afy

# Initialize conda properly
RUN /opt/conda/bin/conda init bash \
    && echo "conda activate mlc-llm" >> ~/.bashrc

# Development stage - optimized for development
FROM base as development

# Install development dependencies in conda environment
RUN /opt/conda/envs/mlc-llm/bin/pip install --no-cache-dir \
    wheel setuptools build \
    pytest pytest-cov \
    black flake8 mypy isort \
    jupyter ipython

# Create mock MLC-LLM structure
RUN mkdir -p /workspace/mlc-llm/python/mlc_llm \
    && echo '__version__ = "0.1.0-test"' > /workspace/mlc-llm/python/mlc_llm/__init__.py \
    && echo 'print("MLC-LLM test version loaded")' >> /workspace/mlc-llm/python/mlc_llm/__init__.py

# Set environment variables
ENV MLC_LLM_SOURCE_DIR=/workspace/mlc-llm \
    PYTHONPATH=/workspace/mlc-llm/python

WORKDIR /workspace

# Copy entrypoint script
COPY scripts/entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 8888 8000 8080
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]

# Build stage - optimized for CI/CD builds
FROM base as build

# Install build dependencies
RUN /opt/conda/envs/mlc-llm/bin/pip install --no-cache-dir \
    wheel setuptools build cmake

# Copy scripts and create mock structure
COPY ./scripts /workspace/scripts
COPY ./tests /workspace/tests

RUN mkdir -p /workspace/mlc-llm/python/mlc_llm \
    && echo '__version__ = "0.1.0-test"' > /workspace/mlc-llm/python/mlc_llm/__init__.py \
    && echo 'print("MLC-LLM test version loaded")' >> /workspace/mlc-llm/python/mlc_llm/__init__.py

# Mock build artifacts
RUN mkdir -p /workspace/mlc-llm/build \
    && echo "Mock build artifacts" > /workspace/mlc-llm/build/libmlc_llm.so

ENV MLC_LLM_SOURCE_DIR=/workspace/mlc-llm \
    PYTHONPATH=/workspace/mlc-llm/python

WORKDIR /workspace/mlc-llm
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["build"]

# Production stage - minimal runtime image
FROM python:3.11-slim-bullseye as production

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1

# Install only runtime dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean

# Copy only necessary artifacts from build stage
COPY --from=build /opt/conda/envs/mlc-llm /opt/conda/envs/mlc-llm
COPY --from=build /workspace/mlc-llm/python /workspace/mlc-llm/python
COPY --from=build /workspace/mlc-llm/build /workspace/mlc-llm/build

ENV PATH="/opt/conda/envs/mlc-llm/bin:${PATH}" \
    MLC_LLM_SOURCE_DIR=/workspace/mlc-llm \
    PYTHONPATH=/workspace/mlc-llm/python

WORKDIR /workspace/mlc-llm

CMD ["python", "-c", "import mlc_llm; print(f'MLC-LLM {mlc_llm.__version__} ready')"]

