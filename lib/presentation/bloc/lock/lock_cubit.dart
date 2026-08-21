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
    final repository = sl<PosRepository>();
    final result = await repository.getPOSPinUsers(
      search: search,
      hasPin: true,
    );
    final lockStatusResult = await repository.getMyPOSLockStatus();
    final myHasPin = lockStatusResult.fold(
      (_) => true,
      (status) => status['has_pin'] == true,
    );
    result.fold(
      (failure) => emit(
        state.copyWith(errorMessage: failure.message, loadingEmployees: false),
      ),
      (employees) {
        // Pertahanan tambahan untuk kompatibilitas dengan server lama/cache:
        // modal PIN tidak pernah menampilkan operator tanpa PIN.
        final eligibleEmployees = employees
            .where((row) => row['has_pin'] == true)
            .toList();
        final prefs = sl<SharedPreferences>();
        final loginUserId = prefs.getString('user_id') ?? '';
        final loginUserName = prefs.getString('username')?.trim() ?? '';
        final normalizedSearch = search.trim().toLowerCase();
        final loginMatchesSearch =
            normalizedSearch.isEmpty ||
            loginUserName.toLowerCase().contains(normalizedSearch);
        if (!myHasPin && loginUserId.isNotEmpty && loginMatchesSearch) {
          eligibleEmployees.insert(0, {
            '_id': loginUserId,
            'name': loginUserName.isEmpty ? 'Akun login' : loginUserName,
            'username': loginUserName,
            'has_pin': false,
            'is_login_user': true,
          });
        } else {
          for (final employee in eligibleEmployees) {
            if (employee['_id']?.toString() == loginUserId) {
              employee['is_login_user'] = true;
            }
          }
        }
        final currentSelection = state.selectedEmployeeId;
        final selected =
            eligibleEmployees.any(
              (row) => row['_id']?.toString() == currentSelection,
            )
            ? currentSelection
            : (eligibleEmployees.any(
                    (row) => row['_id']?.toString() == state.activeEmployeeId,
                  )
                  ? state.activeEmployeeId
                  : eligibleEmployees.firstOrNull?['_id']?.toString());
        final selectedRow = eligibleEmployees
            .where((row) => row['_id']?.toString() == selected)
            .firstOrNull;
        emit(
          state.copyWith(
            status: AppLockStatus.locked,
            employees: eligibleEmployees,
            selectedEmployeeId: selected,
            hasPinConfigured: selectedRow == null
                ? state.hasPinConfigured
                : selectedRow['has_pin'] == true,
            errorMessage: eligibleEmployees.isEmpty
                ? 'Belum ada karyawan POS yang memiliki PIN.'
                : '',
            loadingEmployees: false,
          ),
        );
      },
    );
  }

  Future<bool> createLoginUserPin({
    required String password,
    required String pin,
  }) async {
    final loginUserId = sl<SharedPreferences>().getString('user_id');
    if (loginUserId == null || state.selectedEmployeeId != loginUserId) {
      emit(
        state.copyWith(errorMessage: 'PIN hanya dapat dibuat untuk akun login'),
      );
      return false;
    }
    final result = await sl<PosRepository>().setMyPOSPin(
      password: password,
      pin: pin,
    );
    return result.fold(
      (failure) {
        emit(state.copyWith(errorMessage: failure.message));
        return false;
      },
      (_) {
        final employees = state.employees.map((employee) {
          if (employee['_id']?.toString() != loginUserId) return employee;
          return {...employee, 'has_pin': true};
        }).toList();
        emit(
          state.copyWith(
            employees: employees,
            hasPinConfigured: true,
            errorMessage: '',
          ),
        );
        return true;
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
