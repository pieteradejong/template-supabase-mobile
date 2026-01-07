import "dotenv/config";
import type { ExpoConfig } from "expo/config";

/**
 * App Identity Configuration
 *
 * This file centralizes all app identity settings (name, slug, scheme, bundle IDs).
 * Values can be overridden via environment variables for easy customization.
 *
 * To customize for your app:
 * 1. Set environment variables in apps/mobile/.env.local (optional)
 * 2. Or edit the defaults directly in this file
 *
 * Environment variables (all optional):
 * - APP_NAME: Display name shown to users
 * - APP_SLUG: Expo project slug (URL-friendly identifier)
 * - APP_SCHEME: Deep linking scheme (e.g., "myapp")
 * - APP_IOS_BUNDLE_ID: iOS bundle identifier (reverse-DNS, e.g., "com.company.app")
 * - APP_ANDROID_PACKAGE: Android package name (reverse-DNS, e.g., "com.company.app")
 */

// Helper to get env var or default, with validation
function getEnvOrDefault(
  envVar: string | undefined,
  defaultValue: string,
  fieldName: string
): string {
  const value = envVar || defaultValue;
  if (!value || value.trim() === "") {
    throw new Error(
      `Invalid ${fieldName}: cannot be empty. Set ${envVar ? `environment variable or ` : ""}default value.`
    );
  }
  return value;
}

// App identity with env overrides
const appName = getEnvOrDefault(process.env.APP_NAME, "Template App", "app name");

const appSlug = getEnvOrDefault(process.env.APP_SLUG, "template-app", "app slug");

const appScheme = getEnvOrDefault(process.env.APP_SCHEME, "template", "app scheme");

const iosBundleId = getEnvOrDefault(
  process.env.APP_IOS_BUNDLE_ID,
  "com.example.app",
  "iOS bundle identifier"
);

const androidPackage = getEnvOrDefault(
  process.env.APP_ANDROID_PACKAGE,
  "com.example.app",
  "Android package name"
);

const config: ExpoConfig = {
  name: appName,
  slug: appSlug,
  version: "1.0.0",
  scheme: appScheme,
  platforms: ["ios", "android"],
  ios: {
    bundleIdentifier: iosBundleId,
    supportsTablet: true,
  },
  android: {
    package: androidPackage,
    adaptiveIcon: {
      backgroundColor: "#ffffff",
    },
  },
  web: {
    bundler: "metro",
  },
  plugins: ["expo-router"],
};

export default config;
