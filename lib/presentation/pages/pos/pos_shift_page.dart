import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../injections.dart';
import '../../bloc/pos_shift/pos_shift_bloc.dart';
import '../../bloc/pos_shift/pos_shift_state.dart';
import 'widgets/pos_active_shift_tab.dart';
import 'widgets/pos_shift_history_tab.dart';
import '../../../../core/_core.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/pos_full_width_tabs.dart';

class PosShiftPage extends StatelessWidget {
  final GlobalKey? storeTourKey;
  final GlobalKey? formTourKey;
  final GlobalKey? openTourKey;
  const PosShiftPage({
    super.key,
    this.storeTourKey,
    this.formTourKey,
    this.openTourKey,
  });

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
                const PosFullWidthTabBar(
                  tabs: [
                    PosFullWidthTab(
                      icon: Icons.point_of_sale,
                      label: 'Shift Aktif',
                    ),
                    PosFullWidthTab(icon: Icons.history, label: 'Riwayat'),
                  ],
                ),
                Expanded(
                  child: TabBarView(
                    children: [
                      PosActiveShiftTab(
                        storeTourKey: storeTourKey,
                        formTourKey: formTourKey,
                        openTourKey: openTourKey,
                      ),
                      const PosShiftHistoryTab(),
                    ],
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
