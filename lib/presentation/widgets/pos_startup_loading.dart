import 'package:flutter/material.dart';
import '../../core/_core.dart';

/// One presentation for access verification and initial cashier data loading.
class PosStartupLoading extends StatelessWidget {
  const PosStartupLoading({super.key});

  @override
  Widget build(BuildContext context) {
    final english = Localizations.localeOf(context).languageCode == 'en';
    return ColoredBox(
      color: Colors.white,
      child: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox.square(
                dimension: 112,
                child: ClipRect(
                  child: Image.asset(
                    'assets/images/pantoo_loading.gif',
                    fit: BoxFit.contain,
                    gaplessPlayback: true,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                english ? 'Getting the cashier ready…' : 'Menyiapkan kasir…',
                textScaler: TextScaler.noScaling,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                  decoration: TextDecoration.none,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                english ? 'Please wait a moment' : 'Mohon tunggu sebentar',
                textScaler: TextScaler.noScaling,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: Colors.black54,
                  decoration: TextDecoration.none,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
