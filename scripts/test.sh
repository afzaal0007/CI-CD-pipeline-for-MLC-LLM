#!/bin/bash
# Test script for MLC-LLM
# Comprehensive testing framework for CI/CD and local development

set -e

# Configuration
SOURCE_DIR="${MLC_LLM_SOURCE_DIR:-$(pwd)}"
TEST_DIR="${SOURCE_DIR}/tests"
COVERAGE_DIR="${SOURCE_DIR}/coverage"
REPORT_DIR="${SOURCE_DIR}/test-reports"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_SKIPPED=0

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    ((TESTS_PASSED++))
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    ((TESTS_SKIPPED++))
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    ((TESTS_FAILED++))
}

log_test() {
    echo -e "${BLUE}[TEST]${NC} $1"
}

# Function to create test directory structure
setup_test_environment() {
    log_info "Setting up test environment..."
    
    mkdir -p "$TEST_DIR"
    mkdir -p "$COVERAGE_DIR"
    mkdir -p "$REPORT_DIR"
    
    # Create basic test files if they don't exist
    if [ ! -f "$TEST_DIR/test_import.py" ]; then
        cat > "$TEST_DIR/test_import.py" << 'EOF'
"""Basic import tests for MLC-LLM."""
import pytest
import sys
import os

def test_mlc_llm_import():
    """Test that mlc_llm can be imported."""
    try:
        import mlc_llm
        assert mlc_llm is not None
    except ImportError as e:
        pytest.fail(f"Failed to import mlc_llm: {e}")

def test_mlc_llm_version():
    """Test that mlc_llm has version information."""
    import mlc_llm
    version = getattr(mlc_llm, '__version__', None)
    assert version is not None, "mlc_llm should have a __version__ attribute"
    assert isinstance(version, str), "Version should be a string"
    assert len(version) > 0, "Version should not be empty"

def test_python_version():
    """Test that Python version is compatible."""
    assert sys.version_info >= (3, 8), "Python 3.8 or higher is required"

def test_environment_variables():
    """Test that required environment variables are set."""
    mlc_source_dir = os.environ.get('MLC_LLM_SOURCE_DIR')
    if mlc_source_dir:
        assert os.path.exists(mlc_source_dir), f"MLC_LLM_SOURCE_DIR {mlc_source_dir} does not exist"
EOF
    fi
    
    if [ ! -f "$TEST_DIR/test_docker.py" ]; then
        cat > "$TEST_DIR/test_docker.py" << 'EOF'
"""Docker-specific tests for MLC-LLM."""
import pytest
import subprocess
import os

def test_conda_environment():
    """Test that conda environment is properly activated."""
    try:
        result = subprocess.run(['conda', 'info'], capture_output=True, text=True)
        assert result.returncode == 0, "Conda should be available"
        assert 'mlc-llm' in result.stdout, "mlc-llm conda environment should be active"
    except FileNotFoundError:
        pytest.skip("Conda not available in this environment")

def test_cuda_availability():
    """Test CUDA availability if in GPU environment."""
    try:
        result = subprocess.run(['nvidia-smi'], capture_output=True, text=True)
        if result.returncode == 0:
            assert 'CUDA' in result.stdout or 'NVIDIA' in result.stdout
    except FileNotFoundError:
        pytest.skip("NVIDIA drivers not available")

def test_cmake_version():
    """Test that CMake is available and has correct version."""
    try:
        result = subprocess.run(['cmake', '--version'], capture_output=True, text=True)
        assert result.returncode == 0, "CMake should be available"
        # Extract version number
        import re
        version_match = re.search(r'cmake version (\d+\.\d+\.\d+)', result.stdout)
        assert version_match, "Could not parse CMake version"
        version = version_match.group(1)
        major, minor, patch = map(int, version.split('.'))
        assert (major, minor) >= (3, 24), f"CMake 3.24+ required, got {version}"
    except FileNotFoundError:
        pytest.fail("CMake is required but not found")
EOF
    fi
    
    if [ ! -f "$TEST_DIR/conftest.py" ]; then
        cat > "$TEST_DIR/conftest.py" << 'EOF'
"""Pytest configuration for MLC-LLM tests."""
import pytest
import os
import sys

# Add source directory to Python path
source_dir = os.environ.get('MLC_LLM_SOURCE_DIR', os.path.dirname(os.path.dirname(__file__)))
sys.path.insert(0, os.path.join(source_dir, 'python'))

@pytest.fixture(scope="session")
def mlc_source_dir():
    """Provide MLC-LLM source directory."""
    return source_dir

@pytest.fixture(scope="session")
def build_dir():
    """Provide build directory."""
    return os.path.join(source_dir, 'build')
EOF
    fi
    
    log_success "Test environment setup completed"
}

# Function to run import tests
run_import_tests() {
    log_test "Running import tests..."
    
    # Test basic Python import
    if python -c "import sys; print(f'Python {sys.version}')" >/dev/null 2>&1; then
        log_success "Python is available"
    else
        log_error "Python is not available"
        return 1
    fi
    
    # Test MLC-LLM import
    if python -c "import mlc_llm; print(f'MLC-LLM imported successfully')" >/dev/null 2>&1; then
        log_success "MLC-LLM can be imported"
    else
        log_error "Failed to import MLC-LLM"
        return 1
    fi
    
    # Test version information
    local version=$(python -c "import mlc_llm; print(getattr(mlc_llm, '__version__', 'unknown'))" 2>/dev/null || echo "unknown")
    if [ "$version" != "unknown" ]; then
        log_success "MLC-LLM version: $version"
    else
        log_warning "MLC-LLM version information not available"
    fi
}

# Function to run dependency tests
run_dependency_tests() {
    log_test "Running dependency tests..."
    
    local deps=("cmake" "git" "python" "rustc")
    local missing_deps=()
    
    for dep in "${deps[@]}"; do
        if command -v "$dep" >/dev/null 2>&1; then
            local version=$("$dep" --version 2>/dev/null | head -n1 || echo "version unknown")
            log_success "$dep is available: $version"
        else
            missing_deps+=("$dep")
            log_error "$dep is not available"
        fi
    done
    
    if [ ${#missing_deps[@]} -eq 0 ]; then
        log_success "All required dependencies are available"
        return 0
    else
        log_error "Missing dependencies: ${missing_deps[*]}"
        return 1
    fi
}

# Function to run library tests
run_library_tests() {
    log_test "Running library tests..."
    
    local build_dir="$SOURCE_DIR/build"
    
    if [ ! -d "$build_dir" ]; then
        log_warning "Build directory not found, skipping library tests"
        return 0
    fi
    
    # Check for MLC-LLM libraries
    local mlc_libs=("libmlc_llm.so" "libmlc_llm.dylib" "mlc_llm.dll")
    local mlc_found=false
    
    for lib in "${mlc_libs[@]}"; do
        if [ -f "$build_dir/$lib" ]; then
            log_success "Found MLC-LLM library: $lib"
            mlc_found=true
            break
        fi
    done
    
    if [ "$mlc_found" = false ]; then
        log_warning "No MLC-LLM libraries found in build directory"
    fi
    
    # Check for TVM runtime libraries
    local tvm_libs=("libtvm_runtime.so" "libtvm_runtime.dylib" "tvm_runtime.dll")
    local tvm_found=false
    
    for lib in "${tvm_libs[@]}"; do
        if [ -f "$build_dir/$lib" ]; then
            log_success "Found TVM runtime library: $lib"
            tvm_found=true
            break
        fi
    done
    
    if [ "$tvm_found" = false ]; then
        log_warning "No TVM runtime libraries found in build directory"
    fi
}

# Function to run pytest tests
run_pytest_tests() {
    log_test "Running pytest tests..."
    
    if [ ! -d "$TEST_DIR" ]; then
        log_warning "Test directory not found, skipping pytest tests"
        return 0
    fi
    
    # Check if pytest is available
    if ! command -v pytest >/dev/null 2>&1; then
        log_warning "pytest not available, installing..."
        pip install pytest pytest-cov pytest-xdist || {
            log_error "Failed to install pytest"
            return 1
        }
    fi
    
    # Run pytest with coverage
    local pytest_args=(
        "$TEST_DIR"
        "-v"
        "--tb=short"
        "--junitxml=$REPORT_DIR/junit.xml"
    )
    
    # Add coverage if mlc_llm module exists
    if python -c "import mlc_llm" >/dev/null 2>&1; then
        pytest_args+=(
            "--cov=mlc_llm"
            "--cov-report=xml:$COVERAGE_DIR/coverage.xml"
            "--cov-report=html:$COVERAGE_DIR/html"
            "--cov-report=term"
        )
    fi
    
    if pytest "${pytest_args[@]}"; then
        log_success "Pytest tests passed"
    else
        log_error "Some pytest tests failed"
        return 1
    fi
}

# Function to run performance tests
run_performance_tests() {
    log_test "Running basic performance tests..."
    
    # Test import time
    local import_time=$(python -c "
import time
start = time.time()
import mlc_llm
end = time.time()
print(f'{end - start:.3f}')
" 2>/dev/null || echo "failed")
    
    if [ "$import_time" != "failed" ]; then
        log_success "MLC-LLM import time: ${import_time}s"
    else
        log_error "Failed to measure import time"
    fi
}

# Function to generate test report
generate_test_report() {
    log_info "Generating test report..."
    
    local report_file="$REPORT_DIR/test_summary.txt"
    
    cat > "$report_file" << EOF
MLC-LLM Test Summary
===================

Test Results:
- Passed: $TESTS_PASSED
- Failed: $TESTS_FAILED
- Skipped: $TESTS_SKIPPED
- Total: $((TESTS_PASSED + TESTS_FAILED + TESTS_SKIPPED))

Test Environment:
- Source Directory: $SOURCE_DIR
- Test Directory: $TEST_DIR
- Python Version: $(python --version 2>&1)
- Date: $(date)

Test Status: $([ $TESTS_FAILED -eq 0 ] && echo "PASS" || echo "FAIL")
EOF

    cat "$report_file"
    log_success "Test report generated: $report_file"
}

# Function to display usage
show_usage() {
    echo "Usage: $0 [OPTIONS] [TEST_TYPE]"
    echo ""
    echo "Test Types:"
    echo "  all           Run all tests (default)"
    echo "  import        Run import tests only"
    echo "  deps          Run dependency tests only"
    echo "  library       Run library tests only"
    echo "  pytest        Run pytest tests only"
    echo "  performance   Run performance tests only"
    echo ""
    echo "Options:"
    echo "  --source-dir DIR      Source directory [default: current directory]"
    echo "  --coverage            Generate coverage reports"
    echo "  --verbose             Verbose output"
    echo "  --fail-fast           Stop on first failure"
    echo "  --help                Show this help message"
    echo ""
}

# Parse command line arguments
TEST_TYPE="all"
GENERATE_COVERAGE=false
VERBOSE=false
FAIL_FAST=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --source-dir)
            SOURCE_DIR="$2"
            TEST_DIR="$SOURCE_DIR/tests"
            COVERAGE_DIR="$SOURCE_DIR/coverage"
            REPORT_DIR="$SOURCE_DIR/test-reports"
            shift 2
            ;;
        --coverage)
            GENERATE_COVERAGE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --fail-fast)
            FAIL_FAST=true
            shift
            ;;
        --help)
            show_usage
            exit 0
            ;;
        all|import|deps|library|pytest|performance)
            TEST_TYPE="$1"
            shift
            ;;
        *)
            log_error "Unknown option: $1"
            show_usage
            exit 1
            ;;
    esac
done

# Main test execution
main() {
    log_info "Starting MLC-LLM test suite..."
    log_info "Test type: $TEST_TYPE"
    log_info "Source directory: $SOURCE_DIR"
    
    # Setup test environment
    setup_test_environment
    
    # Set fail-fast behavior
    if [ "$FAIL_FAST" = true ]; then
        set -e
    fi
    
    # Run tests based on type
    case $TEST_TYPE in
        "all")
            run_import_tests || [ "$FAIL_FAST" = false ]
            run_dependency_tests || [ "$FAIL_FAST" = false ]
            run_library_tests || [ "$FAIL_FAST" = false ]
            run_pytest_tests || [ "$FAIL_FAST" = false ]
            run_performance_tests || [ "$FAIL_FAST" = false ]
            ;;
        "import")
            run_import_tests
            ;;
        "deps")
            run_dependency_tests
            ;;
        "library")
            run_library_tests
            ;;
        "pytest")
            run_pytest_tests
            ;;
        "performance")
            run_performance_tests
            ;;
        *)
            log_error "Unknown test type: $TEST_TYPE"
            exit 1
            ;;
    esac
    
    # Generate test report
    generate_test_report
    
    # Exit with appropriate code
    if [ $TESTS_FAILED -eq 0 ]; then
        log_success "All tests completed successfully!"
        exit 0
    else
        log_error "Some tests failed. Check the test report for details."
        exit 1
    fi
}

# Run main function
main "$@"

