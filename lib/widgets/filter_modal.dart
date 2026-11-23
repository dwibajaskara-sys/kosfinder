import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/kos_provider.dart';

/// Modal bottom sheet untuk mengatur filter batas harga maksimum dan fasilitas (US03-AC2, US03-AC3).
class FilterModal extends StatefulWidget {
  const FilterModal({super.key});

  /// Daftar fasilitas tetap sesuai aturan PRD & spesifikasi proyek
  static const List<String> availableFacilities = [
    'WiFi',
    'AC',
    'Kamar Mandi Dalam',
    'Listrik',
    'Parkir',
  ];

  @override
  State<FilterModal> createState() => _FilterModalState();
}

class _FilterModalState extends State<FilterModal> {
  late TextEditingController _priceController;
  late List<String> _selectedFacilities;

  @override
  void initState() {
    super.initState();
    final provider = context.read<KosProvider>();
    _priceController = TextEditingController(
      text: provider.maxPrice != null ? provider.maxPrice.toString() : '',
    );
    _selectedFacilities = List.from(provider.selectedFacilities);
  }

  @override
  void dispose() {
    _priceController.dispose();
    super.dispose();
  }

  void _applyFilter() {
    final rawText = _priceController.text.trim();
    final price = int.tryParse(rawText);

    context.read<KosProvider>().setFilter(
          maxPrice: price,
          facilities: _selectedFacilities,
        );

    Navigator.pop(context);
  }

  void _resetFilter() {
    context.read<KosProvider>().clearFilter();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Filter Kos',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                TextButton(
                  onPressed: _resetFilter,
                  child: const Text('Reset'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Filter Batas Harga Maksimum (US03-AC2)
            const Text(
              'Batas Harga Maksimum (Rp)',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Contoh: 1000000',
                prefixText: 'Rp ',
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // 2. Filter Fasilitas Tetap (US03-AC3)
            const Text(
              'Fasilitas',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: FilterModal.availableFacilities.map((facility) {
                final isSelected = _selectedFacilities.contains(facility);
                return FilterChip(
                  label: Text(facility),
                  selected: isSelected,
                  selectedColor: Colors.teal.shade100,
                  checkmarkColor: Colors.teal.shade800,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedFacilities.add(facility);
                      } else {
                        _selectedFacilities.remove(facility);
                      }
                    });
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Tombol Terapkan
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _applyFilter,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.teal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Terapkan Filter',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
