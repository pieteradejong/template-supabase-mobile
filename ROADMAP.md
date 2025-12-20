# ROADMAP: Supabase + React + React Native Template

## Project Overview

A production-ready GitHub template combining:
- **Web**: Vite + React + Tailwind
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

## Project Structure

```
├── apps/
│   ├── web/                    # Vite + React + Tailwind
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
│   └── functions/              # Edge functions
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
├── tsconfig.base.json
└── README.md
```

---

## Phase 0: Project Foundation

**Goal:** Empty monorepo with working init/test/run scripts

### Deliverables

- [ ] Monorepo structure with pnpm workspaces
- [ ] Shared TypeScript config (`tsconfig.base.json`)
- [ ] Shared ESLint + Prettier config
- [ ] Empty Vite app (displays "Hello World")
- [ ] Empty Expo app (displays "Hello World")
- [ ] `init.sh` script
- [ ] `test.sh` script
- [ ] `run.sh` script
- [ ] GitHub Actions workflow calling `test.sh --ci`
- [ ] README with setup instructions

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
#    - Copy .env.example to .env.local if not exists
#    - Prompt for values or use defaults for local dev

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
./init.sh           # Completes with exit 0
./test.sh           # Completes with exit 0
./run.sh            # Both apps accessible at localhost
./run.sh --web      # Only web app starts
./run.sh --mobile   # Only mobile app starts
```

### Definition of Done

- [ ] A new developer can clone and have both apps running in under 5 minutes
- [ ] CI pipeline passes on GitHub Actions
- [ ] No TypeScript errors
- [ ] No ESLint errors

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
- [ ] Both apps fetch and display data from Supabase
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

- [ ] Both apps show data from Supabase
- [ ] Types are generated and match the schema
- [ ] Type generation runs in CI
- [ ] Changing schema and regenerating types works smoothly

---

## Phase 2: Authentication

**Goal:** Users can sign up, sign in, sign out

### Deliverables

- [ ] Magic link auth (primary method)
- [ ] Email/password auth (secondary option)
- [ ] Secure token storage:
  - Web: localStorage (with XSS considerations documented)
  - Mobile: Expo SecureStore
- [ ] Shared auth hooks in `packages/supabase`
- [ ] Auth state management (React context)
- [ ] Protected route/screen example (requires auth)
- [ ] Unprotected route/screen example (public)
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
  }
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

- [ ] Full auth flow works on web
- [ ] Full auth flow works on mobile (iOS and Android)
- [ ] Tokens stored securely per platform
- [ ] Can't access protected content without auth
- [ ] RLS prevents cross-user data access

---

## Phase 3: Security Hardening

**Goal:** Production-grade security

### Deliverables

- [ ] Security headers (web):
  - Content-Security-Policy
  - Strict-Transport-Security
  - X-Content-Type-Options
  - X-Frame-Options
  - Referrer-Policy
- [ ] CORS configuration (locked to specific origins)
- [ ] Zod validation schemas in `packages/utils`
- [ ] Input validation examples in both apps
- [ ] Environment variable separation (dev/staging/prod)
- [ ] `pnpm audit` in CI (fail on high/critical)
- [ ] Dependabot configuration
- [ ] Security documentation/checklist

### Zod Validation Examples

```typescript
// packages/utils/src/validation/items.ts
import { z } from 'zod';

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
- [ ] Example: items table changes reflected live in both apps
- [ ] Proper cleanup on unmount

#### Storage
- [ ] Storage bucket setup (with RLS)
- [ ] Upload file example (both apps)
- [ ] Download/display file example
- [ ] File deletion example

### Edge Function Template

```typescript
// supabase/functions/example/index.ts
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'

serve(async (req) => {
  // CORS
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    // Verify JWT
    const authHeader = req.headers.get('Authorization')
    // ... verification logic

    // Validate input
    const body = await req.json()
    // ... Zod validation

    // Business logic
    // ...

    return new Response(JSON.stringify({ data }), {
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  } catch (error) {
    return new Response(JSON.stringify({ error: error.message }), {
      status: 400,
      headers: { ...corsHeaders, 'Content-Type': 'application/json' },
    })
  }
})
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
- [ ] All features work on both web and mobile
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

## Appendix A: Technology Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Web framework | Vite + React | Fast, simple, well-supported |
| Mobile framework | Expo (managed) | Easier cross-platform, EAS for builds |
| Styling | Tailwind CSS | Utility-first, works well in both contexts |
| Monorepo | pnpm workspaces | Simple, no extra tooling needed |
| Auth method | Magic link (primary) | Lowest friction, no passwords |
| Validation | Zod | Type-safe, great DX |
| Backend | Supabase | Full-featured, good DX, scales well |

## Appendix B: Environment Variables

```bash
# .env.example

# Supabase
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key  # Never expose to client

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
          node-version: '20'
          cache: 'pnpm'
      - run: pnpm install
      - run: ./test.sh --ci
```