/// Model data Kos mewakili entitas tabel `public.kos` di Supabase.
class Kos {
  final String id;
  final DateTime createdAt;
  final String pemilikId;
  final String nama;
  final String area;
  final int hargaPerBulan;
  final String deskripsi;
  final List<String> fasilitas;
  final String kontakPemilik;
  final String status; // 'Tersedia' atau 'Penuh'

  const Kos({
    required this.id,
    required this.createdAt,
    required this.pemilikId,
    required this.nama,
    required this.area,
    required this.hargaPerBulan,
    required this.deskripsi,
    required this.fasilitas,
    required this.kontakPemilik,
    this.status = 'Tersedia',
  });

  /// Mengembalikan true jika status kos masih 'Tersedia'
  bool get isTersedia => status == 'Tersedia';

  /// Membuat instance Kos dari Map/JSON hasil query Supabase
  factory Kos.fromMap(Map<String, dynamic> map) {
    return Kos(
      id: map['id']?.toString() ?? '',
      createdAt: map['created_at'] != null
          ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now()
          : DateTime.now(),
      pemilikId: map['pemilik_id']?.toString() ?? '',
      nama: map['nama']?.toString() ?? '',
      area: map['area']?.toString() ?? '',
      hargaPerBulan: (map['harga_per_bulan'] as num?)?.toInt() ?? 0,
      deskripsi: map['deskripsi']?.toString() ?? '',
      fasilitas: (map['fasilitas'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          const <String>[],
      kontakPemilik: map['kontak_pemilik']?.toString() ?? '',
      status: map['status']?.toString() ?? 'Tersedia',
    );
  }

  /// Mengubah instance Kos menjadi Map untuk payload insert Supabase
  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'area': area,
      'harga_per_bulan': hargaPerBulan,
      'deskripsi': deskripsi,
      'fasilitas': fasilitas,
      'kontak_pemilik': kontakPemilik,
      'status': status,
      'pemilik_id': pemilikId,
    };
  }

  /// Mengubah instance Kos menjadi Map untuk payload update Supabase
  /// TIDAK menyertakan pemilik_id, id, dan created_at karena kolom-kolom ini
  /// tidak boleh diubah saat update.
  Map<String, dynamic> toUpdateMap() {
    return {
      'nama': nama,
      'area': area,
      'harga_per_bulan': hargaPerBulan,
      'deskripsi': deskripsi,
      'fasilitas': fasilitas,
      'kontak_pemilik': kontakPemilik,
      'status': status,
    };
  }

  Kos copyWith({
    String? id,
    DateTime? createdAt,
    String? pemilikId,
    String? nama,
    String? area,
    int? hargaPerBulan,
    String? deskripsi,
    List<String>? fasilitas,
    String? kontakPemilik,
    String? status,
  }) {
    return Kos(
      id: id ?? this.id,
      createdAt: createdAt ?? this.createdAt,
      pemilikId: pemilikId ?? this.pemilikId,
      nama: nama ?? this.nama,
      area: area ?? this.area,
      hargaPerBulan: hargaPerBulan ?? this.hargaPerBulan,
      deskripsi: deskripsi ?? this.deskripsi,
      fasilitas: fasilitas ?? this.fasilitas,
      kontakPemilik: kontakPemilik ?? this.kontakPemilik,
      status: status ?? this.status,
    );
  }
}
