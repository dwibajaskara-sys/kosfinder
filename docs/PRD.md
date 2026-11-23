# Product Requirement Document (PRD) — KosFinder

## 1. Masalah dan Tujuan yang Bisa Diukur
* **Masalah:** Informasi kos di sekitar kampus tersebar tidak terpusat (grup chat, brosur), menyulitkan pencari membandingkan harga/fasilitas serta menyulitkan pemilik mempromosikan kamar secara teratur.
* **Tujuan yang Bisa Diukur:**
  * Pencari kos dapat melihat daftar, mencari area, memfilter harga, dan melihat kontak pemilik dalam waktu < 3 detik tanpa login.
  * Pemilik kos dapat mendaftar, masuk, serta menambah/mengubah/menghapus data kos miliknya dalam waktu < 1 menit.
  * 100% aturan otorisasi penulisan kos ditegakkan di backend (Supabase RLS).

## 2. Pengguna
1. **Pencari Kos:** Mahasiswa/pendatang yang mencari kamar kos (akses publik tanpa login).
2. **Pemilik Kos:** Individu pengelola kos yang mempublikasikan dan mengelola ketersediaan kos miliknya (wajib login).

## 3. Scope Versi 1
* **Fitur yang Masuk:**
  * Penjelajahan daftar kos dan halaman detail kos dengan *placeholder* gambar lokal seragam.
  * Pencarian area (*case-insensitive*) dan filter harga maksimum ($\le$ input harga) serta filter fasilitas tetap.
  * Registrasi & Login Pemilik via Supabase Auth (Email & Password, nama di metadata).
  * Manajemen kos milik sendiri (Create, Read, Update, Delete) oleh pemilik.
  * Status ketersediaan kos sederhana: "Tersedia" atau "Penuh".
  * Nomor kontak WhatsApp/telepon pemilik di halaman detail (disalin ke clipboard saat ditekan).
  * Halaman About menampilkan NIM dan Nama mahasiswa.
* **Fitur yang TIDAK Masuk (Out of Scope):**
  * Pembayaran online / gateway transfer.
  * Fitur in-app chat.
  * Ulasan, rating, dan komentar.
  * Rekomendasi berbasis AI.
  * Verifikasi KTP / identitas pemilik kos.
  * Upload foto dari galeri/kamera (hanya aset lokal *placeholder* bawaan).
  * Integrasi peta / Google Maps interaktif.

## 4. Non-Functional Requirements (NFR)
* **NFR-SEC (Keamanan):** Hak akses edit/hapus kos **wajib ditegakkan di backend** via Supabase Row Level Security (RLS), bukan sekadar menyembunyikan tombol di UI. Tidak ada API key sensitif/secret di repo.
* **NFR-REL (Keandalan):** Jika koneksi internet terputus saat fetch data, aplikasi menampilkan pesan error ramah pengguna dan tombol coba lagi, tanpa crash.
* **NFR-USAB (Kemudahan):** Seluruh aksi utama (cari, filter, kontak pemilik) dapat diselesaikan maksimal dalam 3 ketukan layar.
* **NFR-PERF (Performa):** Tampilan daftar awal dirender dalam waktu < 2 detik pada jaringan stabil.
* **NFR-PRIV (Privasi):** Hanya nomor kontak yang sengaja dipublikasikan oleh pemilik pada data kos yang dapat dilihat publik; tidak ada password atau key yang ditulis di kode, chat, atau repository; autentikasi sepenuhnya ditangani Supabase Auth.

---

## 5. User Stories & Acceptance Criteria

### US01: Melihat Daftar Kos
*Sebagai Pencari Kos, saya ingin melihat daftar kos yang tersedia, agar saya mengetahui opsi kos yang ada.*
* **US01-AC1 (Tampil Normal):** *Given* terdapat data kos di Supabase, *When* pengguna membuka aplikasi, *Then* daftar kos tampil memuat nama, area, harga/bulan (format Rupiah), badge status ("Tersedia"/"Penuh"), dan thumbnail placeholder lokal.
* **US01-AC2 (Koneksi Gagal):** *Given* perangkat tanpa koneksi internet, *When* aplikasi dibuka, *Then* muncul pesan error "Gagal memuat data kos. Periksa koneksi internet Anda" dan tombol coba lagi (*retry*), tanpa *force close*.
* **US01-AC3 (Data Kosong):** *Given* tabel kos di database kosong, *When* pengguna membuka aplikasi, *Then* muncul ilustrasi/pesan "Belum ada kos yang terdaftar".

### US02: Melihat Detail Kos
*Sebagai Pencari Kos, saya ingin melihat detail informasi kos dan kontak pemilik, agar saya bisa menghubungi pemilik untuk menyewa.*
* **US02-AC1 (Buka Detail):** *Given* daftar kos tampil, *When* pengguna menekan salah satu kartu kos, *Then* halaman detail terbuka menampilkan gambar placeholder, nama kos, area, harga/bulan, status ketersediaan, deskripsi lengkap, daftar fasilitas tercentang, dan nomor kontak pemilik.
* **US02-AC2 (Salin Kontak):** *Given* halaman detail terbuka, *When* pengguna menekan nomor telepon/WhatsApp, *Then* sistem menyalin nomor ke clipboard dan menampilkan snackbar "Nomor disalin".

### US03: Pencarian dan Filter Kos
*Sebagai Pencari Kos, saya ingin mencari kos berdasarkan area dan batas harga maksimum, agar saya menemukan kos sesuai kriteria budget dan lokasi.*
* **US03-AC1 (Pencarian Area Case-Insensitive):** *Given* terdapat kos di area "Singaraja", *When* pengguna mengetik "singaraja" atau "SINGARAJA", *Then* kos tersebut muncul pada daftar hasil.
* **US03-AC2 (Filter Harga Maksimum):** *Given* kos A (Rp800.000) dan kos B (Rp1.500.000), *When* pengguna memfilter harga maksimum Rp1.000.000, *Then* hanya kos A yang tampil di hasil.
* **US03-AC3 (Filter Fasilitas):** *Given* kos dengan fasilitas WiFi dan AC, *When* pengguna mencentang filter "WiFi", *Then* kos dengan fasilitas WiFi tetap tampil.
* **US03-AC4 (Hasil Pencarian Kosong):** *Given* kriteria pencarian tidak cocok dengan kos mana pun, *When* pencarian dieksekusi, *Then* muncul pesan "Tidak ada kos yang sesuai kriteria pencarian".

### US04: Registrasi dan Login Pemilik
*Sebagai Pemilik Kos, saya ingin mendaftar dan masuk ke akun saya, agar saya dapat mengelola kos yang saya miliki.*
* **US04-AC1 (Registrasi Berhasil):** *Given* form registrasi, *When* pemilik memasukkan nama lengkap, email valid, dan password minimal 6 karakter (mengikuti kebijakan Supabase Auth), *Then* akun terdaftar di Supabase Auth dan pengguna otomatis masuk/diarahkan ke sesi login.
* **US04-AC2 (Login Berhasil & Gagal):** *Given* form login, *When* kredensial benar dimasukkan, *Then* pengguna masuk ke dashboard pemilik. *When* password salah dimasukkan, *Then* muncul pesan error "Email atau kata sandi salah".
* **US04-AC3 (Logout):** *Given* pemilik sedang login, *When* tombol Logout ditekan, *Then* sesi dihapus dan kembali ke tampilan publik.
* **US04-AC4 (Koneksi Gagal Saat Login):** *Given* perangkat tanpa koneksi internet, *When* pemilik mencoba login, *Then* muncul pesan "Gagal terhubung. Periksa koneksi internet" dan aplikasi tidak crash.
* **US04-AC5 (Validasi Form Registrasi):** *Given* form registrasi, *When* email tidak valid (tanpa @) atau password kurang dari 6 karakter, *Then* form menampilkan pesan validasi dan data tidak dikirim.

### US05: Menambah Kos Baru
*Sebagai Pemilik Kos, saya ingin menambahkan data kos baru, agar kos saya dapat dilihat oleh pencari kos.*
* **US05-AC1 (Tambah Sukses):** *Given* pemilik telah login, *When* mengisi form tambah kos (nama, area, harga angka, deskripsi, fasilitas pilihan, kontak WA, status ketersediaan) lalu menekan simpan, *Then* data tersimpan di Supabase dengan `pemilik_id` terisi otomatis sesuai ID akun login.
* **US05-AC2 (Validasi Form):** *Given* form tambah kos, *When* field wajib (nama/harga/kontak) dibiarkan kosong atau harga $\le 0$, *Then* form menampilkan pesan validasi dan data tidak terkirim ke server.

### US06: Mengubah Data Kos Milik Sendiri
*Sebagai Pemilik Kos, saya ingin mengubah informasi kos saya, agar informasi tetap akurat saat terjadi perubahan.*
* **US06-AC1 (Ubah Milik Sendiri):** *Given* pemilik A login dan membuka kos miliknya, *When* mengubah harga/status dan menekan simpan, *Then* perubahan tersimpan di database dan UI terbarui.
* **US06-AC2 (Penolakan Backend Pemilik Lain):** *Given* pemilik B mencoba mengubah kos milik pemilik A melalui permintaan langsung/API, *Then* backend Supabase RLS menolak permintaan dengan pesan error otorisasi (*permission denied*).
* **US06-AC3 (Penolakan Halaman Edit Pemilik Lain):** *Given* pemilik B membuka halaman edit kos milik A (misalnya lewat manipulasi UI atau deep link), *When* menekan simpan, *Then* aplikasi menampilkan pesan error "Anda tidak berhak mengubah kos ini" dan data tidak berubah.

### US07: Menghapus Data Kos Milik Sendiri
*Sebagai Pemilik Kos, saya ingin menghapus kos saya jika sudah tidak disewakan lagi.*
* **US07-AC1 (Hapus Sukses):** *Given* pemilik login dan menekan tombol hapus pada kos miliknya, *When* mengonfirmasi dialog hapus, *Then* data terhapus dari Supabase dan hilang dari daftar.
* **US07-AC2 (Penolakan Hapus Pemilik Lain):** *Given* pemilik B mencoba menghapus kos milik pemilik A, *Then* Supabase RLS menolak permintaan penghapusan.

---

## 6. Daftar Pertanyaan yang Masih Ambigu
*(Semua pertanyaan klarifikasi utama telah terjawab lengkap pada klarifikasi Tahap 2. Tidak ada hal ambigu yang tersisa).*
