import 'package:flutter_bloc/flutter_bloc.dart';
import 'pos_return_event.dart';
import 'pos_return_state.dart';
import '../../../domain/repositories/pos_repository.dart';

class PosReturnBloc extends Bloc<PosReturnEvent, PosReturnState> {
  final PosRepository posRepository;

  PosReturnBloc({required this.posRepository}) : super(const PosReturnState()) {
    on<LoadReturns>(_onLoadReturns);
    on<SearchInvoice>(_onSearchInvoice);
    on<SelectReturnItem>(_onSelectReturnItem);
    on<UpdateReturnItem>(_onUpdateReturnItem);
    on<SubmitReturn>(_onSubmitReturn);
    on<ApproveReturn>(_onApproveReturn);
    on<ProcessReturn>(_onProcessReturn);
    on<DeleteReturn>(_onDeleteReturn);
    on<ClearReturnForm>(_onClearReturnForm);
  }

  Future<void> _onLoadReturns(
    LoadReturns event,
    Emitter<PosReturnState> emit,
  ) async {
    emit(state.copyWith(status: PosReturnStatus.loading));
    final result = await posRepository.getAllSalesReturns(
      search: event.search,
      status: event.status,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosReturnStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (data) =>
          emit(state.copyWith(status: PosReturnStatus.success, returns: data)),
    );
  }

  Future<void> _onSearchInvoice(
    SearchInvoice event,
    Emitter<PosReturnState> emit,
  ) async {
    emit(state.copyWith(status: PosReturnStatus.loading));
    final result = await posRepository.findInvoice(event.invoice);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosReturnStatus.failure,
          errorMessage: failure.message,
          searchResult: null,
          returnItems: const [],
        ),
      ),
      (data) {
        final items = data['items'] as List;
        final returnItems = items
            .map(
              (i) => {
                'selected': false,
                'inventaris_id': i['inventaris_id'],
                'nama_inventaris': i['nama_inventaris'],
                'qty_original': i['qty'],
                'qty_returned': i['qty'],
                'unit': i['unit'],
                'harga_jual': i['harga_jual'],
                'kondisi': 'baik',
                'masuk_ke_stok': true,
              },
            )
            .toList();
        emit(
          state.copyWith(
            status: PosReturnStatus.success,
            searchResult: data,
            returnItems: returnItems,
          ),
        );
      },
    );
  }

  void _onSelectReturnItem(
    SelectReturnItem event,
    Emitter<PosReturnState> emit,
  ) {
    final updated = state.returnItems.map((item) {
      if (item['inventaris_id'] == event.inventarisId) {
        return {...item, 'selected': event.selected};
      }
      return item;
    }).toList();
    emit(state.copyWith(returnItems: updated));
  }

  void _onUpdateReturnItem(
    UpdateReturnItem event,
    Emitter<PosReturnState> emit,
  ) {
    final updated = state.returnItems.map((item) {
      if (item['inventaris_id'] == event.inventarisId) {
        final masukKeStok = event.kondisi == 'tidak_layak'
            ? false
            : event.masukKeStok;
        return {
          ...item,
          'qty_returned': event.qtyReturned,
          'kondisi': event.kondisi,
          'masuk_ke_stok': masukKeStok,
        };
      }
      return item;
    }).toList();
    emit(state.copyWith(returnItems: updated));
  }

  Future<void> _onSubmitReturn(
    SubmitReturn event,
    Emitter<PosReturnState> emit,
  ) async {
    if (state.searchResult == null) return;
    final selectedItems = state.returnItems
        .where((i) => i['selected'] == true && i['qty_returned'] > 0)
        .toList();
    if (selectedItems.isEmpty) {
      emit(
        state.copyWith(
          status: PosReturnStatus.failure,
          errorMessage: 'Pilih minimal 1 item untuk diretur',
        ),
      );
      return;
    }

    emit(state.copyWith(status: PosReturnStatus.loading));
    final payload = {
      'tanggal_retur': DateTime.now().toIso8601String().substring(0, 10),
      'sumber': 'pos',
      'sumber_id': state.searchResult!['_id'],
      'sumber_no': state.searchResult!['invoice'],
      'customer_name': state.searchResult!['pelanggan'] ?? 'Umum',
      'alasan': event.alasan,
      'metode_refund': event.metodeRefund,
      'catatan': event.catatan,
      'items': selectedItems
          .map(
            (i) => {
              'inventaris_id': i['inventaris_id'],
              'qty_returned': i['qty_returned'],
              'harga_jual': i['harga_jual'],
              'kondisi': i['kondisi'],
              'masuk_ke_stok': i['masuk_ke_stok'],
            },
          )
          .toList(),
    };

    final result = await posRepository.createSalesReturn(payload);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosReturnStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (success) {
        emit(
          state.copyWith(
            status: PosReturnStatus.success,
            searchResult: null,
            returnItems: const [],
          ),
        );
        add(const LoadReturns());
      },
    );
  }

  Future<void> _onApproveReturn(
    ApproveReturn event,
    Emitter<PosReturnState> emit,
  ) async {
    emit(state.copyWith(status: PosReturnStatus.loading));
    final result = await posRepository.approveSalesReturn(event.id);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosReturnStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (success) => add(const LoadReturns()),
    );
  }

  Future<void> _onProcessReturn(
    ProcessReturn event,
    Emitter<PosReturnState> emit,
  ) async {
    emit(state.copyWith(status: PosReturnStatus.loading));
    final result = await posRepository.processSalesReturn(event.id);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosReturnStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (success) => add(const LoadReturns()),
    );
  }

  Future<void> _onDeleteReturn(
    DeleteReturn event,
    Emitter<PosReturnState> emit,
  ) async {
    emit(state.copyWith(status: PosReturnStatus.loading));
    final result = await posRepository.deleteSalesReturn(event.id);
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosReturnStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (success) => add(const LoadReturns()),
    );
  }

  void _onClearReturnForm(ClearReturnForm event, Emitter<PosReturnState> emit) {
    emit(
      state.copyWith(
        searchResult: null,
        returnItems: const [],
        status: PosReturnStatus.initial,
      ),
    );
  }
}
