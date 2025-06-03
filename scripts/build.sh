#!/bin/bash
# Build script for MLC-LLM
# Supports both local development and CI/CD environments

set -e

# Configuration
BUILD_TYPE="Release"
NUM_CORES=$(nproc 2>/dev/null || echo 4)
SOURCE_DIR="${MLC_LLM_SOURCE_DIR:-$(pwd)}"
BUILD_DIR="${SOURCE_DIR}/build"
INSTALL_PREFIX="${INSTALL_PREFIX:-/usr/local}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check dependencies
check_dependencies() {
    log_info "Checking build dependencies..."
    
    local missing_deps=()
    
    # Check for required tools
    command -v cmake >/dev/null 2>&1 || missing_deps+=("cmake")
    command -v git >/dev/null 2>&1 || missing_deps+=("git")
    command -v python >/dev/null 2>&1 || missing_deps+=("python")
    command -v rustc >/dev/null 2>&1 || missing_deps+=("rust")
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "Missing dependencies: ${missing_deps[*]}"
        log_info "Please install the missing dependencies and try again."
        exit 1
    fi
    
    # Check CMake version
    local cmake_version=$(cmake --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
    local required_version="3.24.0"
    
    if [ "$(printf '%s\n' "$required_version" "$cmake_version" | sort -V | head -n1)" != "$required_version" ]; then
        log_error "CMake version $cmake_version is too old. Required: $required_version or higher."
        exit 1
    fi
    
    log_success "All dependencies satisfied"
}

# Function to initialize submodules
init_submodules() {
    log_info "Initializing git submodules..."
    cd "$SOURCE_DIR"
    
    if [ -f ".gitmodules" ]; then
        git submodule update --init --recursive
        log_success "Submodules initialized"
    else
        log_warning "No .gitmodules found, skipping submodule initialization"
    fi
}

# Function to configure build
configure_build() {
    log_info "Configuring build..."
    
    # Create build directory
    mkdir -p "$BUILD_DIR"
    cd "$BUILD_DIR"
    
    # Generate CMake configuration if available
    if [ -f "$SOURCE_DIR/cmake/gen_cmake_config.py" ]; then
        log_info "Generating CMake configuration..."
        python "$SOURCE_DIR/cmake/gen_cmake_config.py"
    fi
    
    # Configure with CMake
    cmake \
        -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
        -DCMAKE_INSTALL_PREFIX="$INSTALL_PREFIX" \
        -DUSE_CUDA=ON \
        -DUSE_VULKAN=ON \
        -DUSE_METAL=ON \
        -DUSE_OPENCL=ON \
        "$SOURCE_DIR"
    
    log_success "Build configured"
}

# Function to build project
build_project() {
    log_info "Building MLC-LLM with $NUM_CORES cores..."
    cd "$BUILD_DIR"
    
    cmake --build . --parallel "$NUM_CORES" --config "$BUILD_TYPE"
    
    log_success "Build completed"
}

# Function to install Python package
install_python_package() {
    log_info "Installing Python package..."
    cd "$SOURCE_DIR"
    
    # Set environment variables
    export MLC_LLM_SOURCE_DIR="$SOURCE_DIR"
    export PYTHONPATH="$SOURCE_DIR/python:$PYTHONPATH"
    
    # Install in development mode
    pip install -e . || {
        log_warning "Development install failed, trying regular install..."
        pip install .
    }
    
    log_success "Python package installed"
}

# Function to run tests
run_tests() {
    log_info "Running basic validation tests..."
    
    # Test Python import
    python -c "import mlc_llm; print(f'MLC-LLM version: {getattr(mlc_llm, \"__version__\", \"unknown\")}')" || {
        log_error "Failed to import mlc_llm"
        return 1
    }
    
    # Check if libraries were built
    if [ -f "$BUILD_DIR/libmlc_llm.so" ] || [ -f "$BUILD_DIR/libmlc_llm.dylib" ] || [ -f "$BUILD_DIR/mlc_llm.dll" ]; then
        log_success "MLC-LLM libraries found"
    else
        log_warning "MLC-LLM libraries not found in expected location"
    fi
    
    # Check if TVM runtime was built
    if [ -f "$BUILD_DIR/libtvm_runtime.so" ] || [ -f "$BUILD_DIR/libtvm_runtime.dylib" ] || [ -f "$BUILD_DIR/tvm_runtime.dll" ]; then
        log_success "TVM runtime libraries found"
    else
        log_warning "TVM runtime libraries not found in expected location"
    fi
    
    log_success "Basic validation completed"
}

# Function to display usage
show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  --build-type TYPE     Build type (Debug|Release|RelWithDebInfo) [default: Release]"
    echo "  --jobs NUM            Number of parallel jobs [default: $(nproc)]"
    echo "  --source-dir DIR      Source directory [default: current directory]"
    echo "  --build-dir DIR       Build directory [default: SOURCE_DIR/build]"
    echo "  --install-prefix DIR  Install prefix [default: /usr/local]"
    echo "  --skip-deps           Skip dependency checks"
    echo "  --skip-submodules     Skip submodule initialization"
    echo "  --skip-tests          Skip validation tests"
    echo "  --clean               Clean build directory before building"
    echo "  --help                Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  MLC_LLM_SOURCE_DIR    Source directory override"
    echo "  INSTALL_PREFIX        Install prefix override"
    echo ""
}

# Parse command line arguments
SKIP_DEPS=false
SKIP_SUBMODULES=false
SKIP_TESTS=false
CLEAN_BUILD=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --build-type)
            BUILD_TYPE="$2"
            shift 2
            ;;
        --jobs)
            NUM_CORES="$2"
            shift 2
            ;;
        --source-dir)
            SOURCE_DIR="$2"
            BUILD_DIR="$SOURCE_DIR/build"
            shift 2
            ;;
        --build-dir)
            BUILD_DIR="$2"
            shift 2
            ;;
        --install-prefix)
            INSTALL_PREFIX="$2"
            shift 2
            ;;
        --skip-deps)
            SKIP_DEPS=true
            shift
            ;;
        --skip-submodules)
            SKIP_SUBMODULES=true
            shift
            ;;
        --skip-tests)
            SKIP_TESTS=true
            shift
            ;;
        --clean)
            CLEAN_BUILD=true
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main build process
main() {
    log_info "Starting MLC-LLM build process..."
    log_info "Source directory: $SOURCE_DIR"
    log_info "Build directory: $BUILD_DIR"
    log_info "Build type: $BUILD_TYPE"
    log_info "Parallel jobs: $NUM_CORES"
    
    # Clean build directory if requested
    if [ "$CLEAN_BUILD" = true ]; then
        log_info "Cleaning build directory..."
        rm -rf "$BUILD_DIR"
    fi
    
    # Check dependencies
    if [ "$SKIP_DEPS" = false ]; then
        check_dependencies
    fi
    
    # Initialize submodules
    if [ "$SKIP_SUBMODULES" = false ]; then
        init_submodules
    fi
    
    # Configure and build
    configure_build
    build_project
    
    # Install Python package
    install_python_package
    
    # Run tests
    if [ "$SKIP_TESTS" = false ]; then
        run_tests
    fi
    
    log_success "MLC-LLM build completed successfully!"
    log_info "You can now use MLC-LLM:"
    log_info "  - Python: python -c 'import mlc_llm'"
    log_info "  - CLI: python -m mlc_llm --help"
}

# Run main function
main "$@"

