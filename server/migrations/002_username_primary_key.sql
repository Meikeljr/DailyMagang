-- Move account identity and activity ownership to the user supplied username.
-- Existing users and their owned activities are mapped before the old UUID key is removed.
ALTER TABLE users ADD COLUMN IF NOT EXISTS username VARCHAR(80);

ALTER TABLE activities ADD COLUMN IF NOT EXISTS owner_username VARCHAR(80);

DO $$
DECLARE user_id_type TEXT;
BEGIN
  SELECT data_type INTO user_id_type
  FROM information_schema.columns
  WHERE table_schema='public' AND table_name='activities' AND column_name='user_id';

  IF user_id_type = 'uuid' THEN
    UPDATE activities a SET owner_username=u.username
    FROM users u WHERE a.user_id=u.id;

    -- Remove any FK from the old activity UUID column before replacing it.
    DECLARE c RECORD;
    BEGIN
      FOR c IN SELECT conname FROM pg_constraint
        WHERE conrelid='public.activities'::regclass AND contype='f'
          AND pg_get_constraintdef(oid) LIKE '%(user_id)%'
      LOOP
        EXECUTE format('ALTER TABLE activities DROP CONSTRAINT %I', c.conname);
      END LOOP;
    END;
    ALTER TABLE activities DROP COLUMN user_id;
    ALTER TABLE activities RENAME COLUMN owner_username TO user_id;
  END IF;
END $$;

-- Retain legacy unassigned activities with a NULL owner; they remain hidden from user APIs.
ALTER TABLE activities ALTER COLUMN user_id TYPE VARCHAR(80) USING user_id::text;

DO $$
DECLARE c RECORD;
BEGIN
  FOR c IN SELECT conname FROM pg_constraint
    WHERE conrelid='public.activities'::regclass AND contype='f'
      AND pg_get_constraintdef(oid) LIKE '%(user_id)%'
  LOOP
    EXECUTE format('ALTER TABLE activities DROP CONSTRAINT %I', c.conname);
  END LOOP;

  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='activities_user_id_fkey' AND conrelid='public.activities'::regclass) THEN
    ALTER TABLE activities ADD CONSTRAINT activities_user_id_fkey
      FOREIGN KEY (user_id) REFERENCES users(username) ON DELETE CASCADE;
  END IF;

  IF EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.users'::regclass AND contype='p') THEN
    SELECT conname INTO c FROM pg_constraint WHERE conrelid='public.users'::regclass AND contype='p';
    EXECUTE format('ALTER TABLE users DROP CONSTRAINT %I', c.conname);
  END IF;
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='public' AND table_name='users' AND column_name='id') THEN
    ALTER TABLE users DROP COLUMN id;
  END IF;
  ALTER TABLE users ALTER COLUMN username SET NOT NULL;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conrelid='public.users'::regclass AND contype='p') THEN
    ALTER TABLE users ADD CONSTRAINT users_pkey PRIMARY KEY (username);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS activities_user_dates_idx ON activities(user_id, date_start, date_end);
CREATE INDEX IF NOT EXISTS activities_user_updated_idx ON activities(user_id, updated_at DESC);
