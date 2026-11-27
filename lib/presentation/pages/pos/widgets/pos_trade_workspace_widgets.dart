import 'package:flutter/material.dart';
import '../../../../core/themes/colors_theme.dart';
import '../../../../domain/models/pos_trade.dart';
import '../../../../l10n/pos_localization.dart';

String tradeUiText(BuildContext context, String id, String en) =>
    posLocale(context).localeName.startsWith('en') ? en : id;

/// Inventory's white surfaces, teal actions and outlined, persistently labelled fields.
class PosTradeTheme extends StatelessWidget {
  const PosTradeTheme({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFD7E0E5)),
    );
    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: AppColors.primary,
          onPrimary: Colors.white,
        ),
        inputDecorationTheme: theme.inputDecorationTheme.copyWith(
          filled: true,
          fillColor: Colors.white,
          isDense: true,
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 16,
          ),
          border: border,
          enabledBorder: border,
          focusedBorder: border.copyWith(
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            foregroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
      child: child,
    );
  }
}

enum TradeNoticeTone { info, warning, error, success }

class PosTradeNotice extends StatelessWidget {
  const PosTradeNotice({
    super.key,
    required this.text,
    this.tone = TradeNoticeTone.info,
    this.action,
  });
  final String text;
  final TradeNoticeTone tone;
  final Widget? action;
  @override
  Widget build(BuildContext context) {
    final (color, background, icon) = switch (tone) {
      TradeNoticeTone.warning => (
        const Color(0xFF8A5700),
        const Color(0xFFFFF7E6),
        Icons.pending_actions_outlined,
      ),
      TradeNoticeTone.error => (
        const Color(0xFFB42318),
        const Color(0xFFFEF3F2),
        Icons.error_outline,
      ),
      TradeNoticeTone.success => (
        AppColors.primary,
        const Color(0xFFEAF6F2),
        Icons.check_circle_outline,
      ),
      TradeNoticeTone.info => (
        const Color(0xFF475467),
        const Color(0xFFEEF5F7),
        Icons.info_outline,
      ),
    };
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: .16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(fontSize: 13, height: 1.5, color: color),
                ),
              ),
            ],
          ),
          if (action != null)
            Padding(padding: const EdgeInsets.only(top: 10), child: action!),
        ],
      ),
    );
  }
}

class PosTradeStatusBadge extends StatelessWidget {
  const PosTradeStatusBadge({
    super.key,
    required this.document,
    required this.overdue,
  });
  final PosTradeDocument document;
  final bool overdue;
  @override
  Widget build(BuildContext context) {
    final color = overdue
        ? const Color(0xFFB42318)
        : document.outstanding <= 0
        ? AppColors.primary
        : const Color(0xFF8A5700);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        overdue
            ? tradeUiText(context, 'Lewat jatuh tempo', 'Overdue')
            : posStatusLabel(document.status, context),
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class PosTradeDocumentTile extends StatelessWidget {
  const PosTradeDocumentTile({
    super.key,
    required this.document,
    required this.amount,
    required this.total,
    required this.dueDate,
    required this.overdue,
    this.onTap,
  });
  final PosTradeDocument document;
  final String amount, total, dueDate;
  final bool overdue;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) {
    final l = posLocale(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFFE1E5E9)),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        document.party,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          height: 1.35,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(
                      Icons.chevron_right,
                      size: 20,
                      color: Color(0xFF667085),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  document.reference.isEmpty
                      ? document.number
                      : document.reference,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF667085),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l.businessOutstanding,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF667085),
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          amount,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF182230),
                          ),
                        ),
                      ],
                    ),
                    PosTradeStatusBadge(document: document, overdue: overdue),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 14,
                  runSpacing: 6,
                  children: [
                    Text(
                      '${l.businessDueDate}: $dueDate',
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: overdue
                            ? const Color(0xFFB42318)
                            : const Color(0xFF667085),
                      ),
                    ),
                    Text(
                      '${l.businessAmount}: $total',
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: Color(0xFF667085),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PosTradeEmptyState extends StatelessWidget {
  const PosTradeEmptyState({super.key, required this.filtered, this.onReset});
  final bool filtered;
  final VoidCallback? onReset;
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xFFE1E5E9)),
    ),
    child: Column(
      children: [
        const Icon(
          Icons.receipt_long_outlined,
          size: 32,
          color: AppColors.primary,
        ),
        const SizedBox(height: 12),
        Text(
          filtered
              ? tradeUiText(
                  context,
                  'Tidak ada tagihan yang cocok',
                  'No matching bills',
                )
              : posLocale(context).businessEmpty,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        const SizedBox(height: 6),
        Text(
          filtered
              ? tradeUiText(
                  context,
                  'Coba kata kunci lain atau atur ulang filter.',
                  'Try another search or reset the filters.',
                )
              : tradeUiText(
                  context,
                  'Tagihan dari transaksi akan tampil di sini. Catat tagihan manual hanya jika belum tercatat di sistem.',
                  'Transaction bills appear here. Record a manual bill only if it is not already in the system.',
                ),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.5,
            color: Color(0xFF667085),
          ),
        ),
        if (filtered && onReset != null)
          TextButton(
            onPressed: onReset,
            child: Text(
              tradeUiText(context, 'Atur ulang filter', 'Reset filters'),
            ),
          ),
      ],
    ),
  );
}

class PosTradeFormHeader extends StatelessWidget {
  const PosTradeFormHeader({super.key, required this.title});
  final String title;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: Color(0xFF182230),
          ),
        ),
      ),
      const SizedBox(width: 8),
      IconButton(
        tooltip: tradeUiText(context, 'Tutup', 'Close'),
        onPressed: () => Navigator.pop(context),
        icon: const Icon(Icons.close),
      ),
    ],
  );
}
