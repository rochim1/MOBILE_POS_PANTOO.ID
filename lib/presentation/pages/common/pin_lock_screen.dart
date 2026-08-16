import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import '../../bloc/lock/lock_cubit.dart';
import '../../bloc/lock/lock_state.dart';
import '../../bloc/auth/auth_cubit.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _pin = '';
  final int _pinLength = 6;
  bool _isVerifying = false;
  bool _isLoggingOut = false;
  Timer? _searchDebounce;
  bool _employeeListFiltered = false;
  final TextEditingController _employeeSearchController =
      TextEditingController();

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _employeeSearchController.dispose();
    super.dispose();
  }

  void _onKeypadTap(String value) {
    final hasPin = context.read<AppLockCubit>().state.hasPinConfigured;
    if (hasPin && !_isVerifying && _pin.length < _pinLength) {
      setState(() {
        _pin += value;
      });

      if (_pin.length == _pinLength) {
        _verifyPin();
      }
    }
  }

  void _onDeleteTap() {
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  Future<void> _verifyPin() async {
    if (_pin.length < 4 || _isVerifying) return;
    setState(() => _isVerifying = true);
    final success = await context.read<AppLockCubit>().unlock(_pin);
    if (!mounted) return;
    if (!success) {
      setState(() {
        _pin = '';
        _isVerifying = false;
      });
    } else {
      setState(() => _isVerifying = false);
    }
  }

  Future<void> _confirmLogout() async {
    if (_isLoggingOut) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text(
          'Sesi kasir dan akun akan ditutup. Anda perlu login kembali untuk menggunakan POS.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.pop(dialogContext, true),
            icon: const Icon(Icons.logout),
            label: const Text('Logout'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    // Tunggu route dialog benar-benar selesai dibongkar sebelum AuthCubit
    // mengganti seluruh pohon aplikasi. Tanpa ini, focus traversal dialog bisa
    // membaca RenderBox milik overlay PIN yang sudah dalam proses deaktifasi.
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(kThemeAnimationDuration);
    if (!mounted) return;
    setState(() => _isLoggingOut = true);
    await context.read<AuthCubit>().logout();
  }

  String _employeeName(Map<String, dynamic>? employee) {
    if (employee == null) return 'Pilih karyawan';
    final name = employee['name']?.toString() ?? '';
    return name.isNotEmpty
        ? name
        : employee['username']?.toString() ?? 'Karyawan';
  }

  Future<void> _showEmployeePicker() async {
    final cubit = context.read<AppLockCubit>();
    if (cubit.state.employees.isEmpty) {
      await cubit.loadEmployees();
    }
    if (!mounted) return;
    _employeeSearchController.clear();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) => BlocProvider.value(
        value: cubit,
        child: FractionallySizedBox(
          heightFactor: 0.78,
          child: Column(
            children: [
              Container(
                width: 42,
                height: 4,
                margin: const EdgeInsets.only(top: 10, bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Icon(Icons.badge_outlined, color: AppColors.primary),
                    SizedBox(width: 10),
                    Text(
                      'Pilih Kasir',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
                child: TextField(
                  controller: _employeeSearchController,
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau username…',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      onPressed: () {
                        _employeeSearchController.clear();
                        _employeeListFiltered = false;
                        cubit.loadEmployees();
                      },
                      icon: const Icon(Icons.close),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (value) {
                    _employeeListFiltered = value.trim().isNotEmpty;
                    _searchDebounce?.cancel();
                    _searchDebounce = Timer(
                      const Duration(milliseconds: 350),
                      () => cubit.loadEmployees(search: value),
                    );
                  },
                ),
              ),
              Expanded(
                child: BlocBuilder<AppLockCubit, AppLockState>(
                  builder: (context, state) {
                    if (state.loadingEmployees && state.employees.isEmpty) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (state.employees.isEmpty) {
                      return const Center(
                        child: Text('Karyawan tidak ditemukan'),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 20),
                      itemCount: state.employees.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final employee = state.employees[index];
                        final id = employee['_id']?.toString() ?? '';
                        final hasPin = employee['has_pin'] == true;
                        final selected = id == state.selectedEmployeeId;
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withValues(
                              alpha: 0.12,
                            ),
                            child: const Icon(
                              Icons.person_outline,
                              color: AppColors.primary,
                            ),
                          ),
                          title: Text(
                            _employeeName(employee),
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: Text(
                            employee['username']?.toString() ?? '-',
                          ),
                          trailing: hasPin
                              ? Icon(
                                  selected
                                      ? Icons.check_circle
                                      : Icons.chevron_right,
                                  color: selected
                                      ? AppColors.primary
                                      : Colors.grey,
                                )
                              : const Text(
                                  'Belum ada PIN',
                                  style: TextStyle(
                                    color: Colors.orange,
                                    fontSize: 11,
                                  ),
                                ),
                          onTap: () {
                            setState(() => _pin = '');
                            cubit.selectEmployee(id);
                            Navigator.pop(sheetContext);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
    _searchDebounce?.cancel();
    _searchDebounce = null;
    if (mounted &&
        _employeeListFiltered &&
        cubit.state.status == AppLockStatus.locked) {
      _employeeListFiltered = false;
      await cubit.loadEmployees();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => Center(
            child: FittedBox(
              fit: BoxFit.contain,
              child: SizedBox(
                width: 420,
                height: 740,
                child: BlocBuilder<AppLockCubit, AppLockState>(
                  builder: (context, state) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 14,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.lock_outline,
                          size: 48,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Pilih Kasir',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          'Masukkan PIN',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: state.loadingEmployees
                                ? null
                                : _showEmployeePicker,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 13,
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.badge_outlined),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      _employeeName(
                                        state.employees
                                            .where(
                                              (employee) =>
                                                  employee['_id']?.toString() ==
                                                  state.selectedEmployeeId,
                                            )
                                            .firstOrNull,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (state.loadingEmployees)
                                    const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  else
                                    const Icon(Icons.expand_more),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          state.errorMessage.isNotEmpty
                              ? state.errorMessage
                              : 'Masukkan PIN 4–6 digit karyawan',
                          style: TextStyle(
                            color: state.errorMessage.isNotEmpty
                                ? Colors.orangeAccent
                                : Colors.white70,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _pinLength,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 7),
                              width: 13,
                              height: 13,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: index < _pin.length
                                    ? Colors.white
                                    : Colors.white30,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        _buildKeypadRow(['1', '2', '3']),
                        const SizedBox(height: 10),
                        _buildKeypadRow(['4', '5', '6']),
                        const SizedBox(height: 10),
                        _buildKeypadRow(['7', '8', '9']),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            const SizedBox(width: 64, height: 64),
                            _buildKeypadButton('0'),
                            SizedBox(
                              width: 64,
                              height: 64,
                              child: TextButton(
                                onPressed: _isVerifying ? null : _onDeleteTap,
                                style: TextButton.styleFrom(
                                  shape: const CircleBorder(),
                                  foregroundColor: Colors.white,
                                ),
                                child: const Icon(
                                  Icons.backspace_outlined,
                                  size: 27,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed:
                                state.hasPinConfigured &&
                                    _pin.length >= 4 &&
                                    !_isVerifying
                                ? _verifyPin
                                : null,
                            icon: _isVerifying
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.lock_open),
                            label: const Text('Masuk sebagai Kasir'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 13),
                              backgroundColor: Colors.white,
                              foregroundColor: AppColors.primary,
                              disabledBackgroundColor: Colors.white24,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'PIN dibuat atau direset oleh admin melalui Pengaturan POS.',
                          style: TextStyle(color: Colors.white60, fontSize: 11),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        TextButton.icon(
                          onPressed: _isLoggingOut ? null : _confirmLogout,
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white38,
                          ),
                          icon: _isLoggingOut
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.logout, size: 18),
                          label: const Text('Logout akun'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: keys.map((key) => _buildKeypadButton(key)).toList(),
    );
  }

  Widget _buildKeypadButton(String text) {
    return SizedBox(
      width: 64,
      height: 64,
      child: TextButton(
        onPressed: _isVerifying ? null : () => _onKeypadTap(text),
        style: TextButton.styleFrom(
          shape: const CircleBorder(),
          foregroundColor: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.1),
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}
