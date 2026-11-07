import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_return/pos_return_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_return/pos_return_event.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_return_page.dart';

class _Repository implements PosRepository {
  int reads = 0, writes = 0;
  bool failRead = true;
  final release = Completer<Either<Failure, bool>>();
  @override
  Map<String, dynamic>? pendingReturnDraft() => null;
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getAllSalesReturns({
    String? search,
    String? status,
  }) async {
    reads++;
    if (failRead) return const Left(ServerFailure('QA offline'));
    return Right([
      {
        '_id': 'ret-1',
        'no_retur': 'QA',
        'sumber_no': 'INV-QA',
        'status': 'approved',
        'total_refund': 10000,
      },
    ]);
  }

  @override
  Future<Either<Failure, bool>> processSalesReturn(String id) {
    writes++;
    return release.future;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'failed list offers read-only retry; refund button stays disabled with progress until response',
    (tester) async {
      final repository = _Repository();
      final bloc = PosReturnBloc(posRepository: repository);
      addTearDown(bloc.close);
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider.value(
            value: bloc,
            child: const Scaffold(
              body: PosReturnView(permissions: {'process_returns': true}),
            ),
          ),
        ),
      );
      bloc.add(const LoadReturns());
      await tester.pumpAndSettle();
      expect(find.text('Daftar retur belum termuat'), findsOneWidget);
      expect(find.text('Belum ada retur'), findsNothing);
      repository.failRead = false;
      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();
      expect(repository.writes, 0);
      await tester.tap(find.text('Proses'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Proses Retur'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      expect(repository.writes, 1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        tester.widget<ElevatedButton>(find.byType(ElevatedButton)).onPressed,
        isNull,
      );
      repository.release.complete(
        const Left(ServerFailure('QA uncertain: jangan ulangi refund')),
      );
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 5));
    },
  );
}
