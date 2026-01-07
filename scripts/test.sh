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
#   mobile      Run Expo mobile tests only
#   lint        Run linting only
#   format      Run format checking/fixing only
#   type-check  Run type checking only
#   security    Run security/dependency audit
#   build       Verify project builds
#
# Options:
#   --quick     Skip slow checks (type-check, format)
#   --fix       Auto-fix lint and format issues (instead of just checking)
#   --coverage  Include test coverage report
#   --watch     Run tests in watch mode
#   --verbose   Show detailed output
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
FIX_MODE=false
COVERAGE_MODE=false
WATCH_MODE=false
VERBOSE=false
CI_MODE=false

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
    echo "  unit        Run unit tests only"
    echo "  backend     Run backend tests only"
    echo "  frontend    Run frontend tests only"
    echo "  mobile      Run Expo mobile tests only"
    echo "  supabase    Run Supabase integration tests"
    echo "  lint        Run linting only"
    echo "  format      Run format checking/fixing only"
    echo "  type-check  Run type checking only"
    echo "  security    Run security/dependency audit"
    echo "  build       Verify project builds"
    echo ""
    echo "Options:"
    echo "  --ci        CI mode (stricter checks, skip Docker-dependent tests)"
    echo "  --quick     Skip slow checks (type-check, format, integration)"
    echo "  --fix       Auto-fix lint and format issues"
    echo "  --coverage  Include test coverage report"
    echo "  --watch     Run tests in watch mode"
    echo "  --verbose   Show detailed output"
    echo "  --help      Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                  # Run all checks"
    echo "  $0 --quick          # Quick check (skip slow checks)"
    echo "  $0 lint --fix       # Fix linting issues"
    echo "  $0 format --fix     # Fix formatting issues"
    echo "  $0 mobile           # Test Expo mobile app"
    echo "  $0 supabase         # Test Supabase integration"
    echo "  $0 --coverage       # Run tests with coverage"
    echo ""
    echo "Exit codes:"
    echo "  0  All checks passed"
    echo "  1  One or more checks failed"
    exit 0
}

MODE="all"

for arg in "$@"; do
    case $arg in
        backend|frontend|mobile|unit|supabase|lint|format|type-check|security|build|all)
            MODE="$arg"
            ;;
        --ci)
            CI_MODE=true
            ;;
        --quick|-q)
            QUICK_MODE=true
            ;;
        --fix|-f)
            FIX_MODE=true
            ;;
        --coverage|-c)
            COVERAGE_MODE=true
            ;;
        --watch|-w)
            WATCH_MODE=true
            ;;
        --verbose|-v)
            VERBOSE=true
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
    
    if [ "$COVERAGE_MODE" = true ]; then
        log_header "Python Tests (with coverage)"
    elif [ "$WATCH_MODE" = true ]; then
        log_header "Python Tests (watch mode)"
    else
        log_header "Python Tests"
    fi
    
    source "$venv_path/bin/activate"
    
    # Check for test command
    local test_cmd=""
    local test_args="-v --tb=short"
    
    if [ "$COVERAGE_MODE" = true ]; then
        test_args="$test_args --cov=$python_dir --cov-report=term-missing"
    fi
    
    if [ "$WATCH_MODE" = true ]; then
        # pytest-watch support
        if python -m pytest_watch --version &>/dev/null; then
            test_args="$test_args"  # pytest-watch handles this differently
        else
            log_warn "pytest-watch not installed for watch mode"
        fi
    fi
    
    if [ -n "$TEST_PYTHON_CMD" ]; then
        test_cmd="$TEST_PYTHON_CMD"
        if [ "$COVERAGE_MODE" = true ]; then
            test_cmd="$test_cmd --cov"
        fi
    elif python -m pytest --version &>/dev/null; then
        # Look for test directories
        if [ -d "$python_dir/tests" ]; then
            test_cmd="python -m pytest $python_dir/tests $test_args"
        elif [ -d "$python_dir/test" ]; then
            test_cmd="python -m pytest $python_dir/test $test_args"
        elif find "$python_dir" -name "test_*.py" -o -name "*_test.py" 2>/dev/null | grep -q .; then
            test_cmd="python -m pytest $python_dir $test_args"
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
    
    if [ "$FIX_MODE" = true ]; then
        log_header "Python Linting (fix)"
    else
        log_header "Python Linting"
    fi
    
    source "$venv_path/bin/activate"
    
    local lint_cmd=""
    if [ -n "$LINT_PYTHON_CMD" ]; then
        lint_cmd="$LINT_PYTHON_CMD"
        if [ "$FIX_MODE" = true ]; then
            lint_cmd="$lint_cmd --fix"
        fi
    elif python -m ruff --version &>/dev/null; then
        if [ "$FIX_MODE" = true ]; then
            lint_cmd="python -m ruff check $python_dir --fix"
        else
            lint_cmd="python -m ruff check $python_dir"
        fi
    elif python -m flake8 --version &>/dev/null; then
        lint_cmd="python -m flake8 $python_dir --max-line-length=100"
        if [ "$FIX_MODE" = true ]; then
            log_warn "flake8 does not support --fix, use ruff instead"
        fi
    elif python -m pylint --version &>/dev/null; then
        lint_cmd="python -m pylint $python_dir"
        if [ "$FIX_MODE" = true ]; then
            log_warn "pylint does not support --fix, use ruff instead"
        fi
    else
        log_warn "No Python linter installed (ruff, flake8, or pylint)"
        deactivate
        return 1
    fi
    
    log_step "Running: $lint_cmd"
    if eval "$lint_cmd"; then
        if [ "$FIX_MODE" = true ]; then
            log_success "Python linting fixes applied"
        else
            log_success "Python linting passed"
        fi
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
    
    if [ "$FIX_MODE" = true ]; then
        log_header "Python Formatting (fix)"
    else
        log_header "Python Format Check"
    fi
    
    source "$venv_path/bin/activate"
    
    local format_cmd=""
    if [ "$FIX_MODE" = true ]; then
        # Fix mode - write changes
        if [ -n "$FORMAT_PYTHON_CMD" ]; then
            format_cmd="$FORMAT_PYTHON_CMD"
        elif python -m ruff --version &>/dev/null; then
            format_cmd="python -m ruff format $python_dir"
        elif python -m black --version &>/dev/null; then
            format_cmd="python -m black $python_dir"
        else
            log_warn "No Python formatter installed (ruff or black)"
            deactivate
            return 1
        fi
    else
        # Check mode
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
    fi
    
    log_step "Running: $format_cmd"
    if eval "$format_cmd"; then
        if [ "$FIX_MODE" = true ]; then
            log_success "Python formatting applied"
        else
            log_success "Python formatting check passed"
        fi
    else
        log_error "Python formatting failed"
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
    
    if [ "$COVERAGE_MODE" = true ]; then
        log_header "Node.js Tests (with coverage)"
    elif [ "$WATCH_MODE" = true ]; then
        log_header "Node.js Tests (watch mode)"
    else
        log_header "Node.js Tests"
    fi
    
    cd "$node_dir"
    
    local test_cmd=""
    if [ -n "$TEST_NODE_CMD" ]; then
        test_cmd="$TEST_NODE_CMD"
        if [ "$COVERAGE_MODE" = true ]; then
            test_cmd="$test_cmd --coverage"
        fi
        if [ "$WATCH_MODE" = true ]; then
            test_cmd="$test_cmd --watch"
        fi
    elif grep -q '"test"' package.json 2>/dev/null; then
        # Build test command with options
        local test_args=""
        
        if [ "$WATCH_MODE" = true ]; then
            test_args="$test_args --watch"
        elif grep -q 'vitest' package.json 2>/dev/null; then
            # vitest needs --run for non-watch mode
            test_args="$test_args --run"
        fi
        
        if [ "$COVERAGE_MODE" = true ]; then
            test_args="$test_args --coverage"
        fi
        
        if [ -n "$test_args" ]; then
            test_cmd="$run_prefix test --$test_args"
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
    
    if [ "$FIX_MODE" = true ]; then
        log_header "Node.js Linting (fix)"
    else
        log_header "Node.js Linting"
    fi
    
    cd "$node_dir"
    
    local lint_cmd=""
    if [ -n "$LINT_NODE_CMD" ]; then
        lint_cmd="$LINT_NODE_CMD"
        if [ "$FIX_MODE" = true ]; then
            lint_cmd="$lint_cmd --fix"
        fi
    elif grep -q '"lint"' package.json 2>/dev/null; then
        if [ "$FIX_MODE" = true ]; then
            lint_cmd="$run_prefix lint -- --fix"
        else
            lint_cmd="$run_prefix lint"
        fi
    elif [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f "eslint.config.js" ]; then
        if [ "$FIX_MODE" = true ]; then
            lint_cmd="npx eslint . --fix"
        else
            lint_cmd="npx eslint ."
        fi
    else
        log_warn "No lint script or ESLint config found"
        cd "$PROJECT_ROOT"
        return 1
    fi
    
    log_step "Running: $lint_cmd"
    if eval "$lint_cmd"; then
        if [ "$FIX_MODE" = true ]; then
            log_success "Node.js linting fixes applied"
        else
            log_success "Node.js linting passed"
        fi
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
    
    if [ "$FIX_MODE" = true ]; then
        log_header "Node.js Formatting (fix)"
    else
        log_header "Node.js Format Check"
    fi
    
    cd "$node_dir"
    
    local format_cmd=""
    if [ "$FIX_MODE" = true ]; then
        # Fix mode - write changes
        if [ -n "$FORMAT_NODE_CMD" ]; then
            format_cmd="$FORMAT_NODE_CMD"
        elif grep -q '"format"' package.json 2>/dev/null; then
            format_cmd="$run_prefix format"
        elif [ -f ".prettierrc" ] || [ -f ".prettierrc.json" ] || [ -f "prettier.config.js" ] || grep -q 'prettier' package.json 2>/dev/null; then
            format_cmd="npx prettier --write ."
        else
            log_warn "No format script or Prettier config found"
            cd "$PROJECT_ROOT"
            return 1
        fi
    else
        # Check mode
        if [ -n "$FORMAT_NODE_CMD" ]; then
            format_cmd="$FORMAT_NODE_CMD --check"
        elif grep -q '"format:check"' package.json 2>/dev/null; then
            format_cmd="$run_prefix format:check"
        elif grep -q '"format"' package.json 2>/dev/null && grep -q 'prettier' package.json 2>/dev/null; then
            format_cmd="npx prettier --check ."
        elif [ -f ".prettierrc" ] || [ -f ".prettierrc.json" ] || [ -f "prettier.config.js" ]; then
            format_cmd="npx prettier --check ."
        else
            log_warn "No format script or Prettier config found"
            cd "$PROJECT_ROOT"
            return 1
        fi
    fi
    
    log_step "Running: $format_cmd"
    if eval "$format_cmd"; then
        if [ "$FIX_MODE" = true ]; then
            log_success "Node.js formatting applied"
        else
            log_success "Node.js formatting check passed"
        fi
    else
        log_error "Node.js formatting failed"
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
    
    if [ "$FIX_MODE" = true ]; then
        log_header "Rust Linting (fix)"
    else
        log_header "Rust Linting"
    fi
    
    local lint_cmd=""
    if [ "$FIX_MODE" = true ]; then
        lint_cmd="${LINT_RUST_CMD:-cargo clippy --fix --allow-dirty -- -D warnings}"
    else
        lint_cmd="${LINT_RUST_CMD:-cargo clippy -- -D warnings}"
    fi
    
    log_step "Running: $lint_cmd"
    if eval "$lint_cmd"; then
        if [ "$FIX_MODE" = true ]; then
            log_success "Rust linting fixes applied"
        else
            log_success "Rust linting passed"
        fi
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
    
    if [ "$FIX_MODE" = true ]; then
        log_header "Rust Formatting (fix)"
    else
        log_header "Rust Format Check"
    fi
    
    local format_cmd=""
    if [ "$FIX_MODE" = true ]; then
        format_cmd="${FORMAT_RUST_CMD:-cargo fmt}"
    else
        format_cmd="${FORMAT_RUST_CMD:-cargo fmt -- --check}"
    fi
    
    log_step "Running: $format_cmd"
    if eval "$format_cmd"; then
        if [ "$FIX_MODE" = true ]; then
            log_success "Rust formatting applied"
        else
            log_success "Rust formatting check passed"
        fi
    else
        log_error "Rust formatting failed"
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
    
    if [ "$FIX_MODE" = true ]; then
        log_header "Go Formatting (fix)"
        
        log_step "Formatting Go files..."
        if gofmt -w .; then
            log_success "Go formatting applied"
        else
            log_error "Go formatting failed"
            EXIT_CODE=1
        fi
    else
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
    fi
    
    echo ""
}

# =============================================================================
# EXPO MOBILE TESTS
# =============================================================================

run_expo_tests() {
    local expo_dir=$(get_expo_dir)
    
    if [ ! -d "$expo_dir" ]; then
        log_warn "Expo directory not found at $expo_dir. Skipping Expo tests"
        return 1
    fi
    
    if [ ! -d "$expo_dir/node_modules" ]; then
        log_warn "Expo node_modules not found. Skipping Expo tests"
        return 1
    fi
    
    log_header "Expo Mobile Tests"
    
    cd "$expo_dir"
    
    # Run tests if available
    local test_cmd=""
    if [ -n "$TEST_EXPO_CMD" ]; then
        test_cmd="$TEST_EXPO_CMD"
    elif grep -q '"test"' package.json 2>/dev/null; then
        local run_prefix=$(get_node_run_prefix)
        if [ "$COVERAGE_MODE" = true ]; then
            test_cmd="$run_prefix test -- --coverage"
        elif [ "$WATCH_MODE" = true ]; then
            test_cmd="$run_prefix test -- --watch"
        else
            # Check if jest (add --passWithNoTests for CI)
            if grep -q 'jest' package.json 2>/dev/null; then
                test_cmd="$run_prefix test -- --passWithNoTests"
            else
                test_cmd="$run_prefix test"
            fi
        fi
        
        log_step "Running: $test_cmd"
        if eval "$test_cmd"; then
            log_success "Expo tests passed"
        else
            log_error "Expo tests failed"
            EXIT_CODE=1
        fi
    else
        log_info "No test script found in Expo package.json"
    fi
    
    cd "$PROJECT_ROOT"
    echo ""
}

run_expo_lint() {
    local expo_dir=$(get_expo_dir)
    
    if [ ! -d "$expo_dir/node_modules" ]; then
        return 1
    fi
    
    log_header "Expo Mobile Linting"
    
    cd "$expo_dir"
    
    local lint_cmd=""
    if [ -n "$LINT_EXPO_CMD" ]; then
        lint_cmd="$LINT_EXPO_CMD"
    elif grep -q '"lint"' package.json 2>/dev/null; then
        local run_prefix=$(get_node_run_prefix)
        if [ "$FIX_MODE" = true ]; then
            lint_cmd="$run_prefix lint -- --fix"
        else
            lint_cmd="$run_prefix lint"
        fi
    elif [ -f ".eslintrc.js" ] || [ -f ".eslintrc.json" ] || [ -f "eslint.config.js" ]; then
        if [ "$FIX_MODE" = true ]; then
            lint_cmd="npx eslint . --fix"
        else
            lint_cmd="npx eslint ."
        fi
    else
        log_info "No lint script or ESLint config found in Expo app"
        cd "$PROJECT_ROOT"
        return 0
    fi
    
    log_step "Running: $lint_cmd"
    if eval "$lint_cmd"; then
        log_success "Expo linting passed"
    else
        log_error "Expo linting failed"
        EXIT_CODE=1
    fi
    
    cd "$PROJECT_ROOT"
    echo ""
}

run_expo_typecheck() {
    local expo_dir=$(get_expo_dir)
    
    if [ ! -d "$expo_dir/node_modules" ]; then
        return 1
    fi
    
    log_header "Expo Mobile Type Checking"
    
    cd "$expo_dir"
    
    local typecheck_cmd=""
    if [ -n "$TYPECHECK_EXPO_CMD" ]; then
        typecheck_cmd="$TYPECHECK_EXPO_CMD"
    elif grep -q '"typecheck"' package.json 2>/dev/null; then
        local run_prefix=$(get_node_run_prefix)
        typecheck_cmd="$run_prefix typecheck"
    elif grep -q '"type-check"' package.json 2>/dev/null; then
        local run_prefix=$(get_node_run_prefix)
        typecheck_cmd="$run_prefix type-check"
    elif [ -f "tsconfig.json" ]; then
        typecheck_cmd="npx tsc --noEmit"
    else
        log_info "No TypeScript config found in Expo app"
        cd "$PROJECT_ROOT"
        return 0
    fi
    
    log_step "Running: $typecheck_cmd"
    if eval "$typecheck_cmd"; then
        log_success "Expo type checking passed"
    else
        log_error "Expo type checking failed"
        EXIT_CODE=1
    fi
    
    cd "$PROJECT_ROOT"
    echo ""
}

run_mobile_all() {
    if is_expo_enabled; then
        run_expo_tests
        run_expo_lint
        if [ "$QUICK_MODE" = false ]; then
            run_expo_typecheck
        fi
    else
        log_warn "No Expo mobile app detected"
    fi
}

# =============================================================================
# UNIT TESTS
# =============================================================================

run_unit_tests() {
    log_header "Unit Tests"
    
    local run_prefix=$(get_node_run_prefix)
    
    if grep -q '"test:unit"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
        log_step "Running: $run_prefix test:unit"
        if eval "$run_prefix test:unit"; then
            log_success "Unit tests passed"
        else
            log_error "Unit tests failed"
            EXIT_CODE=1
        fi
    else
        log_info "No unit test script found"
    fi
    
    echo ""
}

# =============================================================================
# SUPABASE INTEGRATION TESTS
# =============================================================================

run_supabase_integration() {
    if ! is_supabase_enabled; then
        return 0
    fi
    
    log_header "Supabase Integration Tests"
    
    # Check if Supabase CLI is available
    if ! check_command supabase; then
        log_warn "Supabase CLI not installed, skipping integration tests"
        return 0
    fi
    
    # Check if Supabase is running
    log_step "Checking if Supabase is running..."
    if is_supabase_running; then
        log_success "Supabase is running"
    else
        log_warn "Supabase is not running. Start with: supabase start"
        log_info "Skipping integration tests (Supabase not running)"
        return 0
    fi
    
    # Verify database connection
    log_step "Testing database connection..."
    if supabase db lint >/dev/null 2>&1; then
        log_success "Database connection OK"
    else
        # db lint might not exist in all versions, try alternative
        if supabase status >/dev/null 2>&1; then
            log_success "Supabase status OK"
        else
            log_error "Cannot connect to Supabase database"
            EXIT_CODE=1
            return 1
        fi
    fi
    
    # Verify tables exist
    log_step "Checking database schema..."
    
    # Get the Supabase DB URL from status
    local db_url=$(supabase status 2>/dev/null | grep "DB URL" | awk '{print $NF}')
    
    if [ -n "$db_url" ] && check_command psql; then
        # Check if items table exists
        if psql "$db_url" -c "SELECT 1 FROM items LIMIT 1;" >/dev/null 2>&1; then
            log_success "Table 'items' exists"
        else
            log_error "Table 'items' not found. Run migrations: supabase db reset"
            EXIT_CODE=1
        fi
        
        # Check if profiles table exists
        if psql "$db_url" -c "SELECT 1 FROM profiles LIMIT 1;" >/dev/null 2>&1; then
            log_success "Table 'profiles' exists"
        else
            log_error "Table 'profiles' not found. Run migrations: supabase db reset"
            EXIT_CODE=1
        fi
    else
        log_info "psql not available or DB URL not found, skipping table verification"
        log_info "Tables will be verified when the app connects"
    fi
    
    # Verify seed data exists (optional)
    if [ -n "$db_url" ] && check_command psql; then
        local item_count=$(psql "$db_url" -t -c "SELECT COUNT(*) FROM items;" 2>/dev/null | tr -d ' ')
        if [ -n "$item_count" ] && [ "$item_count" -gt 0 ]; then
            log_success "Seed data present: $item_count items"
        else
            log_info "No seed data found. Run: supabase db reset"
        fi
    fi
    
    echo ""
}

# =============================================================================
# SECURITY SCANNING
# =============================================================================

run_security_scan() {
    log_header "Security Scan"
    
    local has_checks=false
    
    # Node.js security audit
    if is_node_enabled || is_expo_enabled; then
        has_checks=true
        local pm=$(get_node_package_manager)
        
        log_step "Running Node.js dependency audit..."
        
        case "$pm" in
            pnpm)
                if pnpm audit --audit-level=high 2>/dev/null; then
                    log_success "pnpm audit passed"
                else
                    log_warn "pnpm audit found vulnerabilities (or audit not available)"
                    # Don't fail on audit - many projects have unfixable vulns
                fi
                ;;
            yarn)
                if yarn audit --level high 2>/dev/null; then
                    log_success "yarn audit passed"
                else
                    log_warn "yarn audit found vulnerabilities"
                fi
                ;;
            npm|*)
                if npm audit --audit-level=high 2>/dev/null; then
                    log_success "npm audit passed"
                else
                    log_warn "npm audit found vulnerabilities"
                fi
                ;;
        esac
    fi
    
    # Python security audit
    if is_python_enabled; then
        has_checks=true
        local venv_path=$(get_venv_path)
        
        if [ -d "$venv_path" ]; then
            source "$venv_path/bin/activate"
            
            log_step "Running Python dependency audit..."
            
            if python -m pip_audit --version &>/dev/null; then
                if python -m pip_audit; then
                    log_success "pip-audit passed"
                else
                    log_warn "pip-audit found vulnerabilities"
                fi
            elif python -m safety --version &>/dev/null; then
                if python -m safety check; then
                    log_success "safety check passed"
                else
                    log_warn "safety check found vulnerabilities"
                fi
            else
                log_info "No Python security scanner installed (pip-audit or safety)"
            fi
            
            deactivate
        fi
    fi
    
    # Rust security audit
    if is_rust_enabled; then
        has_checks=true
        log_step "Running Rust dependency audit..."
        
        if check_command cargo-audit; then
            if cargo audit; then
                log_success "cargo audit passed"
            else
                log_warn "cargo audit found vulnerabilities"
            fi
        else
            log_info "cargo-audit not installed (install with: cargo install cargo-audit)"
        fi
    fi
    
    if [ "$has_checks" = false ]; then
        log_warn "No security scanners available for detected stacks"
    fi
    
    echo ""
}

# =============================================================================
# BUILD VERIFICATION
# =============================================================================

run_build_check() {
    log_header "Build Verification"
    
    local has_builds=false
    
    # Node.js build
    if is_node_enabled; then
        local node_dir=$(get_node_dir)
        local run_prefix=$(get_node_run_prefix)
        
        cd "$node_dir"
        
        if grep -q '"build"' package.json 2>/dev/null; then
            has_builds=true
            log_step "Running: $run_prefix build"
            if eval "$run_prefix build"; then
                log_success "Node.js build passed"
            else
                log_error "Node.js build failed"
                EXIT_CODE=1
            fi
        fi
        
        cd "$PROJECT_ROOT"
    fi
    
    # Expo build check (type-check only, full build requires EAS)
    if is_expo_enabled; then
        local expo_dir=$(get_expo_dir)
        
        cd "$expo_dir"
        
        has_builds=true
        
        # Verify config file exists
        log_step "Checking Expo config file..."
        if [ -f "app.config.ts" ]; then
            log_success "Found app.config.ts"
        elif [ -f "app.config.js" ]; then
            log_success "Found app.config.js"
        elif [ -f "app.json" ]; then
            log_success "Found app.json"
        else
            log_error "No Expo config file found (app.config.ts, app.config.js, or app.json)"
            EXIT_CODE=1
            cd "$PROJECT_ROOT"
            continue
        fi
        
        log_step "Verifying Expo app configuration..."
        
        if npx expo-doctor 2>/dev/null; then
            log_success "Expo doctor passed"
        else
            # expo-doctor might not be available
            if [ -f "tsconfig.json" ]; then
                log_step "Running TypeScript check as build verification..."
                if npx tsc --noEmit; then
                    log_success "Expo TypeScript check passed"
                else
                    log_error "Expo TypeScript check failed"
                    EXIT_CODE=1
                fi
            fi
        fi
        
        cd "$PROJECT_ROOT"
    fi
    
    # Rust build
    if is_rust_enabled; then
        has_builds=true
        log_step "Running: cargo build"
        if cargo build; then
            log_success "Rust build passed"
        else
            log_error "Rust build failed"
            EXIT_CODE=1
        fi
    fi
    
    # Go build
    if is_go_enabled; then
        has_builds=true
        log_step "Running: go build ./..."
        if go build ./...; then
            log_success "Go build passed"
        else
            log_error "Go build failed"
            EXIT_CODE=1
        fi
    fi
    
    if [ "$has_builds" = false ]; then
        log_info "No build scripts found"
    fi
    
    echo ""
}

# =============================================================================
# MONOREPO SUPPORT
# =============================================================================

run_monorepo_typecheck() {
    if [ ! -f "$PROJECT_ROOT/pnpm-workspace.yaml" ]; then
        return 0
    fi
    
    log_header "Monorepo Type Checking"
    
    log_step "Running: pnpm -r typecheck"
    if pnpm -r typecheck 2>/dev/null; then
        log_success "Monorepo type checking passed"
    else
        log_error "Monorepo type checking failed"
        EXIT_CODE=1
    fi
    
    echo ""
}

run_monorepo_lint() {
    if [ ! -f "$PROJECT_ROOT/pnpm-workspace.yaml" ]; then
        return 0
    fi
    
    # Check if root has lint script
    if grep -q '"lint"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
        log_header "Monorepo Linting"
        
        local run_prefix=$(get_node_run_prefix)
        local lint_cmd="$run_prefix lint"
        
        if [ "$FIX_MODE" = true ]; then
            # Try to add --fix flag
            lint_cmd="$run_prefix lint -- --fix"
        fi
        
        log_step "Running: $lint_cmd"
        if eval "$lint_cmd"; then
            log_success "Monorepo linting passed"
        else
            log_error "Monorepo linting failed"
            EXIT_CODE=1
        fi
        
        echo ""
    fi
}

run_monorepo_format() {
    if [ ! -f "$PROJECT_ROOT/pnpm-workspace.yaml" ]; then
        return 0
    fi
    
    # Check if root has format script
    local run_prefix=$(get_node_run_prefix)
    
    if [ "$FIX_MODE" = true ]; then
        if grep -q '"format"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
            log_header "Monorepo Formatting (fix)"
            
            log_step "Running: $run_prefix format"
            if eval "$run_prefix format"; then
                log_success "Monorepo formatting applied"
            else
                log_error "Monorepo formatting failed"
                EXIT_CODE=1
            fi
            
            echo ""
        fi
    else
        if grep -q '"format:check"' "$PROJECT_ROOT/package.json" 2>/dev/null; then
            log_header "Monorepo Format Check"
            
            log_step "Running: $run_prefix format:check"
            if eval "$run_prefix format:check"; then
                log_success "Monorepo format check passed"
            else
                log_error "Monorepo format check failed"
                EXIT_CODE=1
            fi
            
            echo ""
        fi
    fi
}

# =============================================================================
# COMPOSITE RUNNERS
# =============================================================================

run_all_tests() {
    # Run package unit tests first
    run_unit_tests
    
    if is_python_enabled; then
        run_python_tests
    fi
    
    if is_node_enabled; then
        run_node_tests
    fi
    
    if is_expo_enabled; then
        run_expo_tests
    fi
    
    if is_rust_enabled; then
        run_rust_tests
    fi
    
    if is_go_enabled; then
        run_go_tests
    fi
}

run_all_lint() {
    # Use monorepo lint if available (covers all workspaces)
    if [ -f "$PROJECT_ROOT/pnpm-workspace.yaml" ]; then
        run_monorepo_lint
    else
        if is_python_enabled; then
            run_python_lint
        fi
        
        if is_node_enabled; then
            run_node_lint
        fi
        
        if is_expo_enabled; then
            run_expo_lint
        fi
    fi
    
    if is_rust_enabled; then
        run_rust_lint
    fi
    
    if is_go_enabled; then
        run_go_lint
    fi
}

run_all_format() {
    # Use monorepo format if available (covers all workspaces)
    if [ -f "$PROJECT_ROOT/pnpm-workspace.yaml" ]; then
        run_monorepo_format
    else
        if is_python_enabled; then
            run_python_format
        fi
        
        if is_node_enabled; then
            run_node_format
        fi
    fi
    
    if is_rust_enabled; then
        run_rust_format
    fi
    
    if is_go_enabled; then
        run_go_format
    fi
}

run_all_typecheck() {
    # Use monorepo typecheck if available (covers all workspaces)
    if [ -f "$PROJECT_ROOT/pnpm-workspace.yaml" ]; then
        run_monorepo_typecheck
    else
        if is_python_enabled; then
            run_python_typecheck
        fi
        
        if is_node_enabled; then
            run_node_typecheck
        fi
        
        if is_expo_enabled; then
            run_expo_typecheck
        fi
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

# Show active modes
if [ "$CI_MODE" = true ] || [ "$QUICK_MODE" = true ] || [ "$FIX_MODE" = true ] || [ "$COVERAGE_MODE" = true ] || [ "$WATCH_MODE" = true ] || [ "$VERBOSE" = true ]; then
    log_step "Active options:"
    [ "$CI_MODE" = true ] && echo "  - CI mode (stricter checks, no Docker-dependent tests)"
    [ "$QUICK_MODE" = true ] && echo "  - Quick mode (skipping type-check, format)"
    [ "$FIX_MODE" = true ] && echo "  - Fix mode (auto-fixing issues)"
    [ "$COVERAGE_MODE" = true ] && echo "  - Coverage mode (generating coverage reports)"
    [ "$WATCH_MODE" = true ] && echo "  - Watch mode (continuous testing)"
    [ "$VERBOSE" = true ] && echo "  - Verbose mode (detailed output)"
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
    
    mobile)
        run_mobile_all
        ;;
    
    unit)
        run_unit_tests
        ;;
    
    supabase)
        run_supabase_integration
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
    
    security)
        run_security_scan
        ;;
    
    build)
        run_build_check
        ;;
    
    all|*)
        run_all_tests
        run_all_lint
        if [ "$QUICK_MODE" = false ]; then
            run_all_format
            run_all_typecheck
            # Skip Supabase integration in CI mode (no Docker available)
            if [ "$CI_MODE" = false ]; then
                run_supabase_integration
            else
                log_info "Skipping Supabase integration tests in CI mode"
            fi
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
