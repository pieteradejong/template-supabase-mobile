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

## Adding New Learnings

When you discover something non-obvious:

1. Document it here with the problem, cause, and solution
2. Keep it concise and actionable
3. Include code examples where helpful
