# Project Learnings

Discoveries made during development that aren't obvious from documentation.

---

## Expo Go + VPN

**Problem:** Expo Go on iPhone can't connect to Metro bundler on Mac when VPN is active.

**Cause:** VPN routes Mac traffic through a tunnel, making it unreachable from the local WiFi network. Even though both devices show the same WiFi, they're effectively on different networks.

**Solution:** Use tunnel mode by default.

```bash
# Default command uses tunnel mode
pnpm dev

# Equivalent to:
expo start --tunnel
```

Tunnel mode routes through Expo's ngrok servers, bypassing all local network issues.

### When to use LAN mode

If you're **not on VPN** and want faster hot reloads:

```bash
pnpm dev:lan
```

LAN mode connects directly over local network (faster, but requires same network without VPN).

### Available modes

| Command | Mode | Use Case |
|---------|------|----------|
| `pnpm dev` | Tunnel | Default, works on VPN |
| `pnpm dev:lan` | LAN | Faster, when not on VPN |
| `pnpm dev:local` | Localhost | Simulators only |

---

## Logging

See [LOGGING.md](LOGGING.md) for full logging standards.

### Mobile app logger

The mobile app uses `createLogger()` from `apps/mobile/lib/logger.ts`:

```typescript
import { createLogger } from "../lib/logger";

const log = createLogger("MyComponent");

log.debug("Detailed info", { data: value });
log.info("Normal operation");
log.warn("Something unexpected");
log.error("Something broke", error);
```

### Log levels by environment

- **Development (`__DEV__ = true`):** All levels (debug and above)
- **Production:** Only warn and error

---

## Supabase URL Misconfiguration (HTML / 404 response)

**Problem:** The app fails to fetch data and the error contains HTML (often a Supabase Studio 404 page).

**Cause:** `EXPO_PUBLIC_SUPABASE_URL` is pointing at the Supabase dashboard (`https://supabase.com/...`) instead of the project API URL.

**Solution:** Set `EXPO_PUBLIC_SUPABASE_URL` to the **Project URL**:

- Format: `https://<project-ref>.supabase.co`
- Example: `https://wbtwkqezastyccdowgpl.supabase.co`

Also ensure `EXPO_PUBLIC_SUPABASE_ANON_KEY` is the **publishable/anon key**, not a secret key.

---

## Expo env file name gotcha

**Problem:** Env vars appear “not loaded” when running via scripts.

**Cause:** Secrets file is missing or named incorrectly.

**Solution:** This template uses **one canonical secrets file**:

- `apps/mobile/.env.local`

Create it from the example:

```bash
cp apps/mobile/env.local.example apps/mobile/.env.local
```

Then set:

- `EXPO_PUBLIC_SUPABASE_URL=https://<project-ref>.supabase.co`
- `EXPO_PUBLIC_SUPABASE_ANON_KEY=<anon key>`

We intentionally **do not** support `apps/mobile/env.local` or root `.env.local`:

- **One source of truth**: scripts + Expo read the same file, so there’s nothing to “sync”.
- **Less confusion**: avoids “it works in one command but not another” due to different env file locations.
- **Safer by default**: the file is ignored by git, and we can add CI guardrails to prevent accidental commits.

---

## Test failures: vitest/eslint not found

**Problem:** `./scripts/test.sh --quick` fails with `vitest: command not found` or `eslint: command not found`.

**Cause:** Workspace dependencies haven’t been installed yet.

**Solution:** Run:

```bash
pnpm install
```

---

## CRUD Demo

The mobile app (`apps/mobile/app/index.tsx`) includes a minimal CRUD demo for the `items` table:

- **Create**: Tap the "+" button in the header → modal opens → enter title (required) and description (optional) → Create.
- **Delete**: Long-press any item card → confirm dialog → item is deleted.

Both operations use optimistic UI updates (no refetch needed) and include error handling with user-friendly alerts.

---

## Adding New Learnings

When you discover something non-obvious:

1. Document it here with the problem, cause, and solution
2. Keep it concise and actionable
3. Include code examples where helpful
