import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/kos_provider.dart';
import '../widgets/kos_card.dart';
import 'about_screen.dart';
import 'kos_detail_screen.dart';

/// Layar utama penjelajahan dan pencarian daftar kos publik (US01, US03).
class KosListScreen extends StatefulWidget {
  const KosListScreen({super.key});

  @override
  State<KosListScreen> createState() => _KosListScreenState();
}

class _KosListScreenState extends State<KosListScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<KosProvider>().fetchKosList();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'KosFinder',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'Tentang Aplikasi',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Segarkan',
            onPressed: () {
              context.read<KosProvider>().fetchKosList();
            },
          ),
        ],
      ),
      body: Consumer<KosProvider>(
        builder: (context, provider, child) {
          // 1. State Loading
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // 2. State Error (US01-AC2: pesan ramah pengguna & tombol coba lagi)
          if (provider.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.wifi_off_rounded,
                      size: 64,
                      color: Colors.red.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      provider.errorMessage ?? 'Gagal memuat data kos. Periksa koneksi internet Anda.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => provider.fetchKosList(),
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          // 3. State Database Kosong (US01-AC3: Belum ada kos terdaftar)
          if (provider.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.home_outlined,
                    size: 72,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada kos yang terdaftar',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => provider.fetchKosList(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('Muat Ulang'),
                  ),
                ],
              ),
            );
          }

          // 4. Tampilan Data Normal / Hasil Pencarian (US01-AC1, US03-AC1, US03-AC4)
          final displayList = provider.filteredKosList;

          return Column(
            children: [
              // Kolom Pencarian Area Case-Insensitive (US03-AC1)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari berdasarkan area (misal: Singaraja)...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              provider.clearSearchQuery();
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) {
                    provider.setSearchQuery(val);
                  },
                ),
              ),

              // Jika pencarian tidak menemukan hasil (US03-AC4)
              if (provider.isSearchEmpty)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Tidak ada kos yang sesuai kriteria pencarian',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              provider.clearSearchQuery();
                            },
                            child: const Text('Reset Pencarian'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                // Tampilan Daftar Hasil
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => provider.fetchKosList(),
                    child: ListView.builder(
                      padding: const EdgeInsets.only(top: 4, bottom: 24),
                      itemCount: displayList.length,
                      itemBuilder: (context, index) {
                        final kos = displayList[index];
                        return KosCard(
                          kos: kos,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => KosDetailScreen(kos: kos),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
