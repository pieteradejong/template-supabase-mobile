# Supabase Mobile Template

A production-ready Expo mobile app template with Supabase backend.

## Quick Start

```bash
# Clone the repository
git clone <repo-url>
cd <repo-name>

# Initialize the project
./scripts/init.sh

# Start development server
./scripts/run.sh
```

Scan the QR code with Expo Go on your phone.

## Development

### Running the App

| Command | Mode | Use Case |
|---------|------|----------|
| `pnpm dev` | Tunnel | Default, works on VPN |
| `pnpm dev:lan` | LAN | Faster, when not on VPN |
| `pnpm dev:local` | Localhost | iOS/Android simulators only |

**Note:** Tunnel mode is the default because most developers use VPN. See [LEARNINGS.md](LEARNINGS.md) for details.

### Scripts

| Script | Purpose |
|--------|---------|
| `./scripts/init.sh` | Setup from fresh clone |
| `./scripts/test.sh` | Run all checks (lint, types, format) |
| `./scripts/run.sh` | Start Expo dev server |

### Project Structure

```
apps/mobile/          # Expo app
  app/                # Expo Router screens
  lib/                # Utilities (logger, etc.)
scripts/              # Project scripts
```

## Documentation

- [ROADMAP.md](ROADMAP.md) - Build phases
- [ARCHITECTURE.md](ARCHITECTURE.md) - Technical decisions
- [CONVENTIONS.md](CONVENTIONS.md) - Code style
- [LOGGING.md](LOGGING.md) - Logging standards
- [LEARNINGS.md](LEARNINGS.md) - Gotchas and discoveries

## Tech Stack

- **Mobile:** Expo (React Native)
- **Backend:** Supabase (hosted or local via Supabase CLI)
- **Language:** TypeScript

## Hosted Supabase (fastest setup)

1. Create a Supabase project (Dashboard).
2. Apply schema + seed data to hosted Supabase (idempotent):

```bash
./scripts/supabase-hosted.sh --project-ref <your-project-ref>
```

3. Configure Expo env vars:
   - Copy `apps/mobile/env.local.example` → `apps/mobile/.env.local`
   - Fill in:
     - `EXPO_PUBLIC_SUPABASE_URL=...`
     - `EXPO_PUBLIC_SUPABASE_ANON_KEY=...`
4. Start the app:

```bash
./scripts/run.sh mobile
```

## License

MIT
