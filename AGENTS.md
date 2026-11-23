# Aturan Kerja Agen AI — KosFinder

Dokumen ini adalah pedoman dan kontrak kerja utama bagi agen AI yang berkontribusi pada pengembangan proyek **KosFinder**. Agen AI wajib membaca, memahami, dan mematuhi seluruh poin di bawah ini tanpa kecuali.

---

## 1. Konteks Proyek & Dokumen Acuan
Proyek **KosFinder** adalah aplikasi mobile pencarian dan pengelolaan kos berbasis Flutter dengan backend Supabase.
Seluruh pekerjaan harus selalu merujuk dan patuh pada tiga dokumen utama berikut:
1. `docs/PRD.md` — Masalah, scope, user stories, dan acceptance criteria (AC). Agen dilarang menambah fitur di luar PRD.
2. `docs/ARCHITECTURE.md` — Komponen aplikasi (Screen - Provider - Repository - Supabase), skema database, konfigurasi `--dart-define`, dan daftar package yang diizinkan.
3. `docs/TASKS.md` — Daftar task terurut per vertical slice beserta batasan berkas yang boleh diubah.

---

## 2. Cara Kerja Agen
* **Satu Task Per Permintaan:** Kerjakan hanya satu task yang diperintahkan dalam satu waktu. Jangan menggabungkan beberapa task sekaligus.
* **Batasan File:** Hanya ubah berkas yang secara eksplisit disebutkan pada task yang bersangkutan di `docs/TASKS.md`. Dilarang mengubah berkas lain tanpa izin SE.
* **Perubahan Besar:** Rencanakan dan jelaskan terlebih dahulu sebelum melakukan perubahan struktural atau arsitektural yang signifikan.
* **Solusi Paling Sederhana:** Selalu pilih solusi yang paling sederhana, mudah dipahami, dan langsung memenuhi acceptance criteria (hindari over-engineering).
* **Larangan Menambah Package:** Dilarang keras menambahkan package/dependency baru ke `pubspec.yaml` tanpa persetujuan eksplisit dari SE (*Software Engineer*).

---

## 3. Standar Teknologi
* **Framework:** Flutter (Channel stable, Android target).
* **State Management:** Provider (sederhana, konsisten, terisolasi per fitur).
* **Backend:** Supabase (Database PostgreSQL, Supabase Auth, Row Level Security, Storage jika relevan).

---

## 4. Keamanan & Kredensial
* **Nir-Kredensial:** Dilarang keras menuliskan API key, password, URL rahasia, atau kredensial apa pun di dalam kode sumber, pesan chat, maupun repositori Git.
* **Konfigurasi Environment:** Konfigurasi Supabase (`SUPABASE_URL` dan `SUPABASE_ANON_KEY`) wajib dibaca secara dinamis menggunakan `--dart-define`. File .env tidak dipakai untuk konfigurasi aplikasi; jika ada file .env lokal untuk keperluan lain, file itu harus diabaikan di .gitignore dan tidak boleh di-commit.
* **Larangan Service Role:** `service_role` key **TIDAK PERNAH** boleh dipakai atau dimasukkan ke dalam aplikasi mobile.
* **Otorisasi Backend (RLS):** Penegakan hak akses data (Create, Read, Update, Delete) wajib ditegakkan secara mutlak di tingkat database menggunakan **Row Level Security (RLS)** Supabase, bukan hanya menyembunyikan tombol di antarmuka (UI).

---

## 5. Standar Git & Commit
* **Satu Task, Satu Commit:** Setiap kali menyelesaikan satu task atau satu dokumen resmi, buat satu commit terpisah setelah disetujui oleh SE.
* **Format Pesan Commit:** Pesan commit wajib secara eksplisit menyebutkan ID task atau dokumen terkait, misalnya:
  * `T01: inisialisasi model dan repository kos`
  * `T03: implementasi filter harga (US03-AC2)`
  * `docs: tambah AGENTS dan ARCHITECTURE`
* **Pembersihan Sebelum Commit:** Pastikan tidak ada berkas temporer, kredensial, atau perubahan di luar lingkup task yang ikut ter-stage atau ter-commit.

---

## 6. Definition of Done (DoD)
Sebuah task hanya dianggap selesai (*Done*) jika memenuhi seluruh kriteria berikut:
1. `flutter analyze` berjalan bersih tanpa error atau warning baru.
2. `flutter test` lulus 100% untuk seluruh unit test yang relevan.
3. Aplikasi berhasil dijalankan dan diuji langsung pada device target (emulator atau HP Android).
4. Agen memberikan laporan ringkas kepada SE mengenai apa yang telah dibuat, hasil pengujian, dan mencatat secara transparan hal apa saja yang belum sempat diuji.

---

## 7. Identitas Mahasiswa (Halaman About)
Aplikasi wajib menampilkan identitas pengembang pada halaman **About** dengan format:
**2415051068 - I Kadek Dwi Bajaskara**
