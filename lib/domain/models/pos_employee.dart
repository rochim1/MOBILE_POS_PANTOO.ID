import 'package:equatable/equatable.dart';

class PosEmployee extends Equatable {
  final String id;
  final String name;
  final String role; // 'kasir', 'supervisor', 'manager'
  final String pin;

  const PosEmployee({
    required this.id,
    required this.name,
    required this.role,
    required this.pin,
  });

  factory PosEmployee.fromJson(Map<String, dynamic> json) {
    return PosEmployee(
      id: json['id'] as String,
      name: json['name'] as String,
      role: json['role'] as String,
      pin: json['pin'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'role': role, 'pin': pin};
  }

  @override
  List<Object?> get props => [id, name, role, pin];
}
