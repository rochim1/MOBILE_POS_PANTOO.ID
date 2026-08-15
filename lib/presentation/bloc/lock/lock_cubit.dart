import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injections.dart';
import '../../../../domain/repositories/pos_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lock_state.dart';

class AppLockCubit extends Cubit<AppLockState> {
  AppLockCubit() : super(const AppLockState()) {
    _init();
  }

  Future<void> _init() async {
    emit(state.copyWith(status: AppLockStatus.unlocked));
  }

  Future<void> lock() async {
    final loginUserId = sl<SharedPreferences>().getString('user_id');
    emit(
      state.copyWith(
        status: AppLockStatus.locked,
        loadingEmployees: true,
        selectedEmployeeId: loginUserId,
      ),
    );
    await loadEmployees();
  }

  Future<void> loadEmployees({String search = ''}) async {
    emit(state.copyWith(loadingEmployees: true, errorMessage: ''));
    final result = await sl<PosRepository>().getPOSPinUsers(search: search);
    result.fold(
      (failure) => emit(
        state.copyWith(errorMessage: failure.message, loadingEmployees: false),
      ),
      (employees) {
        final selected =
            state.selectedEmployeeId ??
            (employees.any(
                  (row) => row['_id']?.toString() == state.activeEmployeeId,
                )
                ? state.activeEmployeeId
                : (employees
                              .where((row) => row['has_pin'] == true)
                              .firstOrNull ??
                          employees.firstOrNull)?['_id']
                      ?.toString());
        final selectedRow = employees
            .where((row) => row['_id']?.toString() == selected)
            .firstOrNull;
        emit(
          state.copyWith(
            status: AppLockStatus.locked,
            employees: employees,
            selectedEmployeeId: selected,
            hasPinConfigured: selectedRow == null
                ? state.hasPinConfigured
                : selectedRow['has_pin'] == true,
            errorMessage: employees.isEmpty
                ? 'Belum ada karyawan POS yang dapat dipilih.'
                : '',
            loadingEmployees: false,
          ),
        );
      },
    );
  }

  void selectEmployee(String userId) {
    final row = state.employees
        .where((item) => item['_id']?.toString() == userId)
        .firstOrNull;
    emit(
      state.copyWith(
        selectedEmployeeId: userId,
        hasPinConfigured: row?['has_pin'] == true,
        errorMessage: row?['has_pin'] == true
            ? ''
            : 'PIN karyawan belum dibuat. Hubungi admin POS.',
      ),
    );
  }

  Future<bool> unlock(String enteredPin) async {
    try {
      final employeeId = state.selectedEmployeeId;
      if (employeeId == null) {
        emit(state.copyWith(errorMessage: 'Pilih karyawan terlebih dahulu'));
        return false;
      }
      final result = await sl<PosRepository>().verifyPOSUserPin(
        employeeId,
        enteredPin,
      );
      return result.fold(
        (failure) {
          emit(state.copyWith(errorMessage: failure.message));
          return false;
        },
        (response) {
          if (response['success'] == true) {
            final operatorToken = response['operator_token']?.toString() ?? '';
            sl<PosRepository>().setOperatorSessionToken(operatorToken);
            emit(
              state.copyWith(
                status: AppLockStatus.unlocked,
                errorMessage: '',
                activeEmployeeId: response['user_id']?.toString(),
                activeEmployeeName:
                    response['name']?.toString().isNotEmpty == true
                    ? response['name'].toString()
                    : response['username']?.toString(),
                operatorSessionToken: operatorToken,
              ),
            );
            return true;
          }
          emit(
            state.copyWith(
              errorMessage: response['message']?.toString() ?? 'PIN salah',
            ),
          );
          return false;
        },
      );
    } catch (e) {
      emit(state.copyWith(errorMessage: 'Terjadi kesalahan sistem'));
      return false;
    }
  }

  void reset() {
    sl<PosRepository>().setOperatorSessionToken('');
    emit(const AppLockState(status: AppLockStatus.unlocked));
  }
}
