import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import '../../bloc/pos/pos_bloc.dart';
import 'pos_outlet_page.dart';
import 'pos_shift_page.dart';
import 'pos_customer_page.dart';
import 'pos_printer_page.dart';
import 'pos_return_page.dart';
import 'pos_offline_queue_page.dart';

class PosMoreMenuPage extends StatelessWidget {
  const PosMoreMenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildSectionTitle('Manajemen Toko'),
              const SizedBox(height: 12),
              _buildMenuGrid([
                _buildMenuItem(
                  context,
                  icon: Icons.storefront,
                  title: 'Manajemen Outlet',
                  subtitle: 'Atur detail outlet dan informasi cabang',
                  color: AppColors.primary,
                  onTap: () {
                    final posBloc = context.read<PosBloc>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: posBloc,
                          child: const PosOutletPage(),
                        ),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.replay_circle_filled,
                  title: 'Retur Penjualan',
                  subtitle: 'Riwayat dan pengajuan retur barang',
                  color: Colors.redAccent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PosReturnPage()),
                  ),
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.point_of_sale,
                  title: 'Kas & Shift',
                  subtitle: 'Kelola kas masuk/keluar dan rekap shift',
                  color: Colors.orange,
                  onTap: () {
                    final posBloc = context.read<PosBloc>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: posBloc,
                          child: const PosShiftPage(),
                        ),
                      ),
                    );
                  },
                ),
              ]),
              const SizedBox(height: 24),
              _buildSectionTitle('Lain-lain'),
              const SizedBox(height: 12),
              _buildMenuGrid([
                _buildMenuItem(
                  context,
                  icon: Icons.people_alt,
                  title: 'Pelanggan',
                  subtitle: 'Daftar pelanggan dan riwayat loyalitas',
                  color: Colors.purple,
                  onTap: () {
                    final posBloc = context.read<PosBloc>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: posBloc,
                          child: const PosCustomerPage(),
                        ),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.print,
                  title: 'Pengaturan Printer',
                  subtitle: 'Atur format dan tampilan struk kasir',
                  color: Colors.blue,
                  onTap: () {
                    final posBloc = context.read<PosBloc>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BlocProvider.value(
                          value: posBloc,
                          child: const PosPrinterPage(),
                        ),
                      ),
                    );
                  },
                ),
                _buildMenuItem(
                  context,
                  icon: Icons.cloud_sync,
                  title: 'Antrean & Sinkronisasi',
                  subtitle: 'Periksa, audit, dan kirim transaksi offline',
                  color: Colors.teal,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const PosOfflineQueuePage(),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 16,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildMenuGrid(List<Widget> children) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 760 ? 2 : 1;
        final itemWidth =
            (constraints.maxWidth - ((columns - 1) * 12)) / columns;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: children
              .map((child) => SizedBox(width: itemWidth, child: child))
              .toList(),
        );
      },
    );
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
