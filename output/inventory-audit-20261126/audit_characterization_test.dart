// Audit evidence only: these assertions characterize CURRENT gaps, not fixes.
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_transfer_editor_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_transfer_operation_page.dart';
import '../../test/pos_transfer_editor_test.dart' show TransferFake;

class LostCreateResponse extends TransferFake {
  final createdKeys = <String>{};
  bool loseResponse = true;

  @override
  Future<Map<String, dynamic>> query(String document,
      [Map<String, dynamic> variables = const {}]) async {
    if (document.contains('MobileTransferAvailable')) {
      return {
        'GetInventarisAvailableInLocation': [
          {'inventaris_id': 'product', 'nama_inventaris': 'Audit product',
            'unit': 'pcs', 'qty': 10.0}
        ]
      };
    }
    return super.query(document, variables);
  }

  @override
  Future<Map<String, dynamic>> mutate(String document,
      Map<String, dynamic> variables, String root) async {
    requests.add(variables);
    createdKeys.add(variables['request_id'] as String);
    if (pending != null) return pending!.future;
    if (loseResponse) throw Exception('Audit: server committed, response lost');
    return {'_id': 'doc', 'status': 'draft'};
  }
}

class LostPartialReceipt extends TransferFake {
  double received = 0;
  final receiptKeys = <String>{};

  @override
  Future<Map<String, dynamic>> detail(String id) async => {
    '_id': id, 'status': 'in_transit', 'no_transfer': 'AUDIT-PARTIAL',
    'updatedAt': 'revision-$received', 'tanggal_transfer': '2026-01-01',
    'ke': {'cabang_id': 'to'},
    'items': [{'_id': 'line', 'nama_inventaris': 'Audit product',
      'qty': 5.0, 'received_qty': received, 'unit': 'pcs'}],
  };

  @override
  Future<Map<String, dynamic>> mutate(String document,
      Map<String, dynamic> variables, String root) async {
    requests.add(variables);
    if (receiptKeys.add(variables['request_id'] as String)) {
      received += (variables['items'] as List).single['qty'] as double;
    }
    throw Exception('Audit: receipt committed, response lost');
  }
}

Future<void> saveVisible(WidgetTester tester, String label) async {
  await tester.scrollUntilVisible(find.text(label), 450,
      scrollable: find.byType(Scrollable).first, maxScrolls: 40);
  await tester.tap(find.text(label));
  await tester.pump(const Duration(milliseconds: 200));
}

Widget createForm(LostCreateResponse repo) => PosTransferEditorPage(
    initialSourceId: 'from', initialDestinationId: 'to',
    initialInventoryId: 'product', initialQuantity: 1, repository: repo);

void main() {
  testWidgets('AUDIT GAP: reopening create form loses idempotency identity after lost response', (tester) async {
    final repo = LostCreateResponse();
    Future<void> open() async {
      await tester.pumpWidget(MaterialApp(key: UniqueKey(), home: createForm(repo)));
      await tester.pumpAndSettle();
    }
    await open();
    await saveVisible(tester, 'Simpan mutasi');
    await tester.pumpAndSettle();
    await tester.pump(const Duration(seconds: 4));
    await saveVisible(tester, 'Simpan mutasi');
    await tester.pumpAndSettle();
    expect(repo.requests.length, 2);
    expect(repo.requests[0]['request_id'], repo.requests[1]['request_id']);
    expect(repo.createdKeys.length, 1, reason: 'Same open form is protected');
    await tester.pump(const Duration(seconds: 4));
    await open();
    await saveVisible(tester, 'Simpan mutasi');
    await tester.pumpAndSettle();
    expect(repo.requests[2]['input'], repo.requests[0]['input']);
    expect(repo.requests[2]['request_id'], isNot(repo.requests[0]['request_id']));
    expect(repo.createdKeys.length, 2,
        reason: 'Same intent now looks like a new transfer to a deduplicating server');
    await tester.pump(const Duration(seconds: 4));
    expect(tester.takeException(), isNull);
  });

  testWidgets('AUDIT GAP: system back can dismiss create form while mutation is in flight', (tester) async {
    final repo = LostCreateResponse()..pending = Completer<Map<String, dynamic>>();
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) =>
      Scaffold(body: TextButton(onPressed: () => Navigator.push(context,
        MaterialPageRoute<void>(builder: (_) => createForm(repo))),
        child: const Text('Audit launch'))))));
    await tester.tap(find.text('Audit launch'));
    await tester.pumpAndSettle();
    await saveVisible(tester, 'Simpan mutasi');
    expect(find.text('Menyimpan...'), findsOneWidget);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Audit launch'), findsOneWidget);
    expect(find.byType(PosTransferEditorPage), findsNothing);
    expect(repo.requests.length, 1);
    repo.pending!.complete({'_id': 'doc', 'status': 'draft'});
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('AUDIT GAP: reopened partial receipt permits a second identity after lost response', (tester) async {
    final repo = LostPartialReceipt();
    Future<void> openAndReceiveOne() async {
      await tester.pumpWidget(MaterialApp(key: UniqueKey(), home:
        PosTransferOperationPage(transfer: const {'_id': 'doc'},
          mode: 'receive', repository: repo)));
      await tester.pumpAndSettle();
      final field = find.byType(TextFormField).at(2);
      await tester.ensureVisible(field);
      await tester.enterText(field, '1');
      await tester.pump();
      await saveVisible(tester, 'Terima jumlah ini');
      await tester.pumpAndSettle();
      await tester.pump(const Duration(seconds: 4));
    }
    await openAndReceiveOne();
    expect(repo.received, 1);
    await openAndReceiveOne();
    expect(repo.requests[1]['items'], repo.requests[0]['items']);
    expect(repo.requests[1]['request_id'], isNot(repo.requests[0]['request_id']));
    expect(repo.received, 2,
        reason: 'Without a durable pending receipt, repeat after reopen is a new movement');
    expect(tester.takeException(), isNull);
  });
}
