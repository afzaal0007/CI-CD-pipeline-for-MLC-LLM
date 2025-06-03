#!/bin/bash
# Script to display the project structure
# Useful for documentation and understanding the layout

set -e

# Colors for output
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}MLC-LLM CI/CD Pipeline Project Structure${NC}"
echo "=========================================="
echo ""

# Function to show tree-like structure
show_structure() {
    echo -e "${GREEN}Project Directory Structure:${NC}"
    echo ""
    
    if command -v tree >/dev/null 2>&1; then
        tree -a -I '.git|__pycache__|*.pyc|*.pyo|build|dist|*.egg-info|node_modules'
    else
        echo "mlc-llm-pipeline/"
        echo "├── .github/"
        echo "│   └── workflows/"
        echo "│       └── ci-cd.yml              # Main CI/CD pipeline"
        echo "├── docs/"
        echo "│   ├── setup.md                  # Setup guide"
        echo "│   ├── usage.md                  # Usage examples"
        echo "│   ├── api.md                    # API reference"
        echo "│   └── troubleshooting.md        # Troubleshooting guide"
        echo "├── scripts/"
        echo "│   ├── build.sh                  # Build script"
        echo "│   ├── test.sh                   # Test script"
        echo "│   ├── entrypoint.sh             # Docker entrypoint"
        echo "│   └── show-structure.sh         # This script"
        echo "├── tests/"
        echo "│   ├── test_import.py            # Import tests"
        echo "│   ├── test_docker.py            # Docker tests"
        echo "│   └── conftest.py               # Pytest configuration"
        echo "├── Dockerfile                     # Multi-stage Docker configuration"
        echo "├── .dockerignore                 # Docker ignore patterns"
        echo "├── .gitignore                    # Git ignore patterns"
        echo "└── README.md                     # Main documentation"
    fi
}

# Function to show file purposes
show_file_purposes() {
    echo ""
    echo -e "${GREEN}Key Files and Their Purposes:${NC}"
    echo ""
    
    cat << 'EOF'
🐳 Docker Files:
   Dockerfile              - Multi-stage build for dev/build/prod environments
   .dockerignore          - Patterns to exclude from Docker build context
   scripts/entrypoint.sh  - Smart entrypoint supporting multiple modes

🔄 CI/CD Files:
   .github/workflows/ci-cd.yml - Complete GitHub Actions pipeline
   scripts/build.sh       - Comprehensive build script with options
   scripts/test.sh        - Full test suite with multiple test types

🧪 Testing Files:
   tests/test_import.py   - Basic import and module tests
   tests/test_docker.py   - Docker environment validation tests
   tests/conftest.py      - Pytest configuration and fixtures

📚 Documentation:
   README.md              - Main project documentation with examples
   docs/setup.md          - Detailed setup instructions
   docs/usage.md          - Usage examples and best practices
   docs/api.md            - API reference documentation
   docs/troubleshooting.md - Common issues and solutions

⚙️ Configuration:
   .gitignore             - Git ignore patterns for clean commits
EOF
}

# Function to show pipeline overview
show_pipeline_overview() {
    echo ""
    echo -e "${GREEN}CI/CD Pipeline Overview:${NC}"
    echo ""
    
    cat << 'EOF'
📋 Pipeline Stages:
   1. Code Quality        - Linting, formatting, type checking
   2. Docker Build        - Multi-stage image build and push to GHCR
   3. Docker Testing      - Validate container functionality
   4. Wheel Building      - Cross-platform Python wheel creation
   5. Release Creation    - GitHub releases with artifacts
   6. Production Deploy   - Minimal production image deployment
   7. Cleanup             - Remove old package versions

🎯 Workflow Triggers:
   • push: main          - Full pipeline execution
   • push: develop       - Build and test only
   • pull_request        - Validation pipeline
   • tag: v*            - Release pipeline
   • workflow_dispatch   - Manual trigger with options

🏗️ Build Targets:
   • Linux x64 wheels    - Built on ubuntu-latest
   • Windows x64 wheels  - Built on windows-latest
   • Docker images       - Multi-architecture support planned
EOF
}

# Function to show usage examples
show_usage_examples() {
    echo ""
    echo -e "${GREEN}Quick Usage Examples:${NC}"
    echo ""
    
    cat << 'EOF'
🚀 Getting Started:
   # Clone and setup
   git clone https://github.com/your-username/mlc-llm-pipeline.git
   cd mlc-llm-pipeline
   
   # Build with Docker
   docker build -t mlc-llm:dev --target development .
   
   # Local development build
   ./scripts/build.sh
   
   # Run tests
   ./scripts/test.sh

🐳 Docker Usage:
   # Development environment
   docker run -it --gpus all -v $(pwd):/workspace mlc-llm:dev
   
   # Build in container
   docker run --rm -v $(pwd):/workspace mlc-llm:dev build
   
   # Production deployment
   docker run --gpus all ghcr.io/your-username/mlc-llm:prod

🔧 Build Options:
   # Release build with 8 cores
   ./scripts/build.sh --build-type Release --jobs 8 --clean
   
   # Debug build without tests
   ./scripts/build.sh --build-type Debug --skip-tests
   
   # Custom source directory
   ./scripts/build.sh --source-dir /path/to/mlc-llm

🧪 Testing Options:
   # All tests
   ./scripts/test.sh
   
   # Specific test types
   ./scripts/test.sh import deps library pytest performance
   
   # With coverage and verbose output
   ./scripts/test.sh --coverage --verbose --fail-fast
EOF
}

# Function to show system requirements
show_requirements() {
    echo ""
    echo -e "${GREEN}System Requirements:${NC}"
    echo ""
    
    cat << 'EOF'
💻 Hardware Requirements:
   • CPU: 4+ cores (8+ recommended)
   • RAM: 8+ GB (16+ GB recommended)
   • Storage: 50+ GB (100+ GB recommended)
   • GPU: Optional NVIDIA GPU for acceleration

🛠️ Software Requirements:
   • Python 3.8+ (3.11+ recommended)
   • CMake 3.24+
   • Git 2.0+
   • Rust 1.65+
   • Docker 20.0+
   • CUDA 12.2+ (optional, for GPU support)

🎯 Platform Support:
   • Linux x64      - Full support (dev/build/runtime)
   • Windows x64    - Full support (dev/build/runtime)
   • macOS x64      - Development and runtime only
   • macOS ARM64    - Development and runtime only
EOF
}

# Function to show contribution info
show_contribution_info() {
    echo ""
    echo -e "${GREEN}Contributing to the Project:${NC}"
    echo ""
    
    cat << 'EOF'
🤝 Development Workflow:
   1. Fork the repository
   2. Create feature branch: git checkout -b feature/amazing-feature
   3. Make changes following coding standards
   4. Run tests: ./scripts/test.sh
   5. Commit changes: git commit -m 'Add amazing feature'
   6. Push branch: git push origin feature/amazing-feature
   7. Open Pull Request

📝 Coding Standards:
   • Python: PEP 8 compliance (Black + Flake8)
   • Shell: ShellCheck compliance
   • Docker: Multi-stage builds, security best practices
   • Documentation: Clear, concise, with examples

🧪 Testing Requirements:
   • All new features must include tests
   • Maintain or improve code coverage
   • Tests must pass on all supported platforms
   • Docker images must pass security scans
EOF
}

# Main execution
main() {
    local show_all=true
    local sections=()
    
    # Parse command line arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --structure)
                sections+=("structure")
                show_all=false
                shift
                ;;
            --files)
                sections+=("files")
                show_all=false
                shift
                ;;
            --pipeline)
                sections+=("pipeline")
                show_all=false
                shift
                ;;
            --usage)
                sections+=("usage")
                show_all=false
                shift
                ;;
            --requirements)
                sections+=("requirements")
                show_all=false
                shift
                ;;
            --contributing)
                sections+=("contributing")
                show_all=false
                shift
                ;;
            --help)
                echo "Usage: $0 [OPTIONS]"
                echo ""
                echo "Options:"
                echo "  --structure      Show project directory structure"
                echo "  --files          Show file purposes"
                echo "  --pipeline       Show CI/CD pipeline overview"
                echo "  --usage          Show usage examples"
                echo "  --requirements   Show system requirements"
                echo "  --contributing   Show contribution guidelines"
                echo "  --help           Show this help message"
                echo ""
                echo "If no options are specified, all sections are shown."
                exit 0
                ;;
            *)
                echo "Unknown option: $1"
                echo "Use --help for usage information."
                exit 1
                ;;
        esac
    done
    
    # Show all sections if none specified
    if [ "$show_all" = true ]; then
        sections=("structure" "files" "pipeline" "usage" "requirements" "contributing")
    fi
    
    # Display requested sections
    for section in "${sections[@]}"; do
        case $section in
            "structure")
                show_structure
                ;;
            "files")
                show_file_purposes
                ;;
            "pipeline")
                show_pipeline_overview
                ;;
            "usage")
                show_usage_examples
                ;;
            "requirements")
                show_requirements
                ;;
            "contributing")
                show_contribution_info
                ;;
        esac
    done
    
    echo ""
    echo -e "${YELLOW}For more detailed information:${NC}"
    echo "📖 Setup Guide: docs/setup.md"
    echo "🚀 Usage Guide: docs/usage.md"
    echo "🔧 API Reference: docs/api.md"
    echo "❓ Troubleshooting: docs/troubleshooting.md"
    echo ""
    echo -e "${YELLOW}Need help?${NC}"
    echo "🐛 Issues: https://github.com/your-username/mlc-llm-pipeline/issues"
    echo "💬 Discussions: https://github.com/your-username/mlc-llm-pipeline/discussions"
    echo ""
}

# Run main function with all arguments
main "$@"

