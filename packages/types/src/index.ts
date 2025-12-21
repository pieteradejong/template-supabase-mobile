/**
 * @acme/types - Shared TypeScript types
 *
 * This package exports types generated from Supabase and
 * other shared type definitions.
 */

export type { Database, Tables, Enums } from "./database";

// Re-export commonly used table types for convenience
export type { Tables as TableTypes } from "./database";
