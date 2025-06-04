# MLC-LLM Pipeline Setup Guide

This guide provides comprehensive instructions for setting up the MLC-LLM CI/CD pipeline in your environment.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Quick Setup](#quick-setup)
- [Detailed Setup](#detailed-setup)
- [Docker Setup](#docker-setup)
- [CI/CD Configuration](#cicd-configuration)
- [Verification](#verification)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### System Requirements

#### Hardware Requirements

| Component | Minimum | Recommended | Notes |
|-----------|---------|-------------|-------|
| CPU | 4 cores | 8+ cores | More cores = faster builds |
| RAM | 8 GB | 16+ GB | CMake builds are memory-intensive |
| Storage | 50 GB | 100+ GB | Includes Docker images and build cache |
| GPU | Optional | NVIDIA GPU | For GPU-accelerated builds |

#### Software Requirements

| Software | Version | Installation |
|----------|---------|-------------|
| **Git** | 2.0+ | [Download](https://git-scm.com/downloads) |
| **Python** | 3.8+ | [Download](https://python.org/downloads) |
| **CMake** | 3.24+ | [Download](https://cmake.org/download) |
| **Rust** | 1.65+ | [Install](https://rustup.rs/) |
| **Docker** | 20.0+ | [Install](https://docs.docker.com/get-docker/) |

### Platform-Specific Setup

#### Ubuntu/Debian

```bash
# Update package list
sudo apt-get update

# Install build essentials
sudo apt-get install -y \
    build-essential \
    cmake \
    git \
    git-lfs \
    curl \
    wget \
    python3 \
    python3-pip \
    python3-venv

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER
```

#### CentOS/RHEL

```bash
# Install EPEL repository
sudo yum install -y epel-release

# Install build tools
sudo yum groupinstall -y "Development Tools"
sudo yum install -y \
    cmake3 \
    git \
    git-lfs \
    curl \
    wget \
    python3 \
    python3-pip

# Create cmake symlink
sudo ln -s /usr/bin/cmake3 /usr/bin/cmake

# Install Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env
```

#### Windows

```powershell
# Using Chocolatey (install chocolatey first)
choco install -y git cmake python rust docker-desktop

# Or using winget
winget install Git.Git
winget install Kitware.CMake
winget install Python.Python.3.11
winget install Rustlang.Rust.MSVC
winget install Docker.DockerDesktop
```

#### macOS

```bash
# Using Homebrew
brew install git cmake python rust docker

# Or using MacPorts
sudo port install git cmake python311 rust docker
```

## Quick Setup

For experienced users who want to get started quickly:

```bash
# 1. Clone the repository
git clone https://github.com/afzaal0007/mlc-llm-pipeline.git
cd mlc-llm-pipeline

# 2. Set up environment
./scripts/setup.sh  # Creates conda environment and installs dependencies

# 3. Build Docker image
docker build -t mlc-llm:dev --target development .

# 4. Run tests
./scripts/test.sh

# 5. Start development environment
docker run -it --gpus all -v $(pwd):/workspace mlc-llm:dev
```

## Detailed Setup

### Step 1: Repository Setup

```bash
# Clone the repository
git clone https://github.com/your-username/mlc-llm-pipeline.git
cd mlc-llm-pipeline

# Initialize git hooks (optional)
git config core.hooksPath .githooks
chmod +x .githooks/*
```

### Step 2: Python Environment Setup

#### Option A: Using Conda (Recommended)

```bash
# Install Miniconda if not already installed
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh

# Create and activate environment
conda create -n mlc-llm python=3.11
conda activate mlc-llm

# Install dependencies
conda install -c conda-forge cmake rust git pip
pip install -r requirements-dev.txt
```

#### Option B: Using venv

```bash
# Create virtual environment
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Upgrade pip and install dependencies
pip install --upgrade pip
pip install -r requirements-dev.txt
```

### Step 3: Build Dependencies

#### Install CMake (if not available)

```bash
# Ubuntu/Debian
wget https://github.com/Kitware/CMake/releases/download/v3.28.0/cmake-3.28.0-linux-x86_64.sh
sudo sh cmake-3.28.0-linux-x86_64.sh --prefix=/usr/local --skip-license

# Or compile from source
wget https://github.com/Kitware/CMake/releases/download/v3.28.0/cmake-3.28.0.tar.gz
tar -xzf cmake-3.28.0.tar.gz
cd cmake-3.28.0
./bootstrap && make && sudo make install
```

#### Install Rust (if not available)

```bash
# Install Rust toolchain
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
source ~/.cargo/env

# Verify installation
rustc --version
cargo --version
```

#### Setup Git LFS

```bash
# Install git-lfs
git lfs install

# Verify installation
git lfs version
```

### Step 4: GPU Support (Optional)

#### NVIDIA CUDA Setup

```bash
# Ubuntu - Install CUDA Toolkit
wget https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2204/x86_64/cuda-ubuntu2204.pin
sudo mv cuda-ubuntu2204.pin /etc/apt/preferences.d/cuda-repository-pin-600
wget https://developer.download.nvidia.com/compute/cuda/12.2.0/local_installers/cuda-repo-ubuntu2204-12-2-local_12.2.0-535.54.03-1_amd64.deb
sudo dpkg -i cuda-repo-ubuntu2204-12-2-local_12.2.0-535.54.03-1_amd64.deb
sudo cp /var/cuda-repo-ubuntu2204-12-2-local/cuda-*-keyring.gpg /usr/share/keyrings/
sudo apt-get update
sudo apt-get -y install cuda

# Set environment variables
echo 'export CUDA_HOME=/usr/local/cuda' >> ~/.bashrc
echo 'export PATH=$CUDA_HOME/bin:$PATH' >> ~/.bashrc
echo 'export LD_LIBRARY_PATH=$CUDA_HOME/lib64:$LD_LIBRARY_PATH' >> ~/.bashrc
source ~/.bashrc
```

#### AMD ROCm Setup (Linux)

```bash
# Ubuntu - Install ROCm
wget https://repo.radeon.com/amdgpu-install/22.40.5/ubuntu/jammy/amdgpu-install_5.4.50405-1_all.deb
sudo dpkg -i amdgpu-install_5.4.50405-1_all.deb
sudo apt update
sudo apt install amdgpu-dkms rocm-dev

# Add user to render group
sudo usermod -a -G render $USER
```

## Docker Setup

### Basic Docker Configuration

```bash
# Install Docker (if not already installed)
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Log out and back in, then test
docker run hello-world
```

### GPU Support in Docker

#### NVIDIA Container Toolkit

```bash
# Install NVIDIA Container Toolkit
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit

# Configure Docker
sudo nvidia-ctk runtime configure --runtime=docker
sudo systemctl restart docker

# Test GPU access
docker run --rm --gpus all nvidia/cuda:12.2-base-ubuntu22.04 nvidia-smi
```

### Build Docker Images

```bash
# Build development image
docker build -t mlc-llm:dev --target development .

# Build production image
docker build -t mlc-llm:prod --target production .

# Build with build args
docker build \
    --build-arg CUDA_VERSION=12.2 \
    --build-arg PYTHON_VERSION=3.11 \
    -t mlc-llm:custom .
```

## CI/CD Configuration

### GitHub Actions Setup

1. **Fork the repository** to your GitHub account

2. **Enable GitHub Actions** in your repository settings

3. **Configure secrets** (if needed):
   ```bash
   # Go to Settings > Secrets and variables > Actions
   # Add the following secrets if needed:
   CODECOV_TOKEN          # For code coverage reporting
   SLACK_WEBHOOK_URL      # For Slack notifications
   DOCKER_HUB_USERNAME    # For Docker Hub publishing
   DOCKER_HUB_TOKEN       # For Docker Hub publishing
   ```

4. **Enable GitHub Container Registry**:
   - Go to Settings > Packages
   - Ensure Container registry is enabled
   - Configure package visibility as needed

### Local CI Testing

Test the CI pipeline locally using act:

```bash
# Install act
curl https://raw.githubusercontent.com/nektos/act/master/install.sh | sudo bash

# Run specific jobs
act -j lint-and-format
act -j build-docker-image
act -j test-docker-image

# Run entire workflow
act push
```

## Verification

### Verify Build Environment

```bash
# Check all dependencies
./scripts/check-deps.sh

# Expected output:
# ✓ Python 3.11.0 found
# ✓ CMake 3.28.0 found
# ✓ Git 2.40.0 found
# ✓ Rust 1.70.0 found
# ✓ Docker 24.0.0 found
# ✓ CUDA 12.2 found (optional)
```

### Test Build Process

```bash
# Test local build
./scripts/build.sh --skip-tests

# Test Docker build
docker build --target build .

# Test full pipeline
./scripts/test.sh all
```

### Verify Docker Images

```bash
# Test development image
docker run --rm mlc-llm:dev help

# Test production image
docker run --rm mlc-llm:prod

# Test GPU access (if available)
docker run --rm --gpus all mlc-llm:dev bash -c "nvidia-smi || echo 'No GPU'"
```

### Verify CI/CD Pipeline

```bash
# Create a test commit
echo "# Test" > test.md
git add test.md
git commit -m "Test CI/CD pipeline"
git push origin main

# Check GitHub Actions tab for pipeline execution
# Expected: All jobs should pass
```

## Troubleshooting

### Common Issues

#### CMake Version Issues

```bash
# Error: CMake 3.24 or higher is required
# Solution: Install newer CMake
wget -O - https://apt.kitware.com/keys/kitware-archive-latest.asc 2>/dev/null | gpg --dearmor - | sudo tee /etc/apt/trusted.gpg.d/kitware.gpg >/dev/null
echo 'deb https://apt.kitware.com/ubuntu/ focal main' | sudo tee /etc/apt/sources.list.d/kitware.list >/dev/null
sudo apt update
sudo apt install cmake
```

#### Docker Permission Issues

```bash
# Error: permission denied while trying to connect to Docker daemon
# Solution: Add user to docker group
sudo usermod -aG docker $USER
# Log out and back in
```

#### GPU Access Issues

```bash
# Error: NVIDIA-SMI has failed
# Check driver installation
nvidia-smi

# Check Docker GPU support
docker run --rm --gpus all nvidia/cuda:12.2-base nvidia-smi

# Install NVIDIA Container Toolkit if needed
# (see GPU setup section above)
```

#### Memory Issues

```bash
# Error: virtual memory exhausted
# Solution: Reduce parallel jobs
./scripts/build.sh --jobs 2

# Or increase swap space
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

#### Dependency Conflicts

```bash
# Error: conflicting dependencies
# Solution: Use fresh environment
conda deactivate
conda env remove -n mlc-llm
conda create -n mlc-llm python=3.11
conda activate mlc-llm
# Reinstall dependencies
```

### Debug Mode

```bash
# Enable verbose output
export VERBOSE=1
./scripts/build.sh

# Enable debug builds
./scripts/build.sh --build-type Debug

# Enable Docker debug
export DOCKER_BUILDKIT=0
docker build --progress=plain .
```

### Getting Help

1. **Check logs**: Build logs contain detailed error information
2. **Search issues**: Check GitHub issues for similar problems
3. **Create issue**: Report bugs with:
   - System information (`uname -a`)
   - Python version (`python --version`)
   - CMake version (`cmake --version`)
   - Docker version (`docker --version`)
   - Complete error logs

## Next Steps

After successful setup:

1. **Read the [Usage Guide](usage.md)** for detailed usage instructions
2. **Check the [API Documentation](api.md)** for development reference
3. **Review [Troubleshooting Guide](troubleshooting.md)** for common issues
4. **Explore examples** in the `examples/` directory

---

**Need help?** [Open an issue](https://github.com/afzaal0007/mlc-llm-pipeline/issues) or check our [discussions](https://github.com/afzaal0007/mlc-llm-pipeline/discussions).

