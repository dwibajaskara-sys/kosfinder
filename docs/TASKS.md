# Daftar Task Pengembangan — KosFinder

Dokumen ini memuat daftar task terurut per *vertical slice* sesuai `docs/ARCHITECTURE.md` dan `docs/PRD.md`. Setiap slice menghasilkan aplikasi yang bisa dijalankan dan diuji langsung.

---

## Slice 1: Daftar dan Detail Kos (Wajib)
| ID | Tujuan | Story & AC Terkait | File yang Boleh Diubah | Cara Menguji | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **T01** | Setup dependensi (`pubspec.yaml`), config `--dart-define`, dan inisialisasi Supabase di `main.dart` | NFR-SEC, US01-AC1 | `pubspec.yaml`, `lib/main.dart`, `lib/core/config/supabase_config.dart` | `flutter analyze && flutter test`, aplikasi berjalan tanpa error inisialisasi | [x] Selesai |
| **T02** | Buat model data `Kos` dan `KosRepository` untuk fetch daftar kos dari Supabase | US01-AC1, US01-AC2, US01-AC3 | `lib/models/kos.dart`, `lib/repositories/kos_repository.dart`, `test/models/kos_test.dart`, `test/repositories/kos_repository_test.dart` | Jalankan unit test `flutter test test/models/kos_test.dart test/repositories/kos_repository_test.dart` | [x] Selesai |
| **T03** | Buat `KosProvider` dan `KosListScreen` untuk menampilkan daftar kos, loading, error, dan data kosong | US01-AC1, US01-AC2, US01-AC3 | `lib/providers/kos_provider.dart`, `lib/screens/kos_list_screen.dart`, `lib/widgets/kos_card.dart`, `test/providers/kos_provider_test.dart` | Jalankan di emulator, pastikan daftar kos tampil; matikan wifi untuk uji pesan error | [ ] Belum |
| **T04** | Buat `KosDetailScreen` dan aksi salin nomor kontak pemilik ke clipboard via snackbar | US02-AC1, US02-AC2 | `lib/screens/kos_detail_screen.dart`, `lib/screens/kos_list_screen.dart`, `test/screens/kos_detail_screen_test.dart` | Tap kartu kos, buka detail, tap nomor kontak pastikan muncul snackbar "Nomor disalin" | [ ] Belum |
| **T05** | Buat `AboutScreen` yang menampilkan identitas mahasiswa (2415051068 - I Kadek Dwi Bajaskara) | NFR-USAB | `lib/screens/about_screen.dart`, `lib/screens/kos_list_screen.dart`, `test/screens/about_screen_test.dart` | Buka menu About dari appbar, pastikan NIM & Nama tampil sesuai | [ ] Belum |

---

## Slice 2: Pencarian dan Filter (Wajib)
| ID | Tujuan | Story & AC Terkait | File yang Boleh Diubah | Cara Menguji | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **T06** | Implementasi pencarian area *case-insensitive* pada `KosProvider` dan search field di `KosListScreen` | US03-AC1, US03-AC4 | `lib/providers/kos_provider.dart`, `lib/screens/kos_list_screen.dart`, `test/providers/kos_provider_test.dart` | Cari "singaraja" dan "Singaraja" hasil sama; cari kata sembarang cek pesan kosong | [ ] Belum |
| **T07** | Implementasi filter harga maksimum ($\le$ input) dan filter fasilitas tetap pada `KosProvider` & UI modal | US03-AC2, US03-AC3, US03-AC4 | `lib/providers/kos_provider.dart`, `lib/widgets/filter_modal.dart`, `lib/screens/kos_list_screen.dart`, `test/providers/kos_provider_test.dart` | Set filter maks Rp1.000.000 & centang WiFi, cek hanya kos yang cocok yang tampil | [ ] Belum |

---

## Slice 3: Login Pemilik (Wajib)
| ID | Tujuan | Story & AC Terkait | File yang Boleh Diubah | Cara Menguji | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **T08** | Buat `AuthRepository` dan `AuthProvider` untuk registrasi, login, logout, dan cek sesi Supabase Auth | US04-AC1, US04-AC2, US04-AC3, US04-AC4 | `lib/repositories/auth_repository.dart`, `lib/providers/auth_provider.dart`, `test/providers/auth_provider_test.dart` | Jalankan unit test auth repository & provider dengan mock Supabase client | [ ] Belum |
| **T09** | Buat `RegisterScreen` dan `LoginScreen` dengan validasi form (email @, password $\ge 6$) dan navigasi | US04-AC1, US04-AC2, US04-AC3, US04-AC4, US04-AC5 | `lib/screens/login_screen.dart`, `lib/screens/register_screen.dart`, `lib/screens/kos_list_screen.dart`, `test/screens/auth_screens_test.dart` | Tes registrasi email invalid; tes login kredensial benar & salah di emulator | [ ] Belum |

---

## Slice 4: Tambah, Ubah, Hapus Kos Milik Sendiri (Wajib)
| ID | Tujuan | Story & AC Terkait | File yang Boleh Diubah | Cara Menguji | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **T10** | Buat `OwnerDashboardScreen` untuk menampilkan daftar kos yang dimiliki pemilik yang sedang login | US04-AC2, US05-AC1, US06-AC1 | `lib/screens/owner_dashboard_screen.dart`, `lib/providers/owner_kos_provider.dart`, `test/providers/owner_kos_provider_test.dart` | Login akun pemilik, pastikan hanya kos miliknya yang tampil di dashboard | [ ] Belum |
| **T11** | Buat `KosFormScreen` untuk tambah kos baru dengan validasi field wajib dan submit ke Supabase | US05-AC1, US05-AC2 | `lib/screens/kos_form_screen.dart`, `lib/providers/owner_kos_provider.dart`, `test/screens/kos_form_screen_test.dart` | Tambah kos di form emulator, pastikan kos baru tersimpan dengan `pemilik_id` yang tepat | [ ] Belum |
| **T12** | Implementasi edit kos sendiri di `KosFormScreen` dan proteksi penolakan edit kos milik orang lain | US06-AC1, US06-AC2, US06-AC3 | `lib/screens/kos_form_screen.dart`, `lib/repositories/kos_repository.dart`, `lib/providers/owner_kos_provider.dart`, `test/screens/kos_form_screen_test.dart` | Edit kos sendiri berhasil; coba akses edit kos akun lain pastikan dicegah RLS/UI | [ ] Belum |
| **T13** | Implementasi hapus kos milik sendiri di `OwnerDashboardScreen` dengan dialog konfirmasi dan RLS | US07-AC1, US07-AC2 | `lib/screens/owner_dashboard_screen.dart`, `lib/repositories/kos_repository.dart`, `lib/providers/owner_kos_provider.dart`, `test/screens/owner_dashboard_screen_test.dart` | Hapus kos sendiri setelah konfirmasi dialog, pastikan terhapus dari UI & Supabase | [ ] Belum |

---

## Slice 5: Ketersediaan Kamar (Bonus/Opsional)
| ID | Tujuan | Story & AC Terkait | File yang Boleh Diubah | Cara Menguji | Status |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **T14** | Catat jumlah kamar total & kamar kosong pada form kos; jika kamar kosong bernilai 0 otomatis "Penuh" | Slice 5 (Bonus) | `lib/models/kos.dart`, `lib/screens/kos_form_screen.dart`, `lib/widgets/kos_card.dart`, `lib/screens/kos_detail_screen.dart`, `test/models/kos_test.dart` | Ubah kamar kosong jadi 0 di form, cek detail di pencari otomatis berstatus "Penuh" | [ ] Belum |
