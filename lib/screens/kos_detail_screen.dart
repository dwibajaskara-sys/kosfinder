import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/kos.dart';

/// Halaman detail kos publik (US02).
class KosDetailScreen extends StatelessWidget {
  final Kos kos;

  const KosDetailScreen({super.key, required this.kos});

  Future<void> _copyContactToClipboard(BuildContext context) async {
    try {
      await Clipboard.setData(ClipboardData(text: kos.kontakPemilik));
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor disalin'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyalin nomor'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    final isTersedia = kos.isTersedia;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          kos.nama,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Placeholder visual seragam lokal bawaan aplikasi (US02-AC1)
            Container(
              height: 220,
              width: double.infinity,
              color: Colors.teal.shade50,
              child: Stack(
                children: [
                  Center(
                    child: Icon(
                      Icons.home_work_rounded,
                      size: 96,
                      color: Colors.teal.shade300,
                    ),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isTersedia ? Colors.green.shade700 : Colors.red.shade700,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        kos.status,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    kos.nama,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 18, color: Colors.grey.shade700),
                      const SizedBox(width: 4),
                      Text(
                        kos.area,
                        style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '${currencyFormatter.format(kos.hargaPerBulan)} / bulan',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.teal.shade800,
                    ),
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Fasilitas',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  if (kos.fasilitas.isEmpty)
                    const Text('Tidak ada fasilitas yang tercatat.')
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: kos.fasilitas.map((f) {
                        return Chip(
                          avatar: const Icon(Icons.check_circle, size: 18, color: Colors.teal),
                          label: Text(f),
                          backgroundColor: Colors.teal.shade50,
                          side: BorderSide(color: Colors.teal.shade200),
                        );
                      }).toList(),
                    ),
                  const Divider(height: 32),
                  const Text(
                    'Deskripsi',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    kos.deskripsi.isNotEmpty ? kos.deskripsi : 'Tidak ada deskripsi.',
                    style: const TextStyle(fontSize: 15, height: 1.5),
                  ),
                  const Divider(height: 32),
                  const Text(
                    'Kontak Pemilik',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  // Kartu Kontak Pemilik (US02-AC2: Salin ke clipboard & tampilkan snackbar)
                  Card(
                    color: Colors.teal.shade50,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: Colors.teal.shade200),
                    ),
                    child: ListTile(
                      leading: const Icon(Icons.phone, color: Colors.teal),
                      title: Text(
                        kos.kontakPemilik,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: const Text('Ketuk untuk menyalin nomor'),
                      trailing: const Icon(Icons.copy_rounded, color: Colors.teal),
                      onTap: () => _copyContactToClipboard(context),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
