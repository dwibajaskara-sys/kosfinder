-- Grant akses tabel kos ke role anon dan authenticated
-- RLS tetap aktif dan menyaring baris sesuai policy di 001_init.sql

GRANT SELECT ON TABLE public.kos TO anon, authenticated;
GRANT INSERT, UPDATE, DELETE ON TABLE public.kos TO authenticated;
