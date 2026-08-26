import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/lock/lock_cubit.dart';
import '../bloc/lock/lock_state.dart';
import '../pages/common/pin_lock_screen.dart';

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

class _InactivityWrapperState extends State<InactivityWrapper> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    if (widget.authenticated) _startTimer();
  }

  @override
  void didUpdateWidget(covariant InactivityWrapper oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.authenticated == widget.authenticated) return;
    if (widget.authenticated) {
      _startTimer();
    } else {
      _timer?.cancel();
      _timer = null;
      context.read<AppLockCubit>().reset();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    if (!widget.authenticated) return;
    _timer = Timer(widget.inactivityDuration, _lockApp);
  }

  void _resetTimer() {
    if (!widget.authenticated) return;
    final state = context.read<AppLockCubit>().state;
    if (state.status == AppLockStatus.unlocked) {
      _startTimer();
    }
  }

  Future<void> _lockApp() async {
    if (!widget.authenticated || !mounted) return;
    await context.read<AppLockCubit>().lock();
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => _resetTimer(),
      onPointerMove: (_) => _resetTimer(),
      onPointerUp: (_) => _resetTimer(),
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
