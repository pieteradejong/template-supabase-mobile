# Phase 0: Project Foundation - Task Breakdown

**Goal:** Mobile-only monorepo with working `init.sh`, `test.sh`, and `run.sh` scripts.

**Definition of Done:**

```bash
git clone <repo>
./init.sh           # Completes with exit 0
./test.sh           # Completes with exit 0
./run.sh mobile     # Mobile app accessible via Expo Go
```

---

## Task 0.1: Initialize Monorepo Structure

### Create root configuration files

- [x] `package.json` - Root package with workspaces config
- [x] `pnpm-workspace.yaml` - Define workspace packages
- [x] `.gitignore` - Comprehensive ignore patterns

---

## Task 0.2: TypeScript Configuration

### TypeScript config for Expo

- [x] `apps/mobile/tsconfig.json` - Extends Expo's base config with strict mode

---

## Task 0.3: ESLint & Prettier Configuration

### Create shared linting config

- [x] `.eslintrc.js` - ESLint configuration
- [x] `.prettierrc` - Prettier configuration
- [x] `.prettierignore` - Prettier ignore patterns
- [x] Add lint dependencies to root `package.json`

---

## Task 0.4: Create Mobile App (Expo)

### Initialize Expo app

- [x] Create `apps/mobile` directory structure
- [x] `apps/mobile/package.json`
- [x] `apps/mobile/tsconfig.json`
- [x] `apps/mobile/app.json`
- [x] `apps/mobile/babel.config.js`
- [x] `apps/mobile/metro.config.js`
- [x] `apps/mobile/app/_layout.tsx` (Expo Router)
- [x] `apps/mobile/app/index.tsx`

---

## Task 0.5: Create Shared Packages (Stubs)

### Create package stubs

- [x] `packages/supabase/package.json`
- [x] `packages/supabase/src/index.ts`
- [x] `packages/supabase/src/client.ts`
- [x] `packages/supabase/tsconfig.json`
- [x] `packages/types/package.json`
- [x] `packages/types/src/index.ts`
- [x] `packages/types/src/database.ts`
- [x] `packages/types/tsconfig.json`
- [x] `packages/utils/package.json`
- [x] `packages/utils/src/index.ts`
- [x] `packages/utils/src/env.ts`
- [x] `packages/utils/tsconfig.json`

---

## Task 0.6: Create Environment Configuration

### Setup environment handling

- [x] `.env.example` - Example environment file
- [x] `packages/utils/src/env.ts` - Environment validation

---

## Task 0.7: Create init.sh Script

### Create initialization script

- [x] `scripts/init.sh`
- [x] `scripts/_common.sh` - Shared utilities
- [x] `scripts/project.conf` - Project configuration

---

## Task 0.8: Create test.sh Script

### Create test script

- [x] `scripts/test.sh`

---

## Task 0.9: Create run.sh Script

### Create run script

- [x] `scripts/run.sh`

---

## Task 0.10: Create GitHub Actions Workflow

### Setup CI pipeline

- [x] `.github/workflows/ci.yml`

---

## Task 0.11: Create README

### Create project README

- [x] `README.md`

---

## Task 0.12: Supabase Local Setup

### Setup local Supabase

- [x] `supabase/config.toml` - Supabase configuration
- [x] `supabase/migrations/00001_initial_schema.sql` - Initial migration
- [x] `supabase/seed.sql` - Seed data

---

## Task 0.13: Make Scripts Executable & Final Verification

### Final setup

- [x] Make scripts executable: `chmod +x scripts/*.sh`
- [x] Run full verification (see checklist below)

---

## Verification Checklist

Before marking Phase 0 complete:

- [x] `pnpm install` works from root
- [x] `./scripts/init.sh` exits with 0 (requires Docker running)
- [x] `./scripts/test.sh` exits with 0
- [x] `./scripts/run.sh mobile` starts Expo
- [x] Mobile app shows "Hello World" in Expo Go
- [x] GitHub Actions CI passes
- [x] No TypeScript errors (26 tests pass)
- [x] No ESLint errors
- [x] No Prettier errors
- [x] A new developer can clone and run in <5 minutes

---

## Phase 0 Status: COMPLETE ✅

Completed: December 21, 2024
