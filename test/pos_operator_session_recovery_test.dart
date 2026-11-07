import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/core/network/pos_operator_identity.dart';
import 'package:mobile_pos_pantoo/core/network/sync_service.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/lock/lock_state.dart';

class _Repo extends Fake implements PosRepository {
  String token = 'offline_operator:a';
  @override
  String get activeOperatorId => operatorIdFromToken(token);
  @override
  void setOperatorSessionToken(String value) {
    token = value;
  }
}

class _Sync extends Fake implements SyncService {
  String token = 'offline_operator:a';
  @override
  void setOperatorSessionToken(String value) {
    token = value;
  }
}

class _Lock extends AppLockCubit {
  void seed(String actor, {bool locked = false}) => emit(
    AppLockState(
      status: locked ? AppLockStatus.locked : AppLockStatus.unlocked,
      activeEmployeeId: actor,
      operatorSessionToken: 'offline_operator:$actor',
    ),
  );
}

String verified(String actor, {bool expired = false}) =>
    'qa.${base64UrlEncode(utf8.encode(jsonEncode({'type': 'pos_operator', 'user_id': actor, 'exp': DateTime.now().millisecondsSinceEpoch ~/ 1000 + (expired ? -100 : 3600)})))}.fixture';
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late _Repo repo;
  late _Sync sync;
  setUp(() async {
    await sl.reset();
    repo = _Repo();
    sync = _Sync();
    sl.registerSingleton<PosRepository>(repo);
    sl.registerSingleton<SyncService>(sync);
  });
  tearDown(() => sl.reset());
  test(
    'online PIN recovery refreshes the same active operator in lock, repository and sync',
    () async {
      final cubit = _Lock()..seed('a');
      final token = verified('a');
      expect(cubit.acceptVerifiedOperatorSession(token), isTrue);
      expect(repo.token, token);
      expect(sync.token, token);
      expect(cubit.state.operatorSessionToken, token);
      expect(cubit.state.activeEmployeeId, 'a');
      await cubit.close();
    },
  );
  for (final mode in ['other-actor', 'expired', 'locked']) {
    test(
      'queue verification cannot switch actor or unlock session: $mode',
      () async {
        final cubit = _Lock()..seed('a', locked: mode == 'locked');
        expect(
          cubit.acceptVerifiedOperatorSession(
            verified(
              mode == 'other-actor' ? 'b' : 'a',
              expired: mode == 'expired',
            ),
          ),
          isFalse,
        );
        expect(repo.token, 'offline_operator:a');
        expect(sync.token, 'offline_operator:a');
        expect(cubit.state.operatorSessionToken, 'offline_operator:a');
        await cubit.close();
      },
    );
  }
}
