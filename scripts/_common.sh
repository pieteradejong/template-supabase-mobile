#!/bin/bash
# Common utilities for project scripts
# Source this file at the beginning of each script

# =============================================================================
# SCRIPT DIRECTORY AND PROJECT ROOT
# =============================================================================

# Get the directory where _common.sh lives (scripts/)
COMMON_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
# Project root is one level up from scripts/
PROJECT_ROOT="$( cd "$COMMON_DIR/.." && pwd )"

# =============================================================================
# COLORS
# =============================================================================

# Check if colors should be used (only when outputting to a terminal)
if [ -t 1 ]; then
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    CYAN='\033[0;36m'
    BOLD='\033[1m'
    NC='\033[0m' # No Color
else
    RED=''
    GREEN=''
    YELLOW=''
    BLUE=''
    CYAN=''
    BOLD=''
    NC=''
fi

# =============================================================================
# LOGGING FUNCTIONS
# =============================================================================

log_info() {
    echo -e "${BLUE}$1${NC}"
}

log_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

log_warn() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

log_error() {
    echo -e "${RED}✗ $1${NC}"
}

log_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

log_step() {
    echo -e "${CYAN}$1${NC}"
}

# =============================================================================
# UTILITY FUNCTIONS
# =============================================================================

# Check if a command exists
check_command() {
    command -v "$1" &> /dev/null
}

# Check if a port is in use
check_port() {
    local port=$1
    if lsof -Pi ":$port" -sTCP:LISTEN -t >/dev/null 2>&1; then
        return 0  # Port is in use
    fi
    return 1  # Port is free
}

# Require a command to exist, exit with error if not found
require_command() {
    local cmd=$1
    local install_hint=${2:-""}
    if ! check_command "$cmd"; then
        log_error "Required command '$cmd' is not installed"
        if [ -n "$install_hint" ]; then
            echo "  Install with: $install_hint"
        fi
        exit 1
    fi
}

# =============================================================================
# STACK DETECTION FUNCTIONS
# =============================================================================

# Detect Python project
detect_python() {
    [ -f "$PROJECT_ROOT/requirements.txt" ] || \
    [ -f "$PROJECT_ROOT/pyproject.toml" ] || \
    [ -f "$PROJECT_ROOT/setup.py" ] || \
    [ -f "$PROJECT_ROOT/Pipfile" ] || \
    [ -d "$PROJECT_ROOT/${PYTHON_DIR:-backend}" ] && [ -f "$PROJECT_ROOT/${PYTHON_DIR:-backend}/requirements.txt" ] || \
    [ -d "$PROJECT_ROOT/${PYTHON_DIR:-backend}" ] && [ -f "$PROJECT_ROOT/${PYTHON_DIR:-backend}/pyproject.toml" ]
}

# Detect Node.js project
detect_node() {
    [ -f "$PROJECT_ROOT/package.json" ] || \
    [ -d "$PROJECT_ROOT/${NODE_DIR:-frontend}" ] && [ -f "$PROJECT_ROOT/${NODE_DIR:-frontend}/package.json" ]
}

# Detect Rust project
detect_rust() {
    [ -f "$PROJECT_ROOT/Cargo.toml" ]
}

# Detect Go project
detect_go() {
    [ -f "$PROJECT_ROOT/go.mod" ]
}

# Detect Docker project
detect_docker() {
    [ -f "$PROJECT_ROOT/Dockerfile" ] || \
    [ -f "$PROJECT_ROOT/docker-compose.yml" ] || \
    [ -f "$PROJECT_ROOT/docker-compose.yaml" ] || \
    [ -f "$PROJECT_ROOT/compose.yml" ] || \
    [ -f "$PROJECT_ROOT/compose.yaml" ]
}

# =============================================================================
# STACK ENABLED CHECKS (respects config overrides)
# =============================================================================

is_python_enabled() {
    case "${ENABLE_PYTHON:-auto}" in
        true) return 0 ;;
        false) return 1 ;;
        auto|*) detect_python ;;
    esac
}

is_node_enabled() {
    case "${ENABLE_NODE:-auto}" in
        true) return 0 ;;
        false) return 1 ;;
        auto|*) detect_node ;;
    esac
}

is_rust_enabled() {
    case "${ENABLE_RUST:-auto}" in
        true) return 0 ;;
        false) return 1 ;;
        auto|*) detect_rust ;;
    esac
}

is_go_enabled() {
    case "${ENABLE_GO:-auto}" in
        true) return 0 ;;
        false) return 1 ;;
        auto|*) detect_go ;;
    esac
}

is_docker_enabled() {
    case "${ENABLE_DOCKER:-auto}" in
        true) return 0 ;;
        false) return 1 ;;
        auto|*) detect_docker ;;
    esac
}

# =============================================================================
# PATH HELPERS
# =============================================================================

# Get Python directory (where Python code lives)
get_python_dir() {
    if [ -n "${PYTHON_DIR:-}" ]; then
        echo "$PROJECT_ROOT/$PYTHON_DIR"
    elif [ -d "$PROJECT_ROOT/backend" ]; then
        echo "$PROJECT_ROOT/backend"
    elif [ -d "$PROJECT_ROOT/src" ] && [ -f "$PROJECT_ROOT/src/__init__.py" ]; then
        echo "$PROJECT_ROOT/src"
    else
        echo "$PROJECT_ROOT"
    fi
}

# Get Node directory (where Node.js code lives)
get_node_dir() {
    if [ -n "${NODE_DIR:-}" ]; then
        echo "$PROJECT_ROOT/$NODE_DIR"
    elif [ -d "$PROJECT_ROOT/frontend" ]; then
        echo "$PROJECT_ROOT/frontend"
    elif [ -d "$PROJECT_ROOT/web" ]; then
        echo "$PROJECT_ROOT/web"
    elif [ -d "$PROJECT_ROOT/client" ]; then
        echo "$PROJECT_ROOT/client"
    else
        echo "$PROJECT_ROOT"
    fi
}

# Get the Python requirements file path
get_python_requirements() {
    local python_dir=$(get_python_dir)
    if [ -n "${PYTHON_REQUIREMENTS:-}" ]; then
        echo "$python_dir/$PYTHON_REQUIREMENTS"
    elif [ -f "$python_dir/requirements.txt" ]; then
        echo "$python_dir/requirements.txt"
    elif [ -f "$PROJECT_ROOT/requirements.txt" ]; then
        echo "$PROJECT_ROOT/requirements.txt"
    else
        echo ""
    fi
}

# Get venv path
get_venv_path() {
    echo "$PROJECT_ROOT/${PYTHON_VENV:-venv}"
}

# =============================================================================
# PACKAGE MANAGER DETECTION
# =============================================================================

# Detect Node package manager
get_node_package_manager() {
    if [ -n "${NODE_PACKAGE_MANAGER:-}" ]; then
        echo "$NODE_PACKAGE_MANAGER"
    elif [ -f "$PROJECT_ROOT/pnpm-lock.yaml" ] || [ -f "$(get_node_dir)/pnpm-lock.yaml" ]; then
        echo "pnpm"
    elif [ -f "$PROJECT_ROOT/yarn.lock" ] || [ -f "$(get_node_dir)/yarn.lock" ]; then
        echo "yarn"
    else
        echo "npm"
    fi
}

# Get the install command for the detected package manager
get_node_install_cmd() {
    local pm=$(get_node_package_manager)
    case "$pm" in
        pnpm) echo "pnpm install" ;;
        yarn) echo "yarn install" ;;
        npm|*) echo "npm install" ;;
    esac
}

# Get the run command prefix for the detected package manager
get_node_run_prefix() {
    local pm=$(get_node_package_manager)
    case "$pm" in
        pnpm) echo "pnpm" ;;
        yarn) echo "yarn" ;;
        npm|*) echo "npm run" ;;
    esac
}

# =============================================================================
# CONFIGURATION LOADING
# =============================================================================

# Load project.conf if it exists
load_config() {
    local config_file="$COMMON_DIR/project.conf"
    if [ -f "$config_file" ]; then
        # shellcheck source=/dev/null
        source "$config_file"
        return 0
    fi
    return 1
}

# =============================================================================
# DETECTED STACKS SUMMARY
# =============================================================================

print_detected_stacks() {
    log_step "Detected stacks:"
    local found=false
    
    if is_python_enabled; then
        echo "  - Python ($(get_python_dir))"
        found=true
    fi
    
    if is_node_enabled; then
        local pm=$(get_node_package_manager)
        echo "  - Node.js ($(get_node_dir), package manager: $pm)"
        found=true
    fi
    
    if is_rust_enabled; then
        echo "  - Rust"
        found=true
    fi
    
    if is_go_enabled; then
        echo "  - Go"
        found=true
    fi
    
    if is_docker_enabled; then
        echo "  - Docker"
        found=true
    fi
    
    if [ "$found" = false ]; then
        log_warn "No supported stacks detected"
    fi
    
    echo ""
}

# =============================================================================
# INITIALIZATION
# =============================================================================

# Load config on source
load_config

# Change to project root
cd "$PROJECT_ROOT"
