import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import '../../bloc/lock/lock_cubit.dart';
import '../../bloc/lock/lock_state.dart';
import '../../bloc/auth/auth_cubit.dart';
import 'package:mobile_pos_pantoo/core/network/sync_service.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import '../../widgets/pos_employee_avatar.dart';
import '../../widgets/pos_keyboard_stable_sheet.dart';
import '../../widgets/pos_customer_display_pairing.dart';
import '../pos/widgets/pos_setup_tour.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _CreatePinDialog extends StatefulWidget {
  const _CreatePinDialog();

  @override
  State<_CreatePinDialog> createState() => _CreatePinDialogState();
}

class _CreatePinDialogState extends State<_CreatePinDialog> {
  final _passwordController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmationController = TextEditingController();
  bool _saving = false;
  String _error = '';

  @override
  void dispose() {
    _passwordController.dispose();
    _pinController.dispose();
    _confirmationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _pinController.text.trim();
    if (_passwordController.text.isEmpty) {
      setState(() => _error = 'Password wajib diisi');
      return;
    }
    if (!RegExp(r'^\d{4,6}$').hasMatch(pin)) {
      setState(() => _error = 'PIN harus 4–6 digit angka');
      return;
    }
    if (pin != _confirmationController.text.trim()) {
      setState(() => _error = 'Konfirmasi PIN tidak sama');
      return;
    }
    setState(() {
      _saving = true;
      _error = '';
    });
    final success = await context.read<AppLockCubit>().createLoginUserPin(
      password: _passwordController.text,
      pin: pin,
    );
    if (!mounted) return;
    if (success) {
      Navigator.pop(context, pin);
      return;
    }
    setState(() {
      _saving = false;
      _error = context.read<AppLockCubit>().state.errorMessage;
    });
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('Buat PIN Kasir'),
    content: SizedBox(
      width: (MediaQuery.sizeOf(context).width - 80).clamp(220.0, 380.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Konfirmasi password akun login, lalu buat PIN kasir 4–6 digit.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _passwordController,
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
            controller: _pinController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'PIN baru',
              prefixIcon: Icon(Icons.pin_outlined),
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _confirmationController,
            obscureText: true,
            keyboardType: TextInputType.number,
            maxLength: 6,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(
              labelText: 'Ulangi PIN',
              prefixIcon: Icon(Icons.verified_user_outlined),
              border: OutlineInputBorder(),
              counterText: '',
            ),
          ),
          if (_error.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              _error,
              style: const TextStyle(color: AppColors.danger, fontSize: 12),
            ),
          ],
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: _saving ? null : () => Navigator.pop(context),
        child: const Text('Batal'),
      ),
      FilledButton.icon(
        onPressed: _saving ? null : _submit,
        icon: _saving
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
  );
}

class _PinLockScreenState extends State<PinLockScreen> {
  String _pin = '';
  final int _pinLength = 6;
  final FocusNode _pinKeyboardFocusNode = FocusNode(debugLabel: 'PIN keypad');
  bool _isVerifying = false;
  bool _isLoggingOut = false;
  Timer? _searchDebounce;
  Timer? _lockoutTimer;
  bool _employeeListFiltered = false;

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_onHardwareKeyEvent);
    // The lock is layered over a dashboard whose text field may still own
    // focus. Give the PIN keypad focus as soon as its route is ready.
    WidgetsBinding.instance.addPostFrameCallback((_) => _focusPinKeyboard());
  }

  bool _onHardwareKeyEvent(KeyEvent event) {
    // Normal focused events are handled by the Focus widget below. This
    // fallback is for a dashboard control retaining focus behind the lock.
    if (_pinKeyboardFocusNode.hasFocus) return false;
    return _onPinKeyEvent(_pinKeyboardFocusNode, event) ==
        KeyEventResult.handled;
  }

  void _focusPinKeyboard() {
    if (mounted && ModalRoute.of(context)?.isCurrent == true) {
      _pinKeyboardFocusNode.requestFocus();
    }
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _lockoutTimer?.cancel();
    HardwareKeyboard.instance.removeHandler(_onHardwareKeyEvent);
    _pinKeyboardFocusNode.dispose();
    super.dispose();
  }

  void _onKeypadTap(String value) {
    final hasPin = context.read<AppLockCubit>().state.hasPinConfigured;
    if (hasPin && !_isVerifying && !_isPinLocked && _pin.length < _pinLength) {
      setState(() {
        _pin += value;
      });
      if (_pin.length == _pinLength) {
        _verifyPin();
      }
    }
  }

  void _onDeleteTap() {
    if (_isVerifying || _isPinLocked) return;
    if (_pin.isNotEmpty) {
      setState(() {
        _pin = _pin.substring(0, _pin.length - 1);
      });
    }
  }

  KeyEventResult _onPinKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    // Keep text editing in PIN-owned fields (for example a PIN setup dialog)
    // intact, while ignoring a dashboard field hidden behind this lock.
    final focusedContext = FocusManager.instance.primaryFocus?.context;
    if (focusedContext?.findAncestorWidgetOfExactType<EditableText>() != null &&
        focusedContext?.findAncestorWidgetOfExactType<PinLockScreen>() !=
            null) {
      return KeyEventResult.ignored;
    }
    if (ModalRoute.of(context)?.isCurrent != true) {
      return KeyEventResult.ignored;
    }

    final digit = switch (event.logicalKey) {
      LogicalKeyboardKey.digit0 || LogicalKeyboardKey.numpad0 => '0',
      LogicalKeyboardKey.digit1 || LogicalKeyboardKey.numpad1 => '1',
      LogicalKeyboardKey.digit2 || LogicalKeyboardKey.numpad2 => '2',
      LogicalKeyboardKey.digit3 || LogicalKeyboardKey.numpad3 => '3',
      LogicalKeyboardKey.digit4 || LogicalKeyboardKey.numpad4 => '4',
      LogicalKeyboardKey.digit5 || LogicalKeyboardKey.numpad5 => '5',
      LogicalKeyboardKey.digit6 || LogicalKeyboardKey.numpad6 => '6',
      LogicalKeyboardKey.digit7 || LogicalKeyboardKey.numpad7 => '7',
      LogicalKeyboardKey.digit8 || LogicalKeyboardKey.numpad8 => '8',
      LogicalKeyboardKey.digit9 || LogicalKeyboardKey.numpad9 => '9',
      _ => null,
    };
    if (digit != null) {
      _onKeypadTap(digit);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.backspace ||
        event.logicalKey == LogicalKeyboardKey.delete) {
      _onDeleteTap();
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.numpadEnter) {
      _verifyPin();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Future<void> _verifyPin() async {
    if (_pin.length < 4 || _isVerifying || _isPinLocked) return;
    setState(() => _isVerifying = true);
    final success = await context.read<AppLockCubit>().unlock(_pin);
    if (!mounted) return;
    if (!success) {
      _syncLockoutTimer();
      setState(() {
        _pin = '';
        _isVerifying = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) => _focusPinKeyboard());
    } else {
      setState(() => _isVerifying = false);
    }
  }

  bool get _isPinLocked {
    final until = context.read<AppLockCubit>().state.lockedUntil;
    return until != null && until.isAfter(DateTime.now());
  }

  int get _lockoutSeconds {
    final until = context.read<AppLockCubit>().state.lockedUntil;
    if (until == null) return 0;
    final milliseconds = until.difference(DateTime.now()).inMilliseconds;
    if (milliseconds <= 0) return 0;
    return (milliseconds / 1000).ceil();
  }

  void _syncLockoutTimer() {
    _lockoutTimer?.cancel();
    if (!_isPinLocked) return;
    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      if (_lockoutSeconds <= 0) {
        timer.cancel();
        context.read<AppLockCubit>().clearExpiredPinLockout();
      }
      setState(() {});
    });
  }

  Future<void> _confirmLogout() async {
    if (_isLoggingOut) return;
    final summary = await sl<SyncService>().getQueueSummary();
    if (!mounted) return;
    final unresolved = (summary['unresolved'] as num?)?.toInt() ?? 0;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: Text(
          unresolved > 0
              ? '$unresolved transaksi penjualan offline belum selesai. Data tetap tersimpan di perangkat, tetapi tidak dapat disinkronkan sampai akun instansi ini login kembali.'
              : 'Sesi kasir dan akun akan ditutup. Anda perlu login kembali untuk menggunakan POS.',
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
    final createdPin = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      animationStyle: AnimationStyle.noAnimation,
      builder: (_) => const _CreatePinDialog(),
    );
    if (createdPin == null || !mounted) return;
    FocusManager.instance.primaryFocus?.unfocus();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
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
        child: PosKeyboardStableSheet(
          heightFactor: 0.68,
          child: Column(
            children: [
              Container(
                width: 36,
                height: 3,
                margin: const EdgeInsets.only(top: 8, bottom: 9),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.badge_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Pilih Kasir',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 7),
                child: SizedBox(
                  height: 40,
                  child: TextField(
                    autofocus: true,
                    style: const TextStyle(fontSize: 13),
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau username…',
                      hintStyle: const TextStyle(fontSize: 13),
                      prefixIcon: const Icon(Icons.search, size: 19),
                      prefixIconConstraints: const BoxConstraints(
                        minWidth: 38,
                        minHeight: 38,
                      ),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 9),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(9),
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
                      padding: EdgeInsets.fromLTRB(
                        8,
                        2,
                        8,
                        12 + MediaQuery.viewInsetsOf(context).bottom,
                      ),
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
                          dense: true,
                          visualDensity: const VisualDensity(
                            horizontal: -2,
                            vertical: -2,
                          ),
                          minTileHeight: 50,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                          ),
                          leading: PosEmployeeAvatar(
                            employee: employee,
                            radius: 17,
                          ),
                          title: Text(
                            _employeeName(employee),
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            employee['username']?.toString() ?? '-',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: canCreatePin
                              ? const Text(
                                  'Buat PIN',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 11,
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
                                  size: 20,
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
    _syncLockoutTimer();
    _searchDebounce?.cancel();
    _searchDebounce = null;
    if (mounted &&
        _employeeListFiltered &&
        cubit.state.status == AppLockStatus.locked) {
      _employeeListFiltered = false;
      await cubit.loadEmployees();
    }
    _focusPinKeyboard();
  }

  @override
  Widget build(BuildContext context) {
    final screen = _buildScreen(context);
    return Focus(
      key: const Key('pin_keyboard_focus'),
      focusNode: _pinKeyboardFocusNode,
      autofocus: true,
      onKeyEvent: _onPinKeyEvent,
      child: screen,
    );
  }

  Widget _buildScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showMarketingPanel = constraints.maxWidth >= 1000;
            return Row(
              children: [
                if (showMarketingPanel)
                  const Expanded(child: _PinMarketingPanel()),
                Expanded(
                  child: ColoredBox(
                    color: Colors.white.withValues(alpha: 0.94),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: 16,
                              right: 16,
                              top: 8,
                              bottom: 8,
                            ),
                            child: Align(
                              alignment: Alignment.center,
                              child: FittedBox(
                                fit: BoxFit.contain,
                                alignment: Alignment.center,
                                child: SizedBox(
                                  key: posPinSetupTourTarget,
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
                                          selectedEmployee?['is_login_user'] ==
                                              true &&
                                          state.hasPinConfigured == false;
                                      final pinLocked =
                                          state.lockedUntil != null &&
                                          state.lockedUntil!.isAfter(
                                            DateTime.now(),
                                          );
                                      final lockoutSeconds = pinLocked
                                          ? ((state.lockedUntil!
                                                            .difference(
                                                              DateTime.now(),
                                                            )
                                                            .inMilliseconds /
                                                        1000)
                                                    .ceil())
                                                .clamp(1, 30)
                                          : 0;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 28,
                                          vertical: 14,
                                        ),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            const Text(
                                              'Akses Kasir',
                                              style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.heading,
                                              ),
                                            ),
                                            const Text(
                                              'Pilih operator dan masukkan PIN untuk melanjutkan',
                                              textAlign: TextAlign.center,
                                              style: TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Material(
                                              key: posPinOperatorTourTarget,
                                              color: AppColors.surfaceSecondary,
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              child: InkWell(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                                onTap: state.loadingEmployees
                                                    ? null
                                                    : _showEmployeePicker,
                                                child: Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 14,
                                                        vertical: 13,
                                                      ),
                                                  child: Row(
                                                    children: [
                                                      PosEmployeeAvatar(
                                                        employee:
                                                            selectedEmployee,
                                                        radius: 15,
                                                      ),
                                                      const SizedBox(width: 12),
                                                      Expanded(
                                                        child: Text(
                                                          _employeeName(
                                                            selectedEmployee,
                                                          ),
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                      if (state
                                                          .loadingEmployees)
                                                        const SizedBox(
                                                          width: 18,
                                                          height: 18,
                                                          child:
                                                              CircularProgressIndicator(
                                                                strokeWidth: 2,
                                                              ),
                                                        )
                                                      else
                                                        const Icon(
                                                          Icons.expand_more,
                                                        ),
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
                                                color:
                                                    state
                                                        .errorMessage
                                                        .isNotEmpty
                                                    ? AppColors.danger
                                                    : AppColors.textSecondary,
                                                fontSize: 13,
                                              ),
                                              textAlign: TextAlign.center,
                                              maxLines: 2,
                                            ),
                                            if (pinLocked) ...[
                                              const SizedBox(height: 8),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors
                                                      .warningBackground,
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  border: Border.all(
                                                    color:
                                                        AppColors.warningBorder,
                                                  ),
                                                ),
                                                child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    const Icon(
                                                      Icons.timer_outlined,
                                                      size: 18,
                                                      color: AppColors.warning,
                                                    ),
                                                    const SizedBox(width: 7),
                                                    Text(
                                                      'Coba lagi dalam $lockoutSeconds detik',
                                                      style: const TextStyle(
                                                        color:
                                                            AppColors.heading,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                            const SizedBox(height: 14),
                                            Row(
                                              key: posPinEntryTourTarget,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: List.generate(
                                                _pinLength,
                                                (index) => Container(
                                                  margin:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 7,
                                                      ),
                                                  width: 13,
                                                  height: 13,
                                                  decoration: BoxDecoration(
                                                    shape: BoxShape.circle,
                                                    color: index < _pin.length
                                                        ? AppColors.primary
                                                        : AppColors.border,
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
                                                const SizedBox(
                                                  width: 64,
                                                  height: 64,
                                                ),
                                                _buildKeypadButton('0'),
                                                SizedBox(
                                                  width: 64,
                                                  height: 64,
                                                  child: TextButton(
                                                    onPressed:
                                                        _isVerifying ||
                                                            pinLocked
                                                        ? null
                                                        : _onDeleteTap,
                                                    style: TextButton.styleFrom(
                                                      shape:
                                                          const CircleBorder(),
                                                      foregroundColor:
                                                          AppColors.body,
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
                                                key: posPinSubmitTourTarget,
                                                onPressed:
                                                    _isVerifying || pinLocked
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
                                                        child:
                                                            CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                            ),
                                                      )
                                                    : Icon(
                                                        canCreateOwnPin
                                                            ? Icons
                                                                  .add_moderator_outlined
                                                            : Icons.lock_open,
                                                      ),
                                                label: Text(
                                                  canCreateOwnPin
                                                      ? 'Buat PIN Akun Ini'
                                                      : 'Masuk sebagai Kasir',
                                                ),
                                                style: ElevatedButton.styleFrom(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        vertical: 13,
                                                      ),
                                                  backgroundColor:
                                                      AppColors.primary,
                                                  foregroundColor: Colors.white,
                                                  disabledBackgroundColor:
                                                      AppColors.neutralBorder,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              canCreateOwnPin
                                                  ? 'PIN akun lain tetap dibuat atau direset oleh admin POS.'
                                                  : 'PIN dapat dibuat sendiri untuk akun login atau dikelola oleh admin POS.',
                                              style: TextStyle(
                                                color: AppColors.textSecondary,
                                                fontSize: 11,
                                              ),
                                              textAlign: TextAlign.center,
                                            ),
                                            const SizedBox(height: 4),
                                            TextButton.icon(
                                              onPressed: () =>
                                                  showPosCustomerDisplayPairing(
                                                    context,
                                                  ),
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    AppColors.primary,
                                              ),
                                              icon: const Icon(
                                                Icons.connected_tv_outlined,
                                                size: 18,
                                              ),
                                              label: const Text(
                                                'Hubungkan layar pelanggan',
                                              ),
                                            ),
                                            TextButton.icon(
                                              onPressed: _isLoggingOut
                                                  ? null
                                                  : _confirmLogout,
                                              style: TextButton.styleFrom(
                                                foregroundColor:
                                                    AppColors.danger,
                                                disabledForegroundColor:
                                                    AppColors.textMuted,
                                              ),
                                              icon: _isLoggingOut
                                                  ? const SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                            color: AppColors
                                                                .danger,
                                                          ),
                                                    )
                                                  : const Icon(
                                                      Icons.logout,
                                                      size: 18,
                                                    ),
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
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
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
        onPressed: _isVerifying || _isPinLocked
            ? null
            : () => _onKeypadTap(text),
        style: TextButton.styleFrom(
          shape: const CircleBorder(),
          foregroundColor: AppColors.heading,
          backgroundColor: AppColors.surfaceSecondary,
        ),
        child: Text(
          text,
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w400),
        ),
      ),
    );
  }
}

class _PinMarketingPanel extends StatelessWidget {
  const _PinMarketingPanel();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/pantoo_brand_ambassador.png'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.7),
              Colors.black.withValues(alpha: 0.28),
            ],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(40, 30, 40, 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 72,
                    height: 64,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.92),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/images/brand_logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pantoo POS',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Kasir cepat, bisnis lebih tertata',
                          style: TextStyle(color: Colors.white70, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              const Text(
                'Satu kasir untuk setiap peluang',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Layani pelanggan, pantau stok, dan kelola penjualan dari satu tempat.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                  shadows: [
                    Shadow(
                      color: Colors.black38,
                      offset: Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
