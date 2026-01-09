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

## Template customization checklist

Do these steps first when starting a new app from this template.

### App identity (Expo)

All app identity settings are centralized in `apps/mobile/app.config.ts`:

- **Option 1 (recommended):** Set environment variables in `apps/mobile/.env.local`:
  - `APP_NAME` - Display name shown to users (default: "Template App")
  - `APP_SLUG` - Expo project slug (default: "template-app")
  - `APP_SCHEME` - Deep linking scheme (default: "template")
  - `APP_IOS_BUNDLE_ID` - iOS bundle identifier, reverse-DNS format (default: "com.example.app")
  - `APP_ANDROID_PACKAGE` - Android package name, reverse-DNS format (default: "com.example.app")

- **Option 2:** Edit defaults directly in `apps/mobile/app.config.ts`

**Note:** Bundle identifiers and package names must be unique. Use reverse-DNS format (e.g., `com.yourcompany.yourapp`).

### Package namespace

This template uses the `@acme/*` scope for internal workspace packages (`@acme/supabase`, `@acme/types`, `@acme/utils`). **You can keep this as-is** - it's only used internally and doesn't affect your published app. If you want to rename it for consistency:

- Update package names in `apps/mobile/package.json` and `packages/*/package.json`
- Update import paths across the repo (e.g. `import { supabase } from "@acme/supabase"`)
- Update TS path mapping in `apps/mobile/tsconfig.json` (and other app/package tsconfigs if added)

### Supabase project

- Create/link a Supabase project and apply migrations:
  - `./scripts/supabase-hosted.sh --project-ref <your-project-ref>`
- Set Expo env vars in `apps/mobile/.env.local`:
  - `EXPO_PUBLIC_SUPABASE_URL=https://<project-ref>.supabase.co`
  - `EXPO_PUBLIC_SUPABASE_ANON_KEY=<publishable/anon key>`

### Script metadata (optional)

- Set a friendly name for script output by uncommenting `PROJECT_NAME` in `scripts/project.conf`.

## Tech Stack

- **Mobile:** Expo (React Native)
- **Backend:** Supabase (hosted or local via Supabase CLI)
- **Language:** TypeScript

## Hosted Supabase (fastest setup)

1. Create a Supabase project (Dashboard).
2. Initialize project with hosted Supabase (one command):

```bash
./scripts/init.sh --project-ref <your-project-ref>
```

This will:
- Install dependencies
- Link to your hosted Supabase project
- Apply migrations and seed data
- Generate TypeScript types
- Create `apps/mobile/.env.local` with credentials

**Note:** If the anon key isn't automatically extracted, get it from [Supabase Dashboard](https://supabase.com/dashboard/project/<your-project-ref>/settings/api) and update `apps/mobile/.env.local`.

3. Start the app:

```bash
./scripts/run.sh mobile
```

**Alternative:** Use the standalone script if you prefer:

```bash
./scripts/init.sh  # Install dependencies only
pnpm supabase:hosted --project-ref <your-project-ref>  # Setup hosted Supabase
```

## License

MIT
