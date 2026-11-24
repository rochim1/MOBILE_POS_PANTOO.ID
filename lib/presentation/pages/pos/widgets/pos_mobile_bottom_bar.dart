import 'package:flutter/material.dart';
import 'pos_cashier_entry_button.dart';

/// Keeps every navigation action inside the bar, never over the page content.
class PosMobileBottomBar extends StatelessWidget {
  const PosMobileBottomBar({
    super.key,
    required this.reports,
    required this.catalog,
    required this.transactions,
    required this.more,
    this.onOpenCashier,
  });

  final Widget reports;
  final Widget catalog;
  final Widget transactions;
  final Widget more;
  final VoidCallback? onOpenCashier;

  @override
  Widget build(BuildContext context) => BottomAppBar(
    height: 60,
    padding: EdgeInsets.zero,
    color: Colors.white,
    surfaceTintColor: Colors.transparent,
    shadowColor: Colors.transparent,
    elevation: 0,
    child: Row(
      children: [
        Expanded(child: reports),
        Expanded(child: catalog),
        SizedBox(
          width: 56,
          child: onOpenCashier == null
              ? null
              : Center(
                  child: PosCashierEntryButton(onOpenCashier: onOpenCashier!),
                ),
        ),
        Expanded(child: transactions),
        Expanded(child: more),
      ],
    ),
  );
}
