import 'package:dartz/dartz.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_inventory_repository.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_inventory_page.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/pos_inventory_editor_page.dart';

class _POS extends Fake implements PosRepository {}
class _Bloc extends PosBloc {
  _Bloc():super(posRepository:_POS()) {
    emit(state.copyWith(runtimeConfig:{'features':{'track_stock':true},'permissions':{
      'view_inventory_purchases':true,'create_inventory_purchases':true,
    },'inventory_policy':{'inventory_profile':'simple','default_receiving_location_id':'dest'}}));
  }
}
class _Inventory extends Fake implements PosInventoryRepository {
  @override
  Future<Either<Failure,Map<String,dynamic>>> getDirectPurchaseWorkspace()async=>const Right({});
  @override
  Future<Either<Failure,Map<String,dynamic>>> getPurchaseAdvanceWorkspace({String search='',int page=1})async=>const Right({});
  @override
  Future<Either<Failure,PosInventoryDocumentPage>> getDocuments({required PosInventoryDocumentType type,String search='',String status='',List<String> statuses=const [],String inventoryId='',bool receivableOnly=false,bool openQuantityOnly=false,String workflowView='',String locationId='',String dateFrom='',String dateTo='',String reason='',int page=1,int limit=20})async=>const Right(PosInventoryDocumentPage([],0));
  @override
  Future<Either<Failure,PosInventoryLookups>> getLookups({bool purchaseOnly=false})async=>const Right(PosInventoryLookups(suppliers:[],warehouses:[{'_id':'dest','nama_cabang':'QA destination','alamat_cabang':'QA address','is_receiving_location':true}],activeWarehouseId:'dest',inventoryItems:[],scrapReasons:[],scrapIncidentTypes:[],scrapOccurrenceLocations:[],purchaseReturnReasons:[],purchaseReturnMethods:[]));
}
void main(){
  tearDown(()=>sl.reset());
  testWidgets('purchase editor pushed outside home route keeps the exact POS context and finishes loading',(tester)async{
    SharedPreferences.setMockInitialValues({});
    sl.registerSingleton<SharedPreferences>(await SharedPreferences.getInstance());
    sl.registerSingleton<PosInventoryRepository>(_Inventory());
    final bloc=_Bloc();addTearDown(bloc.close);
    await tester.pumpWidget(MaterialApp(home:BlocProvider<PosBloc>.value(value:bloc,child:const Scaffold(body:PosInventoryPage(initialSection:'purchase')))));
    await tester.pumpAndSettle(const Duration(milliseconds:100),EnginePhase.sendSemanticsUpdate,const Duration(seconds:4));
    await tester.tap(find.widgetWithText(FilledButton,'Tambah'));
    await tester.pump();await tester.pump(const Duration(seconds:1));
    expect(tester.takeException(),isNull);
    final editor=find.byType(PosInventoryEditorPage);expect(editor,findsOneWidget);
    expect(tester.element(editor).read<PosBloc>(),same(bloc));
    expect(find.text('QA destination'),findsWidgets);
    await tester.pageBack();await tester.pumpAndSettle();
    expect(bloc.isClosed,isFalse);
  });
}
