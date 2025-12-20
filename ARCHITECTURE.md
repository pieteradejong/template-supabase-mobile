# ARCHITECTURE

## Overview

This document describes the architectural decisions and patterns used in this template. It's intended for AI assistants (like Cursor) and developers to understand how the pieces fit together.

---

## Monorepo Structure

We use **pnpm workspaces** (not Turborepo) to keep things simple while enabling code sharing.

```
├── apps/           # Deployable applications
├── packages/       # Shared code
├── supabase/       # Database and edge functions
├── scripts/        # Project-level scripts
└── docs/           # Documentation
```

### Why pnpm workspaces over Turborepo?

- Simpler mental model
- No caching complexity
- Fewer assumptions for template users
- Users can add Turborepo later if needed

---

## Applications

### Web (`apps/web`)

**Stack:** Vite + React + Tailwind CSS

```
apps/web/
├── src/
│   ├── components/     # UI components
│   ├── hooks/          # React hooks (app-specific)
│   ├── pages/          # Route pages
│   ├── lib/            # Utilities, configs
│   └── main.tsx        # Entry point
├── public/             # Static assets
├── index.html
├── vite.config.ts
├── tailwind.config.js
└── tsconfig.json       # Extends base config
```

**Key decisions:**

- Vite for fast dev server and optimized builds
- File-based routing is NOT enforced (keep it flexible)
- Tailwind for styling (utility-first, purged in production)

### Mobile (`apps/mobile`)

**Stack:** Expo (managed workflow)

```
apps/mobile/
├── app/                # Expo Router (file-based routing)
│   ├── (auth)/         # Auth-required routes
│   ├── (public)/       # Public routes
│   └── _layout.tsx     # Root layout
├── components/         # UI components
├── hooks/              # React hooks (app-specific)
├── lib/                # Utilities, configs
├── app.json            # Expo config
├── eas.json            # EAS Build config
└── tsconfig.json       # Extends base config
```

**Key decisions:**

- Managed workflow for simpler updates and EAS integration
- Expo Router for file-based navigation (consistent with modern patterns)
- Expo SecureStore for sensitive data (tokens)

---

## Shared Packages

### `packages/supabase`

Central Supabase integration shared by both apps.

```
packages/supabase/
├── src/
│   ├── client.ts       # Supabase client initialization
│   ├── hooks/
│   │   ├── useAuth.ts  # Authentication hook
│   │   ├── useQuery.ts # Data fetching hook
│   │   └── useRealtime.ts  # Realtime subscription hook
│   ├── storage.ts      # Storage helpers
│   └── index.ts        # Public exports
├── package.json
└── tsconfig.json
```

**Key patterns:**

```typescript
// Client initialization - NEVER import service role client in apps
import { createClient } from "@supabase/supabase-js";
import type { Database } from "@acme/types";

export const supabase = createClient<Database>(
  process.env.SUPABASE_URL!,
  process.env.SUPABASE_ANON_KEY!,
);
```

```typescript
// Auth hook - abstracts storage differences
export function useAuth() {
  // Web: uses localStorage (Supabase default)
  // Mobile: uses SecureStore via custom storage adapter
}
```

### `packages/types`

Generated TypeScript types from Supabase schema.

```
packages/types/
├── src/
│   ├── database.ts     # Auto-generated from Supabase
│   ├── api.ts          # API request/response types
│   └── index.ts        # Re-exports
└── package.json
```

**Generation command:**

```bash
supabase gen types typescript --project-id <ref> > packages/types/src/database.ts
```

### `packages/utils`

Shared business logic and utilities.

```
packages/utils/
├── src/
│   ├── validation/     # Zod schemas
│   ├── formatting/     # Date, currency, etc.
│   ├── constants.ts    # Shared constants
│   └── index.ts
└── package.json
```

---

## Supabase

### Directory Structure

```
supabase/
├── migrations/         # SQL migrations (ordered by timestamp)
│   ├── 00001_initial.sql
│   └── 00002_rls_policies.sql
├── functions/          # Edge functions
│   └── example/
│       └── index.ts
├── seed.sql            # Development seed data
└── config.toml         # Local Supabase config
```

### Migration Conventions

- Prefix with incrementing number: `00001_`, `00002_`, etc.
- One migration per logical change
- Include both UP and DOWN when possible (as comments)
- Always enable RLS immediately after creating a table

### Row-Level Security (RLS) Pattern

```sql
-- 1. Create table
CREATE TABLE items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE NOT NULL,
  title TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Enable RLS immediately
ALTER TABLE items ENABLE ROW LEVEL SECURITY;

-- 3. Default deny (no policies = no access)

-- 4. Add specific policies
CREATE POLICY "Users can view own items"
  ON items FOR SELECT
  USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own items"
  ON items FOR INSERT
  WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own items"
  ON items FOR UPDATE
  USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own items"
  ON items FOR DELETE
  USING (auth.uid() = user_id);
```

### Edge Functions Pattern

```typescript
// supabase/functions/_shared/cors.ts
export const corsHeaders = {
  "Access-Control-Allow-Origin": Deno.env.get("ALLOWED_ORIGIN") || "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

// supabase/functions/_shared/auth.ts
export async function verifyAuth(req: Request) {
  const authHeader = req.headers.get("Authorization");
  if (!authHeader) throw new Error("Missing authorization header");

  const supabase = createClient(
    Deno.env.get("SUPABASE_URL")!,
    Deno.env.get("SUPABASE_ANON_KEY")!,
    { global: { headers: { Authorization: authHeader } } },
  );

  const {
    data: { user },
    error,
  } = await supabase.auth.getUser();
  if (error || !user) throw new Error("Invalid token");

  return { supabase, user };
}
```

---

## Authentication Flow

### Magic Link (Primary)

```
1. User enters email
2. App calls supabase.auth.signInWithOtp({ email })
3. Supabase sends email with magic link
4. User clicks link
5. Supabase redirects to app with tokens
6. App stores tokens (localStorage/SecureStore)
7. User is authenticated
```

### Token Storage

| Platform | Storage          | Security                         |
| -------- | ---------------- | -------------------------------- |
| Web      | localStorage     | Vulnerable to XSS; CSP mitigates |
| iOS      | Expo SecureStore | Keychain (encrypted)             |
| Android  | Expo SecureStore | EncryptedSharedPreferences       |

### Session Refresh

Supabase SDK handles refresh automatically. The custom auth hook should:

1. Listen for `onAuthStateChange` events
2. Update React state accordingly
3. Handle token refresh errors (sign out user)

---

## State Management

We keep state management minimal:

1. **Auth state**: React Context (via `useAuth` hook)
2. **Server state**: Direct Supabase queries (or React Query if added later)
3. **Local state**: React's useState/useReducer

**Why no Redux/Zustand by default?**

- Supabase handles server state well
- Auth context covers the main global state need
- Users can add state management if needed

---

## Security Layers

```
┌─────────────────────────────────────────┐
│           Client Application            │
│  - Input validation (Zod)               │
│  - Secure token storage                 │
└──────────────────┬──────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│           Edge Functions                │
│  - JWT verification                     │
│  - Input validation                     │
│  - Business logic authorization         │
└──────────────────┬──────────────────────┘
                   │
                   ▼
┌─────────────────────────────────────────┐
│           Supabase RLS                  │
│  - Row-level security policies          │
│  - Database-level access control        │
└─────────────────────────────────────────┘
```

Defense in depth: even if one layer fails, others protect the data.

---

## Environment Configuration

### Development

- Local Supabase via Docker (`supabase start`)
- `.env.local` with local URLs

### Staging (optional)

- Separate Supabase project
- `.env.staging`

### Production

- Production Supabase project
- Environment variables in deployment platform
- NEVER commit production secrets

---

## Import Conventions

```typescript
// Absolute imports from packages
import { supabase, useAuth } from "@acme/supabase";
import { createItemSchema } from "@acme/utils";
import type { Database } from "@acme/types";

// Relative imports within an app
import { Button } from "../components/Button";
import { useLocalState } from "../hooks/useLocalState";
```

Configure in `tsconfig.json`:

```json
{
  "compilerOptions": {
    "paths": {
      "@acme/*": ["../../packages/*/src"]
    }
  }
}
```

---

## Testing Strategy

| Layer          | Tool              | What to Test                                  |
| -------------- | ----------------- | --------------------------------------------- |
| Unit           | Vitest            | Utilities, validation schemas, pure functions |
| Integration    | Vitest + Supabase | Database queries, RLS policies, auth flows    |
| E2E (optional) | Playwright/Detox  | Critical user journeys                        |

### RLS Testing Pattern

```typescript
// Create test users
const userA = await createTestUser();
const userB = await createTestUser();

// User A creates an item
const item = await supabaseAs(userA).from("items").insert({ title: "A item" });

// User B should NOT see it
const { data } = await supabaseAs(userB).from("items").select("*");
expect(data).toHaveLength(0);

// User A should see it
const { data: ownData } = await supabaseAs(userA).from("items").select("*");
expect(ownData).toHaveLength(1);
```

---

## Adding New Features Checklist

When adding a new feature:

1. [ ] Add types to `packages/types`
2. [ ] Add validation schemas to `packages/utils`
3. [ ] Create migration in `supabase/migrations`
4. [ ] Add RLS policies in migration
5. [ ] Regenerate types: `pnpm gen:types`
6. [ ] Add hooks to `packages/supabase` if needed
7. [ ] Implement in both apps
8. [ ] Add tests
9. [ ] Update documentation
