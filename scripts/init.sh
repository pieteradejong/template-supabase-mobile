#!/bin/bash
# =============================================================================
# Project Initialization Script
# =============================================================================
# Sets up the development environment from a fresh clone.
# Detects project stacks automatically and installs dependencies.
#
# Usage:
#   ./scripts/init.sh [OPTIONS]
#
# Options:
#   --no-clean    Skip cleanup of existing artifacts
#   --help        Show this help message
# =============================================================================

set -e  # Exit on error

# Source common utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/_common.sh"

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

SKIP_CLEAN=false

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Initialize the project development environment."
    echo ""
    echo "Options:"
    echo "  --no-clean    Skip cleanup of existing artifacts"
    echo "  --help        Show this help message"
    echo ""
    echo "This script will:"
    echo "  1. Detect project stacks (Python, Node.js, Rust, Go, Docker)"
    echo "  2. Clean existing build artifacts (unless --no-clean)"
    echo "  3. Install dependencies for each detected stack"
    exit 0
}

for arg in "$@"; do
    case $arg in
        --no-clean)
            SKIP_CLEAN=true
            shift
            ;;
        --help|-h)
            show_help
            ;;
        *)
            log_error "Unknown option: $arg"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# =============================================================================
# MAIN
# =============================================================================

log_header "${PROJECT_NAME:-Project} - Initialization"
echo ""

print_detected_stacks

# =============================================================================
# CLEANUP
# =============================================================================

if [ "$SKIP_CLEAN" = false ]; then
    log_step "Cleaning existing artifacts..."
    
    # Python cleanup
    if is_python_enabled; then
        local_venv=$(get_venv_path)
        if [ -d "$local_venv" ]; then
            echo "  Removing $local_venv..."
            rm -rf "$local_venv"
        fi
        
        # Remove Python caches
        echo "  Removing Python caches..."
        find "$PROJECT_ROOT" -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
        find "$PROJECT_ROOT" -type f -name "*.pyc" -delete 2>/dev/null || true
        find "$PROJECT_ROOT" -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
        find "$PROJECT_ROOT" -type d -name "*.egg-info" -exec rm -rf {} + 2>/dev/null || true
        find "$PROJECT_ROOT" -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
        find "$PROJECT_ROOT" -type d -name ".ruff_cache" -exec rm -rf {} + 2>/dev/null || true
    fi
    
    # Node.js cleanup
    if is_node_enabled; then
        local_node_dir=$(get_node_dir)
        
        if [ -d "$local_node_dir/node_modules" ]; then
            echo "  Removing $local_node_dir/node_modules..."
            rm -rf "$local_node_dir/node_modules"
        fi
        
        if [ -d "$local_node_dir/dist" ]; then
            echo "  Removing $local_node_dir/dist..."
            rm -rf "$local_node_dir/dist"
        fi
        
        if [ -d "$local_node_dir/.vite" ]; then
            echo "  Removing $local_node_dir/.vite..."
            rm -rf "$local_node_dir/.vite"
        fi
        
        if [ -d "$local_node_dir/.next" ]; then
            echo "  Removing $local_node_dir/.next..."
            rm -rf "$local_node_dir/.next"
        fi
    fi
    
    # Rust cleanup
    if is_rust_enabled && check_command cargo; then
        echo "  Running cargo clean..."
        cargo clean 2>/dev/null || true
    fi
    
    # Go cleanup
    if is_go_enabled && check_command go; then
        echo "  Cleaning Go cache..."
        go clean -cache 2>/dev/null || true
    fi
    
    log_success "Cleanup complete"
    echo ""
fi

# =============================================================================
# PYTHON INITIALIZATION
# =============================================================================

if is_python_enabled; then
    log_header "Python Setup"
    
    require_command python3 "Install Python 3 from https://python.org"
    
    local_venv=$(get_venv_path)
    local_python_dir=$(get_python_dir)
    local_requirements=$(get_python_requirements)
    
    # Create virtual environment
    log_step "Creating virtual environment..."
    python3 -m venv "$local_venv"
    log_success "Virtual environment created at $local_venv"
    
    # Activate and install
    log_step "Installing Python dependencies..."
    source "$local_venv/bin/activate"
    
    # Upgrade pip
    pip install --upgrade pip --quiet
    
    # Install from requirements or pyproject.toml
    if [ -n "$INIT_PYTHON_CMD" ]; then
        eval "$INIT_PYTHON_CMD"
    elif [ -n "$local_requirements" ] && [ -f "$local_requirements" ]; then
        pip install -r "$local_requirements"
    elif [ -f "$local_python_dir/pyproject.toml" ]; then
        pip install -e "$local_python_dir"
    elif [ -f "$PROJECT_ROOT/pyproject.toml" ]; then
        pip install -e "$PROJECT_ROOT"
    else
        log_warn "No requirements.txt or pyproject.toml found"
    fi
    
    deactivate
    log_success "Python dependencies installed"
    echo ""
fi

# =============================================================================
# NODE.JS INITIALIZATION
# =============================================================================

if is_node_enabled; then
    log_header "Node.js Setup"
    
    local_node_dir=$(get_node_dir)
    local_pm=$(get_node_package_manager)
    local_install_cmd=$(get_node_install_cmd)
    
    require_command "$local_pm" "Install from https://nodejs.org"
    
    log_step "Installing Node.js dependencies with $local_pm..."
    
    cd "$local_node_dir"
    
    if [ -n "$INIT_NODE_CMD" ]; then
        eval "$INIT_NODE_CMD"
    else
        eval "$local_install_cmd"
    fi
    
    cd "$PROJECT_ROOT"
    
    log_success "Node.js dependencies installed"
    echo ""
fi

# =============================================================================
# RUST INITIALIZATION
# =============================================================================

if is_rust_enabled; then
    log_header "Rust Setup"
    
    require_command cargo "Install from https://rustup.rs"
    
    log_step "Building Rust project..."
    
    if [ -n "$INIT_RUST_CMD" ]; then
        eval "$INIT_RUST_CMD"
    else
        cargo build
    fi
    
    log_success "Rust project built"
    echo ""
fi

# =============================================================================
# GO INITIALIZATION
# =============================================================================

if is_go_enabled; then
    log_header "Go Setup"
    
    require_command go "Install from https://go.dev"
    
    log_step "Downloading Go dependencies..."
    
    if [ -n "$INIT_GO_CMD" ]; then
        eval "$INIT_GO_CMD"
    else
        go mod download
    fi
    
    log_success "Go dependencies downloaded"
    echo ""
fi

# =============================================================================
# DOCKER INITIALIZATION
# =============================================================================

if is_docker_enabled; then
    log_header "Docker Setup"
    
    if check_command docker; then
        log_step "Building Docker images..."
        
        if [ -n "$INIT_DOCKER_CMD" ]; then
            eval "$INIT_DOCKER_CMD"
        elif [ -f "$PROJECT_ROOT/docker-compose.yml" ] || [ -f "$PROJECT_ROOT/docker-compose.yaml" ] || \
             [ -f "$PROJECT_ROOT/compose.yml" ] || [ -f "$PROJECT_ROOT/compose.yaml" ]; then
            docker compose build
        elif [ -f "$PROJECT_ROOT/Dockerfile" ]; then
            docker build -t "${PROJECT_NAME:-project}" .
        fi
        
        log_success "Docker images built"
    else
        log_warn "Docker detected but docker command not available"
    fi
    echo ""
fi

# =============================================================================
# SUPABASE INITIALIZATION
# =============================================================================

if is_supabase_enabled; then
    log_header "Supabase Setup"

    # -----------------------------------------------------------------------------
    # Hosted Supabase (no local Docker required)
    # -----------------------------------------------------------------------------
    #
    # If Supabase credentials are present via environment variables or an Expo env
    # file, we treat this as a hosted Supabase setup and skip local Supabase startup.
    #
    # Expo convention: EXPO_PUBLIC_* variables are safe to expose to the client.
    #
    EXPO_ENV_LOCAL="$(get_expo_dir)/.env.local"

    # Load Expo env file if present (KEY=VALUE lines). This helps init.sh detect
    # hosted credentials without requiring users to export vars in their shell.
    if [ -f "$EXPO_ENV_LOCAL" ]; then
        # shellcheck disable=SC1090
        set -a
        source "$EXPO_ENV_LOCAL"
        set +a
    fi

    HOSTED_URL="${EXPO_PUBLIC_SUPABASE_URL:-${SUPABASE_URL:-}}"
    HOSTED_ANON_KEY="${EXPO_PUBLIC_SUPABASE_ANON_KEY:-${SUPABASE_ANON_KEY:-}}"

    # If these are present, assume hosted (or at least "preconfigured") Supabase.
    # Local Supabase can still be used by setting URL to localhost/127.0.0.1.
    if [ -n "$HOSTED_URL" ] && [ -n "$HOSTED_ANON_KEY" ]; then
        log_success "Supabase credentials detected (hosted/preconfigured). Skipping local Supabase startup."
        echo "  URL: $HOSTED_URL"
        echo ""
        log_info "Next: ensure your hosted project has the schema + seed data:"
        echo "  - Run: supabase/migrations/00001_initial_schema.sql"
        echo "  - Run: supabase/seed.sql"
        echo ""
    else
    
    # Check prerequisites
    if ! check_command supabase; then
        log_error "Supabase CLI is not installed"
        echo "  Install with: brew install supabase/tap/supabase"
        echo "  Or see: https://supabase.com/docs/guides/cli"
        exit 1
    fi
    log_success "Supabase CLI found"
    
    if ! check_command docker; then
        log_error "Docker is required for local Supabase"
        echo "  Install from: https://docker.com"
        exit 1
    fi
    log_success "Docker found"
    
    # Check if Docker is running
    if ! docker info >/dev/null 2>&1; then
        log_error "Docker is not running"
        echo "  Please start Docker Desktop or the Docker daemon"
        exit 1
    fi
    log_success "Docker is running"
    
    # Start Supabase
    log_step "Starting local Supabase..."
    cd "$(get_supabase_dir)/.."
    
    if is_supabase_running; then
        log_info "Supabase is already running"
    else
        supabase start
    fi
    
    # Get Supabase status and extract credentials
    log_step "Getting Supabase credentials..."
    SUPABASE_STATUS=$(supabase status 2>/dev/null || true)
    
    # Extract API URL and anon key from status output
    API_URL=$(echo "$SUPABASE_STATUS" | grep "API URL" | awk '{print $NF}')
    ANON_KEY=$(echo "$SUPABASE_STATUS" | grep "anon key" | awk '{print $NF}')
    
    if [ -n "$API_URL" ] && [ -n "$ANON_KEY" ]; then
        log_success "Supabase is running"
        echo "  API URL: $API_URL"
        echo "  Studio:  http://127.0.0.1:54323"
        
        # Create or update .env.local with Supabase credentials
        ENV_LOCAL="$PROJECT_ROOT/.env.local"
        EXPO_ENV_LOCAL="$(get_expo_dir)/.env.local"
        if [ ! -f "$ENV_LOCAL" ]; then
            log_step "Creating .env.local with Supabase credentials..."
            cat > "$ENV_LOCAL" << EOF
# Auto-generated by init.sh
# Local Supabase credentials from 'supabase status'

EXPO_PUBLIC_SUPABASE_URL=$API_URL
EXPO_PUBLIC_SUPABASE_ANON_KEY=$ANON_KEY

APP_ENV=development
EOF
            log_success ".env.local created"
        else
            log_info ".env.local already exists, not overwriting"
            echo "  Update manually if needed with:"
            echo "  EXPO_PUBLIC_SUPABASE_URL=$API_URL"
            echo "  EXPO_PUBLIC_SUPABASE_ANON_KEY=$ANON_KEY"
        fi

        # Expo loads env vars relative to the app directory; mirror env for convenience.
        if [ -d "$(get_expo_dir)" ] && [ ! -f "$EXPO_ENV_LOCAL" ]; then
            log_step "Creating Expo env file at $(get_expo_dir)/.env.local..."
            cat > "$EXPO_ENV_LOCAL" << EOF
# Auto-generated by init.sh
# Local Supabase credentials from 'supabase status'

EXPO_PUBLIC_SUPABASE_URL=$API_URL
EXPO_PUBLIC_SUPABASE_ANON_KEY=$ANON_KEY

APP_ENV=development
EOF
            log_success "Expo env file created"
        fi
    else
        log_warn "Could not extract Supabase credentials from status"
        echo "  Run 'supabase status' manually to get credentials"
    fi
    
    # Generate types
    log_step "Generating TypeScript types from database schema..."
    if [ -d "$PROJECT_ROOT/packages/types" ]; then
        supabase gen types typescript --local > "$PROJECT_ROOT/packages/types/src/database.ts"
        log_success "Types generated at packages/types/src/database.ts"
    else
        log_warn "packages/types directory not found, skipping type generation"
    fi
    
    cd "$PROJECT_ROOT"
    echo ""
    fi
fi

# =============================================================================
# COMPLETE
# =============================================================================

log_header "Initialization Complete"
echo ""
echo "Next steps:"
echo "  1. Run './scripts/test.sh' to verify setup"
echo "  2. Run './scripts/run.sh' to start the development server"
echo ""
