#!/bin/bash
# =============================================================================
# Development Server Script
# =============================================================================
# Starts the development environment for detected project stacks.
#
# Usage:
#   ./scripts/run.sh [MODE] [OPTIONS]
#
# Modes:
#   all         Start all detected services (default)
#   backend     Start only backend services (Python, Rust, Go)
#   frontend    Start only frontend services (Node.js)
#   docker      Start with Docker Compose
#
# Options:
#   --help      Show this help message
# =============================================================================

# Don't use set -e because we manage process lifecycle manually

# Source common utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/_common.sh"

# =============================================================================
# CONFIGURATION
# =============================================================================

BACKEND_PORT=${BACKEND_PORT:-8000}
FRONTEND_PORT=${FRONTEND_PORT:-5173}

# Process tracking
BACKEND_PID=""
FRONTEND_PID=""
MOBILE_PID=""

# Log files
BACKEND_LOG="/tmp/${PROJECT_NAME:-project}_backend.log"
FRONTEND_LOG="/tmp/${PROJECT_NAME:-project}_frontend.log"
MOBILE_LOG="/tmp/${PROJECT_NAME:-project}_mobile.log"

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

show_help() {
    echo "Usage: $0 [MODE] [OPTIONS]"
    echo ""
    echo "Start the development environment."
    echo ""
    echo "Modes:"
    echo "  all         Start all detected services (default)"
    echo "  backend     Start only backend services (Python, Rust, Go)"
    echo "  frontend    Start only frontend services (Node.js)"
    echo "  mobile      Start only Expo mobile app (starts Supabase first)"
    echo "  supabase    Start only local Supabase"
    echo "  docker      Start with Docker Compose"
    echo ""
    echo "Options:"
    echo "  --help      Show this help message"
    echo ""
    echo "Environment variables:"
    echo "  BACKEND_PORT   Port for backend server (default: 8000)"
    echo "  FRONTEND_PORT  Port for frontend server (default: 5173)"
    exit 0
}

MODE="all"

for arg in "$@"; do
    case $arg in
        backend|frontend|mobile|supabase|all|docker)
            MODE="$arg"
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
# CLEANUP HANDLER
# =============================================================================

cleanup() {
    echo ""
    log_step "Shutting down..."
    
    if [ -n "$BACKEND_PID" ]; then
        kill "$BACKEND_PID" 2>/dev/null || true
        wait "$BACKEND_PID" 2>/dev/null || true
        log_info "Backend stopped"
    fi
    
    if [ -n "$FRONTEND_PID" ]; then
        kill "$FRONTEND_PID" 2>/dev/null || true
        wait "$FRONTEND_PID" 2>/dev/null || true
        log_info "Frontend stopped"
    fi
    
    if [ -n "$MOBILE_PID" ]; then
        kill "$MOBILE_PID" 2>/dev/null || true
        wait "$MOBILE_PID" 2>/dev/null || true
        log_info "Mobile stopped"
    fi
    
    exit 0
}

trap cleanup SIGINT SIGTERM

# =============================================================================
# BACKEND STARTERS
# =============================================================================

start_python_backend() {
    local python_dir=$(get_python_dir)
    local venv_path=$(get_venv_path)
    
    if [ ! -d "$venv_path" ]; then
        log_error "Virtual environment not found at $venv_path"
        log_info "Run './scripts/init.sh' first"
        return 1
    fi
    
    log_step "Starting Python backend..."
    
    source "$venv_path/bin/activate"
    
    if check_port "$BACKEND_PORT"; then
        log_error "Port $BACKEND_PORT is already in use"
        deactivate
        return 1
    fi
    
    cd "$python_dir"
    
    # Determine run command
    local run_cmd=""
    if [ -n "$RUN_PYTHON_CMD" ]; then
        run_cmd="$RUN_PYTHON_CMD"
    elif [ -f "main.py" ] && grep -q "uvicorn\|fastapi" main.py 2>/dev/null; then
        run_cmd="uvicorn main:app --reload --port $BACKEND_PORT --host 0.0.0.0"
    elif [ -f "app.py" ] && grep -q "flask\|Flask" app.py 2>/dev/null; then
        run_cmd="flask run --port $BACKEND_PORT --host 0.0.0.0"
    elif [ -f "manage.py" ]; then
        run_cmd="python manage.py runserver 0.0.0.0:$BACKEND_PORT"
    elif [ -f "main.py" ]; then
        run_cmd="python main.py"
    elif [ -f "app.py" ]; then
        run_cmd="python app.py"
    else
        log_warn "No recognizable Python entry point found"
        deactivate
        cd "$PROJECT_ROOT"
        return 1
    fi
    
    eval "$run_cmd" > "$BACKEND_LOG" 2>&1 &
    BACKEND_PID=$!
    
    cd "$PROJECT_ROOT"
    
    log_success "Python backend started (PID: $BACKEND_PID)"
    log_info "  URL: http://localhost:$BACKEND_PORT"
    log_info "  Log: tail -f $BACKEND_LOG"
}

start_rust_backend() {
    if check_port "$BACKEND_PORT"; then
        log_error "Port $BACKEND_PORT is already in use"
        return 1
    fi
    
    log_step "Starting Rust backend..."
    
    local run_cmd="${RUN_RUST_CMD:-cargo run}"
    
    eval "$run_cmd" > "$BACKEND_LOG" 2>&1 &
    BACKEND_PID=$!
    
    log_success "Rust backend started (PID: $BACKEND_PID)"
    log_info "  Log: tail -f $BACKEND_LOG"
}

start_go_backend() {
    if check_port "$BACKEND_PORT"; then
        log_error "Port $BACKEND_PORT is already in use"
        return 1
    fi
    
    log_step "Starting Go backend..."
    
    local run_cmd="${RUN_GO_CMD:-go run .}"
    
    eval "$run_cmd" > "$BACKEND_LOG" 2>&1 &
    BACKEND_PID=$!
    
    log_success "Go backend started (PID: $BACKEND_PID)"
    log_info "  Log: tail -f $BACKEND_LOG"
}

# =============================================================================
# FRONTEND STARTER
# =============================================================================

start_node_frontend() {
    local node_dir=$(get_node_dir)
    local run_prefix=$(get_node_run_prefix)
    
    if [ ! -d "$node_dir/node_modules" ]; then
        log_error "node_modules not found in $node_dir"
        log_info "Run './scripts/init.sh' first"
        return 1
    fi
    
    if check_port "$FRONTEND_PORT"; then
        log_error "Port $FRONTEND_PORT is already in use"
        return 1
    fi
    
    log_step "Starting Node.js frontend..."
    
    cd "$node_dir"
    
    # Determine run command
    local run_cmd=""
    if [ -n "$RUN_NODE_CMD" ]; then
        run_cmd="$RUN_NODE_CMD"
    elif grep -q '"dev"' package.json 2>/dev/null; then
        run_cmd="$run_prefix dev"
    elif grep -q '"start"' package.json 2>/dev/null; then
        run_cmd="$run_prefix start"
    else
        log_warn "No 'dev' or 'start' script found in package.json"
        cd "$PROJECT_ROOT"
        return 1
    fi
    
    eval "$run_cmd" > "$FRONTEND_LOG" 2>&1 &
    FRONTEND_PID=$!
    
    cd "$PROJECT_ROOT"
    
    log_success "Node.js frontend started (PID: $FRONTEND_PID)"
    log_info "  URL: http://localhost:$FRONTEND_PORT"
    log_info "  Log: tail -f $FRONTEND_LOG"
}

# =============================================================================
# DOCKER STARTER
# =============================================================================

start_docker() {
    log_step "Starting with Docker Compose..."
    
    local compose_cmd=""
    if [ -n "$RUN_DOCKER_CMD" ]; then
        compose_cmd="$RUN_DOCKER_CMD"
    else
        compose_cmd="docker compose up"
    fi
    
    # Run in foreground for docker
    eval "$compose_cmd"
}

# =============================================================================
# EXPO MOBILE STARTER
# =============================================================================

start_expo_mobile() {
    local expo_dir=$(get_expo_dir)
    local run_prefix=$(get_node_run_prefix)
    
    if [ ! -d "$expo_dir/node_modules" ]; then
        log_error "node_modules not found in $expo_dir"
        log_info "Run './scripts/init.sh' first"
        return 1
    fi
    
    log_step "Starting Expo mobile app..."
    
    cd "$expo_dir"

    # Load env vars for Expo process (so process.env has Supabase creds).
    # We support both `.env.local` (recommended) and `env.local` (common mistake).
    local expo_env_local="$expo_dir/.env.local"
    local expo_env_local_alt="$expo_dir/env.local"
    local root_env_local="$PROJECT_ROOT/.env.local"

    if [ -f "$expo_env_local" ]; then
        log_info "Loading env: $expo_env_local"
        # shellcheck disable=SC1090
        set -a
        source "$expo_env_local"
        set +a
    elif [ -f "$expo_env_local_alt" ]; then
        log_info "Loading env: $expo_env_local_alt"
        # shellcheck disable=SC1090
        set -a
        source "$expo_env_local_alt"
        set +a
    elif [ -f "$root_env_local" ]; then
        log_info "Loading env: $root_env_local"
        # shellcheck disable=SC1090
        set -a
        source "$root_env_local"
        set +a
    fi
    
    # Determine run command
    local run_cmd=""
    if [ -n "$RUN_EXPO_CMD" ]; then
        run_cmd="$RUN_EXPO_CMD"
    else
        run_cmd="$run_prefix dev"
    fi
    
    # Run Expo in foreground (interactive for QR code scanning)
    eval "$run_cmd"
    
    cd "$PROJECT_ROOT"
}

# =============================================================================
# SUPABASE STARTER
# =============================================================================

ensure_supabase_running() {
    if ! is_supabase_enabled; then
        return 0
    fi

    # If the Expo app is configured to use a hosted Supabase project, don't try to
    # start local Supabase (avoids Docker/Supabase CLI warnings for hosted setups).
    #
    # We try to load Expo env file so this works without exporting variables.
    if is_expo_enabled; then
        local expo_env_local="$(get_expo_dir)/.env.local"
        if [ -f "$expo_env_local" ]; then
            # shellcheck disable=SC1090
            set -a
            source "$expo_env_local"
            set +a
        fi
    fi

    local configured_url="${EXPO_PUBLIC_SUPABASE_URL:-${SUPABASE_URL:-}}"
    if [ -n "$configured_url" ]; then
        case "$configured_url" in
            *127.0.0.1*|*localhost*)
                # Local Supabase expected, continue
                ;;
            *)
                log_success "Hosted Supabase detected (SUPABASE_URL is not localhost). Skipping local Supabase startup."
                return 0
                ;;
        esac
    fi
    
    if ! check_command supabase; then
        log_warn "Supabase CLI not installed, skipping Supabase startup"
        return 1
    fi
    
    if ! check_command docker; then
        log_warn "Docker not installed, skipping Supabase startup"
        return 1
    fi
    
    if ! docker info >/dev/null 2>&1; then
        log_warn "Docker is not running, skipping Supabase startup"
        return 1
    fi
    
    if is_supabase_running; then
        log_success "Supabase is already running"
        return 0
    fi
    
    log_step "Starting Supabase..."
    cd "$PROJECT_ROOT"
    supabase start
    
    if is_supabase_running; then
        log_success "Supabase started"
        echo "  API:    http://127.0.0.1:54321"
        echo "  Studio: http://127.0.0.1:54323"
        return 0
    else
        log_error "Failed to start Supabase"
        return 1
    fi
}

start_supabase_only() {
    if ! is_supabase_enabled; then
        log_error "No Supabase configuration found"
        log_info "Expected: supabase/config.toml"
        exit 1
    fi
    
    ensure_supabase_running
    
    echo ""
    log_success "Supabase is running"
    echo ""
    echo "Services:"
    echo "  API URL:     http://127.0.0.1:54321"
    echo "  Studio:      http://127.0.0.1:54323"
    echo "  Inbucket:    http://127.0.0.1:54324"
    echo ""
    echo "Run 'supabase status' to see all service URLs and credentials"
    echo "Run 'supabase stop' to stop Supabase"
}

# =============================================================================
# MAIN
# =============================================================================

log_header "${PROJECT_NAME:-Project} - Development Server"
echo ""

case $MODE in
    docker)
        if is_docker_enabled; then
            start_docker
        else
            log_error "No Docker configuration found"
            exit 1
        fi
        ;;
    
    backend)
        if is_python_enabled; then
            start_python_backend
        elif is_rust_enabled; then
            start_rust_backend
        elif is_go_enabled; then
            start_go_backend
        else
            log_error "No backend stack detected"
            exit 1
        fi
        
        echo ""
        log_success "Backend running. Press Ctrl+C to stop"
        wait "$BACKEND_PID" 2>/dev/null || true
        ;;
    
    frontend)
        if is_node_enabled; then
            start_node_frontend
        else
            log_error "No frontend stack detected"
            exit 1
        fi
        
        echo ""
        log_success "Frontend running. Press Ctrl+C to stop"
        wait "$FRONTEND_PID" 2>/dev/null || true
        ;;
    
    mobile)
        if is_expo_enabled; then
            # Ensure Supabase is running before starting mobile
            if is_supabase_enabled; then
                ensure_supabase_running || log_warn "Supabase not started, continuing anyway..."
                echo ""
            fi
            start_expo_mobile
        else
            log_error "No Expo mobile app detected"
            log_info "Expected: apps/mobile/app.json"
            exit 1
        fi
        ;;
    
    supabase)
        start_supabase_only
        ;;
    
    all|*)
        started=false
        
        # Start backend
        if is_python_enabled; then
            start_python_backend && started=true
            echo ""
        elif is_rust_enabled; then
            start_rust_backend && started=true
            echo ""
        elif is_go_enabled; then
            start_go_backend && started=true
            echo ""
        fi
        
        # Start frontend
        if is_node_enabled; then
            start_node_frontend && started=true
            echo ""
        fi
        
        # Start mobile (Expo runs in foreground, so check it last)
        if is_expo_enabled; then
            if [ "$started" = true ]; then
                log_info "Mobile app detected. Run './scripts/run.sh mobile' separately for Expo."
            else
                start_expo_mobile
                started=true
            fi
        fi
        
        if [ "$started" = false ]; then
            log_error "No services could be started"
            log_info "Make sure you have run './scripts/init.sh' first"
            exit 1
        fi
        
        # Only show "running" message if we have background processes
        if [ -n "$BACKEND_PID" ] || [ -n "$FRONTEND_PID" ]; then
            log_success "All services running. Press Ctrl+C to stop"
            echo ""
        fi
        
        # Wait for all processes
        if [ -n "$BACKEND_PID" ] && [ -n "$FRONTEND_PID" ]; then
            wait "$BACKEND_PID" "$FRONTEND_PID" 2>/dev/null || true
        elif [ -n "$BACKEND_PID" ]; then
            wait "$BACKEND_PID" 2>/dev/null || true
        elif [ -n "$FRONTEND_PID" ]; then
            wait "$FRONTEND_PID" 2>/dev/null || true
        fi
        ;;
esac
