CREATE EXTENSION IF NOT EXISTS pgcrypto;
CREATE TABLE IF NOT EXISTS users (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(), full_name VARCHAR(160) NOT NULL,
  position VARCHAR(120) NOT NULL, username VARCHAR(80) UNIQUE NOT NULL,
  password_hash TEXT NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE TABLE IF NOT EXISTS activities (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(), user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  activity VARCHAR(240) NOT NULL, date_start DATE NOT NULL, date_end DATE NOT NULL,
  start_time TIME, end_time TIME, place VARCHAR(200) NOT NULL, progress SMALLINT NOT NULL DEFAULT 0 CHECK(progress BETWEEN 0 AND 100),
  detail TEXT NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT now(), updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK(date_end >= date_start),
  CHECK((date_start = date_end AND start_time IS NOT NULL AND end_time IS NOT NULL AND end_time > start_time)
     OR (date_start <> date_end AND start_time IS NULL AND end_time IS NULL))
);
-- Upgrade the earlier single-user schema without deleting its existing activity rows.
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='activities' AND column_name='location')
     AND NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='activities' AND column_name='place') THEN
    ALTER TABLE activities RENAME COLUMN location TO place;
  END IF;
END $$;
ALTER TABLE activities ADD COLUMN IF NOT EXISTS user_id UUID;
ALTER TABLE activities ADD COLUMN IF NOT EXISTS place VARCHAR(200);
ALTER TABLE activities ALTER COLUMN place TYPE VARCHAR(200);
-- Legacy rows remain unassigned and are excluded from all user-scoped API queries.
-- New records always receive the authenticated user's ID from the server session.
CREATE INDEX IF NOT EXISTS activities_user_dates_idx ON activities(user_id, date_start, date_end);
CREATE INDEX IF NOT EXISTS activities_user_updated_idx ON activities(user_id, updated_at DESC);
