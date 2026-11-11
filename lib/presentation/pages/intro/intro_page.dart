import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'package:mobile_pos_pantoo/l10n/language_picker.dart';
import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/core/themes/colors_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../widgets/login/login_form.dart';
import '../pos/pos_onboarding_page.dart';
import '../../widgets/intro/feature_item.dart';

class IntroPage extends StatefulWidget {
  const IntroPage({super.key});

  @override
  State<IntroPage> createState() => _IntroPageState();
}

class _IntroPageState extends State<IntroPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required String description,
    required List<Widget> features,
    required int pageIndex,
  }) {
    final theme = Theme.of(context);

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Align(alignment: Alignment.centerRight, child: LanguagePicker()),
                  // Logo
                  SizedBox(
                    height: 110,
                    child: Image.asset(
                      'assets/images/pantoo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // App Name / Title
                  PosText(
                    title,
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Colors.black87,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),
                  // Simple description
                  PosText(
                    description,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.black54,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 24),
                  // Features list
                  ...features,

                  const SizedBox(height: 24),
                  // Start / Next button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () async {
                        if (pageIndex < 2) {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeInOut,
                          );
                        } else {
                          final prefs = GetIt.I<SharedPreferences>();
                          await prefs.setBool('has_seen_intro', true);
                          if (context.mounted) {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        }
                      },
                      child: Text(
                        pageIndex < 2 ? ('Selanjutnya').tr(context) : ('Mulai Sekarang').tr(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background image matches login page exactly
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/geometric_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentPage = index;
                      });
                    },
                    children: [
                      // Slide 1
                      _buildCard(
                        context: context,
                        pageIndex: 0,
                        title: ('Mobile POS Pantoo').tr(context),
                        description: ('Solusi kasir modern untuk usaha Anda').tr(context),
                        features:  [
                          FeatureItem(
                            icon: Icons.access_time_rounded,
                            title: ('Transaksi Cepat').tr(context),
                            subtitle: ('Proses pembayaran tanpa hambatan').tr(context),
                          ),
                          SizedBox(height: 16),
                          FeatureItem(
                            icon: Icons.analytics_rounded,
                            title: ('Laporan Lengkap').tr(context),
                            subtitle: ('Pantau penjualan setiap saat').tr(context),
                          ),
                          SizedBox(height: 16),
                          FeatureItem(
                            icon: Icons.touch_app_rounded,
                            title: ('Mudah Digunakan').tr(context),
                            subtitle: ('Antarmuka yang user-friendly').tr(context),
                          ),
                        ],
                      ),
                      // Slide 2
                      _buildCard(
                        context: context,
                        pageIndex: 1,
                        title: ('Manajemen Terpadu').tr(context),
                        description:
                            ('Sistem lengkap dengan berbagai fitur andalan.').tr(context),
                        features:  [
                          FeatureItem(
                            icon: Icons.inventory_2_rounded,
                            title: ('Manajemen Stok').tr(context),
                            subtitle: ('Kontrol inventaris secara real-time').tr(context),
                          ),
                          SizedBox(height: 16),
                          FeatureItem(
                            icon: Icons.people_alt_rounded,
                            title: ('Data Pelanggan').tr(context),
                            subtitle: ('Kelola database pelanggan Anda').tr(context),
                          ),
                          SizedBox(height: 16),
                          FeatureItem(
                            icon: Icons.receipt_long_rounded,
                            title: ('Riwayat Transaksi').tr(context),
                            subtitle: ('Akses seluruh riwayat penjualan').tr(context),
                          ),
                        ],
                      ),
                      // Slide 3
                      _buildCard(
                        context: context,
                        pageIndex: 2,
                        title: ('Mulai Lebih Cepat').tr(context),
                        description:
                            ('Tingkatkan produktivitas bisnis Anda sekarang juga.').tr(context),
                        features:  [
                          FeatureItem(
                            icon: Icons.cloud_done_rounded,
                            title: ('Sinkronisasi Cloud').tr(context),
                            subtitle: ('Data tersimpan aman di server').tr(context),
                          ),
                          SizedBox(height: 16),
                          FeatureItem(
                            icon: Icons.security_rounded,
                            title: ('Akses Aman').tr(context),
                            subtitle: ('Privasi dan keamanan terjamin').tr(context),
                          ),
                          SizedBox(height: 16),
                          FeatureItem(
                            icon: Icons.rocket_launch_rounded,
                            title: ('Siap Digunakan').tr(context),
                            subtitle: ('Login sekarang dan rasakan kemudahannya').tr(context),
                          ),
                        ],
                      ),
                      // Slide 4: Login Form
                      BlocListener<AuthCubit, AuthState>(
                        listener: (context, state) {
                          if (state.isAuthenticated) {
                            final prefs = GetIt.I<SharedPreferences>();
                            prefs.setBool('has_seen_intro', true);
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (_) =>
                                    PosOnboardingPage.initialDestination(prefs),
                              ),
                              (route) => false,
                            );
                          }
                          if (state.isFailure && state.captcha == null) {
                            final message =
                                state.error ?? 'Login gagal. Coba lagi.';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: PosText(
                                  message,
                                  style: const TextStyle(color: Colors.white),
                                ),
                                backgroundColor: AppColors.danger,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 400),
                              child: Card(
                                elevation: 8,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: LoginForm(),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                // Page Indicators
                Padding(
                  padding: const EdgeInsets.only(bottom: 32),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 8,
                        width: _currentPage == index ? 24 : 8,
                        decoration: BoxDecoration(
                          color: _currentPage == index
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
