import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injections.dart';
import '../../bloc/pos_shift/pos_shift_bloc.dart';
import '../../bloc/pos_shift/pos_shift_state.dart';
import 'widgets/pos_active_shift_tab.dart';
import 'widgets/pos_shift_history_tab.dart';
import '../../../../core/_core.dart';
import '../../widgets/app_toast.dart';

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
          child: ColoredBox(
            color: AppColors.bgPrimary,
            child: Column(
              children: [
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                  child: const TabBar(
                    labelColor: AppColors.primary,
                    unselectedLabelColor: Colors.black54,
                    indicatorColor: AppColors.primary,
                    indicatorSize: TabBarIndicatorSize.tab,
                    tabs: [
                      Tab(
                        icon: Icon(Icons.point_of_sale, size: 19),
                        text: 'Aktif',
                      ),
                      Tab(icon: Icon(Icons.history, size: 19), text: 'Riwayat'),
                    ],
                  ),
                ),
                const Expanded(
                  child: TabBarView(
                    children: [PosActiveShiftTab(), PosShiftHistoryTab()],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
