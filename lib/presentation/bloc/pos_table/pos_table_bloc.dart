import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_table_repository.dart';
import 'pos_table_event.dart';
import 'pos_table_state.dart';

class PosTableBloc extends Bloc<PosTableEvent, PosTableState> {
  final PosTableRepository repository;
  String _lastSearch = '';
  String _storeId = '';

  PosTableBloc({required this.repository}) : super(const PosTableState()) {
    on<LoadTables>(_onLoadTables);
    on<CreateTable>(_onCreateTable);
    on<UpdateTable>(_onUpdateTable);
    on<DeleteTable>(_onDeleteTable);
    on<UpdateTableStatus>(_onUpdateTableStatus);
  }

  Future<void> _onLoadTables(
    LoadTables event,
    Emitter<PosTableState> emit,
  ) async {
    emit(state.copyWith(status: PosTableStatus.loading));
    _lastSearch = event.search ?? '';
    _storeId = event.storeId;

    final result = await repository.getTables(
      storeId: event.storeId,
      search: event.search,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(
          status: PosTableStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (tables) =>
          emit(state.copyWith(status: PosTableStatus.success, tables: tables)),
    );
  }

  Future<void> _onCreateTable(
    CreateTable event,
    Emitter<PosTableState> emit,
  ) async {
    emit(state.copyWith(status: PosTableStatus.loading));

    final result = await repository.createTable(
      storeId: _storeId,
      name: event.name,
      capacity: event.capacity,
    );

    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: PosTableStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (table) async {
        final shouldDisplay =
            _lastSearch.isEmpty ||
            table.name.toLowerCase().contains(_lastSearch.toLowerCase());
        final tables = shouldDisplay
            ? ([...state.tables, table]
                ..sort((a, b) => a.name.compareTo(b.name)))
            : state.tables;
        emit(
          state.copyWith(
            status: PosTableStatus.actionSuccess,
            tables: tables,
            successMessage: 'Meja "${table.name}" berhasil ditambahkan',
          ),
        );
        // Reload the list
        add(LoadTables(storeId: _storeId, search: _lastSearch));
      },
    );
  }

  Future<void> _onUpdateTable(
    UpdateTable event,
    Emitter<PosTableState> emit,
  ) async {
    emit(state.copyWith(status: PosTableStatus.loading));

    final result = await repository.updateTable(
      storeId: _storeId,
      id: event.id,
      name: event.name,
      capacity: event.capacity,
      status: event.status,
    );

    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: PosTableStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (table) async {
        final tables =
            state.tables
                .map((item) => item.id == table.id ? table : item)
                .where(
                  (item) =>
                      _lastSearch.isEmpty ||
                      item.name.toLowerCase().contains(
                        _lastSearch.toLowerCase(),
                      ),
                )
                .toList()
              ..sort((a, b) => a.name.compareTo(b.name));
        emit(
          state.copyWith(
            status: PosTableStatus.actionSuccess,
            tables: tables,
            successMessage: 'Meja "${table.name}" berhasil diperbarui',
          ),
        );
        // Reload the list
        add(LoadTables(storeId: _storeId, search: _lastSearch));
      },
    );
  }

  Future<void> _onDeleteTable(
    DeleteTable event,
    Emitter<PosTableState> emit,
  ) async {
    emit(state.copyWith(status: PosTableStatus.loading));

    final result = await repository.deleteTable(
      id: event.id,
      storeId: _storeId,
    );

    await result.fold(
      (failure) async => emit(
        state.copyWith(
          status: PosTableStatus.failure,
          errorMessage: failure.message,
        ),
      ),
      (message) async {
        emit(
          state.copyWith(
            status: PosTableStatus.actionSuccess,
            tables: state.tables
                .where((table) => table.id != event.id)
                .toList(),
            successMessage: message,
          ),
        );
        // Reload the list
        add(LoadTables(storeId: _storeId, search: _lastSearch));
      },
    );
  }

  Future<void> _onUpdateTableStatus(
    UpdateTableStatus event,
    Emitter<PosTableState> emit,
  ) async {
    add(UpdateTable(id: event.id, status: event.status));
  }
}
