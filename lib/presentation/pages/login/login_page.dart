import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/core/themes/colors_theme.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/auth/auth_state.dart';
import '../../widgets/login/login_form.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 420;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/geometric_bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: BlocListener<AuthCubit, AuthState>(
          listener: (context, state) {
            if (state.isFailure && state.captcha == null) {
              final message = state.error ?? 'Login gagal. Coba lagi.';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
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
              padding: EdgeInsets.all(compact ? 14 : 24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Card(
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(compact ? 18 : 24),
                    child: const LoginForm(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
