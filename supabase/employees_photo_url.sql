-- ============================================================================
-- Employee photo support  (run in the Supabase SQL editor)
-- ----------------------------------------------------------------------------
-- Adds the column the web "Register employee" photo capture writes to, and the
-- Storage bucket photos are uploaded to.
--
-- 1) Column for the public photo URL:
ALTER TABLE employees ADD COLUMN IF NOT EXISTS photo_url text;

-- 2) Storage bucket for employee photos (public read so the admin can display
--    thumbnails). If you prefer, create it from Dashboard → Storage instead.
INSERT INTO storage.buckets (id, name, public)
VALUES ('employee-photos', 'employee-photos', true)
ON CONFLICT (id) DO NOTHING;

-- 3) Allow uploads/reads with the anon (publishable) key, matching the rest of
--    this single-tenant pilot. Tighten these once Supabase Auth + RLS land.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_policies
    WHERE schemaname = 'storage' AND tablename = 'objects'
      AND policyname = 'employee_photos_rw'
  ) THEN
    CREATE POLICY employee_photos_rw ON storage.objects
      FOR ALL TO anon, authenticated
      USING (bucket_id = 'employee-photos')
      WITH CHECK (bucket_id = 'employee-photos');
  END IF;
END $$;
