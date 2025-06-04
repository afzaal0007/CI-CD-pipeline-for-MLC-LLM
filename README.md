# MLC-LLM CI/CD Pipeline

[![CI/CD Pipeline](https://github.com/afzaal0007/mlc-llm-pipeline/actions/workflows/ci-cd.yml/badge.svg)](https://github.com/afzaal0007/mlc-llm-pipeline/actions/workflows/ci-cd.yml)
[![Docker Image](https://ghcr.io/afzaal0007/mlc-llm-pipeline:latest)](https://github.com/afzaal0007/mlc-llm-pipeline/pkgs/container/mlc-llm-pipeline)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

A production-quality CI/CD pipeline for [MLC-LLM](https://github.com/mlc-ai/mlc-llm), featuring automated testing, cross-platform builds, and containerized deployment. This pipeline provides comprehensive automation for building, testing, and distributing MLC-LLM across multiple platforms.

## 🚀 Features

### 🐳 **Multipurpose Docker Environment**
- **Development Mode**: Interactive shell with full development tools
- **Build Mode**: Automated compilation and packaging
- **Production Mode**: Minimal runtime image for deployment
- **GPU Support**: CUDA, ROCm, Metal, Vulkan, and OpenCL

### 🔄 **Automated CI/CD Pipeline**
- **Code Quality**: Automated linting with Black, Flake8, and isort
- **Multi-Platform Builds**: Linux x64, Windows x64 Python wheels
- **Container Registry**: Automatic publishing to GitHub Container Registry
- **GitHub Releases**: Automated release creation with artifacts
- **Test-Driven Deployment**: Tests gate all deployment stages

### 🧪 **Comprehensive Testing**
- **Import Tests**: Verify package installation and imports
- **Dependency Tests**: Validate build dependencies
- **Library Tests**: Check compiled artifacts
- **Performance Tests**: Basic performance benchmarks
- **Coverage Reports**: Code coverage analysis with pytest

### 📚 **Production-Ready Documentation**
- **Setup Guides**: Detailed installation and configuration
- **Usage Examples**: Practical examples for all use cases
- **API Documentation**: Comprehensive API reference
- **Troubleshooting**: Common issues and solutions

## 📋 Prerequisites

### System Requirements

| Component | Minimum Version | Recommended |
|-----------|----------------|-------------|
| Python | 3.8+ | 3.11+ |
| CMake | 3.24+ | Latest |
| Git | 2.0+ | Latest |
| Rust | 1.65+ | Latest |
| Docker | 20.0+ | Latest |

### Platform Support

| Platform | Development | Build | Runtime |
|----------|-------------|-------|----------|
| Linux x64 | ✅ | ✅ | ✅ |
| Windows x64 | ✅ | ✅ | ✅ |
| macOS x64 | ✅ | ⚠️ | ✅ |
| macOS ARM64 | ✅ | ⚠️ | ✅ |

*⚠️ = Supported but not in CI pipeline*

### GPU Support

| GPU Type | Linux | Windows | macOS |
|----------|-------|---------|-------|
| NVIDIA (CUDA) | ✅ | ✅ | ❌ |
| AMD (ROCm) | ✅ | ⚠️ | ❌ |
| Intel (Vulkan) | ✅ | ✅ | ❌ |
| Apple (Metal) | ❌ | ❌ | ✅ |

## ⚠️ **Current Status: Test Mode**

**Note**: The pipeline is currently using a simplified test Dockerfile (`Dockerfile.test`) to validate the CI/CD setup. Once the pipeline is working correctly, we'll switch back to the full MLC-LLM build.

**Test Status**: 
- ✅ Basic CI/CD pipeline functionality
- ✅ Docker image building and publishing
- ✅ Python wheel building
- ✅ GitHub releases
- ⏳ Full MLC-LLM compilation (coming after validation)

## 🚀 Quick Start

### Option 1: Using Pre-built Docker Images

```bash
# Development environment
docker run -it --gpus all \
  -v $(pwd):/workspace \
  -p 8888:8888 \
  ghcr.io/afzaal0007/mlc-llm-pipeline:latest bash

# Production environment
docker run --gpus all \
  ghcr.io/afzaal0007/mlc-llm-pipeline:prod
```

### Option 2: Building from Source

```bash
# Clone the repository
git clone https://github.com/afzaal0007/mlc-llm-pipeline.git
cd mlc-llm-pipeline

# Build using the provided script
./scripts/build.sh

# Run tests
./scripts/test.sh
```

### Option 3: Installing Python Wheels

```bash
# Download from GitHub Releases
wget https://github.com/afzaal0007/mlc-llm-pipeline/releases/latest/download/mlc_llm-*.whl
pip install mlc_llm-*.whl

# Verify installation
python -c "import mlc_llm; print(mlc_llm.__version__)"
```

## 🐳 Docker Usage

### Development Mode

```bash
# Start development container
docker run -it --gpus all \
  -v $(pwd):/workspace \
  -p 8888:8888 -p 8000:8000 \
  ghcr.io/afzaal0007/mlc-llm-pipeline:latest

# Inside container - available commands:
# build    - Build MLC-LLM from source
# test     - Run test suite
# lint     - Run linting checks
# format   - Format code
# package  - Build Python wheels
```

### Build Mode

```bash
# Build MLC-LLM in container
docker run --rm \
  -v $(pwd):/workspace \
  ghcr.io/afzaal0007/mlc-llm-pipeline:latest build

# Extract build artifacts
docker cp container_id:/workspace/build ./build
docker cp container_id:/workspace/dist ./dist
```

### Custom Build Options

```bash
# Build with specific GPU backend
docker run --rm \
  -e CMAKE_ARGS="-DUSE_CUDA=ON -DUSE_VULKAN=OFF" \
  ghcr.io/afzaal0007/mlc-llm-pipeline:latest build

# Build with custom configuration
docker run --rm \
  -v $(pwd)/custom_config.py:/workspace/cmake/gen_cmake_config.py \
  ghcr.io/afzaal0007/mlc-llm-pipeline:latest build
```

## 🛠️ Local Development

### Setting Up Development Environment

```bash
# 1. Install system dependencies
sudo apt-get update && sudo apt-get install -y \
    build-essential cmake git git-lfs curl

# 2. Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# 3. Create conda environment
conda create -n mlc-llm python=3.11
conda activate mlc-llm
conda install -c conda-forge cmake rust git

# 4. Clone and build
git clone --recursive https://github.com/mlc-ai/mlc-llm.git
cd mlc-llm
./scripts/build.sh
```

### Build Script Options

```bash
# Full build with all options
./scripts/build.sh --build-type Release --jobs 8 --clean

# Development build
./scripts/build.sh --build-type Debug --skip-tests

# Build with custom source directory
./scripts/build.sh --source-dir /path/to/mlc-llm --build-dir /tmp/build

# Skip dependency checks (if dependencies already verified)
./scripts/build.sh --skip-deps --skip-submodules
```

### Testing Options

```bash
# Run all tests
./scripts/test.sh

# Run specific test types
./scripts/test.sh import     # Import tests only
./scripts/test.sh deps       # Dependency tests only
./scripts/test.sh pytest     # Python unit tests only
./scripts/test.sh performance # Performance tests only

# Advanced testing options
./scripts/test.sh --coverage --verbose --fail-fast
```

## 🔧 Configuration

### Environment Variables

```bash
# MLC-LLM specific
export MLC_LLM_SOURCE_DIR="/path/to/mlc-llm"
export PYTHONPATH="${MLC_LLM_SOURCE_DIR}/python:${PYTHONPATH}"

# Build configuration
export CMAKE_BUILD_TYPE="Release"
export CMAKE_INSTALL_PREFIX="/usr/local"
export CMAKE_ARGS="-DUSE_CUDA=ON -DUSE_VULKAN=ON"

# GPU configuration
export CUDA_HOME="/usr/local/cuda"
export PATH="${CUDA_HOME}/bin:${PATH}"
export LD_LIBRARY_PATH="${CUDA_HOME}/lib64:${LD_LIBRARY_PATH}"
```

### CMake Configuration

The build system automatically detects available GPU backends:

```cmake
# Automatically enabled based on system capabilities
-DUSE_CUDA=ON        # NVIDIA GPUs
-DUSE_VULKAN=ON      # Cross-platform GPU support
-DUSE_METAL=ON       # Apple GPUs
-DUSE_OPENCL=ON      # OpenCL-compatible GPUs
-DUSE_ROCM=ON        # AMD GPUs
```

## 🚀 CI/CD Pipeline

### Pipeline Overview

```mermaid
graph LR
    A[Code Push] --> B[Lint & Format]
    B --> C[Build Docker]
    C --> D[Test Docker]
    D --> E[Build Wheels]
    E --> F[Create Release]
    F --> G[Deploy Production]
```

### Workflow Triggers

| Trigger | Description | Actions |
|---------|-------------|----------|
| `push: main` | Main branch updates | Full pipeline |
| `push: develop` | Development updates | Build + test only |
| `pull_request` | PR validation | Lint + build + test |
| `tag: v*` | Release creation | Full pipeline + release |
| `workflow_dispatch` | Manual trigger | Configurable |

### Pipeline Jobs

1. **Code Quality (`lint-and-format`)**
   - Black code formatting check
   - Flake8 linting
   - Import sorting validation
   - Type checking with mypy

2. **Docker Build (`build-docker-image`)**
   - Multi-stage Docker build
   - Cache optimization
   - GHCR publishing
   - Vulnerability scanning

3. **Docker Testing (`test-docker-image`)**
   - Container functionality tests
   - Environment validation
   - GPU support verification

4. **Wheel Building (`build-wheels`)**
   - Linux x64 wheels
   - Windows x64 wheels
   - Installation testing
   - Artifact storage

5. **Release Creation (`create-release`)**
   - GitHub release creation
   - Wheel attachment
   - Release notes generation

6. **Production Deployment (`build-production-image`)**
   - Minimal production image
   - Security scanning
   - Registry publishing

### GitHub Secrets Configuration

Required secrets for the pipeline:

```bash
# Automatically provided by GitHub
GITHUB_TOKEN          # For GHCR and releases

# Optional for enhanced features
CODECOV_TOKEN         # Code coverage reporting
SLACK_WEBHOOK_URL     # Notification integration
DOCKER_HUB_USERNAME   # Additional registry
DOCKER_HUB_TOKEN      # Additional registry
```

## 📊 Monitoring and Observability

### Build Metrics

- **Build Success Rate**: Track pipeline success/failure rates
- **Build Duration**: Monitor build performance trends
- **Test Coverage**: Code coverage tracking with Codecov
- **Security Scanning**: Vulnerability detection in dependencies

### Container Metrics

```bash
# Check image size
docker images ghcr.io/afzaal0007/mlc-llm-pipeline

# Inspect image layers
docker history ghcr.io/afzaal0007/mlc-llm-pipeline:latest

# Security scan
docker scout cves ghcr.io/afzaal0007/mlc-llm-pipeline:latest
```

### Performance Benchmarks

```bash
# Run performance tests
./scripts/test.sh performance

# Benchmark import time
time python -c "import mlc_llm"

# Memory usage analysis
/usr/bin/time -v python -c "import mlc_llm"
```

## 🛡️ Security

### Container Security

- **Base Image**: Official NVIDIA CUDA images with security updates
- **Non-root User**: Containers run with restricted privileges
- **Minimal Attack Surface**: Production images contain only necessary components
- **Dependency Scanning**: Automated vulnerability detection

### Secret Management

```bash
# Using environment variables for sensitive data
export API_KEY=$(cat /run/secrets/api_key)

# Docker secrets (for Swarm/Kubernetes)
docker run --secret source=api_key,target=/run/secrets/api_key \
  ghcr.io/afzaal0007/mlc-llm-pipeline:latest
```

### Network Security

```bash
# Run with network isolation
docker run --network none \
  ghcr.io/afzaal0007/mlc-llm-pipeline:latest

# Custom network for multi-container setup
docker network create mlc-network
docker run --network mlc-network \
  ghcr.io/afzaal0007/mlc-llm-pipeline:latest
```

## 🔍 Troubleshooting

### Common Issues

#### Build Failures

```bash
# CMake version too old
sudo pip install cmake --upgrade

# CUDA not found
export CUDA_HOME=/usr/local/cuda
export PATH=$CUDA_HOME/bin:$PATH

# Insufficient memory
./scripts/build.sh --jobs 2  # Reduce parallel jobs
```

#### Docker Issues

```bash
# GPU access denied
docker run --gpus all ...  # Ensure GPU support enabled

# Permission denied
sudo usermod -aG docker $USER  # Add user to docker group
logout && login  # Restart session

# Out of disk space
docker system prune -a  # Clean up unused images
```

#### Import Errors

```bash
# Module not found
export PYTHONPATH="/path/to/mlc-llm/python:$PYTHONPATH"

# Library not found
export LD_LIBRARY_PATH="/path/to/mlc-llm/build:$LD_LIBRARY_PATH"

# Conda environment issues
conda activate mlc-llm
which python  # Verify correct Python interpreter
```

### Debug Mode

```bash
# Enable verbose build output
./scripts/build.sh --verbose

# Enable debug symbols
./scripts/build.sh --build-type Debug

# Container debugging
docker run -it --entrypoint bash \
  ghcr.io/afzaal0007/mlc-llm-pipeline:latest
```

### Getting Help

1. **Check the logs**: Build and test logs contain detailed error information
2. **Review documentation**: Comprehensive guides in the `docs/` directory
3. **Search issues**: Check existing GitHub issues for similar problems
4. **Create an issue**: Report bugs with detailed reproduction steps

## 📁 Project Structure

```
mlc-llm-pipeline/
├── .github/workflows/          # GitHub Actions workflows
│   └── ci-cd.yml              # Main CI/CD pipeline
├── docs/                      # Documentation
│   ├── setup.md              # Setup guide
│   ├── usage.md              # Usage examples
│   ├── api.md                # API reference
│   └── troubleshooting.md    # Troubleshooting guide
├── scripts/                   # Build and utility scripts
│   ├── build.sh              # Build script
│   ├── test.sh               # Test script
│   └── entrypoint.sh         # Docker entrypoint
├── tests/                     # Test files
│   ├── test_import.py        # Import tests
│   ├── test_docker.py        # Docker tests
│   └── conftest.py           # Pytest configuration
├── Dockerfile                 # Multi-stage Docker configuration
├── .dockerignore             # Docker ignore patterns
├── .gitignore                # Git ignore patterns
└── README.md                 # This file
```

## 🤝 Contributing

### Development Workflow

1. **Fork the repository**
2. **Create a feature branch**: `git checkout -b feature/amazing-feature`
3. **Make your changes**: Follow the coding standards
4. **Run tests**: `./scripts/test.sh`
5. **Commit your changes**: `git commit -m 'Add amazing feature'`
6. **Push to the branch**: `git push origin feature/amazing-feature`
7. **Open a Pull Request**

### Coding Standards

- **Python**: PEP 8 compliance, enforced by Black and Flake8
- **Shell**: ShellCheck compliance for bash scripts
- **Docker**: Multi-stage builds, minimal layers, security best practices
- **Documentation**: Clear, concise, with practical examples

### Testing Requirements

- All new features must include tests
- Maintain or improve code coverage
- Tests must pass on all supported platforms
- Docker images must pass security scans

## 📄 License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **MLC-LLM Team**: For the amazing MLC-LLM project
- **TVM Community**: For the underlying TVM framework
- **GitHub Actions**: For the CI/CD platform
- **Docker**: For containerization technology
- **NVIDIA**: For CUDA support and base images

## 🔗 Related Projects

- [MLC-LLM](https://github.com/mlc-ai/mlc-llm) - Main project
- [TVM](https://github.com/apache/tvm) - Tensor compiler stack
- [Apache TVM Unity](https://github.com/apache/tvm/tree/unity) - Next-generation TVM

---

**📞 Support**: For questions and support, please [open an issue](https://github.com/afzaal0007/mlc-llm-pipeline/issues) or join our [discussions](https://github.com/afzaal0007/mlc-llm-pipeline/discussions).

**⭐ Star this repository** if you find it helpful!

