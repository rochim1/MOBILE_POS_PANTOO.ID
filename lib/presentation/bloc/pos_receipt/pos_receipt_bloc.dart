import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../domain/repositories/pos_receipt_repository.dart';
import 'pos_receipt_event.dart';
import 'pos_receipt_state.dart';

class PosReceiptBloc extends Bloc<PosReceiptEvent, PosReceiptState> {
  final PosReceiptRepository repository;

  PosReceiptBloc({required this.repository}) : super(const PosReceiptState()) {
    on<LoadReceiptTemplate>(_onLoadReceiptTemplate);
    on<UpdateReceiptTemplate>(_onUpdateReceiptTemplate);
  }

  Future<void> _onLoadReceiptTemplate(
    LoadReceiptTemplate event,
    Emitter<PosReceiptState> emit,
  ) async {
    emit(state.copyWith(status: PosReceiptStatus.loading));

    final result = await repository.getReceiptTemplate();

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosReceiptStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (template) => emit(
        state.copyWith(status: PosReceiptStatus.loaded, template: template),
      ),
    );
  }

  Future<void> _onUpdateReceiptTemplate(
    UpdateReceiptTemplate event,
    Emitter<PosReceiptState> emit,
  ) async {
    emit(state.copyWith(status: PosReceiptStatus.saving));

    final result = await repository.updateReceiptTemplate(event.input);

    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosReceiptStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (template) => emit(
        state.copyWith(
          status: PosReceiptStatus.saved,
          successMessage: 'Pengaturan struk berhasil disimpan',
          template: template,
        ),
      ),
    );
  }
}
