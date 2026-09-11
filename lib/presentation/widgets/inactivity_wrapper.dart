import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/lock/lock_cubit.dart';
import '../bloc/lock/lock_state.dart';
import '../pages/common/pin_lock_screen.dart';
import '../../injections.dart';
import '../../domain/repositories/pos_repository.dart';

class InactivityWrapper extends StatefulWidget {
  final Widget child;
  final Duration inactivityDuration;
  final bool authenticated;

  const InactivityWrapper({
    super.key,
    required this.child,
    required this.authenticated,
    this.inactivityDuration = const Duration(
      minutes: 5,
    ), // Auto-lock after 5 mins
  });

  @override
  State<InactivityWrapper> createState() => _InactivityWrapperState();
}

class _InactivityWrapperState extends State<InactivityWrapper>
    with WidgetsBindingObserver {
  Timer? _timer;
  DateTime _lastActivityAt = DateTime.now();
  DateTime? _backgroundedAt;
  // Jangan menerapkan default kebijakan sebelum konfigurasi instansi selesai
  // dimuat. Ini mencegah perpindahan tab saat startup mengunci sesi.
  bool _lockEnabled = false;
  bool _lockOnBackground = false;
  Duration? _configuredDuration;

  Duration get _inactivityDuration =>
      _configuredDuration ?? widget.inactivityDuration;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    if (widget.authenticated) _loadLockPolicy();
  }

  @override
  void didUpdateWidget(covariant InactivityWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authenticated == widget.authenticated) return;
    if (widget.authenticated) {
      _loadLockPolicy();
    } else {
      _timer?.cancel();
      _timer = null;
      context.read<AppLockCubit>().reset();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (!widget.authenticated || !_lockEnabled) return;
    _lastActivityAt = DateTime.now();
    _scheduleDeadline(_inactivityDuration);
  }

  Future<void> _loadLockPolicy() async {
    final config = await sl<PosRepository>().getRuntimeConfig();
    if (!mounted || !widget.authenticated) return;
    final minutes = (config['pos_auto_lock_minutes'] as num?)?.toInt() ?? 5;
    setState(() {
      _lockEnabled = config['pos_lock_enabled'] != false;
      _lockOnBackground = config['pos_lock_on_background'] != false;
      _configuredDuration = Duration(minutes: minutes.clamp(1, 120));
    });
    if (_lockEnabled) {
      _startTimer();
    } else {
      _timer?.cancel();
      context.read<AppLockCubit>().reset();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!widget.authenticated || !_lockEnabled) return;
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      _backgroundedAt ??= DateTime.now();
      return;
    }
    if (state == AppLifecycleState.resumed) {
      final wasBackgrounded = _backgroundedAt != null;
      _backgroundedAt = null;
      final idleFor = DateTime.now().difference(_lastActivityAt);
      // Browser mengirim `hidden` hanya karena pengguna berpindah tab/window.
      // Jangan langsung meminta PIN; kebijakan background tetap menghormati
      // durasi auto-lock yang dipilih pada Pengaturan POS.
      if (_lockOnBackground &&
          wasBackgrounded &&
          idleFor >= _inactivityDuration) {
        context.read<AppLockCubit>().lock();
        return;
      }
      _recordActivity();
    }
  }

  void _scheduleDeadline(Duration delay) {
    _timer?.cancel();
    _timer = Timer(delay, _checkInactivity);
  }

  void _recordActivity() {
    if (!widget.authenticated) return;
    final state = context.read<AppLockCubit>().state;
    if (state.status == AppLockStatus.unlocked) {
      _lastActivityAt = DateTime.now();
      // A single deadline is enough. When it fires, _checkInactivity uses the
      // latest timestamp and reschedules only the remaining idle duration.
      _timer ??= Timer(_inactivityDuration, _checkInactivity);
    }
  }

  bool _handleKeyEvent(KeyEvent event) {
    _recordActivity();
    return false;
  }

  Future<void> _checkInactivity() async {
    _timer = null;
    if (!widget.authenticated || !_lockEnabled || !mounted) return;
    if (context.read<AppLockCubit>().state.status != AppLockStatus.unlocked) {
      return;
    }
    final idleFor = DateTime.now().difference(_lastActivityAt);
    if (idleFor < _inactivityDuration) {
      _scheduleDeadline(_inactivityDuration - idleFor);
      return;
    }
    await context.read<AppLockCubit>().lock();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _recordActivity(),
      onPointerMove: (_) => _recordActivity(),
      onPointerUp: (_) => _recordActivity(),
      onPointerHover: (_) => _recordActivity(),
      onPointerSignal: (_) => _recordActivity(),
      onPointerCancel: (_) => _recordActivity(),
      child: BlocConsumer<AppLockCubit, AppLockState>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          if (state.status == AppLockStatus.unlocked) {
            _startTimer();
          } else if (state.status == AppLockStatus.locked) {
            _timer?.cancel();
          }
        },
        builder: (context, state) {
          final isLocked =
              widget.authenticated && state.status == AppLockStatus.locked;
          return Stack(
            children: [
              widget.child,
              if (isLocked)
                Positioned.fill(
                  child: HeroControllerScope.none(
                    child: Navigator(
                      onGenerateRoute: (_) => MaterialPageRoute<void>(
                        builder: (_) => const PinLockScreen(),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
