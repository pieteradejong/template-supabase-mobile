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
PROJECT_REF=""

show_help() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Initialize the project development environment."
    echo ""
    echo "Options:"
    echo "  --project-ref <ref>  Setup hosted Supabase (links project, applies migrations)"
    echo "  --no-clean           Skip cleanup of existing artifacts"
    echo "  --help               Show this help message"
    echo ""
    echo "This script will:"
    echo "  1. Detect project stacks (Python, Node.js, Rust, Go, Docker)"
    echo "  2. Clean existing build artifacts (unless --no-clean)"
    echo "  3. Install dependencies for each detected stack"
    echo "  4. Setup Supabase (local or hosted if --project-ref provided)"
    exit 0
}

while [ $# -gt 0 ]; do
    case "$1" in
        --project-ref)
            PROJECT_REF="${2:-}"
            if [ -z "$PROJECT_REF" ]; then
                log_error "--project-ref requires a value"
                show_help
                exit 1
            fi
            shift 2
            ;;
        --no-clean)
            SKIP_CLEAN=true
            shift
            ;;
        --help|-h)
            show_help
            ;;
        *)
            log_error "Unknown option: $1"
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
    # Hosted Supabase Setup (--project-ref provided)
    # -----------------------------------------------------------------------------
    if [ -n "$PROJECT_REF" ]; then
        log_info "Hosted Supabase setup requested (project-ref: $PROJECT_REF)"
        echo ""

        # Check prerequisites
        if ! check_command supabase; then
            log_error "Supabase CLI is not installed"
            echo "  Install with: brew install supabase/tap/supabase"
            echo "  Or see: https://supabase.com/docs/guides/cli"
            exit 1
        fi
        log_success "Supabase CLI found"

        # Link project
        log_step "Linking to hosted Supabase project..."
        cd "$PROJECT_ROOT"
        if supabase link --project-ref "$PROJECT_REF" 2>/dev/null; then
            log_success "Project linked"
        else
            log_error "Failed to link project. Make sure:"
            echo "  1. You've run 'supabase login'"
            echo "  2. The project-ref '$PROJECT_REF' is correct"
            echo "  3. You have access to this project"
            exit 1
        fi
        echo ""

        # Apply migrations
        log_step "Applying migrations to hosted project..."
        if supabase db push; then
            log_success "Migrations applied"
        else
            log_error "Failed to apply migrations"
            exit 1
        fi
        echo ""

        # Extract credentials from linked project
        log_step "Extracting project credentials..."
        SUPABASE_STATUS=$(supabase status 2>/dev/null || true)
        
        # Try to extract from status output
        API_URL=$(echo "$SUPABASE_STATUS" | grep "API URL" | awk '{print $NF}' 2>/dev/null || echo "")
        ANON_KEY=$(echo "$SUPABASE_STATUS" | grep "anon key" | awk '{print $NF}' 2>/dev/null || echo "")

        # If status doesn't have it, construct URL from project-ref
        if [ -z "$API_URL" ]; then
            API_URL="https://${PROJECT_REF}.supabase.co"
            log_info "Constructed API URL from project-ref: $API_URL"
        fi

        # If we still don't have anon key, try to get it from Supabase config
        if [ -z "$ANON_KEY" ]; then
            # Check if there's a config file with the key
            if [ -f "$PROJECT_ROOT/supabase/.temp/project-ref" ]; then
                log_info "Project linked, but anon key not found in status"
                log_info "You may need to get the anon key from Supabase Dashboard"
            fi
        fi

        # Create/update Expo secrets file
        EXPO_ENV_LOCAL="$(get_expo_env_file)"
        log_step "Creating Expo secrets file at $EXPO_ENV_LOCAL..."
        
        if [ -n "$ANON_KEY" ]; then
            cat > "$EXPO_ENV_LOCAL" << EOF
# Auto-generated by init.sh
# Hosted Supabase credentials (project-ref: $PROJECT_REF)

EXPO_PUBLIC_SUPABASE_URL=$API_URL
EXPO_PUBLIC_SUPABASE_ANON_KEY=$ANON_KEY

APP_ENV=development
EOF
            log_success "Expo secrets file created with credentials"
        else
            # Create file with URL but placeholder for key
            cat > "$EXPO_ENV_LOCAL" << EOF
# Auto-generated by init.sh
# Hosted Supabase credentials (project-ref: $PROJECT_REF)
# TODO: Get anon key from Supabase Dashboard → Project Settings → API

EXPO_PUBLIC_SUPABASE_URL=$API_URL
EXPO_PUBLIC_SUPABASE_ANON_KEY=__REPLACE_WITH_ANON_KEY_FROM_DASHBOARD__

APP_ENV=development
EOF
            log_warn "Expo secrets file created, but anon key needs to be set manually"
            log_info "Get your anon key from: https://supabase.com/dashboard/project/$PROJECT_REF/settings/api"
        fi
        echo ""

        # Generate types from hosted project
        log_step "Generating TypeScript types from hosted database schema..."
        if [ -d "$PROJECT_ROOT/packages/types" ]; then
            if supabase gen types typescript --project-id "$PROJECT_REF" > "$PROJECT_ROOT/packages/types/src/database.ts" 2>/dev/null; then
                log_success "Types generated at packages/types/src/database.ts"
            else
                log_warn "Could not generate types from hosted project"
                log_info "You can generate types later with: supabase gen types typescript --project-id $PROJECT_REF"
            fi
        else
            log_warn "packages/types directory not found, skipping type generation"
        fi

        cd "$PROJECT_ROOT"
        echo ""
        log_success "Hosted Supabase setup complete"
        log_info "Next: run './scripts/run.sh mobile' to start the app"
        echo ""

    # -----------------------------------------------------------------------------
    # Pre-configured Hosted Supabase (credentials already present)
    # -----------------------------------------------------------------------------
    elif [ -n "${EXPO_PUBLIC_SUPABASE_URL:-}" ] && [ -n "${EXPO_PUBLIC_SUPABASE_ANON_KEY:-}" ]; then
        EXPO_ENV_LOCAL="$(get_expo_env_file)"
        load_expo_env || true

        HOSTED_URL="${EXPO_PUBLIC_SUPABASE_URL:-}"
        HOSTED_ANON_KEY="${EXPO_PUBLIC_SUPABASE_ANON_KEY:-}"

        if [ -n "$HOSTED_URL" ] && [ -n "$HOSTED_ANON_KEY" ]; then
            log_success "Supabase credentials detected (hosted/preconfigured). Skipping local Supabase startup."
            echo "  URL: $HOSTED_URL"
            echo ""
            log_info "Next: ensure your hosted project has the schema + seed data:"
            echo "  - Run: supabase/migrations/00001_initial_schema.sql"
            echo "  - Run: supabase/seed.sql"
            echo ""
        fi

    # -----------------------------------------------------------------------------
    # Local Supabase Setup (default)
    # -----------------------------------------------------------------------------
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
        
        # Create canonical Expo secrets file (single source of truth).
        EXPO_ENV_LOCAL="$(get_expo_env_file)"
        if [ ! -f "$EXPO_ENV_LOCAL" ]; then
            log_step "Creating Expo secrets file at $EXPO_ENV_LOCAL..."
            cat > "$EXPO_ENV_LOCAL" << EOF
# Auto-generated by init.sh
# Local Supabase credentials from 'supabase status'

EXPO_PUBLIC_SUPABASE_URL=$API_URL
EXPO_PUBLIC_SUPABASE_ANON_KEY=$ANON_KEY

APP_ENV=development
EOF
            log_success "Expo secrets file created"
        else
            log_info "Secrets file already exists, not overwriting:"
            echo "  $EXPO_ENV_LOCAL"
            echo "  Update manually if needed with:"
            echo "  EXPO_PUBLIC_SUPABASE_URL=$API_URL"
            echo "  EXPO_PUBLIC_SUPABASE_ANON_KEY=$ANON_KEY"
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
