import 'package:intl/date_symbol_data_local.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_report.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_report_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_financial_report_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_state.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_report/pos_report_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_report_page.dart';
import 'fixtures/pos_financial_report_fixture.dart';

class _SalesReport implements PosReportRepository {
  @override
  Future<Either<Failure, PosReportData>> getReportData({int days = 7}) async =>
      const Right(PosReportData());
}

class _Pos extends Cubit<PosState> implements PosBloc {
  _Pos() : super(const PosState(runtimeConfig: {'instansi_id': 'tenant-a'}));
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Lock extends AppLockCubit {
  void operator(String id) => emit(
    state.copyWith(status: AppLockStatus.unlocked, activeEmployeeId: id),
  );
}

class _Provider implements GraphQLClientProvider {
  @override
  GraphQLClient client = GraphQLClient(
    cache: GraphQLCache(),
    link: Link.function((request, [forward]) async* {
      yield const Response(response: {}, data: {});
    }),
  );
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets(
    'Report exposes profit loss and disposes prior operator financial data',
    (tester) async {
      await initializeDateFormatting();
      await sl.reset();
      final repo = FakeFinancialRepository();
      final pos = _Pos();
      final lock = _Lock()..operator('owner');
      sl.registerFactory<PosReportBloc>(
        () => PosReportBloc(repository: _SalesReport()),
      );
      sl.registerSingleton<PosFinancialReportRepository>(repo);
      sl.registerSingleton<GraphQLClientProvider>(_Provider());
      addTearDown(() async {
        await pos.close();
        await lock.close();
        await sl.reset();
      });
      await tester.binding.setSurfaceSize(const Size(390, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<PosBloc>.value(value: pos),
            BlocProvider<AppLockCubit>.value(value: lock),
          ],
          child: const MaterialApp(home: Scaffold(body: PosReportPage())),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ringkasan Penjualan').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Laba Rugi').last);
      await tester.pumpAndSettle();
      expect(repo.calls, isNotEmpty);
      expect(find.text('Rp 100.000'), findsWidgets);
      repo.options = const Left(FinancialReportAccessFailure());
      lock.operator('cashier');
      await tester.pumpAndSettle();
      expect(find.text('Rp 100.000'), findsNothing);
      expect(
        find.text('Akses laporan keuangan belum tersedia'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    },
  );
}
