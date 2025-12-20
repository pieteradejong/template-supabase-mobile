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
- **Backend:** Supabase (coming soon)
- **Language:** TypeScript

## License

MIT
