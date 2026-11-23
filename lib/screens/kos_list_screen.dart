import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/kos_provider.dart';
import '../widgets/filter_modal.dart';
import '../widgets/kos_card.dart';
import 'about_screen.dart';
import 'kos_detail_screen.dart';

/// Layar utama penjelajahan, pencarian, dan penyaringan daftar kos publik (US01, US03).
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

  void _openFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const FilterModal(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

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

          // 4. Tampilan Data Normal / Hasil Pencarian & Filter (US01-AC1, US03-AC1, AC2, AC3, AC4)
          final displayList = provider.filteredKosList;

          return Column(
            children: [
              // Baris Pencarian Area & Tombol Filter
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Cari area (misal: Singaraja)...',
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
                    const SizedBox(width: 8),
                    // Tombol Buka Modal Filter (US03-AC2, US03-AC3)
                    Stack(
                      children: [
                        IconButton.filledTonal(
                          icon: const Icon(Icons.tune_rounded),
                          tooltip: 'Filter Kos',
                          onPressed: () => _openFilterModal(context),
                        ),
                        if (provider.isFilterActive)
                          Positioned(
                            top: 6,
                            right: 6,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Colors.teal,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
              ),
            ),

              // Baris Ringkasan Filter Aktif (Chip Filter)
              if (provider.isFilterActive)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        if (provider.maxPrice != null)
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Chip(
                              label: Text('Maks: ${currencyFormatter.format(provider.maxPrice)}'),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () => provider.setFilter(
                                maxPrice: null,
                                facilities: provider.selectedFacilities,
                              ),
                            ),
                          ),
                        ...provider.selectedFacilities.map(
                          (facility) => Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: Chip(
                              label: Text(facility),
                              deleteIcon: const Icon(Icons.close, size: 16),
                              onDeleted: () {
                                final updated = List<String>.from(provider.selectedFacilities)
                                  ..remove(facility);
                                provider.setFilter(
                                  maxPrice: provider.maxPrice,
                                  facilities: updated,
                                );
                              },
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => provider.clearFilter(),
                          child: const Text('Hapus Filter'),
                        ),
                      ],
                    ),
                  ),
                ),

              // Jika pencarian atau filter tidak menemukan hasil (US03-AC4)
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
                              provider.resetAll();
                            },
                            child: const Text('Reset Semua'),
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
