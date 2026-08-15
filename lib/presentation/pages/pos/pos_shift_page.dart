import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injections.dart';
import '../../bloc/pos_shift/pos_shift_bloc.dart';
import '../../bloc/pos_shift/pos_shift_state.dart';
import 'widgets/pos_active_shift_tab.dart';
import 'widgets/pos_shift_history_tab.dart';
import '../../../../core/_core.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/pos_ui.dart';

class PosShiftPage extends StatelessWidget {
  const PosShiftPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<PosShiftBloc>(),
      child: DefaultTabController(
        length: 2,
        child: BlocListener<PosShiftBloc, PosShiftState>(
          listener: (context, state) {
            if (state is PosShiftActionSuccess) {
              AppToast.success(context, state.message);
            } else if (state is PosShiftError) {
              AppToast.error(context, state.message);
            }
          },
          child: Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              title: const PosAppBarTitle(
                title: 'Shift Kasir',
                subtitle: 'Kelola kas kerja harian',
              ),
              bottom: TabBar(
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white70,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(12),
                  ),
                ),
                tabs: const [
                  Tab(icon: Icon(Icons.point_of_sale, size: 19), text: 'Aktif'),
                  Tab(icon: Icon(Icons.history, size: 19), text: 'Riwayat'),
                ],
              ),
            ),
            backgroundColor: AppColors.bgPrimary,
            body: const TabBarView(
              children: [PosActiveShiftTab(), PosShiftHistoryTab()],
            ),
          ),
        ),
      ),
    );
  }
}
