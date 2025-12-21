import { describe, it, expect } from "vitest";
import { envSchema, validateEnv, getEnv } from "./env";

describe("envSchema", () => {
  it("should accept valid environment configuration", () => {
    const validEnv = {
      EXPO_PUBLIC_SUPABASE_URL: "http://localhost:54321",
      EXPO_PUBLIC_SUPABASE_ANON_KEY: "test-anon-key",
      APP_ENV: "development",
    };

    const result = envSchema.safeParse(validEnv);
    expect(result.success).toBe(true);
  });

  it("should accept empty optional fields", () => {
    const minimalEnv = {
      APP_ENV: "development",
    };

    const result = envSchema.safeParse(minimalEnv);
    expect(result.success).toBe(true);
  });

  it("should default APP_ENV to development", () => {
    const result = envSchema.safeParse({});
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.APP_ENV).toBe("development");
    }
  });

  it("should reject invalid APP_ENV values", () => {
    const invalidEnv = {
      APP_ENV: "invalid",
    };

    const result = envSchema.safeParse(invalidEnv);
    expect(result.success).toBe(false);
  });

  it("should reject invalid SUPABASE_URL format", () => {
    const invalidEnv = {
      SUPABASE_URL: "not-a-url",
    };

    const result = envSchema.safeParse(invalidEnv);
    expect(result.success).toBe(false);
  });

  it("should accept valid production environment", () => {
    const prodEnv = {
      SUPABASE_URL: "https://example.supabase.co",
      SUPABASE_ANON_KEY: "production-key",
      APP_ENV: "production",
    };

    const result = envSchema.safeParse(prodEnv);
    expect(result.success).toBe(true);
  });
});

describe("validateEnv", () => {
  it("should return validated config for valid input", () => {
    const validEnv = {
      EXPO_PUBLIC_SUPABASE_URL: "http://localhost:54321",
      EXPO_PUBLIC_SUPABASE_ANON_KEY: "test-key",
      APP_ENV: "development",
    };

    const result = validateEnv(validEnv);
    expect(result.APP_ENV).toBe("development");
    expect(result.EXPO_PUBLIC_SUPABASE_URL).toBe("http://localhost:54321");
  });

  it("should throw on invalid input", () => {
    const invalidEnv = {
      SUPABASE_URL: "not-a-url",
    };

    expect(() => validateEnv(invalidEnv)).toThrow();
  });
});

describe("getEnv", () => {
  it("should return validated config for valid input", () => {
    const validEnv = {
      APP_ENV: "staging",
    };

    const result = getEnv(validEnv);
    expect(result).not.toBeNull();
    expect(result?.APP_ENV).toBe("staging");
  });

  it("should return null for invalid input", () => {
    const invalidEnv = {
      SUPABASE_URL: "not-a-url",
    };

    const result = getEnv(invalidEnv);
    expect(result).toBeNull();
  });
});
