import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/kos.dart';
import '../providers/auth_provider.dart';
import '../providers/owner_kos_provider.dart';

class KosFormScreen extends StatefulWidget {
  const KosFormScreen({super.key, this.kosToEdit});

  final Kos? kosToEdit;

  @override
  State<KosFormScreen> createState() => _KosFormScreenState();
}

class _KosFormScreenState extends State<KosFormScreen> {
  static const _facilities = [
    'WiFi',
    'AC',
    'Kamar Mandi Dalam',
    'Listrik',
    'Parkir',
  ];

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _areaController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactController = TextEditingController();
  final Set<String> _selectedFacilities = {};
  String _status = 'Tersedia';

  bool get _isEditing => widget.kosToEdit != null;

  @override
  void initState() {
    super.initState();
    final kos = widget.kosToEdit;
    if (kos == null) return;

    _nameController.text = kos.nama;
    _areaController.text = kos.area;
    _priceController.text = kos.hargaPerBulan.toString();
    _descriptionController.text = kos.deskripsi;
    _contactController.text = kos.kontakPemilik;
    _selectedFacilities.addAll(kos.fasilitas);
    _status = kos.status;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _areaController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final user = context.read<AuthProvider>().user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi login tidak ditemukan.')),
      );
      return;
    }

    final existingKos = widget.kosToEdit;
    final kos = Kos(
      id: existingKos?.id ?? '',
      createdAt: existingKos?.createdAt ?? DateTime.now(),
      pemilikId: existingKos?.pemilikId ?? user.id,
      nama: _nameController.text.trim(),
      area: _areaController.text.trim(),
      hargaPerBulan: int.parse(_priceController.text.trim()),
      deskripsi: _descriptionController.text.trim(),
      fasilitas: _selectedFacilities.toList(),
      kontakPemilik: _contactController.text.trim(),
      status: _status,
    );

    final provider = context.read<OwnerKosProvider>();
    final saved = _isEditing
        ? await provider.updateKos(kos)
        : await provider.createKos(kos);
    if (!mounted || !saved) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final ownerKosProvider = context.watch<OwnerKosProvider>();

    return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'Edit Kos' : 'Tambah Kos')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  key: const Key('kos-name'),
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Nama kos',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Nama kos wajib diisi'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('kos-area'),
                  controller: _areaController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Area',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Area wajib diisi'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('kos-price'),
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                    labelText: 'Harga per bulan',
                    prefixText: 'Rp ',
                    border: OutlineInputBorder(),
                  ),
                  validator: _validatePrice,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  key: const Key('kos-description'),
                  controller: _descriptionController,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Deskripsi',
                    alignLabelWithHint: true,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Fasilitas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                ..._facilities.map(
                  (facility) => CheckboxListTile(
                    key: ValueKey('facility-$facility'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Text(facility),
                    value: _selectedFacilities.contains(facility),
                    onChanged: ownerKosProvider.isLoading
                        ? null
                        : (selected) {
                            setState(() {
                              if (selected == true) {
                                _selectedFacilities.add(facility);
                              } else {
                                _selectedFacilities.remove(facility);
                              }
                            });
                          },
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  key: const Key('kos-contact'),
                  controller: _contactController,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Kontak pemilik (telepon/WhatsApp)',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Kontak pemilik wajib diisi'
                      : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: const Key('kos-status'),
                  initialValue: _status,
                  decoration: const InputDecoration(
                    labelText: 'Status ketersediaan',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'Tersedia',
                      child: Text('Tersedia'),
                    ),
                    DropdownMenuItem(value: 'Penuh', child: Text('Penuh')),
                  ],
                  onChanged: ownerKosProvider.isLoading
                      ? null
                      : (status) {
                          if (status != null) {
                            setState(() => _status = status);
                          }
                        },
                ),
                if (ownerKosProvider.hasError) ...[
                  const SizedBox(height: 16),
                  Text(
                    ownerKosProvider.errorMessage ??
                        (_isEditing
                            ? 'Gagal memperbarui kos.'
                            : 'Gagal menambahkan kos.'),
                    key: const Key('kos-form-error'),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  key: const Key('kos-submit'),
                  onPressed: ownerKosProvider.isLoading ? null : _submit,
                  icon: ownerKosProvider.isLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_outlined),
                  label: Text(
                    ownerKosProvider.isLoading
                        ? 'Menyimpan...'
                        : _isEditing
                        ? 'Simpan Perubahan'
                        : 'Simpan Kos',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Harga wajib diisi';
    }

    final price = int.tryParse(value.trim());
    if (price == null) return 'Harga harus berupa angka';
    if (price <= 0) return 'Harga harus lebih dari 0';
    return null;
  }
}
