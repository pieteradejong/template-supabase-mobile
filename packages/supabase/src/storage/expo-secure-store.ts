/**
 * Expo SecureStore adapter for Supabase auth session storage.
 *
 * This adapter stores auth tokens securely using:
 * - iOS: Keychain (encrypted)
 * - Android: EncryptedSharedPreferences
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

// We use dynamic import to avoid issues when this code runs in non-Expo environments
let SecureStore: typeof import("expo-secure-store") | null = null;

try {
  // eslint-disable-next-line @typescript-eslint/no-require-imports
  SecureStore = require("expo-secure-store");
} catch {
  // expo-secure-store not available (e.g., in web or Node.js environment)
}

/**
 * Storage adapter interface matching Supabase's expected storage API.
 */
interface StorageAdapter {
  getItem(key: string): Promise<string | null>;
  setItem(key: string, value: string): Promise<void>;
  removeItem(key: string): Promise<void>;
}

/**
 * SecureStore adapter for Supabase authentication.
 * Falls back to in-memory storage if SecureStore is not available.
 */
export class ExpoSecureStoreAdapter implements StorageAdapter {
  private memoryStorage: Map<string, string> = new Map();

  /**
   * Retrieve a value from secure storage.
   */
  async getItem(key: string): Promise<string | null> {
    if (SecureStore) {
      try {
        return await SecureStore.getItemAsync(key);
      } catch (error) {
        console.warn(`SecureStore.getItemAsync failed for key "${key}":`, error);
        return this.memoryStorage.get(key) ?? null;
      }
    }
    return this.memoryStorage.get(key) ?? null;
  }

  /**
   * Store a value in secure storage.
   */
  async setItem(key: string, value: string): Promise<void> {
    if (SecureStore) {
      try {
        await SecureStore.setItemAsync(key, value);
        return;
      } catch (error) {
        console.warn(`SecureStore.setItemAsync failed for key "${key}":`, error);
      }
    }
    this.memoryStorage.set(key, value);
  }

  /**
   * Remove a value from secure storage.
   */
  async removeItem(key: string): Promise<void> {
    if (SecureStore) {
      try {
        await SecureStore.deleteItemAsync(key);
        return;
      } catch (error) {
        console.warn(`SecureStore.deleteItemAsync failed for key "${key}":`, error);
      }
    }
    this.memoryStorage.delete(key);
  }
}
