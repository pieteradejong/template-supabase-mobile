# CONVENTIONS

Code conventions and patterns for this project. Follow these when writing or modifying code.

---

## General Principles

1. **Simplicity over cleverness** - Write code that's easy to read and modify
2. **Explicit over implicit** - Be clear about what code does
3. **Fail fast** - Validate early, error with helpful messages
4. **Type everything** - No `any` types, no implicit types

---

## TypeScript

### Strict Mode

All TypeScript configs extend the base config with strict settings:

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true
  }
}
```

### Type Imports

Always use type-only imports for types:

```typescript
// ✅ Good
import type { User } from '@acme/types';
import { supabase } from '@acme/supabase';

// ❌ Bad
import { User } from '@acme/types';  // User is only a type
```

### Prefer Interfaces for Object Shapes

```typescript
// ✅ Good - use interface for object shapes
interface UserProfile {
  id: string;
  displayName: string;
  email: string;
}

// ✅ Good - use type for unions, primitives, computed types
type Status = 'loading' | 'success' | 'error';
type UserWithPosts = User & { posts: Post[] };

// ❌ Bad - type for simple object shapes
type UserProfile = {
  id: string;
  // ...
};
```

### No `any`

```typescript
// ✅ Good
function parseData(data: unknown): User {
  const parsed = userSchema.parse(data);
  return parsed;
}

// ❌ Bad
function parseData(data: any): User {
  return data as User;
}
```

---

## React

### Function Components Only

```typescript
// ✅ Good
export function Button({ children, onClick }: ButtonProps) {
  return <button onClick={onClick}>{children}</button>;
}

// ❌ Bad - class components
class Button extends React.Component { }

// ❌ Bad - React.FC (verbose, issues with generics)
const Button: React.FC<ButtonProps> = ({ children }) => { };
```

### Props Interface Naming

```typescript
// ✅ Good - Props suffix
interface ButtonProps {
  variant?: 'primary' | 'secondary';
  children: React.ReactNode;
}

export function Button({ variant = 'primary', children }: ButtonProps) { }
```

### Hooks

```typescript
// ✅ Good - descriptive names, consistent return shape
export function useAuth() {
  const [user, setUser] = useState<User | null>(null);
  const [loading, setLoading] = useState(true);
  
  // ... logic
  
  return {
    user,
    loading,
    signIn,
    signOut,
  };
}

// ✅ Good - custom hooks start with "use"
export function useDebounce<T>(value: T, delay: number): T { }
```

### Event Handlers

```typescript
// ✅ Good - named handlers
function LoginForm() {
  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    // ...
  };
  
  return <form onSubmit={handleSubmit}>...</form>;
}

// ❌ Bad - inline complex logic
function LoginForm() {
  return (
    <form onSubmit={(e) => {
      e.preventDefault();
      // 20 lines of logic
    }}>
      ...
    </form>
  );
}
```

---

## File & Folder Naming

### Files

```
# Components - PascalCase
Button.tsx
UserProfile.tsx

# Hooks - camelCase with "use" prefix  
useAuth.ts
useDebounce.ts

# Utilities - camelCase
formatDate.ts
validation.ts

# Types - camelCase
types.ts
database.ts

# Constants - camelCase
constants.ts
```

### Folders

```
# All lowercase, hyphen-separated
components/
user-profile/
auth-hooks/
```

### Index Files

Use `index.ts` for clean exports:

```typescript
// packages/utils/src/index.ts
export * from './validation';
export * from './formatting';
export { CONSTANTS } from './constants';
```

---

## Imports

### Order

1. External packages
2. Internal packages (`@acme/*`)
3. Relative imports (parent, then sibling, then children)
4. Types (at the end)

```typescript
// 1. External
import { useState, useEffect } from 'react';
import { z } from 'zod';

// 2. Internal packages
import { supabase } from '@acme/supabase';
import { formatDate } from '@acme/utils';

// 3. Relative
import { Button } from '../components/Button';
import { useLocalState } from './useLocalState';

// 4. Types
import type { User } from '@acme/types';
```

### No Default Exports

```typescript
// ✅ Good - named exports
export function Button() { }
export const BUTTON_VARIANTS = ['primary', 'secondary'];

// ❌ Bad - default exports (harder to refactor, inconsistent imports)
export default function Button() { }
```

Exception: Page components if required by framework (Next.js, Expo Router).

---

## Error Handling

### Use Result Pattern for Expected Errors

```typescript
// ✅ Good - explicit error handling
interface Result<T, E = Error> {
  data: T | null;
  error: E | null;
}

async function fetchUser(id: string): Promise<Result<User>> {
  const { data, error } = await supabase
    .from('users')
    .select('*')
    .eq('id', id)
    .single();
    
  if (error) {
    return { data: null, error };
  }
  
  return { data, error: null };
}
```

### Throw for Unexpected Errors

```typescript
// ✅ Good - throw for programming errors
function assertNonNull<T>(value: T | null, message: string): T {
  if (value === null) {
    throw new Error(message);
  }
  return value;
}
```

### Always Validate External Data

```typescript
// ✅ Good - validate API responses
const userSchema = z.object({
  id: z.string().uuid(),
  email: z.string().email(),
  displayName: z.string().optional(),
});

async function fetchUser(id: string) {
  const response = await fetch(`/api/users/${id}`);
  const data = await response.json();
  return userSchema.parse(data);  // Throws if invalid
}
```

---

## Supabase

### Client Usage

```typescript
// ✅ Good - typed queries
const { data, error } = await supabase
  .from('items')
  .select('id, title, created_at')
  .eq('user_id', userId)
  .order('created_at', { ascending: false });

// ❌ Bad - select('*') when you don't need everything
const { data } = await supabase.from('items').select('*');
```

### RLS-Aware Code

```typescript
// ✅ Good - trust RLS, keep queries simple
// RLS ensures user can only see their items
const { data: items } = await supabase.from('items').select('*');

// ❌ Bad - redundant filtering (RLS already handles this)
const { data: items } = await supabase
  .from('items')
  .select('*')
  .eq('user_id', currentUser.id);  // RLS already does this
```

### Realtime Subscriptions

```typescript
// ✅ Good - clean up subscriptions
useEffect(() => {
  const channel = supabase
    .channel('items')
    .on('postgres_changes', { event: '*', schema: 'public', table: 'items' }, 
      (payload) => {
        // Handle change
      }
    )
    .subscribe();
    
  return () => {
    supabase.removeChannel(channel);
  };
}, []);
```

---

## Validation with Zod

### Schema Location

All Zod schemas live in `packages/utils/src/validation/`.

### Schema Naming

```typescript
// ✅ Good
export const createItemSchema = z.object({ ... });
export const updateItemSchema = createItemSchema.partial();
export const itemIdSchema = z.string().uuid();

// Infer types from schemas
export type CreateItemInput = z.infer<typeof createItemSchema>;
export type UpdateItemInput = z.infer<typeof updateItemSchema>;
```

### Validation Pattern

```typescript
// ✅ Good - validate at boundaries
async function createItem(input: unknown) {
  // 1. Validate input
  const validatedInput = createItemSchema.parse(input);
  
  // 2. Use validated data
  const { data, error } = await supabase
    .from('items')
    .insert(validatedInput);
    
  return { data, error };
}
```

---

## Testing

### Test File Location

Co-locate tests with source files:

```
src/
  utils/
    formatDate.ts
    formatDate.test.ts
  hooks/
    useAuth.ts
    useAuth.test.ts
```

### Test Naming

```typescript
describe('formatDate', () => {
  it('formats ISO date to readable string', () => { });
  it('returns "Invalid date" for malformed input', () => { });
  it('handles timezone offsets correctly', () => { });
});
```

### Arrange-Act-Assert

```typescript
it('creates an item for authenticated user', async () => {
  // Arrange
  const user = await createTestUser();
  const input = { title: 'Test Item' };
  
  // Act
  const result = await createItem(user, input);
  
  // Assert
  expect(result.error).toBeNull();
  expect(result.data?.title).toBe('Test Item');
});
```

---

## Comments

### When to Comment

```typescript
// ✅ Good - explain WHY, not WHAT
// We retry 3 times because the payment API has intermittent failures
const MAX_RETRIES = 3;

// ✅ Good - document non-obvious behavior
// RLS handles user filtering, so we select all and let the policy filter
const { data } = await supabase.from('items').select('*');

// ❌ Bad - explains the obvious
// Increment counter by 1
counter += 1;
```

### TODO Format

```typescript
// TODO(username): Description of what needs to be done
// TODO: Short description is also fine
```

---

## Git

### Commit Messages

```
type(scope): description

feat(auth): add magic link authentication
fix(items): handle null description in item card
docs(readme): update setup instructions
refactor(supabase): extract auth hook to shared package
test(rls): add cross-user access tests
chore(deps): update supabase-js to v2.39
```

Types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`

### Branch Naming

```
feature/add-magic-link-auth
fix/item-card-null-description
docs/update-readme
```

---

## Environment Variables

### Naming

```bash
# Service name prefix, uppercase, underscores
SUPABASE_URL=
SUPABASE_ANON_KEY=
SUPABASE_SERVICE_ROLE_KEY=

# App-level config
APP_ENV=development
APP_DEBUG=true
```

### Validation

Always validate at startup:

```typescript
// packages/utils/src/env.ts
import { z } from 'zod';

const envSchema = z.object({
  SUPABASE_URL: z.string().url(),
  SUPABASE_ANON_KEY: z.string().min(1),
  APP_ENV: z.enum(['development', 'staging', 'production']).default('development'),
});

export const env = envSchema.parse(process.env);
```