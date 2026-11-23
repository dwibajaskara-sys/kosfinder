import 'dart:async';
import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/kos.dart';

/// Repository untuk mengelola operasi CRUD data kos pada tabel `public.kos`.
class KosRepository {
  final SupabaseClient? client;

  KosRepository({this.client});

  SupabaseClient get _effectiveClient {
    if (client != null) return client!;
    return Supabase.instance.client;
  }

  /// Mengambil daftar semua kos publik, diurutkan dari yang terbaru (US01-AC1, US01-AC3).
  Future<List<Kos>> getPublicKosList() async {
    try {
      final response = await _effectiveClient
          .from('kos')
          .select()
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) => Kos.fromMap(item as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Gagal memuat data kos: ${e.message}');
    } on IOException {
      throw Exception('Gagal memuat data kos. Periksa koneksi internet Anda.');
    } on TimeoutException {
      throw Exception('Gagal memuat data kos. Periksa koneksi internet Anda.');
    } catch (e) {
      throw Exception('Gagal memuat data kos: $e');
    }
  }

  /// Mengambil detail satu kos berdasarkan ID (US02-AC1).
  Future<Kos?> getKosById(String id) async {
    try {
      final response = await _effectiveClient
          .from('kos')
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;
      return Kos.fromMap(response);
    } catch (_) {
      throw Exception('Gagal memuat detail kos. Periksa koneksi internet Anda.');
    }
  }

  /// Mengambil daftar kos yang dimiliki oleh pemilik tertentu.
  Future<List<Kos>> getOwnerKosList(String pemilikId) async {
    try {
      final response = await _effectiveClient
          .from('kos')
          .select()
          .eq('pemilik_id', pemilikId)
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((item) => Kos.fromMap(item as Map<String, dynamic>)).toList();
    } on PostgrestException catch (e) {
      throw Exception('Gagal memuat data kos: ${e.message}');
    } on IOException {
      throw Exception('Gagal memuat data kos. Periksa koneksi internet Anda.');
    } on TimeoutException {
      throw Exception('Gagal memuat data kos. Periksa koneksi internet Anda.');
    } catch (e) {
      throw Exception('Gagal memuat data kos: $e');
    }
  }

  /// Menambah data kos baru (US05-AC1).
  Future<Kos> createKos(Kos kos) async {
    try {
      final response = await _effectiveClient
          .from('kos')
          .insert(kos.toMap())
          .select()
          .single();

      return Kos.fromMap(response);
    } catch (e) {
      throw Exception('Gagal menambahkan kos: $e');
    }
  }

  /// Memperbarui data kos milik sendiri (US06-AC1, US06-AC2).
  Future<Kos> updateKos(Kos kos) async {
    try {
      final response = await _effectiveClient
          .from('kos')
          .update(kos.toUpdateMap())
          .eq('id', kos.id)
          .select()
          .single();

      return Kos.fromMap(response);
    } catch (e) {
      throw Exception('Gagal memperbarui kos: $e');
    }
  }

  /// Menghapus data kos milik sendiri (US07-AC1, US07-AC2).
  Future<void> deleteKos(String kosId) async {
    try {
      await _effectiveClient
          .from('kos')
          .delete()
          .eq('id', kosId)
          .select('id')
          .single();
    } catch (e) {
      throw Exception('Gagal menghapus kos: $e');
    }
  }
}
