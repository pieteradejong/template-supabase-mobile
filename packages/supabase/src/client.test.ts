import { describe, it, expect, beforeEach, afterEach, vi } from "vitest";
import { createSupabaseClient, getSupabase } from "./client";
import { ExpoSecureStoreAdapter } from "./storage/expo-secure-store";

describe("createSupabaseClient", () => {
  const originalEnv = { ...process.env };

  beforeEach(() => {
    // Set env vars for each test
    process.env.EXPO_PUBLIC_SUPABASE_URL = "http://localhost:54321";
    process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY = "test-anon-key";
  });

  afterEach(() => {
    // Restore original env
    process.env = { ...originalEnv };
    vi.restoreAllMocks();
  });

  it("should create a Supabase client instance", () => {
    const client = createSupabaseClient();

    expect(client).toBeDefined();
    expect(typeof client.from).toBe("function");
    expect(typeof client.auth).toBe("object");
  });

  it("should accept custom options", () => {
    const client = createSupabaseClient({
      auth: {
        persistSession: false,
      },
    });

    expect(client).toBeDefined();
  });
});

describe("getSupabase", () => {
  beforeEach(() => {
    process.env.EXPO_PUBLIC_SUPABASE_URL = "http://localhost:54321";
    process.env.EXPO_PUBLIC_SUPABASE_ANON_KEY = "test-anon-key";
  });

  it("should return a Supabase client instance", () => {
    const client = getSupabase();

    expect(client).toBeDefined();
    expect(typeof client.from).toBe("function");
  });

  it("should return the same instance on subsequent calls", () => {
    const client1 = getSupabase();
    const client2 = getSupabase();

    expect(client1).toBe(client2);
  });
});

describe("ExpoSecureStoreAdapter", () => {
  let adapter: ExpoSecureStoreAdapter;

  beforeEach(() => {
    adapter = new ExpoSecureStoreAdapter();
  });

  it("should implement getItem method", async () => {
    const result = await adapter.getItem("test-key");
    // Without expo-secure-store, falls back to in-memory storage
    expect(result).toBeNull();
  });

  it("should implement setItem method", async () => {
    await adapter.setItem("test-key", "test-value");
    const result = await adapter.getItem("test-key");
    // In-memory fallback should work
    expect(result).toBe("test-value");
  });

  it("should implement removeItem method", async () => {
    await adapter.setItem("test-key", "test-value");
    await adapter.removeItem("test-key");
    const result = await adapter.getItem("test-key");
    expect(result).toBeNull();
  });

  it("should handle multiple keys independently", async () => {
    await adapter.setItem("key1", "value1");
    await adapter.setItem("key2", "value2");

    expect(await adapter.getItem("key1")).toBe("value1");
    expect(await adapter.getItem("key2")).toBe("value2");

    await adapter.removeItem("key1");
    expect(await adapter.getItem("key1")).toBeNull();
    expect(await adapter.getItem("key2")).toBe("value2");
  });
});
