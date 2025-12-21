import { describe, it, expect } from "vitest";
import type { Database, Tables, Json } from "./database";

/**
 * Type-level tests for database types.
 * These tests verify that the type helpers work correctly at compile time.
 * Runtime checks are minimal since types are erased at runtime.
 */

describe("Database types", () => {
  it("should have public schema defined", () => {
    // This is a compile-time check - if Database doesn't have public, this won't compile
    const hasPublic: keyof Database = "public";
    expect(hasPublic).toBe("public");
  });

  it("should have Tables defined in public schema", () => {
    const hasTables: keyof Database["public"] = "Tables";
    expect(hasTables).toBe("Tables");
  });
});

describe("Tables helper type", () => {
  it("should correctly type items table rows", () => {
    // Create a mock item that matches the Tables<'items'> type
    const item: Tables<"items"> = {
      id: "test-uuid",
      title: "Test Item",
      description: "A test item",
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    expect(item.id).toBe("test-uuid");
    expect(item.title).toBe("Test Item");
  });

  it("should correctly type profiles table rows", () => {
    const profile: Tables<"profiles"> = {
      id: "test-uuid",
      display_name: "Test User",
      avatar_url: "https://example.com/avatar.png",
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    expect(profile.id).toBe("test-uuid");
    expect(profile.display_name).toBe("Test User");
  });

  it("should allow null for optional fields", () => {
    const profile: Tables<"profiles"> = {
      id: "test-uuid",
      display_name: null,
      avatar_url: null,
      created_at: new Date().toISOString(),
      updated_at: new Date().toISOString(),
    };

    expect(profile.display_name).toBeNull();
    expect(profile.avatar_url).toBeNull();
  });
});

describe("Json type", () => {
  it("should accept primitive values", () => {
    const stringVal: Json = "test";
    const numberVal: Json = 42;
    const boolVal: Json = true;
    const nullVal: Json = null;

    expect(stringVal).toBe("test");
    expect(numberVal).toBe(42);
    expect(boolVal).toBe(true);
    expect(nullVal).toBeNull();
  });

  it("should accept arrays", () => {
    const arrayVal: Json = [1, "two", true, null];
    expect(Array.isArray(arrayVal)).toBe(true);
  });

  it("should accept nested objects", () => {
    const objectVal: Json = {
      name: "test",
      count: 42,
      nested: {
        value: true,
      },
    };

    expect(typeof objectVal).toBe("object");
  });
});
