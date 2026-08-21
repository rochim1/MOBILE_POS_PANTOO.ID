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

  @override
  void dispose() {
    _searchDebounce?.cancel();
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

  Future<void> _createPinForLoginUser() async {
    final passwordController = TextEditingController();
    final pinController = TextEditingController();
    final confirmationController = TextEditingController();
    var saving = false;
    String dialogError = '';
    final createdPin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Buat PIN Kasir'),
          content: SizedBox(
            width: 380,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Konfirmasi password akun login, lalu buat PIN kasir 4–6 digit.',
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  autofocus: true,
                  decoration: const InputDecoration(
                    labelText: 'Password akun',
                    prefixIcon: Icon(Icons.password_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: pinController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'PIN baru',
                    prefixIcon: Icon(Icons.pin_outlined),
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: confirmationController,
                  obscureText: true,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  decoration: const InputDecoration(
                    labelText: 'Ulangi PIN',
                    prefixIcon: Icon(Icons.verified_user_outlined),
                    border: OutlineInputBorder(),
                    counterText: '',
                  ),
                ),
                if (dialogError.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    dialogError,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton.icon(
              onPressed: saving
                  ? null
                  : () async {
                      final pin = pinController.text.trim();
                      if (passwordController.text.isEmpty) {
                        setDialogState(
                          () => dialogError = 'Password wajib diisi',
                        );
                        return;
                      }
                      if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
                        setDialogState(
                          () => dialogError = 'PIN harus 4–6 digit angka',
                        );
                        return;
                      }
                      if (pin != confirmationController.text.trim()) {
                        setDialogState(
                          () => dialogError = 'Konfirmasi PIN tidak sama',
                        );
                        return;
                      }
                      setDialogState(() {
                        saving = true;
                        dialogError = '';
                      });
                      final success = await context
                          .read<AppLockCubit>()
                          .createLoginUserPin(
                            password: passwordController.text,
                            pin: pin,
                          );
                      if (!dialogContext.mounted) return;
                      if (success) {
                        Navigator.pop(dialogContext, pin);
                      } else {
                        setDialogState(() {
                          saving = false;
                          dialogError = context
                              .read<AppLockCubit>()
                              .state
                              .errorMessage;
                        });
                      }
                    },
              icon: saving
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.add_moderator_outlined),
              label: const Text('Buat PIN'),
            ),
          ],
        ),
      ),
    );
    // showDialog menyelesaikan Future saat pop dimulai, sedangkan field masih
    // dipakai selama animasi keluar. Tunggu route benar-benar terlepas sebelum
    // controller dibuang agar AnimatedBuilder tidak memasang listener kembali
    // pada controller yang sudah disposed.
    await Future<void>.delayed(kThemeAnimationDuration);
    passwordController.dispose();
    pinController.dispose();
    confirmationController.dispose();
    if (createdPin == null || !mounted) return;
    setState(() => _pin = createdPin);
    await _verifyPin();
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
                  autofocus: true,
                  decoration: InputDecoration(
                    hintText: 'Cari nama atau username…',
                    prefixIcon: const Icon(Icons.search),
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
                        final selected = id == state.selectedEmployeeId;
                        final canCreatePin =
                            employee['is_login_user'] == true &&
                            employee['has_pin'] != true;
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
                          trailing: canCreatePin
                              ? const Text(
                                  'Buat PIN',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                )
                              : Icon(
                                  selected
                                      ? Icons.check_circle
                                      : Icons.chevron_right,
                                  color: selected
                                      ? AppColors.primary
                                      : Colors.grey,
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
          builder: (context, constraints) => Stack(
            children: [
              Positioned(
                left: 18,
                top: 12,
                child: Image.asset(
                  'assets/images/pantoo.png',
                  height: 34,
                  fit: BoxFit.contain,
                ),
              ),
              Center(
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: SizedBox(
                    width: 420,
                    height: 810,
                    child: BlocBuilder<AppLockCubit, AppLockState>(
                      builder: (context, state) {
                        final selectedEmployee = state.employees
                            .where(
                              (employee) =>
                                  employee['_id']?.toString() ==
                                  state.selectedEmployeeId,
                            )
                            .firstOrNull;
                        final canCreateOwnPin =
                            selectedEmployee?['is_login_user'] == true &&
                            state.hasPinConfigured == false;
                        return Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 28,
                            vertical: 14,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.start,
                            children: [
                              const SizedBox(
                                height: 50,
                                width: double.infinity,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Pantoo POS',
                                          style: TextStyle(
                                            fontSize: 21,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          'Aplikasi Kasir Online',
                                          style: TextStyle(
                                            color: Colors.white70,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Akses Kasir',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const Text(
                                'Pilih operator dan masukkan PIN untuk melanjutkan',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
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
                                            _employeeName(selectedEmployee),
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
                                    : canCreateOwnPin
                                    ? 'Akun login belum memiliki PIN. Buat PIN untuk melanjutkan.'
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
                                    margin: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                    ),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  const SizedBox(width: 64, height: 64),
                                  _buildKeypadButton('0'),
                                  SizedBox(
                                    width: 64,
                                    height: 64,
                                    child: TextButton(
                                      onPressed: _isVerifying
                                          ? null
                                          : _onDeleteTap,
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
                                  onPressed: _isVerifying
                                      ? null
                                      : canCreateOwnPin
                                      ? _createPinForLoginUser
                                      : state.hasPinConfigured &&
                                            _pin.length >= 4
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
                                      : Icon(
                                          canCreateOwnPin
                                              ? Icons.add_moderator_outlined
                                              : Icons.lock_open,
                                        ),
                                  label: Text(
                                    canCreateOwnPin
                                        ? 'Buat PIN Akun Ini'
                                        : 'Masuk sebagai Kasir',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 13,
                                    ),
                                    backgroundColor: Colors.white,
                                    foregroundColor: AppColors.primary,
                                    disabledBackgroundColor: Colors.white24,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                canCreateOwnPin
                                    ? 'PIN akun lain tetap dibuat atau direset oleh admin POS.'
                                    : 'PIN dapat dibuat sendiri untuk akun login atau dikelola oleh admin POS.',
                                style: TextStyle(
                                  color: Colors.white60,
                                  fontSize: 11,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 4),
                              TextButton.icon(
                                onPressed: _isLoggingOut
                                    ? null
                                    : _confirmLogout,
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
                        );
                      },
                    ),
                  ),
                ),
              ),
            ],
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
