-- =============================================================================
-- Seed Data (Idempotent) for Hosted + Local Development
-- =============================================================================
-- This migration inserts demo rows in an idempotent way.
--
-- Why as a migration?
-- - `supabase db push` applies migrations to hosted projects reliably.
-- - `supabase/seed.sql` is primarily used by `supabase db reset` for local dev.
--
-- Notes:
-- - Inserts are guarded by NOT EXISTS to avoid duplicates.
-- - This is meant for template/demo usage; adapt for real apps as needed.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Sample items
-- -----------------------------------------------------------------------------
INSERT INTO items (title, description)
SELECT v.title, v.description
FROM (
  VALUES
    (
      'Welcome to the Template',
      'This is your first item from the database. Edit or delete it to get started.'
    ),
    (
      'Learn Supabase',
      'Supabase provides a Postgres database, authentication, realtime subscriptions, and storage.'
    ),
    (
      'Build Something Amazing',
      'Use this template as a foundation for your mobile app. Happy coding!'
    )
) AS v(title, description)
WHERE NOT EXISTS (
  SELECT 1
  FROM items i
  WHERE i.title = v.title
);

-- -----------------------------------------------------------------------------
-- Sample profiles (for testing queries before auth is implemented)
-- -----------------------------------------------------------------------------
INSERT INTO profiles (display_name, avatar_url)
SELECT v.display_name, v.avatar_url
FROM (
  VALUES
    ('Demo User', 'https://api.dicebear.com/7.x/avataaars/svg?seed=demo'),
    ('Test User', 'https://api.dicebear.com/7.x/avataaars/svg?seed=test')
) AS v(display_name, avatar_url)
WHERE NOT EXISTS (
  SELECT 1
  FROM profiles p
  WHERE p.display_name = v.display_name
);

