import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/network/pos_return_draft_request_store.dart';

class _DeniedStorage implements SharedPreferences {
  final Map<String, String> values = {};
  bool deny = true;
  @override
  String? getString(String key) => values[key];
  @override
  Future<bool> setString(String key, String value) async {
    if (deny) return false;
    values[key] = value;
    return true;
  }

  @override
  Future<bool> remove(String key) async {
    if (deny) return false;
    values.remove(key);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  final input = <String, dynamic>{
    'sumber': 'pos',
    'sumber_id': 'sale-1',
    'items': [
      {'inventaris_id': 'item', 'qty_returned': 1},
    ],
  };
  setUp(() => SharedPreferences.setMockInitialValues({}));
  test('disk refuses persistence: no new request may be sent', () async {
    final prefs = _DeniedStorage();
    final store = PosReturnDraftRequestStore(prefs, 'scope');
    await expectLater(store.begin(input), throwsStateError);
    expect(store.load(), isNull);
  });
  test(
    'failed local acknowledgement retains the original request for safe replay',
    () async {
      final prefs = _DeniedStorage()..deny = false;
      final store = PosReturnDraftRequestStore(prefs, 'scope');
      final proof = await store.begin(input);
      prefs.deny = true;
      await expectLater(
        store.acknowledge(proof['client_request_id'] as String),
        throwsStateError,
      );
      expect(store.load()?['client_request_id'], proof['client_request_id']);
    },
  );
  test(
    'app restart reuses frozen request including nested items, source and original date',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final first = await PosReturnDraftRequestStore(
        prefs,
        'api:tenant:terminal:actor',
      ).begin(input);
      (first['items'] as List).first['qty_returned'] = 999;
      final store = PosReturnDraftRequestStore(
        prefs,
        'api:tenant:terminal:actor',
      );
      final retry = await store.begin({...input, 'sumber_id': 'other'});
      expect(retry['client_request_id'], first['client_request_id']);
      expect(retry['sumber_id'], 'sale-1');
      expect((retry['items'] as List).first['qty_returned'], 1);
    },
  );
  test(
    'proof remains until matching acknowledgement and is isolated by operator',
    () async {
      final prefs = await SharedPreferences.getInstance();
      final a = PosReturnDraftRequestStore(prefs, 'actor-a'),
          b = PosReturnDraftRequestStore(prefs, 'actor-b');
      final proof = await a.begin(input);
      await b.begin(input);
      await a.acknowledge('wrong-key');
      expect(a.load(), isNotNull);
      await a.acknowledge(proof['client_request_id'] as String);
      expect(a.load(), isNull);
      expect(b.load(), isNotNull);
    },
  );
  test('corrupt or mismatched persisted proof fails closed', () async {
    final prefs = await SharedPreferences.getInstance();
    const key = 'pos_return_draft_pending_v1:scope';
    await prefs.setString(key, '{bad');
    expect(
      () => PosReturnDraftRequestStore(prefs, 'scope').load(),
      throwsStateError,
    );
    await prefs.setString(key, jsonEncode({'client_request_id': '', ...input}));
    expect(
      () => PosReturnDraftRequestStore(prefs, 'scope').load(),
      throwsStateError,
    );
  });
}
