import 'package:flutter_test/flutter_test.dart';
import 'package:kosfinder/models/kos.dart';

void main() {
  group('Kos Model Tests', () {
    test('Kos.fromMap maps JSON correctly', () {
      final now = DateTime.now();
      final map = {
        'id': 'kos-123',
        'created_at': now.toIso8601String(),
        'pemilik_id': 'owner-456',
        'nama': 'Kos Melati Indah',
        'area': 'Singaraja',
        'harga_per_bulan': 750000,
        'deskripsi': 'Kos nyaman dekat kampus',
        'fasilitas': ['WiFi', 'AC', 'Parkir'],
        'kontak_pemilik': '08123456789',
        'status': 'Tersedia',
      };

      final kos = Kos.fromMap(map);

      expect(kos.id, 'kos-123');
      expect(kos.pemilikId, 'owner-456');
      expect(kos.nama, 'Kos Melati Indah');
      expect(kos.area, 'Singaraja');
      expect(kos.hargaPerBulan, 750000);
      expect(kos.deskripsi, 'Kos nyaman dekat kampus');
      expect(kos.fasilitas, ['WiFi', 'AC', 'Parkir']);
      expect(kos.kontakPemilik, '08123456789');
      expect(kos.status, 'Tersedia');
      expect(kos.isTersedia, isTrue);
    });

    test('Kos.fromMap handles missing/null values safely with defaults', () {
      final kos = Kos.fromMap({});

      expect(kos.id, isEmpty);
      expect(kos.nama, isEmpty);
      expect(kos.hargaPerBulan, 0);
      expect(kos.fasilitas, isEmpty);
      expect(kos.status, 'Tersedia');
      expect(kos.isTersedia, isTrue);
    });

    test('isTersedia returns false when status is Penuh', () {
      final kos = Kos(
        id: '1',
        createdAt: DateTime.now(),
        pemilikId: 'owner-1',
        nama: 'Kos Anggrek',
        area: 'Denpasar',
        hargaPerBulan: 1200000,
        deskripsi: 'Deskripsi',
        fasilitas: const ['WiFi'],
        kontakPemilik: '0811111111',
        status: 'Penuh',
      );

      expect(kos.isTersedia, isFalse);
    });

    test('Kos.toMap outputs valid database payload', () {
      final kos = Kos(
        id: 'kos-123',
        createdAt: DateTime.now(),
        pemilikId: 'owner-456',
        nama: 'Kos Kenanga',
        area: 'Buleleng',
        hargaPerBulan: 600000,
        deskripsi: 'Kamar luas',
        fasilitas: const ['Listrik', 'WiFi'],
        kontakPemilik: '08987654321',
        status: 'Tersedia',
      );

      final map = kos.toMap();

      expect(map['nama'], 'Kos Kenanga');
      expect(map['area'], 'Buleleng');
      expect(map['harga_per_bulan'], 600000);
      expect(map['deskripsi'], 'Kamar luas');
      expect(map['fasilitas'], ['Listrik', 'WiFi']);
      expect(map['kontak_pemilik'], '08987654321');
      expect(map['status'], 'Tersedia');
      expect(map['pemilik_id'], 'owner-456');
    });

    test('Kos.toUpdateMap does not contain id, pemilik_id, or created_at', () {
      final kos = Kos(
        id: 'kos-123',
        createdAt: DateTime.now(),
        pemilikId: 'owner-456',
        nama: 'Kos Kenanga',
        area: 'Buleleng',
        hargaPerBulan: 600000,
        deskripsi: 'Kamar luas',
        fasilitas: const ['Listrik', 'WiFi'],
        kontakPemilik: '08987654321',
        status: 'Tersedia',
      );

      final updateMap = kos.toUpdateMap();

      expect(updateMap.containsKey('id'), isFalse);
      expect(updateMap.containsKey('pemilik_id'), isFalse);
      expect(updateMap.containsKey('created_at'), isFalse);
      expect(updateMap['nama'], 'Kos Kenanga');
      expect(updateMap['area'], 'Buleleng');
      expect(updateMap['harga_per_bulan'], 600000);
      expect(updateMap['deskripsi'], 'Kamar luas');
      expect(updateMap['fasilitas'], ['Listrik', 'WiFi']);
      expect(updateMap['kontak_pemilik'], '08987654321');
      expect(updateMap['status'], 'Tersedia');
    });

    test('copyWith updates specified fields only', () {
      final original = Kos(
        id: '1',
        createdAt: DateTime.now(),
        pemilikId: 'owner-1',
        nama: 'Kos Asli',
        area: 'Singaraja',
        hargaPerBulan: 800000,
        deskripsi: 'Asli',
        fasilitas: const ['WiFi'],
        kontakPemilik: '08123',
        status: 'Tersedia',
      );

      final updated = original.copyWith(
        hargaPerBulan: 900000,
        status: 'Penuh',
      );

      expect(updated.id, original.id);
      expect(updated.nama, original.nama);
      expect(updated.hargaPerBulan, 900000);
      expect(updated.status, 'Penuh');
    });
  });
}
