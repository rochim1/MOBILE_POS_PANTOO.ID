import 'package:flutter/material.dart';
import '../../../../core/_core.dart';
import '../../widgets/app_toast.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _oldPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  void _submit() {
    if (_oldPasswordCtrl.text.isEmpty ||
        _newPasswordCtrl.text.isEmpty ||
        _confirmPasswordCtrl.text.isEmpty) {
      AppToast.error(context, 'Semua kolom harus diisi');
      return;
    }
    if (_newPasswordCtrl.text != _confirmPasswordCtrl.text) {
      AppToast.error(context, 'Konfirmasi kata sandi tidak cocok');
      return;
    }

    // Mock API call
    FocusScope.of(context).unfocus();
    AppToast.success(context, 'Kata sandi berhasil diubah');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Ubah Kata Sandi'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Demi keamanan, gunakan kombinasi huruf dan angka pada kata sandi baru Anda.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            _buildPasswordField(
              controller: _oldPasswordCtrl,
              label: 'Kata Sandi Saat Ini',
              obscure: _obscureOld,
              onToggle: () => setState(() => _obscureOld = !_obscureOld),
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              controller: _newPasswordCtrl,
              label: 'Kata Sandi Baru',
              obscure: _obscureNew,
              onToggle: () => setState(() => _obscureNew = !_obscureNew),
            ),
            const SizedBox(height: 16),
            _buildPasswordField(
              controller: _confirmPasswordCtrl,
              label: 'Konfirmasi Kata Sandi Baru',
              obscure: _obscureConfirm,
              onToggle: () =>
                  setState(() => _obscureConfirm = !_obscureConfirm),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Simpan Perubahan',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(
            obscure ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: onToggle,
        ),
      ),
    );
  }
}
