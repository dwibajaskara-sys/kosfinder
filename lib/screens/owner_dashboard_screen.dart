import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/owner_kos_provider.dart';
import 'kos_form_screen.dart';
import 'kos_list_screen.dart';

class OwnerDashboardScreen extends StatefulWidget {
  const OwnerDashboardScreen({super.key});

  @override
  State<OwnerDashboardScreen> createState() => _OwnerDashboardScreenState();
}

class _OwnerDashboardScreenState extends State<OwnerDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final userId = context.read<AuthProvider>().user?.id;
      if (userId != null) {
        context.read<OwnerKosProvider>().fetchOwnerKosList(userId);
      }
    });
  }

  Future<void> _signOut() async {
    final authProvider = context.read<AuthProvider>();
    await authProvider.signOut();

    if (!mounted) return;
    if (authProvider.hasError) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(authProvider.errorMessage!)));
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const KosListScreen()),
      (_) => false,
    );
  }

  void _showPlaceholder(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Fitur $feature akan tersedia pada task berikutnya.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final ownerKosProvider = context.watch<OwnerKosProvider>();
    final user = authProvider.user;
    final ownerName = user?.userMetadata?['nama']?.toString();
    final currencyFormatter = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dashboard Pemilik'),
            if (ownerName != null && ownerName.isNotEmpty)
              Text(ownerName, style: Theme.of(context).textTheme.labelMedium),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: authProvider.isLoading ? null : _signOut,
            icon: authProvider.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.logout),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Sesi pemilik tidak ditemukan.'))
          : ownerKosProvider.pemilikId != user.id
          ? const Center(child: CircularProgressIndicator())
          : _buildKosList(ownerKosProvider, currencyFormatter),
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const KosFormScreen()),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Tambah Kos'),
            ),
    );
  }

  Widget _buildKosList(
    OwnerKosProvider provider,
    NumberFormat currencyFormatter,
  ) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.hasError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                provider.errorMessage ?? 'Gagal memuat data kos pemilik.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () {
                  final user = context.read<AuthProvider>().user;
                  if (user != null) provider.fetchOwnerKosList(user.id);
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.isEmpty) {
      return const Center(child: Text('Anda belum menambahkan kos'));
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 88, top: 8),
      itemCount: provider.kosList.length,
      itemBuilder: (context, index) {
        final kos = provider.kosList[index];
        return Card(
          key: ValueKey('owner-kos-${kos.id}'),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(kos.nama, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(kos.area),
                const SizedBox(height: 4),
                Text('${currencyFormatter.format(kos.hargaPerBulan)} / bulan'),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      key: ValueKey('edit-${kos.id}'),
                      onPressed: () => _showPlaceholder('edit kos'),
                      icon: const Icon(Icons.edit_outlined),
                      label: const Text('Edit'),
                    ),
                    TextButton.icon(
                      key: ValueKey('delete-${kos.id}'),
                      onPressed: () => _showPlaceholder('hapus kos'),
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Hapus'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
