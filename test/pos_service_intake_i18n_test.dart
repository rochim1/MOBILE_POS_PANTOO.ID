import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/l10n/pos_translation_lookup.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_service_intake_fields.dart';

void main(){
  test('service object detail copy is available offline in ID and EN',(){
    final en=lookupAppLocalizations(const Locale('en')),id=lookupAppLocalizations(const Locale('id'));
    const copy={
      'Isi objek layanan atau catatan pekerjaan.':'Enter the service item or job notes.',
      'Berat/jumlah mengikuti keranjang. Tidak perlu diisi ulang.':'Weight and quantity come from the cart. No need to enter them again.',
      'Tutup detail per objek':'Close individual item details',
      'Detail per objek (opsional)':'Individual item details (optional)',
      'Berat objek (kg)':'Item weight (kg)',
      'Jumlah objek':'Item quantity',
      'Identitas / tag objek':'Item ID / tag',
      'Catatan objek':'Item notes',
      'Pisahkan 1 ke objek lain':'Split off one item',
      'Hapus detail objek ini':'Remove these item details',
    };
    for(final entry in copy.entries){expect(translatePosText(entry.key,en),entry.value);expect(translatePosText(entry.key,id),entry.key);}
  });
  testWidgets('work dialog renders translated validation and preserves the original item name',(tester)async{
    const product=PosProduct(id:'qa',code:'QA',name:'Barang Uji',category:'test',productType:'service',serviceIntakeMode:'work_order',price:10000,stock:0,tracksStock:false);
    await tester.pumpWidget(MaterialApp(locale:const Locale('en'),localizationsDelegates:AppLocalizations.localizationsDelegates,supportedLocales:AppLocalizations.supportedLocales,home:Builder(builder:(context)=>Scaffold(body:TextButton(onPressed:()=>showPosServiceIntakeDialog(context,cart:{product:1},profile:'jasa'),child:const Text('Open'))))));
    await tester.tap(find.text('Open'));await tester.pumpAndSettle();
    expect(find.textContaining('Barang Uji'),findsOneWidget);
    await tester.tap(find.text('Save'));await tester.pumpAndSettle();
    expect(find.text('Enter the service item or job notes.'),findsOneWidget);
    expect(find.text('Individual item details (optional)'),findsOneWidget);
    await tester.tap(find.text('Cancel'));await tester.pumpAndSettle();
    expect(tester.takeException(),isNull);
  });
}
