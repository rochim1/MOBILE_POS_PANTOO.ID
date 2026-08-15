import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';

class FeaturePlaceholderPage extends StatelessWidget {
  final String title;

  const FeaturePlaceholderPage({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.build_circle_outlined,
              size: 100,
              color: Colors.black26,
            ),
            const SizedBox(height: 24),
            Text(
              'Halaman $title',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fitur ini sedang dalam tahap pengembangan.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
                ),
              ),
              child: const Text('Kembali'),
            ),
          ],
        ),
      ),
    );
  }
}
