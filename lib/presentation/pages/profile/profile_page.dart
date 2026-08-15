import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import 'change_password_page.dart';
import 'branch_outlet_page.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F6FB),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text('Profil Pengguna'),
        foregroundColor: Colors.black87,
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          final username = state.username ?? 'Kasir';

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 32),
                  // Avatar
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.primary, width: 3),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        size: 64,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Username
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Role/Status Placeholder
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF198754).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Staff Kasir Aktif',
                      style: TextStyle(
                        color: Color(0xFF198754),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Info Cards
                  _buildProfileMenuItem(
                    icon: Icons.storefront,
                    title: 'Cabang / Outlet',
                    subtitle: 'Terhubung ke Outlet Utama',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const BranchOutletPage(),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildProfileMenuItem(
                    icon: Icons.security,
                    title: 'Ubah Kata Sandi',
                    subtitle: 'Kelola keamanan akun',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChangePasswordPage(),
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 48),

                  // Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<AuthCubit>().logout();
                        // Redirection is handled by the root BlocBuilder in app.dart!
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.red.shade600,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                          side: BorderSide(color: Colors.red.shade200),
                        ),
                      ),
                      icon: const Icon(Icons.logout),
                      label: const Text(
                        'Keluar dari Aplikasi',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileMenuItem({
    required IconData icon,
    required String title,
    required String subtitle,
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
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.03),
              blurRadius: 10,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F6FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary),
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
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
