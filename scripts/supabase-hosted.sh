#!/bin/bash
# =============================================================================
# Hosted Supabase Setup Script
# =============================================================================
# Links this repo to a hosted Supabase project and applies migrations.
#
# Idempotency:
# - `supabase db push` is idempotent because Supabase tracks which migrations
#   have already been applied.
#
# Usage:
#   ./scripts/supabase-hosted.sh --project-ref <ref>
#
# Where to find <ref>:
# - Supabase Dashboard URL: https://supabase.com/dashboard/project/<ref>
# - Or inside publishable/anon key: sb_publishable_<ref>_...
#
# Prereqs:
# - Supabase CLI installed
# - `supabase login` completed
# =============================================================================

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
source "$SCRIPT_DIR/_common.sh"

PROJECT_REF=""

show_help() {
  echo "Usage: $0 --project-ref <ref>"
  echo ""
  echo "Applies Supabase migrations to a hosted Supabase project."
  echo ""
  echo "Options:"
  echo "  --project-ref <ref>   Supabase project ref (required)"
  echo "  --help                Show this help message"
  echo ""
}

while [ $# -gt 0 ]; do
  case "$1" in
    --project-ref)
      PROJECT_REF="${2:-}"
      shift 2
      ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      log_error "Unknown option: $1"
      echo "Use --help for usage information"
      exit 1
      ;;
  esac
done

if [ -z "$PROJECT_REF" ]; then
  log_error "--project-ref is required"
  show_help
  exit 1
fi

log_header "Hosted Supabase Setup"
echo ""

require_command supabase "brew install supabase/tap/supabase"

log_step "Linking project..."
cd "$PROJECT_ROOT"
supabase link --project-ref "$PROJECT_REF"
log_success "Project linked"
echo ""

log_step "Applying migrations to hosted project..."
supabase db push
log_success "Migrations applied"
echo ""

log_success "Hosted Supabase is ready"
log_info "Next: set Expo env vars in apps/mobile/.env.local and run ./scripts/run.sh mobile"

