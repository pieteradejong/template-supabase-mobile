/**
 * Supabase client configured for Expo with SecureStore
 *
 * This file initializes the Supabase client with secure token storage
 * using Expo SecureStore for iOS Keychain and Android EncryptedSharedPreferences.
 */

import { createSupabaseClient, ExpoSecureStoreAdapter } from "@acme/supabase";

/**
 * Supabase client instance for the mobile app.
 *
 * Uses SecureStore for secure token storage on iOS and Android.
 */
export const supabase = createSupabaseClient({
  auth: {
    storage: new ExpoSecureStoreAdapter(),
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: false,
  },
});
