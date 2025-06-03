#!/bin/bash
# Entrypoint script for MLC-LLM Docker container
# Supports both development and build modes

set -e

# Activate conda environment
source /opt/conda/etc/profile.d/conda.sh
conda activate mlc-llm

# Function to display help
show_help() {
    echo "MLC-LLM Docker Container"
    echo "Usage: docker run [OPTIONS] mlc-llm-image [COMMAND]"
    echo ""
    echo "Commands:"
    echo "  bash                    Start interactive bash shell (development mode)"
    echo "  build                   Build MLC-LLM from source"
    echo "  test                    Run test suite"
    echo "  lint                    Run linting checks"
    echo "  format                  Format code"
    echo "  package                 Build Python wheel packages"
    echo "  serve [OPTIONS]         Start MLC-LLM server"
    echo "  chat [OPTIONS]          Start MLC-LLM chat interface"
    echo "  help                    Show this help message"
    echo ""
    echo "Environment Variables:"
    echo "  MLC_LLM_SOURCE_DIR      Path to MLC-LLM source (default: /workspace)"
    echo "  PYTHONPATH              Python path including MLC-LLM modules"
    echo ""
}

# Function to build MLC-LLM
build_mlc() {
    echo "Building MLC-LLM from source..."
    cd ${MLC_LLM_SOURCE_DIR:-/workspace}
    
    # Initialize submodules if they exist
    if [ -f ".gitmodules" ]; then
        git submodule update --init --recursive
    fi
    
    # Create build directory
    mkdir -p build
    cd build
    
    # Generate CMake configuration
    if [ -f "../cmake/gen_cmake_config.py" ]; then
        python ../cmake/gen_cmake_config.py
    fi
    
    # Build
    cmake ..
    cmake --build . --parallel $(nproc)
    
    # Install Python package
    cd ..
    pip install -e .
    
    echo "Build completed successfully!"
}

# Function to run tests
run_tests() {
    echo "Running MLC-LLM test suite..."
    cd ${MLC_LLM_SOURCE_DIR:-/workspace}
    
    # Run Python tests if they exist
    if [ -d "tests" ]; then
        python -m pytest tests/ -v --cov=mlc_llm --cov-report=xml --cov-report=term
    else
        echo "No tests directory found, running basic import test..."
        python -c "import mlc_llm; print('MLC-LLM imported successfully')"
    fi
}

# Function to run linting
run_lint() {
    echo "Running linting checks..."
    cd ${MLC_LLM_SOURCE_DIR:-/workspace}
    
    # Run black, flake8, and mypy if source exists
    if [ -d "python" ]; then
        echo "Running black..."
        black --check python/ || true
        
        echo "Running flake8..."
        flake8 python/ || true
        
        echo "Running mypy..."
        mypy python/ || true
    fi
}

# Function to format code
format_code() {
    echo "Formatting code..."
    cd ${MLC_LLM_SOURCE_DIR:-/workspace}
    
    if [ -d "python" ]; then
        black python/
        echo "Code formatting completed!"
    fi
}

# Function to build Python packages
build_packages() {
    echo "Building Python wheel packages..."
    cd ${MLC_LLM_SOURCE_DIR:-/workspace}
    
    # Build wheel
    python -m build --wheel --outdir dist/
    
    echo "Packages built successfully!"
    ls -la dist/
}

# Main command handling
case "${1:-bash}" in
    "help" | "--help" | "-h")
        show_help
        ;;
    "bash" | "shell")
        echo "Starting interactive bash shell..."
        exec /bin/bash
        ;;
    "build")
        build_mlc
        ;;
    "test")
        run_tests
        ;;
    "lint")
        run_lint
        ;;
    "format")
        format_code
        ;;
    "package")
        build_packages
        ;;
    "serve")
        shift
        echo "Starting MLC-LLM server..."
        exec python -m mlc_llm.cli.serve "$@"
        ;;
    "chat")
        shift
        echo "Starting MLC-LLM chat..."
        exec python -m mlc_llm.cli.chat "$@"
        ;;
    *)
        echo "Unknown command: $1"
        echo "Use 'help' to see available commands."
        exec "$@"
        ;;
esac

