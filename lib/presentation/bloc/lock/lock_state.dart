import 'package:equatable/equatable.dart';

enum AppLockStatus { initial, locked, unlocked, error }

class AppLockState extends Equatable {
  final AppLockStatus status;
  final bool hasPinConfigured;
  final String errorMessage;
  final String? activeEmployeeName;
  final String? activeEmployeeRole;
  final String? activeEmployeeId;
  final String operatorSessionToken;
  final List<Map<String, dynamic>> employees;
  final String? selectedEmployeeId;
  final bool loadingEmployees;

  const AppLockState({
    this.status = AppLockStatus.initial,
    this.hasPinConfigured = false,
    this.errorMessage = '',
    this.activeEmployeeName,
    this.activeEmployeeRole,
    this.activeEmployeeId,
    this.operatorSessionToken = '',
    this.employees = const [],
    this.selectedEmployeeId,
    this.loadingEmployees = false,
  });

  AppLockState copyWith({
    AppLockStatus? status,
    bool? hasPinConfigured,
    String? errorMessage,
    String? activeEmployeeName,
    String? activeEmployeeRole,
    String? activeEmployeeId,
    String? operatorSessionToken,
    List<Map<String, dynamic>>? employees,
    String? selectedEmployeeId,
    bool? loadingEmployees,
  }) {
    return AppLockState(
      status: status ?? this.status,
      hasPinConfigured: hasPinConfigured ?? this.hasPinConfigured,
      errorMessage: errorMessage ?? this.errorMessage,
      activeEmployeeName: activeEmployeeName ?? this.activeEmployeeName,
      activeEmployeeRole: activeEmployeeRole ?? this.activeEmployeeRole,
      activeEmployeeId: activeEmployeeId ?? this.activeEmployeeId,
      operatorSessionToken: operatorSessionToken ?? this.operatorSessionToken,
      employees: employees ?? this.employees,
      selectedEmployeeId: selectedEmployeeId ?? this.selectedEmployeeId,
      loadingEmployees: loadingEmployees ?? this.loadingEmployees,
    );
  }

  @override
  List<Object?> get props => [
    status,
    hasPinConfigured,
    errorMessage,
    activeEmployeeName,
    activeEmployeeRole,
    activeEmployeeId,
    operatorSessionToken,
    employees,
    selectedEmployeeId,
    loadingEmployees,
  ];
}
