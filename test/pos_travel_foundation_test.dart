import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_remote_profile_catalog.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_business_profile_selector.dart';

class _Repository extends Fake implements PosRepository {
  int calls = 0;
  @override
  dynamic noSuchMethod(Invocation invocation) {
    calls++;
    throw StateError('Travel must stop before any repository side effect');
  }
}

class _TravelBloc extends PosBloc {
  _TravelBloc(_Repository repository) : super(posRepository: repository) {
    emit(
      PosState(
        status: PosStatus.success,
        runtimeConfig: const {'business_profile': 'travel'},
        cart: {
          PosProduct(
            id: 'p',
            code: 'P',
            name: 'Paket',
            price: 100,
            stock: 0,
            category: 'QA',
          ): 1,
        },
      ),
    );
  }
}

void main() {
  test(
    'TEST-TRAVEL-001 bundled and remote catalogs recognize Travel without generic service appointments',
    () {
      final catalog = PosRemoteProfileCatalog.bundled();
      final travel = catalog.profile('travel')!;
      expect(travel.features['require_customer'], isTrue);
      expect(travel.features['use_service_order'], isFalse);
      expect(travel.features['use_appointments'], isFalse);
      expect(travel.description, contains('DP dan pelunasan'));
      expect(PosProfileDefinition.fromJson(travel.toJson()).value, 'travel');
    },
  );
  test(
    'TEST-TRAVEL-009 Mobile refuses Travel payment before repository, outbox or financial side effects',
    () async {
      final repository = _Repository(), bloc = _TravelBloc(repository);
      final failure = bloc.stream.firstWhere(
        (s) => s.status == PosStatus.failure,
      );
      bloc.add(const SubmitPayment(paymentMethod: 'tunai', cashReceived: 100));
      await failure;
      expect(repository.calls, 0);
      expect(bloc.state.cart.length, 1);
      expect(bloc.state.errorMessage, contains('Booking Travel'));
      expect(bloc.state.paymentInProgress, isFalse);
      await bloc.close();
    },
  );
  testWidgets(
    'TEST-TRAVEL-018 Mobile selector exposes Travel booking with deposits',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PosBusinessProfileSelector(
              value: 'travel',
              catalog: PosRemoteProfileCatalog.bundled(),
              onChanged: (_) {},
            ),
          ),
        ),
      );
      expect(find.textContaining('DP dan pelunasan'), findsOneWidget);
      final field = tester.widget<DropdownButtonFormField<String>>(
        find.byType(DropdownButtonFormField<String>),
      );
      expect(field.initialValue, 'travel');
      await tester.pumpWidget(const SizedBox());
    },
  );
}
