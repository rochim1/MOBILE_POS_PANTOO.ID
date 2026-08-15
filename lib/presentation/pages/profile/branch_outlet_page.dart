import 'package:flutter/material.dart';
import '../../../../core/_core.dart';

class BranchOutletPage extends StatelessWidget {
  const BranchOutletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Cabang / Outlet'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildOutletCard(
            context: context,
            name: 'Outlet Pusat Jakarta',
            address: 'Jl. Sudirman No. 1, Jakarta Pusat',
            isActive: true,
          ),
          const SizedBox(height: 12),
          _buildOutletCard(
            context: context,
            name: 'Cabang Bandung',
            address: 'Jl. Asia Afrika No. 10, Bandung',
            isActive: false,
          ),
          const SizedBox(height: 12),
          _buildOutletCard(
            context: context,
            name: 'Cabang Surabaya',
            address: 'Jl. Tunjungan No. 5, Surabaya',
            isActive: false,
          ),
        ],
      ),
    );
  }

  Widget _buildOutletCard({
    required BuildContext context,
    required String name,
    required String address,
    required bool isActive,
  }) {
    return Material(
      color: Colors.white,
      elevation: 1,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isActive ? AppColors.primary : Colors.grey.shade200,
          width: isActive ? 2 : 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withValues(alpha: 0.1)
                : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.storefront,
            color: isActive ? AppColors.primary : Colors.grey,
          ),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'Aktif',
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Text(
            address,
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),
        ),
        onTap: isActive
            ? null
            : () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Beralih ke $name... (Mock)')),
                );
              },
      ),
    );
  }
}
