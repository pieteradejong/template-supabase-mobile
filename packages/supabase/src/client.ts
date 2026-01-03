import { createClient, SupabaseClientOptions } from "@supabase/supabase-js";
import type { Database } from "@acme/types";

/**
 * Get Supabase URL from environment variables.
 * Supports both Expo (EXPO_PUBLIC_) and standard naming.
 */
function getSupabaseUrl(): string {
  const url = process.env.EXPO_PUBLIC_SUPABASE_URL ?? process.env.SUPABASE_URL ?? "";

  if (!url) {
    console.warn("Supabase URL not configured. Set EXPO_PUBLIC_SUPABASE_URL or SUPABASE_URL.");
  } else if (url.includes("supabase.com/dashboard") || url.startsWith("https://supabase.com")) {
    console.warn(
      "Supabase URL looks like a dashboard URL. Use your project API URL (Project URL) like: https://<project-ref>.supabase.co"
    );
  }

  return url;
}

/**
 * Get Supabase anon key from environment variables.
 * Supports both Expo (EXPO_PUBLIC_) and standard naming.
 */
function getSupabaseAnonKey(): string {
  const key = process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY ?? process.env.SUPABASE_ANON_KEY ?? "";

  if (!key) {
    console.warn(
      "Supabase anon key not configured. Set EXPO_PUBLIC_SUPABASE_ANON_KEY or SUPABASE_ANON_KEY."
    );
  }

  return key;
}

/**
 * Create a typed Supabase client with custom options.
 *
 * @param options - Additional Supabase client options
 * @returns Typed Supabase client
 *
 * @example
 * ```typescript
 * import { createSupabaseClient } from '@acme/supabase';
 * import { ExpoSecureStoreAdapter } from '@acme/supabase';
 *
 * const supabase = createSupabaseClient({
 *   auth: {
 *     storage: new ExpoSecureStoreAdapter(),
 *   },
 * });
 * ```
 */
export function createSupabaseClient(options?: SupabaseClientOptions<"public">) {
  const url = getSupabaseUrl();
  const key = getSupabaseAnonKey();

  return createClient<Database>(url, key, {
    auth: {
      autoRefreshToken: true,
      persistSession: true,
      detectSessionInUrl: false,
      ...options?.auth,
    },
    ...options,
  });
}

/**
 * Default Supabase client instance (lazily initialized).
 *
 * For mobile apps, you should create your own client with SecureStore:
 * ```typescript
 * import { createSupabaseClient, ExpoSecureStoreAdapter } from '@acme/supabase';
 *
 * export const supabase = createSupabaseClient({
 *   auth: { storage: new ExpoSecureStoreAdapter() },
 * });
 * ```
 */
let _supabaseClient: ReturnType<typeof createSupabaseClient> | null = null;

/**
 * Get the default Supabase client instance.
 * The client is lazily initialized on first access.
 */
export function getSupabase() {
  if (!_supabaseClient) {
    _supabaseClient = createSupabaseClient();
  }
  return _supabaseClient;
}

/**
 * @deprecated Use `getSupabase()` or `createSupabaseClient()` instead.
 * This export is provided for backwards compatibility but may throw
 * if environment variables are not configured when the module is loaded.
 */
export const supabase = new Proxy({} as ReturnType<typeof createSupabaseClient>, {
  get(_target, prop) {
    return getSupabase()[prop as keyof ReturnType<typeof createSupabaseClient>];
  },
});
