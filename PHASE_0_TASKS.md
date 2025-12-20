# Phase 0: Project Foundation - Task Breakdown

**Goal:** Empty monorepo with working `init.sh`, `test.sh`, and `run.sh` scripts.

**Definition of Done:**

```bash
git clone <repo>
./init.sh           # Completes with exit 0
./test.sh           # Completes with exit 0
./run.sh            # Both apps accessible
```

---

## Task 0.1: Initialize Monorepo Structure

### Create root configuration files

- [ ] `package.json` - Root package with workspaces config
- [ ] `pnpm-workspace.yaml` - Define workspace packages
- [ ] `.npmrc` - pnpm configuration
- [ ] `.gitignore` - Comprehensive ignore patterns

#### `package.json`

```json
{
  "name": "supabase-react-native-template",
  "private": true,
  "scripts": {
    "dev": "./scripts/run.sh",
    "test": "./scripts/test.sh",
    "lint": "eslint . --ext .ts,.tsx",
    "typecheck": "tsc --noEmit",
    "clean": "rm -rf node_modules apps/*/node_modules packages/*/node_modules"
  },
  "devDependencies": {
    "@types/node": "^20",
    "typescript": "^5.3"
  },
  "engines": {
    "node": ">=18",
    "pnpm": ">=8"
  },
  "packageManager": "pnpm@8.15.0"
}
```

#### `pnpm-workspace.yaml`

```yaml
packages:
  - "apps/*"
  - "packages/*"
```

---

## Task 0.2: TypeScript Configuration

### Create shared TypeScript config

- [ ] `tsconfig.base.json` - Shared compiler options

#### `tsconfig.base.json`

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "resolveJsonModule": true,
    "allowJs": false,
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "noEmit": true,
    "esModuleInterop": true,
    "skipLibCheck": true,
    "isolatedModules": true,
    "verbatimModuleSyntax": true,
    "declaration": true,
    "declarationMap": true,
    "sourceMap": true
  }
}
```

---

## Task 0.3: ESLint & Prettier Configuration

### Create shared linting config

- [ ] `.eslintrc.js` - ESLint configuration
- [ ] `.prettierrc` - Prettier configuration
- [ ] `.prettierignore` - Prettier ignore patterns
- [ ] Add lint dependencies to root `package.json`

#### `.eslintrc.js`

```javascript
module.exports = {
  root: true,
  parser: "@typescript-eslint/parser",
  plugins: ["@typescript-eslint"],
  extends: [
    "eslint:recommended",
    "plugin:@typescript-eslint/recommended",
    "plugin:@typescript-eslint/recommended-requiring-type-checking",
    "prettier",
  ],
  parserOptions: {
    project: [
      "./tsconfig.base.json",
      "./apps/*/tsconfig.json",
      "./packages/*/tsconfig.json",
    ],
    tsconfigRootDir: __dirname,
  },
  rules: {
    "@typescript-eslint/no-unused-vars": ["error", { argsIgnorePattern: "^_" }],
    "@typescript-eslint/consistent-type-imports": "error",
    "@typescript-eslint/no-explicit-any": "error",
  },
  ignorePatterns: ["node_modules", "dist", ".expo", "build"],
};
```

#### `.prettierrc`

```json
{
  "semi": true,
  "singleQuote": true,
  "tabWidth": 2,
  "trailingComma": "es5",
  "printWidth": 100
}
```

#### Dependencies to add

```json
{
  "devDependencies": {
    "@typescript-eslint/eslint-plugin": "^6",
    "@typescript-eslint/parser": "^6",
    "eslint": "^8",
    "eslint-config-prettier": "^9",
    "prettier": "^3"
  }
}
```

---

## Task 0.4: Create Web App (Vite + React)

### Initialize Vite React app

- [ ] Create `apps/web` directory structure
- [ ] `apps/web/package.json`
- [ ] `apps/web/tsconfig.json`
- [ ] `apps/web/vite.config.ts`
- [ ] `apps/web/tailwind.config.js`
- [ ] `apps/web/postcss.config.js`
- [ ] `apps/web/index.html`
- [ ] `apps/web/src/main.tsx`
- [ ] `apps/web/src/App.tsx`
- [ ] `apps/web/src/index.css` (Tailwind imports)

#### `apps/web/package.json`

```json
{
  "name": "@acme/web",
  "private": true,
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "react": "^18.2",
    "react-dom": "^18.2"
  },
  "devDependencies": {
    "@types/react": "^18.2",
    "@types/react-dom": "^18.2",
    "@vitejs/plugin-react": "^4",
    "autoprefixer": "^10",
    "postcss": "^8",
    "tailwindcss": "^3",
    "vite": "^5"
  }
}
```

#### `apps/web/src/App.tsx`

```tsx
export function App() {
  return (
    <div className="min-h-screen flex items-center justify-center bg-gray-100">
      <div className="text-center">
        <h1 className="text-4xl font-bold text-gray-900">Hello World</h1>
        <p className="mt-2 text-gray-600">Web app is running</p>
      </div>
    </div>
  );
}
```

---

## Task 0.5: Create Mobile App (Expo)

### Initialize Expo app

- [ ] Create `apps/mobile` directory structure
- [ ] `apps/mobile/package.json`
- [ ] `apps/mobile/tsconfig.json`
- [ ] `apps/mobile/app.json`
- [ ] `apps/mobile/babel.config.js`
- [ ] `apps/mobile/app/_layout.tsx` (Expo Router)
- [ ] `apps/mobile/app/index.tsx`

#### `apps/mobile/package.json`

```json
{
  "name": "@acme/mobile",
  "private": true,
  "main": "expo-router/entry",
  "scripts": {
    "dev": "expo start",
    "android": "expo start --android",
    "ios": "expo start --ios",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "expo": "~50.0",
    "expo-router": "~3.4",
    "expo-status-bar": "~1.11",
    "react": "18.2.0",
    "react-native": "0.73",
    "react-native-safe-area-context": "4.8",
    "react-native-screens": "~3.29"
  },
  "devDependencies": {
    "@babel/core": "^7.20.0",
    "@types/react": "~18.2",
    "typescript": "^5.3"
  }
}
```

#### `apps/mobile/app/index.tsx`

```tsx
import { View, Text, StyleSheet } from "react-native";

export default function HomeScreen() {
  return (
    <View style={styles.container}>
      <Text style={styles.title}>Hello World</Text>
      <Text style={styles.subtitle}>Mobile app is running</Text>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
    backgroundColor: "#f3f4f6",
  },
  title: {
    fontSize: 32,
    fontWeight: "bold",
    color: "#111827",
  },
  subtitle: {
    marginTop: 8,
    fontSize: 16,
    color: "#4b5563",
  },
});
```

---

## Task 0.6: Create Shared Packages (Stubs)

### Create package stubs

- [ ] `packages/supabase/package.json`
- [ ] `packages/supabase/src/index.ts` (empty export)
- [ ] `packages/supabase/tsconfig.json`
- [ ] `packages/types/package.json`
- [ ] `packages/types/src/index.ts`
- [ ] `packages/types/tsconfig.json`
- [ ] `packages/utils/package.json`
- [ ] `packages/utils/src/index.ts`
- [ ] `packages/utils/tsconfig.json`

#### Example: `packages/supabase/package.json`

```json
{
  "name": "@acme/supabase",
  "private": true,
  "main": "./src/index.ts",
  "types": "./src/index.ts",
  "scripts": {
    "typecheck": "tsc --noEmit"
  },
  "devDependencies": {
    "typescript": "^5.3"
  }
}
```

#### Example: `packages/supabase/src/index.ts`

```typescript
// Supabase client will be implemented in Phase 1
export {};
```

---

## Task 0.7: Create Environment Configuration

### Setup environment handling

- [ ] `.env.example` - Example environment file
- [ ] `packages/utils/src/env.ts` - Environment validation (stub)

#### `.env.example`

```bash
# Supabase Configuration
SUPABASE_URL=http://localhost:54321
SUPABASE_ANON_KEY=your-anon-key
SUPABASE_SERVICE_ROLE_KEY=your-service-role-key

# App Configuration
APP_ENV=development
```

---

## Task 0.8: Create init.sh Script

### Create initialization script

- [ ] `scripts/init.sh`

#### `scripts/init.sh`

```bash
#!/bin/bash
set -e

echo "🚀 Initializing project..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check prerequisites
echo "📋 Checking prerequisites..."

check_command() {
    if ! command -v $1 &> /dev/null; then
        echo -e "${RED}❌ $1 is not installed${NC}"
        echo "   Please install $1: $2"
        exit 1
    else
        echo -e "${GREEN}✓${NC} $1 found"
    fi
}

check_command "node" "https://nodejs.org"
check_command "pnpm" "npm install -g pnpm"

# Check Node version
NODE_VERSION=$(node -v | cut -d'v' -f2 | cut -d'.' -f1)
if [ "$NODE_VERSION" -lt 18 ]; then
    echo -e "${RED}❌ Node.js version must be >= 18 (found v$NODE_VERSION)${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} Node.js version OK (v$(node -v | cut -d'v' -f2))"

# Check pnpm version
PNPM_VERSION=$(pnpm -v | cut -d'.' -f1)
if [ "$PNPM_VERSION" -lt 8 ]; then
    echo -e "${RED}❌ pnpm version must be >= 8 (found v$(pnpm -v))${NC}"
    exit 1
fi
echo -e "${GREEN}✓${NC} pnpm version OK (v$(pnpm -v))"

# Install dependencies
echo ""
echo "📦 Installing dependencies..."
pnpm install

# Setup environment file
if [ ! -f .env.local ]; then
    echo ""
    echo "🔧 Creating .env.local from .env.example..."
    cp .env.example .env.local
    echo -e "${YELLOW}⚠️  Please update .env.local with your actual values${NC}"
fi

# Phase 1+ will add:
# - Supabase CLI check
# - supabase start
# - Run migrations
# - Seed database
# - Generate types

echo ""
echo -e "${GREEN}✅ Initialization complete!${NC}"
echo ""
echo "Next steps:"
echo "  1. Update .env.local with your Supabase credentials"
echo "  2. Run ./scripts/run.sh to start development servers"
echo ""
```

---

## Task 0.9: Create test.sh Script

### Create test script

- [ ] `scripts/test.sh`

#### `scripts/test.sh`

```bash
#!/bin/bash
set -e

echo "🧪 Running tests..."

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Parse arguments
CI_MODE=false
QUICK_MODE=false

for arg in "$@"; do
    case $arg in
        --ci)
            CI_MODE=true
            ;;
        --quick)
            QUICK_MODE=true
            ;;
    esac
done

FAILED=0

# Lint
echo ""
echo "📝 Running ESLint..."
if pnpm lint; then
    echo -e "${GREEN}✓${NC} Lint passed"
else
    echo -e "${RED}❌ Lint failed${NC}"
    FAILED=1
fi

# Type check
echo ""
echo "🔍 Running TypeScript type check..."
if pnpm typecheck; then
    echo -e "${GREEN}✓${NC} Type check passed"
else
    echo -e "${RED}❌ Type check failed${NC}"
    FAILED=1
fi

# Unit tests (Phase 1+)
if [ "$QUICK_MODE" = false ]; then
    echo ""
    echo "🧪 Running unit tests..."
    # pnpm test:unit
    echo -e "${GREEN}✓${NC} Unit tests passed (no tests yet)"
fi

# Integration tests (Phase 1+)
if [ "$QUICK_MODE" = false ]; then
    echo ""
    echo "🔗 Running integration tests..."
    # pnpm test:integration
    echo -e "${GREEN}✓${NC} Integration tests passed (no tests yet)"
fi

# Security audit
echo ""
echo "🔒 Running security audit..."
if pnpm audit --audit-level=high; then
    echo -e "${GREEN}✓${NC} Security audit passed"
else
    echo -e "${RED}⚠️  Security vulnerabilities found${NC}"
    if [ "$CI_MODE" = true ]; then
        FAILED=1
    fi
fi

# Summary
echo ""
if [ $FAILED -eq 0 ]; then
    echo -e "${GREEN}✅ All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}❌ Some tests failed${NC}"
    exit 1
fi
```

---

## Task 0.10: Create run.sh Script

### Create run script

- [ ] `scripts/run.sh`

#### `scripts/run.sh`

```bash
#!/bin/bash

echo "🏃 Starting development servers..."

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Parse arguments
RUN_WEB=false
RUN_MOBILE=false
RUN_ALL=false

if [ $# -eq 0 ]; then
    RUN_ALL=true
fi

for arg in "$@"; do
    case $arg in
        --web)
            RUN_WEB=true
            ;;
        --mobile)
            RUN_MOBILE=true
            ;;
        --all)
            RUN_ALL=true
            ;;
    esac
done

if [ "$RUN_ALL" = true ]; then
    RUN_WEB=true
    RUN_MOBILE=true
fi

# Phase 1+ will add:
# - Start local Supabase if not running
# - Start edge functions

# Function to cleanup on exit
cleanup() {
    echo ""
    echo "Shutting down..."
    kill $(jobs -p) 2>/dev/null
}
trap cleanup EXIT

# Start servers
if [ "$RUN_WEB" = true ] && [ "$RUN_MOBILE" = true ]; then
    echo ""
    echo -e "${GREEN}Starting web and mobile servers...${NC}"
    echo ""
    echo -e "${YELLOW}Web:${NC}    http://localhost:5173"
    echo -e "${YELLOW}Mobile:${NC} Press 'i' for iOS, 'a' for Android in Expo"
    echo ""

    # Run both in parallel
    (cd apps/web && pnpm dev) &
    (cd apps/mobile && pnpm dev) &

    wait
elif [ "$RUN_WEB" = true ]; then
    echo ""
    echo -e "${GREEN}Starting web server...${NC}"
    echo -e "${YELLOW}URL:${NC} http://localhost:5173"
    echo ""
    cd apps/web && pnpm dev
elif [ "$RUN_MOBILE" = true ]; then
    echo ""
    echo -e "${GREEN}Starting mobile server...${NC}"
    echo -e "${YELLOW}Press 'i' for iOS, 'a' for Android${NC}"
    echo ""
    cd apps/mobile && pnpm dev
fi
```

---

## Task 0.11: Create GitHub Actions Workflow

### Setup CI pipeline

- [ ] `.github/workflows/ci.yml`

#### `.github/workflows/ci.yml`

```yaml
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
      - name: Checkout
        uses: actions/checkout@v4

      - name: Setup pnpm
        uses: pnpm/action-setup@v2
        with:
          version: 8

      - name: Setup Node.js
        uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "pnpm"

      - name: Install dependencies
        run: pnpm install

      - name: Run tests
        run: ./scripts/test.sh --ci

      - name: Build web
        run: cd apps/web && pnpm build
```

---

## Task 0.12: Create README

### Create project README

- [ ] `README.md`

#### `README.md`

````markdown
# Supabase + React + React Native Template

A production-ready monorepo template for building web and mobile apps with shared code.

## Tech Stack

- **Web**: Vite + React + Tailwind CSS
- **Mobile**: Expo (iOS + Android)
- **Backend**: Supabase
- **Monorepo**: pnpm workspaces

## Quick Start

```bash
# Clone the repository
git clone <repo-url>
cd <repo-name>

# Initialize the project
./scripts/init.sh

# Start development servers
./scripts/run.sh
```
````

## Scripts

| Script                      | Description                                        |
| --------------------------- | -------------------------------------------------- |
| `./scripts/init.sh`         | Initialize project (install deps, setup env)       |
| `./scripts/test.sh`         | Run all tests (lint, typecheck, unit, integration) |
| `./scripts/run.sh`          | Start development servers                          |
| `./scripts/run.sh --web`    | Start web only                                     |
| `./scripts/run.sh --mobile` | Start mobile only                                  |

## Project Structure

```
├── apps/
│   ├── web/          # Vite + React + Tailwind
│   └── mobile/       # Expo (iOS + Android)
├── packages/
│   ├── supabase/     # Supabase client & hooks
│   ├── types/        # Shared TypeScript types
│   └── utils/        # Shared utilities
├── supabase/         # Migrations & edge functions
└── scripts/          # Project scripts
```

## Documentation

- [Roadmap](./ROADMAP.md) - Build phases and tasks
- [Architecture](./ARCHITECTURE.md) - Technical decisions
- [Conventions](./CONVENTIONS.md) - Code style guide

## License

MIT

````

---

## Task 0.13: Make Scripts Executable & Final Verification

### Final setup

- [ ] Make scripts executable: `chmod +x scripts/*.sh`
- [ ] Run full verification:

```bash
# From project root
./scripts/init.sh    # Should complete with exit 0
./scripts/test.sh    # Should complete with exit 0
./scripts/run.sh     # Should start both servers
````

---

## Verification Checklist

Before marking Phase 0 complete:

- [ ] `pnpm install` works from root
- [ ] `./scripts/init.sh` exits with 0
- [ ] `./scripts/test.sh` exits with 0
- [ ] `./scripts/run.sh` starts both apps
- [ ] `./scripts/run.sh --web` starts only web
- [ ] `./scripts/run.sh --mobile` starts only mobile
- [ ] Web app shows "Hello World" at localhost:5173
- [ ] Mobile app shows "Hello World" in Expo Go
- [ ] GitHub Actions CI passes
- [ ] No TypeScript errors
- [ ] No ESLint errors
- [ ] A new developer can clone and run in <5 minutes
