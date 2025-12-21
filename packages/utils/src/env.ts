import { z } from "zod";

/**
 * Environment variable schema for Supabase configuration.
 *
 * This schema validates that required environment variables are set
 * and have the correct format.
 */
export const envSchema = z.object({
  // Supabase Configuration
  // Use EXPO_PUBLIC_ prefix for Expo apps, or standard names for other environments
  SUPABASE_URL: z.string().url().optional().describe("Supabase project URL"),
  SUPABASE_ANON_KEY: z.string().min(1).optional().describe("Supabase anonymous key"),

  // Expo variants (these take precedence in Expo apps)
  EXPO_PUBLIC_SUPABASE_URL: z.string().url().optional().describe("Supabase project URL (Expo)"),
  EXPO_PUBLIC_SUPABASE_ANON_KEY: z
    .string()
    .min(1)
    .optional()
    .describe("Supabase anonymous key (Expo)"),

  // App Configuration
  APP_ENV: z
    .enum(["development", "staging", "production"])
    .default("development")
    .describe("Application environment"),
});

/**
 * Inferred type from the environment schema.
 */
export type EnvConfig = z.infer<typeof envSchema>;

/**
 * Validate environment variables against the schema.
 *
 * @param env - Object containing environment variables (defaults to process.env)
 * @returns Validated and typed environment configuration
 * @throws ZodError if validation fails
 *
 * @example
 * ```typescript
 * import { validateEnv } from '@acme/utils';
 *
 * const env = validateEnv();
 * console.log(env.APP_ENV); // 'development'
 * ```
 */
export function validateEnv(env: Record<string, string | undefined> = process.env): EnvConfig {
  return envSchema.parse(env);
}

/**
 * Get a validated environment configuration.
 * Returns null if validation fails instead of throwing.
 *
 * @param env - Object containing environment variables (defaults to process.env)
 * @returns Validated environment configuration or null
 *
 * @example
 * ```typescript
 * import { getEnv } from '@acme/utils';
 *
 * const env = getEnv();
 * if (!env) {
 *   console.error('Invalid environment configuration');
 *   process.exit(1);
 * }
 * ```
 */
export function getEnv(env: Record<string, string | undefined> = process.env): EnvConfig | null {
  const result = envSchema.safeParse(env);
  return result.success ? result.data : null;
}
