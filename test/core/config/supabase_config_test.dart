import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/core/config/supabase_config.dart';

void main() {
  group('SupabaseConfig Test', () {
    test('default configuration without dart-define should not be configured', () {
      // Saat unit test berjalan tanpa --dart-define, nilai default harus string kosong
      expect(SupabaseConfig.isConfigured, isFalse);
    });

    test('default url and anonKey are empty strings', () {
      expect(SupabaseConfig.url, isEmpty);
      expect(SupabaseConfig.anonKey, isEmpty);
    });
  });
}
