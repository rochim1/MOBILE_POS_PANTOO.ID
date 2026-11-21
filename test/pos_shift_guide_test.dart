import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_setup_tour.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_first_sale_guide.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/widgets/pos_shift_opening_tour.dart';

void main() {
  testWidgets('slow shift form waits and keeps all four spotlight steps', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs=await SharedPreferences.getInstance(), targets=PosSetupTourTargets();
    var ready=false, opens=0;
    StateSetter? refresh;
    await tester.pumpWidget(MaterialApp(home:Scaffold(body:PosFirstSaleGuide(
      preferences:prefs,scope:'shift-test',stepId:'cash',enabled:true,title:'Panduan shift',
      stages:posShiftOpeningTourStages(targets), readyTargets:posShiftOpeningTourStages(targets).map((s)=>s.target!).toList(),
      child:StatefulBuilder(builder:(context,setState) {refresh=setState;return SingleChildScrollView(child:Column(children:[
        TextButton(key:targets.shiftStore,onPressed:(){},child:const Text('Toko')),
        if(ready)...[
          TextField(key:targets.shiftOpeningCash,decoration:const InputDecoration(labelText:'Kas awal')),
          TextField(key:targets.shiftOpeningNotes,decoration:const InputDecoration(labelText:'Catatan')),
          ElevatedButton(key:targets.shiftOpen,onPressed:()=>opens++,child:const Text('Buka')),
        ],
      ]));}),
    ))));
    await tester.pumpAndSettle();
    expect(find.text('1 / 1'),findsNothing);expect(find.text('1 / 4'),findsNothing);
    await tester.pump(const Duration(seconds:2));
    refresh!(()=>ready=true);await tester.pump();await tester.pump(const Duration(milliseconds:200));await tester.pumpAndSettle();
    for(var index=1;index<=4;index++) {
      expect(find.text('$index / 4'),findsOneWidget);
      final button=find.text(index==4?'Mengerti':'Berikutnya');
      await tester.ensureVisible(button);await tester.tap(button);await tester.pumpAndSettle();
    }
    expect(opens,0,reason:'Guide must never open a financial shift automatically');
    expect(tester.takeException(),isNull);
  });
  test('shift steps explain cash zero, optional notes and explicit opening', () {
    final stages=posShiftOpeningTourStages(PosSetupTourTargets());
    expect(stages.length,4);expect(stages[1].description,contains('nol'));
    expect(stages[2].description,contains('opsional'));
    expect(stages.every((s)=>s.onTargetTap==null),isTrue);
  });
}
