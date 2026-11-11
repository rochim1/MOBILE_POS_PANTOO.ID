import 'dart:async';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/network/sync_service.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_state.dart';

class _Repo extends Fake implements PosRepository {
  final roster = Completer<Either<Failure, List<Map<String, dynamic>>>>();
  @override
  void setOperatorSessionToken(String token) {}
  @override
  Future<Either<Failure, List<Map<String, dynamic>>>> getPOSPinUsers({
    String search = '',
    bool? hasPin,
  }) => roster.future;
  @override
  Future<Either<Failure, Map<String, dynamic>>> getMyPOSLockStatus() async =>
      const Right({'has_pin': true});
}

class _Sync extends Fake implements SyncService {
  @override
  void setOperatorSessionToken(String token) {}
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({'user_id': 'qa'});
    sl.registerSingleton<SharedPreferences>(
      await SharedPreferences.getInstance(),
    );
    sl.registerSingleton<SyncService>(_Sync());
  });
  tearDown(() async => sl.reset());
  testWidgets(
    'slow roster keeps PIN locked and shows retry message after timeout',
    (tester) async {
      sl.registerSingleton<PosRepository>(_Repo());
      final cubit = AppLockCubit();
      final pending = cubit.lock();
      expect(cubit.state.status, AppLockStatus.locked);
      await tester.pump(const Duration(seconds: 16));
      await pending;
      expect(cubit.state.status, AppLockStatus.locked);
      expect(cubit.state.loadingEmployees, isFalse);
      expect(cubit.state.errorMessage, contains('coba lagi'));
      await cubit.close();
    },
  );
  test('logout invalidates previous login roster response', () async {
    final repo = _Repo();
    sl.registerSingleton<PosRepository>(repo);
    final cubit = AppLockCubit();
    final pending = cubit.lock();
    cubit.reset();
    repo.roster.complete(
      const Right([
        {'_id': 'qa', 'has_pin': true},
      ]),
    );
    await pending;
    expect(cubit.state.status, AppLockStatus.unlocked);
    expect(cubit.state.employees, isEmpty);
    await cubit.close();
  });
}
