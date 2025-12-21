-- =============================================================================
-- Seed Data for Local Development
-- =============================================================================
-- This file is run after migrations to populate the database with example data.
-- Run with: supabase db reset (applies migrations + seed)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Sample items
-- -----------------------------------------------------------------------------

INSERT INTO items (title, description) VALUES
  ('Welcome to the Template', 'This is your first item from the database. Edit or delete it to get started.'),
  ('Learn Supabase', 'Supabase provides a Postgres database, authentication, realtime subscriptions, and storage.'),
  ('Build Something Amazing', 'Use this template as a foundation for your mobile app. Happy coding!');

-- -----------------------------------------------------------------------------
-- Sample profiles (for testing queries before auth is implemented)
-- -----------------------------------------------------------------------------

INSERT INTO profiles (display_name, avatar_url) VALUES
  ('Demo User', 'https://api.dicebear.com/7.x/avataaars/svg?seed=demo'),
  ('Test User', 'https://api.dicebear.com/7.x/avataaars/svg?seed=test');
