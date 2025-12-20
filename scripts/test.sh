#!/bin/bash
# =============================================================================
# Test Suite Script
# =============================================================================
# Runs tests, linting, and type checking for detected project stacks.
#
# Usage:
#   ./scripts/test.sh [MODE] [OPTIONS]
#
# Modes:
#   all         Run all checks (default)
#   backend     Run backend tests only
#   frontend    Run frontend tests only
#   lint        Run linting only
#   format      Run format checking only
#   type-check  Run type checking only
#
# Options:
#   --quick     Skip slow checks (type-check, format)
#   --help      Show this help message
# =============================================================================

# Don't use set -e because we want to collect all failures

# Source common utilities
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/_common.sh"

# =============================================================================
# STATE
# =============================================================================

EXIT_CODE=0
QUICK_MODE=false

# =============================================================================
# ARGUMENT PARSING
# =============================================================================

show_help() {
    echo "Usage: $0 [MODE] [OPTIONS]"
    echo ""
    echo "Run tests and checks for the project."
    echo ""
    echo "Modes:"
    echo "  all         Run all checks (default)"
    echo "  backend     Run backend tests only"
    echo "  frontend    Run frontend tests only"
    echo "  lint        Run linting only"
    echo "  format      Run format checking only"
    echo "  type-check  Run type checking only"
    echo ""
    echo "Options:"
    echo "  --quick     Skip slow checks (type-check, format)"
    echo "  --help      Show this help message"
    echo ""
    echo "Exit codes:"
    echo "  0  All checks passed"
    echo "  1  One or more checks failed"
    exit 0
}

MODE="all"

for arg in "$@"; do
    case $arg in
        backend|frontend|lint|format|type-check|all)
            MODE="$arg"
            ;;
        --quick|-q)
            QUICK_MODE=true
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
# PYTHON TESTS
# =============================================================================

run_python_tests() {
    local python_dir=$(get_python_dir)
    local venv_path=$(get_venv_path)
    
    if [ ! -d "$venv_path" ]; then
        log_warn "Virtual environment not found. Skipping Python tests"
        return 1
    fi
    
    log_header "Python Tests"
    
    source "$venv_path/bin/activate"
    
    # Check for test command
    local test_cmd=""
    if [ -n "$TEST_PYTHON_CMD" ]; then
        test_cmd="$TEST_PYTHON_CMD"
    elif python -m pytest --version &>/dev/null; then
        # Look for test directories
        if [ -d "$python_dir/tests" ]; then
            test_cmd="python -m pytest $python_dir/tests -v --tb=short"
        elif [ -d "$python_dir/test" ]; then
            test_cmd="python -m pytest $python_dir/test -v --tb=short"
        elif find "$python_dir" -name "test_*.py" -o -name "*_test.py" 2>/dev/null | grep -q .; then
            test_cmd="python -m pytest $python_dir -v --tb=short"
        else
            log_warn "No Python test files found"
            deactivate
            return 0
        fi
    else
        log_warn "pytest not installed. Skipping Python tests"
        deactivate
        return 1
    fi
    
    log_step "Running: $test_cmd"
    if eval "$test_cmd"; then
        log_success "Python tests passed"
    else
        log_error "Python tests failed"
        EXIT_CODE=1
    fi
    
    deactivate
    echo ""
}

run_python_lint() {
    local python_dir=$(get_python_dir)
    local venv_path=$(get_venv_path)
    
    if [ ! -d "$venv_path" ]; then
        return 1
    fi
    
    log_header "Python Linting"
    
    source "$venv_path/bin/activate"
    
    local lint_cmd=""
    if [ -n "$LINT_PYTHON_CMD" ]; then
        lint_cmd="$LINT_PYTHON_CMD"
    elif python -m ruff --version &>/dev/null; then
        lint_cmd="python -m ruff check $python_dir"
    elif python -m flake8 --version &>/dev/null; then
        lint_cmd="python -m flake8 $python_dir --max-line-length=100"
    elif python -m pylint --version &>/dev/null; then
        lint_cmd="python -m pylint $python_dir"
    else
        log_warn "No Python linter installed (ruff, flake8, or pylint)"
        deactivate
        return 1
    fi
    
    log_step "Running: $lint_cmd"
    if eval "$lint_cmd"; then
        log_success "Python linting passed"
    else
        log_error "Python linting failed"
        EXIT_CODE=1
    fi
    
    deactivate
    echo ""
}

run_python_format() {
    local python_dir=$(get_python_dir)
    local venv_path=$(get_venv_path)
    
    if [ ! -d "$venv_path" ]; then
        return 1
    fi
    
    log_header "Python Format Check"
    
    source "$venv_path/bin/activate"
    
    local format_cmd=""
    if [ -n "$FORMAT_PYTHON_CMD" ]; then
        format_cmd="$FORMAT_PYTHON_CMD --check"
    elif python -m ruff --version &>/dev/null; then
        format_cmd="python -m ruff format --check $python_dir"
    elif python -m black --version &>/dev/null; then
        format_cmd="python -m black --check $python_dir"
    else
        log_warn "No Python formatter installed (ruff or black)"
        deactivate
        return 1
    fi
    
    log_step "Running: $format_cmd"
    if eval "$format_cmd"; then
        log_success "Python formatting check passed"
    else
        log_error "Python formatting check failed"
        EXIT_CODE=1
    fi
    
    deactivate
    echo ""
}

run_python_typecheck() {
    local python_dir=$(get_python_dir)
    local venv_path=$(get_venv_path)
    
    if [ ! -d "$venv_path" ]; then
        return 1
    fi
    
    log_header "Python Type Checking"
    
    source "$venv_path/bin/activate"
    
    local typecheck_cmd=""
    if [ -n "$TYPECHECK_PYTHON_CMD" ]; then
        typecheck_cmd="$TYPECHECK_PYTHON_CMD"
    elif python -m mypy --version &>/dev/null; then
        typecheck_cmd="python -m mypy $python_dir --ignore-missing-imports"
    elif python -m pyright --version &>/dev/null; then
        typecheck_cmd="python -m pyright $python_dir"
    else
        log_warn "No Python type checker installed (mypy or pyright)"
        deactivate
        return 1
    fi
    
    log_step "Running: $typecheck_cmd"
    if eval "$typecheck_cmd"; then
        log_success "Python type checking passed"
    else
        log_error "Python type checking failed"
        EXIT_CODE=1
    fi
    
    deactivate
    echo ""
}

# =============================================================================
# NODE.JS TESTS
# =============================================================================

run_node_tests() {
    local node_dir=$(get_node_dir)
    local run_prefix=$(get_node_run_prefix)
    
    if [ ! -d "$node_dir/node_modules" ]; then
        log_warn "node_modules not found. Skipping Node.js tests"
        return 1
    fi
    
    log_header "Node.js Tests"
    
    cd "$node_dir"
    
    local test_cmd=""
    if [ -n "$TEST_NODE_CMD" ]; then
        test_cmd="$TEST_NODE_CMD"
    elif grep -q '"test"' package.json 2>/dev/null; then
        # Check if vitest (add --run for non-watch mode)
        if grep -q 'vitest' package.json 2>/dev/null; then
            test_cmd="$run_prefix test -- --run"
        else
            test_cmd="$run_prefix test"
        fi
    else
        log_warn "No test script found in package.json"
        cd "$PROJECT_ROOT"
        return 0
    fi
    
    log_step "Running: $test_cmd"
    if eval "$test_cmd"; then
        log_success "Node.js tests passed"
    else
        log_error "Node.js tests failed"
        EXIT_CODE=1
    fi
    
    cd "$PROJECT_ROOT"
    echo ""
}

run_node_lint() {
    local node_dir=$(get_node_dir)
    local run_prefix=$(get_node_run_prefix)
    
    if [ ! -d "$node_dir/node_modules" ]; then
        return 1
    fi
    
    log_header "Node.js Linting"
    
    cd "$node_dir"
    
    local lint_cmd=""
    if [ -n "$LINT_NODE_CMD" ]; then
        lint_cmd="$LINT_NODE_CMD"
    elif grep -q '"lint"' package.json 2>/dev/null; then
        lint_cmd="$run_prefix lint"
    elif [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f "eslint.config.js" ]; then
        lint_cmd="npx eslint ."
    else
        log_warn "No lint script or ESLint config found"
        cd "$PROJECT_ROOT"
        return 1
    fi
    
    log_step "Running: $lint_cmd"
    if eval "$lint_cmd"; then
        log_success "Node.js linting passed"
    else
        log_error "Node.js linting failed"
        EXIT_CODE=1
    fi
    
    cd "$PROJECT_ROOT"
    echo ""
}

run_node_format() {
    local node_dir=$(get_node_dir)
    local run_prefix=$(get_node_run_prefix)
    
    if [ ! -d "$node_dir/node_modules" ]; then
        return 1
    fi
    
    log_header "Node.js Format Check"
    
    cd "$node_dir"
    
    local format_cmd=""
    if [ -n "$FORMAT_NODE_CMD" ]; then
        format_cmd="$FORMAT_NODE_CMD"
    elif grep -q '"format:check"' package.json 2>/dev/null; then
        format_cmd="$run_prefix format:check"
    elif grep -q '"format"' package.json 2>/dev/null && grep -q 'prettier' package.json 2>/dev/null; then
        # Try to run format with --check
        format_cmd="npx prettier --check ."
    elif [ -f ".prettierrc" ] || [ -f ".prettierrc.json" ] || [ -f "prettier.config.js" ]; then
        format_cmd="npx prettier --check ."
    else
        log_warn "No format script or Prettier config found"
        cd "$PROJECT_ROOT"
        return 1
    fi
    
    log_step "Running: $format_cmd"
    if eval "$format_cmd"; then
        log_success "Node.js formatting check passed"
    else
        log_error "Node.js formatting check failed"
        EXIT_CODE=1
    fi
    
    cd "$PROJECT_ROOT"
    echo ""
}

run_node_typecheck() {
    local node_dir=$(get_node_dir)
    local run_prefix=$(get_node_run_prefix)
    
    if [ ! -d "$node_dir/node_modules" ]; then
        return 1
    fi
    
    log_header "Node.js Type Checking"
    
    cd "$node_dir"
    
    local typecheck_cmd=""
    if [ -n "$TYPECHECK_NODE_CMD" ]; then
        typecheck_cmd="$TYPECHECK_NODE_CMD"
    elif grep -q '"type-check"' package.json 2>/dev/null; then
        typecheck_cmd="$run_prefix type-check"
    elif grep -q '"typecheck"' package.json 2>/dev/null; then
        typecheck_cmd="$run_prefix typecheck"
    elif [ -f "tsconfig.json" ]; then
        typecheck_cmd="npx tsc --noEmit"
    else
        log_warn "No TypeScript config found"
        cd "$PROJECT_ROOT"
        return 1
    fi
    
    log_step "Running: $typecheck_cmd"
    if eval "$typecheck_cmd"; then
        log_success "Node.js type checking passed"
    else
        log_error "Node.js type checking failed"
        EXIT_CODE=1
    fi
    
    cd "$PROJECT_ROOT"
    echo ""
}

# =============================================================================
# RUST TESTS
# =============================================================================

run_rust_tests() {
    if ! check_command cargo; then
        return 1
    fi
    
    log_header "Rust Tests"
    
    local test_cmd="${TEST_RUST_CMD:-cargo test}"
    
    log_step "Running: $test_cmd"
    if eval "$test_cmd"; then
        log_success "Rust tests passed"
    else
        log_error "Rust tests failed"
        EXIT_CODE=1
    fi
    
    echo ""
}

run_rust_lint() {
    if ! check_command cargo; then
        return 1
    fi
    
    log_header "Rust Linting"
    
    local lint_cmd="${LINT_RUST_CMD:-cargo clippy -- -D warnings}"
    
    log_step "Running: $lint_cmd"
    if eval "$lint_cmd"; then
        log_success "Rust linting passed"
    else
        log_error "Rust linting failed"
        EXIT_CODE=1
    fi
    
    echo ""
}

run_rust_format() {
    if ! check_command cargo; then
        return 1
    fi
    
    log_header "Rust Format Check"
    
    local format_cmd="${FORMAT_RUST_CMD:-cargo fmt -- --check}"
    
    log_step "Running: $format_cmd"
    if eval "$format_cmd"; then
        log_success "Rust formatting check passed"
    else
        log_error "Rust formatting check failed"
        EXIT_CODE=1
    fi
    
    echo ""
}

# =============================================================================
# GO TESTS
# =============================================================================

run_go_tests() {
    if ! check_command go; then
        return 1
    fi
    
    log_header "Go Tests"
    
    local test_cmd="${TEST_GO_CMD:-go test ./...}"
    
    log_step "Running: $test_cmd"
    if eval "$test_cmd"; then
        log_success "Go tests passed"
    else
        log_error "Go tests failed"
        EXIT_CODE=1
    fi
    
    echo ""
}

run_go_lint() {
    log_header "Go Linting"
    
    local lint_cmd=""
    if [ -n "$LINT_GO_CMD" ]; then
        lint_cmd="$LINT_GO_CMD"
    elif check_command golangci-lint; then
        lint_cmd="golangci-lint run"
    elif check_command go; then
        lint_cmd="go vet ./..."
    else
        log_warn "No Go linter available"
        return 1
    fi
    
    log_step "Running: $lint_cmd"
    if eval "$lint_cmd"; then
        log_success "Go linting passed"
    else
        log_error "Go linting failed"
        EXIT_CODE=1
    fi
    
    echo ""
}

run_go_format() {
    if ! check_command gofmt; then
        return 1
    fi
    
    log_header "Go Format Check"
    
    log_step "Checking Go formatting..."
    
    local unformatted=$(gofmt -l .)
    if [ -z "$unformatted" ]; then
        log_success "Go formatting check passed"
    else
        log_error "Go formatting check failed"
        echo "Unformatted files:"
        echo "$unformatted"
        EXIT_CODE=1
    fi
    
    echo ""
}

# =============================================================================
# COMPOSITE RUNNERS
# =============================================================================

run_all_tests() {
    if is_python_enabled; then
        run_python_tests
    fi
    
    if is_node_enabled; then
        run_node_tests
    fi
    
    if is_rust_enabled; then
        run_rust_tests
    fi
    
    if is_go_enabled; then
        run_go_tests
    fi
}

run_all_lint() {
    if is_python_enabled; then
        run_python_lint
    fi
    
    if is_node_enabled; then
        run_node_lint
    fi
    
    if is_rust_enabled; then
        run_rust_lint
    fi
    
    if is_go_enabled; then
        run_go_lint
    fi
}

run_all_format() {
    if is_python_enabled; then
        run_python_format
    fi
    
    if is_node_enabled; then
        run_node_format
    fi
    
    if is_rust_enabled; then
        run_rust_format
    fi
    
    if is_go_enabled; then
        run_go_format
    fi
}

run_all_typecheck() {
    if is_python_enabled; then
        run_python_typecheck
    fi
    
    if is_node_enabled; then
        run_node_typecheck
    fi
    # Rust and Go have built-in type checking via the compiler
}

run_backend_all() {
    if is_python_enabled; then
        run_python_tests
        run_python_lint
        if [ "$QUICK_MODE" = false ]; then
            run_python_format
            run_python_typecheck
        fi
    fi
    
    if is_rust_enabled; then
        run_rust_tests
        run_rust_lint
        if [ "$QUICK_MODE" = false ]; then
            run_rust_format
        fi
    fi
    
    if is_go_enabled; then
        run_go_tests
        run_go_lint
        if [ "$QUICK_MODE" = false ]; then
            run_go_format
        fi
    fi
}

run_frontend_all() {
    if is_node_enabled; then
        run_node_tests
        run_node_lint
        if [ "$QUICK_MODE" = false ]; then
            run_node_format
            run_node_typecheck
        fi
    fi
}

# =============================================================================
# MAIN
# =============================================================================

log_header "${PROJECT_NAME:-Project} - Test Suite"
echo ""

if [ "$QUICK_MODE" = true ]; then
    log_info "Quick mode: skipping type checking and format checks"
    echo ""
fi

print_detected_stacks

case $MODE in
    backend)
        run_backend_all
        ;;
    
    frontend)
        run_frontend_all
        ;;
    
    lint)
        run_all_lint
        ;;
    
    format)
        run_all_format
        ;;
    
    type-check)
        run_all_typecheck
        ;;
    
    all|*)
        run_all_tests
        run_all_lint
        if [ "$QUICK_MODE" = false ]; then
            run_all_format
            run_all_typecheck
        fi
        ;;
esac

# =============================================================================
# SUMMARY
# =============================================================================

echo ""
log_header "Test Summary"

if [ $EXIT_CODE -eq 0 ]; then
    log_success "All checks passed!"
else
    log_error "Some checks failed"
fi

exit $EXIT_CODE
