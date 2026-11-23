-- Migrasi Awal: Tabel Kos dan Aturan Akses (RLS)
-- KosFinder — Aplikasi Pencarian dan Pengelolaan Kos

-- 1. Buat Tabel Kos
CREATE TABLE IF NOT EXISTS public.kos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    pemilik_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    nama TEXT NOT NULL,
    area TEXT NOT NULL,
    harga_per_bulan INTEGER NOT NULL CHECK (harga_per_bulan > 0),
    deskripsi TEXT NOT NULL,
    fasilitas TEXT[] NOT NULL DEFAULT '{}',
    kontak_pemilik TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'Tersedia' CHECK (status IN ('Tersedia', 'Penuh'))
);

-- 2. Aktifkan Row Level Security (RLS) pada tabel kos
ALTER TABLE public.kos ENABLE ROW LEVEL SECURITY;

-- 3. Policy SELECT: Siapa saja (publik anonim & pengguna login) boleh melihat semua data kos
CREATE POLICY "Semua orang boleh melihat kos"
ON public.kos
FOR SELECT
USING (true);

-- 4. Policy INSERT: Hanya pengguna terautentikasi yang boleh menambah kos miliknya sendiri
CREATE POLICY "Pemilik boleh menambah kos sendiri"
ON public.kos
FOR INSERT
TO authenticated
WITH CHECK (auth.uid() = pemilik_id);

-- 5. Policy UPDATE: Hanya pemilik kos bersangkutan yang boleh mengubah data miliknya
CREATE POLICY "Pemilik boleh mengubah kos miliknya sendiri"
ON public.kos
FOR UPDATE
TO authenticated
USING (auth.uid() = pemilik_id)
WITH CHECK (auth.uid() = pemilik_id);

-- 6. Policy DELETE: Hanya pemilik kos bersangkutan yang boleh menghapus data miliknya
CREATE POLICY "Pemilik boleh menghapus kos miliknya sendiri"
ON public.kos
FOR DELETE
TO authenticated
USING (auth.uid() = pemilik_id);
