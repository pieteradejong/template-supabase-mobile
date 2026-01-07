# ROADMAP: Supabase Mobile Template

## Project Overview

A production-ready GitHub template for mobile apps:

- **Mobile**: Expo (managed workflow) targeting iOS and Android
- **Backend**: Supabase (Auth, Database, Realtime, Storage, Edge Functions)
- **Monorepo**: pnpm workspaces with shared packages

### Core Principles

1. **Deployable at every iteration** - Each phase produces a working, shippable product
2. **Thoroughly tested** - High confidence in integrity before moving forward
3. **Three scripts rule everything**:
   - `init.sh` - Fresh clone to running dev environment
   - `test.sh` - Full test suite, exit 0 means safe to deploy
   - `run.sh` - Start the complete dev environment

---

## Next Up: Template Hardening (Recommended)

These are template-first tasks that make this repo more reusable across dozens of future projects.

### Template Hygiene

- [ ] Remove/centralize project-specific strings (app name, bundle identifiers, scheme, package names) so new projects can rename safely.
- [ ] Add a "Template customization checklist" to `README.md` (exact strings to search/replace).

### Hosted Supabase Onboarding (1-command)

- [ ] Extend `./scripts/init.sh` to support hosted Supabase setup (e.g. `--project-ref <ref>` that runs `./scripts/supabase-hosted.sh`).
- [ ] Add `pnpm` script aliases (e.g. `pnpm supabase:hosted`) for quick access.

### Minimal CRUD Demo (No Auth)

- [ ] Add a create item button (insert into `items`) in the mobile app.
- [ ] Add delete interaction (e.g. long-press or swipe-to-delete).
- [ ] Keep schema permissive for Phase 1; tighten with RLS in Phase 2 (auth).

### Template Guardrails

- [ ] Enforce **one canonical secrets file**: `apps/mobile/.env.local` (copy from `apps/mobile/env.local.example`).
- [ ] Scripts must load secrets from `apps/mobile/.env.local` only (no fallbacks) and fail fast when missing or placeholders are present.
- [ ] Add CI checks to prevent common misconfigurations:
  - [ ] Fail if `EXPO_PUBLIC_SUPABASE_URL` is a dashboard URL instead of project URL.
  - [ ] Ensure `apps/mobile/.env.local` (and any other env files) are never committed.
- [ ] Update docs to reflect the single-file secrets setup (no fallbacks).

### Phase 2 Prep (Auth-ready without implementing auth)

- [ ] Decide whether Phase 1 `profiles.id` should already reference `auth.users(id)` (or keep standalone until Phase 2 migration).
- [ ] Add a short "Auth migration plan" note (what changes to `profiles`, and which RLS policies become user-scoped).

---

## Project Structure

```
├── apps/
│   └── mobile/                 # Expo (iOS + Android)
│
├── packages/
│   ├── supabase/               # Supabase client, typed queries, hooks
│   ├── types/                  # Shared TypeScript types (generated from DB)
│   └── utils/                  # Shared business logic, validation, helpers
│
├── supabase/
│   ├── migrations/             # SQL migrations
│   ├── seed.sql                # Example seed data
│   └── functions/              # Edge functions (future)
│
├── .github/
│   └── workflows/              # CI/CD (GitHub Actions)
│
├── scripts/
│   ├── init.sh                 # Initialize entire project
│   ├── test.sh                 # Run all tests
│   └── run.sh                  # Start dev environment
│
├── pnpm-workspace.yaml
└── README.md
```

---

## Phase 0: Project Foundation ✅

**Goal:** Mobile-only monorepo with working init/test/run scripts

### Deliverables

- [x] Monorepo structure with pnpm workspaces
- [x] Shared ESLint + Prettier config
- [x] Expo mobile app (displays "Hello World")
- [x] Shared packages (supabase, types, utils)
- [x] `init.sh` script
- [x] `test.sh` script
- [x] `run.sh` script
- [x] Local Supabase setup with migrations
- [x] GitHub Actions workflow calling `test.sh --ci`
- [x] README with setup instructions

### Script Specifications

#### `init.sh`

```bash
#!/bin/bash
# Exit on any error
set -e

# 1. Check prerequisites
#    - Node.js >= 18
#    - pnpm >= 8
#    - Supabase CLI
#    - Expo CLI (or install via npx)
#    Fail with clear message if missing

# 2. Install dependencies
#    pnpm install

# 3. Setup environment
#    - Copy apps/mobile/env.local.example → apps/mobile/.env.local if not exists
#    - Fail fast if required vars are missing (tell user exactly what to set)

# 4. Initialize Supabase (later phases)
#    - Start local Supabase
#    - Run migrations
#    - Seed database
#    - Generate types

# 5. Verify setup
#    - Check all services are ready
#    - Exit 0 = ready to develop
#    - Exit 1 = clear error message
```

#### `test.sh`

```bash
#!/bin/bash
set -e

# Parse flags
# --ci     : CI mode (stricter, no prompts)
# --quick  : Skip slow tests (for dev feedback)

# 1. Lint (ESLint)
# 2. Type check (TypeScript)
# 3. Unit tests
# 4. Integration tests (later phases)
# 5. Security audit (pnpm audit)

# Exit 0 = safe to deploy
# Exit 1 = show what failed
```

#### `run.sh`

```bash
#!/bin/bash

# Parse flags
# --web    : Only web
# --mobile : Only mobile
# --all    : Everything (default)

# 1. Start local Supabase (if not running)
# 2. Start Vite dev server (web)
# 3. Start Expo dev server (mobile)
# 4. Start edge functions locally (later phases)
```

### Acceptance Criteria

```bash
git clone <repo>
./init.sh           # Completes with exit 0 (requires Docker)
./test.sh           # Completes with exit 0
./run.sh mobile     # Mobile app accessible via Expo Go
```

### Definition of Done

- [x] A new developer can clone and have mobile app running in under 5 minutes
- [x] CI pipeline passes on GitHub Actions
- [x] No TypeScript errors
- [x] No ESLint errors

---

## Phase 1: Supabase Integration (No Auth Yet)

**Goal:** Supabase client working, types generated, example query works

### Deliverables

- [ ] Supabase project setup documentation
- [ ] `packages/supabase` with typed client
- [ ] Type generation script (`supabase gen types`)
- [ ] Example migration: `profiles` table
- [ ] Example migration: `items` table (generic CRUD example)
- [ ] `seed.sql` with example data
- [ ] Env validation (fail fast if vars missing)
- [ ] Mobile app fetches and displays data from Supabase
- [ ] Update `init.sh` to run migrations and seed
- [ ] Update `test.sh` with integration tests

### Database Schema (Example)

```sql
-- profiles: extends auth.users
CREATE TABLE profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  display_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- items: generic CRUD example
CREATE TABLE items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- RLS will be added in Phase 2
```

### Acceptance Criteria

```bash
./init.sh           # Sets up Supabase, runs migrations, seeds data
./test.sh           # Integration tests pass (connects to Supabase, queries work)
./run.sh            # Both apps display seeded data
```

### Definition of Done

- [ ] Mobile app shows data from Supabase
- [ ] Types are generated and match the schema
- [ ] Type generation runs in CI
- [ ] Changing schema and regenerating types works smoothly

---

## Phase 2: Authentication

**Goal:** Users can sign up, sign in, sign out

### Deliverables

- [ ] Magic link auth (primary method)
- [ ] Email/password auth (secondary option)
- [ ] Secure token storage with Expo SecureStore
- [ ] Shared auth hooks in `packages/supabase`
- [ ] Auth state management (React context)
- [ ] Protected screen example (requires auth)
- [ ] Unprotected screen example (public)
- [ ] RLS policies:
  - `profiles`: users can only read/write own profile
  - `items`: users can only CRUD own items
- [ ] Sign out clears all tokens
- [ ] Token refresh handling

### Auth Hooks API

```typescript
// packages/supabase/src/hooks/useAuth.ts
export function useAuth() {
  return {
    user: User | null,
    session: Session | null,
    loading: boolean,
    signInWithMagicLink: (email: string) => Promise<void>,
    signInWithPassword: (email: string, password: string) => Promise<void>,
    signUp: (email: string, password: string) => Promise<void>,
    signOut: () => Promise<void>,
  };
}
```

### Acceptance Criteria

```bash
./test.sh
# - Auth flow tests pass (sign up, sign in, sign out)
# - Token refresh test passes
# - RLS tests pass (user A can't see user B's data)
# - Protected route redirects unauthenticated users
```

### Definition of Done

- [ ] Full auth flow works on mobile (iOS and Android)
- [ ] Tokens stored securely with Expo SecureStore
- [ ] Can't access protected screens without auth
- [ ] RLS prevents cross-user data access

---

## Phase 3: Security Hardening

**Goal:** Production-grade security

### Deliverables

- [ ] Zod validation schemas in `packages/utils`
- [ ] Input validation examples in mobile app
- [ ] Environment variable separation (dev/staging/prod)
- [ ] `pnpm audit` in CI (fail on high/critical)
- [ ] Dependabot configuration
- [ ] Security documentation/checklist
- [ ] Secure storage best practices documented

### Zod Validation Examples

```typescript
// packages/utils/src/validation/items.ts
import { z } from "zod";

export const createItemSchema = z.object({
  title: z.string().min(1).max(200),
  description: z.string().max(2000).optional(),
});

export const updateItemSchema = createItemSchema.partial();

export type CreateItemInput = z.infer<typeof createItemSchema>;
export type UpdateItemInput = z.infer<typeof updateItemSchema>;
```

### Security Checklist (for docs)

- [ ] RLS enabled on all tables
- [ ] Service role key never exposed to client
- [ ] All user input validated with Zod
- [ ] CORS locked to production domains
- [ ] Security headers configured
- [ ] Dependencies audited
- [ ] Secrets in environment variables, not code
- [ ] Magic link expiry is short (10-15 min)

### Acceptance Criteria

```bash
./test.sh
# - Security header tests pass
# - Invalid input rejected at validation layer
# - pnpm audit passes (no high/critical vulnerabilities)
# - Env validation fails appropriately with missing vars
```

### Definition of Done

- [ ] Security checklist passes
- [ ] Audit clean (no high/critical vulnerabilities)
- [ ] Documentation covers all security considerations

---

## Phase 4: Edge Functions, Realtime, Storage

**Goal:** Demonstrate remaining Supabase features

### Deliverables

#### Edge Functions

- [ ] Example edge function with:
  - JWT verification (reusable helper)
  - Input validation (Zod)
  - Error handling
  - CORS headers
- [ ] Edge function invocation from both apps
- [ ] Local edge function development setup

#### Realtime

- [ ] Realtime subscription hook
- [ ] Example: items table changes reflected live in mobile app
- [ ] Proper cleanup on unmount

#### Storage

- [ ] Storage bucket setup (with RLS)
- [ ] Upload file example (mobile app)
- [ ] Download/display file example
- [ ] File deletion example

### Edge Function Template

```typescript
// supabase/functions/example/index.ts
import { serve } from "https://deno.land/std@0.168.0/http/server.ts";
import { createClient } from "https://esm.sh/@supabase/supabase-js@2";

serve(async (req) => {
  // CORS
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    // Verify JWT
    const authHeader = req.headers.get("Authorization");
    // ... verification logic

    // Validate input
    const body = await req.json();
    // ... Zod validation

    // Business logic
    // ...

    return new Response(JSON.stringify({ data }), {
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, "Content-Type": "application/json" },
    });
  }
});
```

### Acceptance Criteria

```bash
./test.sh
# - Edge function: authed request succeeds
# - Edge function: unauthed request returns 401
# - Edge function: invalid input returns 400
# - Realtime: DB change reflects in app within seconds
# - Storage: upload and retrieve file works
# - Storage: RLS prevents unauthorized access
```

### Definition of Done

- [ ] All Supabase features demonstrated
- [ ] All features work on mobile (iOS and Android)
- [ ] All features have tests

---

## Phase 5: Polish & Documentation

**Goal:** Template is ready for public use

### Deliverables

#### Documentation

- [ ] README.md - Quick start, project overview
- [ ] docs/SETUP.md - Detailed setup guide
- [ ] docs/ARCHITECTURE.md - How the pieces fit together
- [ ] docs/SECURITY.md - Security considerations and checklist
- [ ] docs/CUSTOMIZATION.md - How to adapt the template
- [ ] docs/DEPLOYMENT.md - Production deployment guide
- [ ] docs/TROUBLESHOOTING.md - Common issues and solutions

#### Template Polish

- [ ] Clean up all TODO comments
- [ ] Consistent code style throughout
- [ ] Helpful inline comments for learning
- [ ] GitHub issue templates
- [ ] GitHub PR template
- [ ] CONTRIBUTING.md
- [ ] LICENSE file

#### Final Testing

- [ ] Fresh clone test (someone unfamiliar tries it)
- [ ] All documentation is accurate
- [ ] All links work
- [ ] All scripts work on macOS and Linux

### README Structure

```markdown
# Project Name

One-line description.

## Quick Start

\`\`\`bash
git clone <repo>
cd <repo>
./init.sh
./run.sh
\`\`\`

## What's Included

- Feature list

## Documentation

- Links to docs/

## Scripts

- init.sh: ...
- test.sh: ...
- run.sh: ...

## Tech Stack

- List

## License

MIT
```

### Acceptance Criteria

- [ ] Fresh clone + full setup completes successfully
- [ ] All documentation reviewed for accuracy
- [ ] Someone unfamiliar with the project can use it successfully
- [ ] All tests pass
- [ ] No TODO comments remain

### Definition of Done

- [ ] Template is production-ready
- [ ] Documentation is comprehensive
- [ ] Ready for public release

---

## Phase 6: Logging & Health Checks

**Goal:** Production-grade observability

### Deliverables

#### Logging

- [ ] Shared logger in `packages/utils`
- [ ] Structured JSON log format
- [ ] Log levels (error, warn, info, debug)
- [ ] Correlation ID generation and propagation
- [ ] Request/response logging middleware (web)
- [ ] Sensitive data redaction
- [ ] Environment-based log level configuration

#### Health Checks

- [ ] `/health/live` endpoint (liveness)
- [ ] `/health/ready` endpoint (readiness)
- [ ] Supabase connection check
- [ ] Response caching (prevent hammering dependencies)
- [ ] Graceful degradation for non-critical services
- [ ] Health check in CI (verify app starts correctly)

#### Documentation

- [ ] LOGGING.md - Logging standards and patterns
- [ ] Update ARCHITECTURE.md with observability patterns

### Logger Implementation

```typescript
// packages/utils/src/logger.ts
interface LogEntry {
  timestamp: string;
  level: "error" | "warn" | "info" | "debug";
  message: string;
  service: string;
  correlationId?: string;
  userId?: string;
  metadata?: Record<string, unknown>;
  error?: {
    name: string;
    message: string;
    stack?: string;
  };
}

interface Logger {
  error(message: string, error?: Error, metadata?: object): void;
  warn(message: string, metadata?: object): void;
  info(message: string, metadata?: object): void;
  debug(message: string, metadata?: object): void;
  child(context: object): Logger;
}
```

### Health Check Implementation

```typescript
// Response format
interface HealthResponse {
  status: "ok" | "degraded" | "error";
  checks?: Record<
    string,
    {
      status: "ok" | "degraded" | "error";
      latency_ms?: number;
      message?: string;
    }
  >;
  version?: string;
  uptime_seconds?: number;
}

// Endpoints
// GET /health/live   → { status: 'ok' }
// GET /health/ready  → { status: 'ok', checks: { database: {...} } }
```

### Acceptance Criteria

```bash
./test.sh
# - Logger outputs structured JSON
# - Correlation IDs propagate through requests
# - Sensitive data is redacted
# - /health/live returns 200 when app is running
# - /health/ready returns 200 when Supabase is connected
# - /health/ready returns 503 when Supabase is down
```

### Definition of Done

- [ ] Mobile app uses shared logger
- [ ] Health checks integrated into CI
- [ ] LOGGING.md documents all patterns

---

## Appendix A: Technology Decisions

| Decision         | Choice               | Rationale                                  |
| ---------------- | -------------------- | ------------------------------------------ |
| Mobile framework | Expo (managed)       | Easier cross-platform, EAS for builds      |
| Monorepo         | pnpm workspaces      | Simple, no extra tooling needed            |
| Auth method      | Magic link (primary) | Lowest friction, no passwords              |
| Validation       | Zod                  | Type-safe, great DX                        |
| Backend          | Supabase             | Full-featured, good DX, scales well        |

## Appendix B: Environment Variables

```bash
# apps/mobile/.env.local

# Supabase
EXPO_PUBLIC_SUPABASE_URL=https://<project-ref>.supabase.co
EXPO_PUBLIC_SUPABASE_ANON_KEY=<anon key> # Public/publishable; safe for client

# NEVER put service role key in the client app

# App
APP_ENV=development  # development | staging | production
```

## Appendix C: CI/CD Pipeline

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: pnpm/action-setup@v2
      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "pnpm"
      - run: pnpm install
      - run: ./test.sh --ci
```
