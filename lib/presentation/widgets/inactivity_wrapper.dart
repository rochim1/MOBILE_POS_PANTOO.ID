import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/lock/lock_cubit.dart';
import '../bloc/lock/lock_state.dart';
import '../pages/common/pin_lock_screen.dart';

class InactivityWrapper extends StatefulWidget {
  final Widget child;
  final Duration inactivityDuration;

  const InactivityWrapper({
    super.key,
    required this.child,
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
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer(widget.inactivityDuration, _lockApp);
  }

  void _resetTimer() {
    final state = context.read<AppLockCubit>().state;
    if (state.status == AppLockStatus.unlocked) {
      _startTimer();
    }
  }

  Future<void> _lockApp() async {
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
          final isLocked = state.status == AppLockStatus.locked;
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
