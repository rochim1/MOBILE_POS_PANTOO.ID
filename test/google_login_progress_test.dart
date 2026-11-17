import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/auth/auth_cubit.dart';
import 'package:mobile_pos_pantoo/domain/repositories/auth_repository.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/login/google_account_button.dart';

class _Auth extends Fake implements AuthRepository {}

void main() {
  testWidgets('Google setup shows progress then a retry when endpoint stalls', (
    tester,
  ) async {
    final pending = Completer<void>();
    int attempts = 0;
    final cubit = AuthCubit(authRepository: _Auth());
    addTearDown(cubit.close);
    await tester.pumpWidget(
      BlocProvider.value(
        value: cubit,
        child: MaterialApp(
          home: Scaffold(
            body: GoogleAccountButton(
              prepareEndpoint: () {
                attempts++;
                return pending.future;
              },
            ),
          ),
        ),
      ),
    );
    expect(find.text('Menyiapkan login Google…'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(seconds: 16));
    await tester.pump();
    expect(find.byType(LinearProgressIndicator), findsNothing);
    expect(find.text('Coba hubungkan Google'), findsOneWidget);
    expect(find.textContaining('Google belum tersedia'), findsOneWidget);
    await tester.tap(find.text('Coba hubungkan Google'));
    await tester.pump();
    expect(attempts, 2);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
    await tester.pump(const Duration(seconds: 16));
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
  });
}
