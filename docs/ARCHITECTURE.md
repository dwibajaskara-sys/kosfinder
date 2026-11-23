# Arsitektur & Desain Teknis — KosFinder

Dokumen ini mendefinisikan arsitektur sistem, struktur navigasi, skema database, konfigurasi, dan alur rilis aplikasi **KosFinder** sesuai dengan `docs/PRD.md` dan `AGENTS.md`.

---

## 1. Pola Arsitektur (Screen - Provider - Repository - Supabase)
Aplikasi menggunakan arsitektur berlapis yang sederhana dan terpisah secara tegas (*separation of concerns*):

```
┌────────────────────────────────────────────────────────┐
│                   Screen (UI Layer)                    │
│  Menampilkan widget, menangkap input, membaca state    │
└───────────────────────────┬────────────────────────────┘
                            │ listens & calls
┌───────────────────────────▼────────────────────────────┐
│               Provider (State Management)              │
│  Mengelola state (loading, error, list kos, filter)    │
│  Memberitahu UI via ChangeNotifier.notifyListeners()   │
└───────────────────────────┬────────────────────────────┘
                            │ delegates business data
┌───────────────────────────▼────────────────────────────┐
│                    Repository Layer                    │
│  Menjembatani Provider & Supabase, mapping model Kos   │
└───────────────────────────┬────────────────────────────┘
                            │ queries & mutations
┌───────────────────────────▼────────────────────────────┐
│                 Supabase Client (SDK)                  │
│  supabase_flutter (PostgreSQL Database & Auth API)     │
└────────────────────────────────────────────────────────┘
```

### Komponen & User Story Terkait:
1. **Screen (UI):**
   * `KosListScreen`: Halaman utama penjelajahan, pencarian area, dan filter kos (US01, US03).
   * `KosDetailScreen`: Informasi rinci kos & tombol salin kontak pemilik ke clipboard (US02).
   * `LoginScreen` & `RegisterScreen`: Formulir autentikasi pemilik kos (US04).
   * `OwnerDashboardScreen`: Daftar pengelolaan kos milik pemilik yang login (US04, US05, US06, US07).
   * `KosFormScreen`: Form tambah dan edit kos (US05, US06).
   * `AboutScreen`: Menampilkan identitas mahasiswa: **2415051068 - I Kadek Dwi Bajaskara**.
2. **Provider:**
   * `KosProvider`: Mengelola daftar kos publik, query pencarian, filter harga/fasilitas, dan status UI (US01, US02, US03).
   * `OwnerKosProvider`: Mengelola daftar kos milik pemilik yang login, proses create, update, delete (US05, US06, US07).
   * `AuthProvider`: Mengelola sesi login, pendaftaran, logout, dan auth state changes (US04).
3. **Repository:**
   * `KosRepository`: Abstraksi operasi CRUD ke tabel `public.kos` di Supabase (US01, US02, US03, US05, US06, US07).
   * `AuthRepository`: Abstraksi registrasi, login email/password, dan logout via Supabase Auth (US04).

---

## 2. Alur Navigasi Antar Layar
* **Pencari Kos:**
  `KosListScreen` (Home) ──(klik kartu kos)──> `KosDetailScreen` (Salin kontak WA).
  `KosListScreen` ──(ikon profil/login di appbar)──> `LoginScreen`.
  `KosListScreen` ──(menu drawer/appbar)──> `AboutScreen`.
* **Pemilik Kos:**
  `LoginScreen` ──(klik belum punya akun)──> `RegisterScreen`.
  `RegisterScreen` / `LoginScreen` ──(sukses autentikasi)──> `OwnerDashboardScreen`.
  `OwnerDashboardScreen` ──(tombol tambah)──> `KosFormScreen (Mode Tambah)`.
  `OwnerDashboardScreen` ──(tombol edit kos)──> `KosFormScreen (Mode Edit)`.
  `OwnerDashboardScreen` ──(tombol logout)──> Kembali ke `KosListScreen` (sesi dihapus).

---

## 3. Rencana Database & Aturan Akses (RLS)
Sistem hanya memerlukan **satu tabel utama** di Supabase: `public.kos`.

### Skema Tabel `public.kos`:
* `id` (`uuid`, Primary Key, default `gen_random_uuid()`): ID unik kos.
* `created_at` (`timestamptz`, default `now()`): Waktu penambahan data.
* `pemilik_id` (`uuid`, Not Null, References `auth.users(id)` on delete cascade): ID pemilik kos.
* `nama` (`text`, Not Null): Nama kos.
* `area` (`text`, Not Null): Nama wilayah/kota/kecamatan.
* `harga_per_bulan` (`integer`, Not Null, Check > 0): **Bertipe angka** dalam satuan Rupiah (US01, US03).
* `deskripsi` (`text`, Not Null): Deskripsi lengkap kamar & ketentuan kos.
* `fasilitas` (`text[]`, Not Null, default `'{}'`): Array pilihan tetap (`WiFi`, `AC`, `Kamar Mandi Dalam`, `Listrik`, `Parkir`).
* `kontak_pemilik` (`text`, Not Null): Nomor telepon / WhatsApp pemilik (US02, US05).
* `status` (`text`, Not Null, default `'Tersedia'`, Check in `('Tersedia', 'Penuh')`): Status ketersediaan kamar.

### Aturan Akses (Row Level Security):
Tabel `kos` wajib mengaktifkan RLS (`ENABLE ROW LEVEL SECURITY`).
1. **SELECT (Semua Orang):** Publik (baik anonim maupun terautentikasi) dapat membaca seluruh baris data kos (`true`).
2. **INSERT (Pemilik):** Hanya pengguna login yang boleh menambahkan data, dengan syarat `pemilik_id` wajib sama dengan ID akun pembuat (`auth.uid() = pemilik_id`).
3. **UPDATE (Pemilik Sendiri):** Hanya pemilik yang memiliki `auth.uid() = pemilik_id` yang diizinkan memperbarui data kos miliknya. Permintaan update dari user lain ditolak langsung oleh database.
4. **DELETE (Pemilik Sendiri):** Hanya pemilik yang memiliki `auth.uid() = pemilik_id` yang diizinkan menghapus data kos miliknya.

---

## 4. Cara Konfigurasi Tanpa Menulis Key
Kredensial URL dan Anon Key Supabase **tidak pernah ditulis di kode**. Kredensial dibaca runtime melalui konstanta lingkungan bawaan Flutter:
```dart
const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
const String supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
```
Cara menjalankan aplikasi dengan nilai parameter:
```bash
flutter run --dart-define=SUPABASE_URL=https://xyzcompany.supabase.co --dart-define=SUPABASE_ANON_KEY=eyJh...
```

---

## 5. Cara Rilis Produksi
1. Jalankan pengujian dan audit kode:
   ```bash
   flutter analyze
   flutter test
   ```
2. Build binary aplikasi Android:
   ```bash
   flutter build apk --release
   ```
   *(Jika belum menyiapkan signing keystore rilis, gunakan `flutter build apk --debug` untuk kebutuhan evaluasi mata kuliah).*
3. Buat rilis Git:
   ```bash
   git tag v0.1.0
   git push origin v0.1.0
   ```
4. Buka halaman GitHub Releases, buat Draft Release dari tag `v0.1.0`, dan unggah file APK dari `build/app/outputs/flutter-apk/`.

---

## 6. Package yang Dibutuhkan & Alasannya
Untuk menjaga solusi tetap paling sederhana dan performan, hanya 3 package yang digunakan:
1. **`supabase_flutter`**: Library klien resmi Supabase untuk otentikasi pemilik (`auth`) dan query/mutasi data tabel `kos` dengan RLS (Dibutuhkan oleh seluruh story: US01 – US07).
2. **`provider`**: State management standar yang ringan untuk menghubungkan Repository dengan UI secara reaktif tanpa boilerplate berlebih (Dibutuhkan oleh: US01 – US07).
3. **`intl`**: Format angka harga per bulan ke standar mata uang Rupiah Indonesia (misal: `Rp 1.000.000`) (Dibutuhkan oleh: US01, US02, US03).
