# KosFinder

KosFinder adalah aplikasi Flutter untuk mencari kos dan membantu pemilik mengelola informasi kos. Data kos dan autentikasi pemilik disimpan di Supabase.

## Fitur versi 0.1.0

- Melihat daftar dan detail kos, termasuk harga, ketersediaan, fasilitas, dan kontak pemilik.
- Mencari kos berdasarkan area dan memfilter berdasarkan harga maksimum serta fasilitas.
- Menyalin nomor telepon/WhatsApp pemilik dari halaman detail.
- Mendaftar dan login sebagai pemilik untuk menambah, mengubah, dan menghapus kos milik sendiri.
- Menampilkan identitas pengembang pada halaman About.

## Persiapan dan cara menjalankan

Pastikan Flutter stable dan sebuah project Supabase sudah tersedia.

1. Salin `dart_defines.example.json` menjadi `dart_defines.json`.
   Di PowerShell:

   ```powershell
   Copy-Item dart_defines.example.json dart_defines.json
   ```

2. Isi `SUPABASE_URL` dan `SUPABASE_ANON_KEY` di `dart_defines.json` dengan nilai dari dashboard Supabase. Gunakan anon/publishable key, bukan service-role key.
3. Jalankan aplikasi:

   ```bash
   flutter run --dart-define-from-file=dart_defines.json
   ```

`dart_defines.json` berisi konfigurasi lokal dan tidak boleh di-commit.

## Batasan versi 1

Versi ini tidak mencakup pembayaran online, chat dalam aplikasi, ulasan/rating, rekomendasi AI, verifikasi identitas pemilik, unggah foto dari galeri/kamera, atau peta interaktif. Gambar kos menggunakan placeholder lokal.

## Build APK

Jalankan pemeriksaan dan test sebelum build:

```bash
flutter analyze
flutter test
flutter build apk --release --dart-define-from-file=dart_defines.json
```

APK release berada di `build/app/outputs/flutter-apk/app-release.apk`. Jika build release gagal karena konfigurasi signing belum tersedia, build APK debug untuk evaluasi:

```bash
flutter build apk --debug --dart-define-from-file=dart_defines.json
```

APK debug berada di `build/app/outputs/flutter-apk/app-debug.apk`.

## Identitas pengembang

**2415051068 - I Kadek Dwi Bajaskara**
