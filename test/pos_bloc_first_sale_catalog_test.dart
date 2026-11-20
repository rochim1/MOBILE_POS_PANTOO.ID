import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_product.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_store.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_repository.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_bloc.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_event.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos/pos_state.dart';
class _Repository extends Fake implements PosRepository {
  int reads=0;
  @override String get activeOperatorId=>'owner';
  @override String get terminalUserId=>'owner';
  @override Future<Map<String,dynamic>> getRuntimeConfig()async=>{
    'initial_setup':{'automatic':true,'status':'ready','can_manage':true,'first_sale_pending':true},
    'permissions':{'use_cashier':true,'view_products':true,'manage_products':true,'view_shifts':true},
  };
  @override Future<List<PosStore>> getStores()async=>[const PosStore(id:'store',name:'Toko',status:'active',branchId:'wh')];
  @override Future<Map<String,dynamic>?> getActiveShiftForStore(String id)async=>null;
  @override Future<List<PosProduct>> getProducts({String? branchId})async{reads++;return [const PosProduct(id:'item',code:'SKU',name:'Produk pertama',category:'',price:100,stock:0)];}
  @override Future<Set<String>> getFavoriteProductIds()async=>{};
}
void main(){
  test('new owner can see catalog before opening cash, without permitting checkout',()async{
    final repo=_Repository(),bloc=PosBloc(posRepository:_Repository());
    await bloc.close();
    final subject=PosBloc(posRepository:repo);addTearDown(subject.close);
    final loaded=subject.stream.firstWhere((s)=>s.status==PosStatus.success||s.status==PosStatus.failure);
    subject.add(LoadPosData());final state=await loaded;
    expect(state.status,PosStatus.success);expect(repo.reads,1);expect(state.products.single.id,'item');expect(state.activeShift,isNull);
  });
}
