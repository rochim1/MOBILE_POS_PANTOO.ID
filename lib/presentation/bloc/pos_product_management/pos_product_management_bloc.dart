import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/pos_product_management_repository.dart';
import 'pos_product_management_event.dart';
import 'pos_product_management_state.dart';

class PosProductManagementBloc
    extends Bloc<PosProductManagementEvent, PosProductManagementState> {
  final PosProductManagementRepository repository;

  PosProductManagementBloc(this.repository)
    : super(const PosProductManagementState()) {
    on<CreateProduct>(_onCreateProduct);
    on<UpdateProduct>(_onUpdateProduct);
    on<DeleteProduct>(_onDeleteProduct);
  }

  Future<void> _onCreateProduct(
    CreateProduct event,
    Emitter<PosProductManagementState> emit,
  ) async {
    emit(state.copyWith(status: PosProductManagementStatus.loading));
    final result = await repository.createProduct(event.input);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosProductManagementStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (product) => emit(
        state.copyWith(
          status: PosProductManagementStatus.success,
          successMessage: 'Produk berhasil dibuat',
          operation: 'create',
          product: product,
          affectedProductId: product.id,
        ),
      ),
    );
  }

  Future<void> _onUpdateProduct(
    UpdateProduct event,
    Emitter<PosProductManagementState> emit,
  ) async {
    emit(state.copyWith(status: PosProductManagementStatus.loading));
    final result = await repository.updateProduct(event.id, event.input);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosProductManagementStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (product) => emit(
        state.copyWith(
          status: PosProductManagementStatus.success,
          successMessage: 'Produk berhasil diubah',
          operation: 'update',
          product: product,
          affectedProductId: product.id,
        ),
      ),
    );
  }

  Future<void> _onDeleteProduct(
    DeleteProduct event,
    Emitter<PosProductManagementState> emit,
  ) async {
    emit(state.copyWith(status: PosProductManagementStatus.loading));
    final result = await repository.deleteProduct(event.id);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosProductManagementStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (_) => emit(
        state.copyWith(
          status: PosProductManagementStatus.success,
          successMessage: 'Produk berhasil dihapus',
          operation: 'delete',
          clearProduct: true,
          affectedProductId: event.id,
        ),
      ),
    );
  }
}
