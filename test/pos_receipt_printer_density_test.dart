import 'package:dartz/dartz.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_receipt_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_receipt/pos_receipt_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_printer_page.dart';
import 'pos_receipt_layout_test.dart' show receiptTemplate, receiptCompany;

class _Repository extends Fake implements PosReceiptRepository {
  _Repository(this.width);
  final int width;
  @override
  Future<Either<Failure, PosReceiptPrintData>> getReceiptPrintData({bool forceRefresh=false}) async => Right(PosReceiptPrintData(template:receiptTemplate.copyWith(paperWidth:width),company:receiptCompany));
}
void main() {
  for (final width in [58,80]) {
    testWidgets('printer settings and preview keep valid font at 390px: $width', (tester) async {
      tester.view.physicalSize=const Size(390,844);
      tester.view.devicePixelRatio=1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      debugDefaultTargetPlatformOverride=TargetPlatform.android;
      addTearDown(()=>debugDefaultTargetPlatformOverride=null);
      SharedPreferences.setMockInitialValues({});
      sl.pushNewScope();
      addTearDown(sl.popScope);
      sl.registerSingleton<SharedPreferences>(await SharedPreferences.getInstance());
      sl.registerFactory<PosReceiptBloc>(()=>PosReceiptBloc(repository:_Repository(width)));
      await tester.pumpWidget(MaterialApp(locale:const Locale('id'),localizationsDelegates:AppLocalizations.localizationsDelegates,supportedLocales:AppLocalizations.supportedLocales,home:const PosPrinterPage()));
      await tester.pumpAndSettle();
      final paper=find.byWidgetPredicate((w)=>w is DropdownButtonFormField<String> && w.decoration.labelText=='Lebar Kertas');
      await tester.ensureVisible(paper);
      if (width==80) {
        await tester.tap(paper);
        await tester.pumpAndSettle();
        await tester.tap(find.text('58').last);
        await tester.pumpAndSettle();
      }
      final font=find.byWidgetPredicate((w)=>w is DropdownButtonFormField<String> && w.decoration.labelText=='Ukuran Font Default');
      final fontWidget=tester.widget<DropdownButton<String>>(find.descendant(of:font,matching:find.byType(DropdownButton<String>)));
      expect(fontWidget.items!.map((i)=>i.value),['7','8','9']);
      final state=tester.state<FormFieldState<String>>(font);
      expect(state.value,'9');
      final preview=find.text('Air Mineral 600 ml [Dummy]');
      // The settings preview uses its own fixed sample products.
      expect(preview,findsNothing);
      await tester.ensureVisible(find.text('Produk Contoh A'));
      await tester.pumpAndSettle();
      expect(tester.takeException(),isNull);
      await tester.pumpWidget(const SizedBox());
    });
  }
}
