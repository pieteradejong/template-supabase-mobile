-- =============================================================================
-- Initial Schema: profiles and items tables
-- =============================================================================
-- This migration creates the base tables for the template.
-- RLS is enabled but with permissive policies for Phase 1 (no auth).
-- Proper RLS policies will be added in Phase 2 when auth is implemented.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- profiles table
-- -----------------------------------------------------------------------------
-- This table will extend auth.users in Phase 2.
-- For now, it's standalone to demonstrate the pattern.

CREATE TABLE profiles (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  display_name TEXT,
  avatar_url TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Enable RLS (policies added below)
ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

-- Temporary: Allow all access for Phase 1 (no auth yet)
-- These policies will be replaced with proper user-scoped policies in Phase 2
CREATE POLICY "Allow all read for development" ON profiles
  FOR SELECT USING (true);

CREATE POLICY "Allow all insert for development" ON profiles
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow all update for development" ON profiles
  FOR UPDATE USING (true);

CREATE POLICY "Allow all delete for development" ON profiles
  FOR DELETE USING (true);

-- -----------------------------------------------------------------------------
-- items table
-- -----------------------------------------------------------------------------
-- Generic CRUD example table for demonstrating Supabase queries.

CREATE TABLE items (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  title TEXT NOT NULL,
  description TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
  updated_at TIMESTAMPTZ DEFAULT NOW() NOT NULL
);

-- Enable RLS (policies added below)
ALTER TABLE items ENABLE ROW LEVEL SECURITY;

-- Temporary: Allow all access for Phase 1 (no auth yet)
-- These policies will be replaced with proper user-scoped policies in Phase 2
CREATE POLICY "Allow all read for development" ON items
  FOR SELECT USING (true);

CREATE POLICY "Allow all insert for development" ON items
  FOR INSERT WITH CHECK (true);

CREATE POLICY "Allow all update for development" ON items
  FOR UPDATE USING (true);

CREATE POLICY "Allow all delete for development" ON items
  FOR DELETE USING (true);

-- -----------------------------------------------------------------------------
-- updated_at trigger function
-- -----------------------------------------------------------------------------
-- Automatically update the updated_at column on row updates.

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply trigger to profiles
CREATE TRIGGER update_profiles_updated_at
  BEFORE UPDATE ON profiles
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();

-- Apply trigger to items
CREATE TRIGGER update_items_updated_at
  BEFORE UPDATE ON items
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at_column();
