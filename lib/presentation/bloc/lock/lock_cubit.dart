import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injections.dart';
import '../../../../domain/repositories/pos_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'lock_state.dart';
import '../../../../core/network/sync_service.dart';
import '../../../../core/network/pos_operator_identity.dart';

class AppLockCubit extends Cubit<AppLockState> {
  int _employeeLoadRevision = 0;
  AppLockCubit() : super(const AppLockState()) {
    _init();
  }

  Future<void> _init() async {
    emit(state.copyWith(status: AppLockStatus.unlocked));
  }

  /// A queue PIN confirmation may renew this cashier, never switch or unlock it.
  bool acceptVerifiedOperatorSession(String token) {
    final actor = operatorIdFromToken(token);
    if (state.status != AppLockStatus.unlocked ||
        actor.isEmpty ||
        actor != state.activeEmployeeId ||
        actor != sl<PosRepository>().activeOperatorId ||
        !operatorTokenIsCurrent(token)) {
      return false;
    }
    sl<PosRepository>().setOperatorSessionToken(token);
    sl<SyncService>().setOperatorSessionToken(token);
    emit(state.copyWith(operatorSessionToken: token));
    return true;
  }

  Future<void> lock() async {
    final loginUserId = sl<SharedPreferences>().getString('user_id');
    sl<PosRepository>().setOperatorSessionToken('');
    sl<SyncService>().setOperatorSessionToken('');
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
    final revision = ++_employeeLoadRevision;
    final prefs = sl<SharedPreferences>();
    final tenant = prefs.getString('instansi_id');
    final terminal = prefs.getString('user_id');
    bool current() =>
        !isClosed &&
        revision == _employeeLoadRevision &&
        tenant == prefs.getString('instansi_id') &&
        terminal == prefs.getString('user_id');
    try {
      emit(
        state.copyWith(
          status: AppLockStatus.locked,
          loadingEmployees: true,
          errorMessage: '',
        ),
      );
      final repository = sl<PosRepository>();
      final result = await repository
          .getPOSPinUsers(search: search, hasPin: true)
          .timeout(const Duration(seconds: 15));
      if (!current()) return;
      if (result.isLeft()) {
        result.fold(
          (failure) => emit(
            state.copyWith(
              status: AppLockStatus.locked,
              employees: const [],
              clearSelectedEmployee: true,
              hasPinConfigured: false,
              errorMessage: failure.message,
              loadingEmployees: false,
            ),
          ),
          (_) {},
        );
        return;
      }
      // A cached employee list is the complete source for the offline lock
      // screen. Do not make a second status request that can block the UI.
      final usingOfflineCache = result.fold(
        (_) => false,
        (employees) => employees.any((row) => row['offline_cached'] == true),
      );
      final rows = result.getOrElse(() => []);
      final loginHasPin = rows.any(
        (row) => row['_id']?.toString() == terminal && row['has_pin'] == true,
      );
      void publish(bool myHasPin, {bool checkingOwnPin = false}) {
        if (!current() || state.status != AppLockStatus.locked) return;
        result.fold(
          (failure) => emit(
            state.copyWith(
              errorMessage: failure.message,
              loadingEmployees: false,
            ),
          ),
          (employees) {
            // Pertahanan tambahan untuk kompatibilitas dengan server lama/cache:
            // modal PIN tidak pernah menampilkan operator tanpa PIN.
            final eligibleEmployees = employees
                .where((row) => row['has_pin'] == true)
                .map((row) => Map<String, dynamic>.from(row))
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
                        (row) =>
                            row['_id']?.toString() == state.activeEmployeeId,
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
                clearSelectedEmployee: selected == null,
                hasPinConfigured: selectedRow == null
                    ? state.hasPinConfigured
                    : selectedRow['has_pin'] == true,
                errorMessage: checkingOwnPin && eligibleEmployees.isEmpty
                    ? 'Memeriksa PIN akun login...'
                    : eligibleEmployees.isEmpty
                    ? 'Belum ada karyawan POS yang memiliki PIN.'
                    : '',
                loadingEmployees: false,
                lockedUntil: _parseLockedUntil(selectedRow?['locked_until']),
                clearLockedUntil: selectedRow?['locked_until'] == null,
              ),
            );
          },
        );
      }

      // Publish usable operators immediately. Optional own-account setup must
      // not hide this list, and listing never unlocks the terminal.
      publish(true, checkingOwnPin: !usingOfflineCache && !loginHasPin);
      if (usingOfflineCache || loginHasPin) return;
      try {
        final lockStatus = await repository.getMyPOSLockStatus().timeout(
          const Duration(seconds: 10),
        );
        if (!current() || state.status != AppLockStatus.locked) return;
        lockStatus.fold(
          (failure) {
            if (state.employees.isEmpty) {
              emit(state.copyWith(errorMessage: failure.message));
            }
          },
          (status) {
            final hasPin = status['has_pin'];
            if (hasPin is bool) {
              publish(hasPin);
            } else if (state.employees.isEmpty) {
              emit(
                state.copyWith(
                  errorMessage:
                      'Status PIN akun belum lengkap. Coba muat ulang untuk memeriksanya kembali.',
                ),
              );
            }
          },
        );
      } catch (_) {
        if (current() && state.employees.isEmpty) {
          emit(
            state.copyWith(
              loadingEmployees: false,
              errorMessage:
                  'Status PIN akun belum dapat diperiksa. Coba lagi; akun yang sudah terdaftar tetap harus memakai PIN.',
            ),
          );
        }
      }
    } catch (_) {
      if (current()) {
        emit(
          state.copyWith(
            loadingEmployees: false,
            errorMessage:
                'Daftar kasir belum dapat dimuat. Periksa koneksi lalu coba lagi.',
          ),
        );
      }
    }
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
        lockedUntil: _parseLockedUntil(row?['locked_until']),
        clearLockedUntil: row?['locked_until'] == null,
      ),
    );
  }

  Future<bool> unlock(String enteredPin) async {
    final revision = _employeeLoadRevision;
    final prefs = sl<SharedPreferences>();
    final tenant = prefs.getString('instansi_id');
    final terminal = prefs.getString('user_id');
    try {
      if (state.status != AppLockStatus.locked) return false;
      final employeeId = state.selectedEmployeeId;
      if (employeeId == null) {
        emit(state.copyWith(errorMessage: 'Pilih karyawan terlebih dahulu'));
        return false;
      }
      final result = await sl<PosRepository>().verifyPOSUserPin(
        employeeId,
        enteredPin,
      );
      if (isClosed ||
          revision != _employeeLoadRevision ||
          state.status != AppLockStatus.locked ||
          tenant != prefs.getString('instansi_id') ||
          terminal != prefs.getString('user_id') ||
          employeeId != state.selectedEmployeeId) {
        return false;
      }
      final missingOperator = result.fold(
        (failure) => failure.message.contains(
          'Pengguna tidak ditemukan pada instansi ini',
        ),
        (_) => false,
      );
      if (missingOperator) {
        await loadEmployees();
        if (isClosed) return false;
        final rosterRefreshed =
            state.errorMessage.isEmpty &&
            state.employees.isNotEmpty &&
            !state.employees.any((row) => row['_id']?.toString() == employeeId);
        emit(
          state.copyWith(
            errorMessage: rosterRefreshed
                ? 'Daftar kasir telah diperbarui. Pilih kasir dan masukkan PIN kembali.'
                : 'Daftar kasir tidak sesuai dengan sesi saat ini. Keluar dari akun, lalu login kembali; transaksi offline yang belum dikirim tetap tersimpan.',
          ),
        );
        return false;
      }
      return result.fold(
        (failure) {
          emit(state.copyWith(errorMessage: failure.message));
          return false;
        },
        (response) {
          if (response['success'] == true) {
            _employeeLoadRevision++;
            final operatorToken = response['operator_token']?.toString() ?? '';
            // Preserve the operator identity on queued transactions. Sync
            // requires online PIN verification by that same operator.
            sl<PosRepository>().setOperatorSessionToken(operatorToken);
            sl<SyncService>().setOperatorSessionToken(operatorToken);
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
                clearLockedUntil: true,
              ),
            );
            return true;
          }
          emit(
            state.copyWith(
              errorMessage: response['message']?.toString() ?? 'PIN salah',
              lockedUntil: _parseLockedUntil(response['locked_until']),
              clearLockedUntil: response['locked_until'] == null,
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

  void clearExpiredPinLockout() {
    final lockedUntil = state.lockedUntil;
    if (lockedUntil == null || lockedUntil.isAfter(DateTime.now())) return;
    emit(state.copyWith(errorMessage: '', clearLockedUntil: true));
  }

  static DateTime? _parseLockedUntil(dynamic value) {
    final parsed = DateTime.tryParse(value?.toString() ?? '');
    return parsed?.toLocal();
  }

  void reset() {
    _employeeLoadRevision++;
    sl<PosRepository>().setOperatorSessionToken('');
    sl<SyncService>().setOperatorSessionToken('');
    emit(const AppLockState(status: AppLockStatus.unlocked));
  }
}
