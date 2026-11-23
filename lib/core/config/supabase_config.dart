/// Konfigurasi koneksi Supabase.
///
/// Nilai `SUPABASE_URL` dan `SUPABASE_ANON_KEY` dibaca secara dinamis
/// melalui `--dart-define` saat runtime. Tidak ada kredensial yang
/// ditulis secara statis di kode atau repository.
class SupabaseConfig {
  static const String url = String.fromEnvironment('SUPABASE_URL');
  static const String anonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
  );

  /// Memeriksa apakah URL dan Anon/Publishable Key sudah diberikan via `--dart-define`.
  static bool get isConfigured => url.isNotEmpty && anonKey.isNotEmpty;
}
