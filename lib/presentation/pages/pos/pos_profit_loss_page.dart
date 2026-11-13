import 'package:dartz/dartz.dart' hide State;
import 'package:mobile_pos_pantoo/core/reports/pos_report_export.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/financial_report_export_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_financial_report.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_financial_report_repository.dart';
import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_financial_report/pos_financial_report_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_metric_card.dart';

class PosProfitLossPage extends StatelessWidget {
  const PosProfitLossPage({super.key, required this.repository});
  final PosFinancialReportRepository repository;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => PosFinancialReportCubit(repository)..initialize(),
    child: const ColoredBox(color: Color(0xFFF7F8FA), child: _ProfitLossView()),
  );
}

class _ProfitLossView extends StatelessWidget {
  const _ProfitLossView();
  String _money(double? value) => value == null
      ? '—'
      : NumberFormat.currency(
          locale: 'id_ID',
          symbol: 'Rp ',
          decimalDigits: 0,
        ).format(value);
  String _date(BuildContext context, String value) => DateFormat.yMMMd(
    Localizations.localeOf(context).toLanguageTag(),
  ).format(reportDate(value));

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<PosFinancialReportCubit, PosFinancialReportState>(
    builder: (context, state) {
      final l = posLocale(context);
      final cubit = context.read<PosFinancialReportCubit>();
      final report = state.report;
      final locale = Localizations.localeOf(context).toLanguageTag();
      return RefreshIndicator(
        onRefresh: cubit.initialize,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l.financialProfitLoss,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF182230),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.financialReportSubtitle,
                        style: const TextStyle(color: Color(0xFF667085)),
                      ),
                    ],
                  ),
                ),
                if (state.options?.canExport == true &&
                    report != null &&
                    report.fingerprint.isNotEmpty)
                  FinancialReportExportButton(
                    enabled: true,
                    isCurrent: () =>
                        !cubit.isClosed &&
                        identical(cubit.state.report, report),
                    load: () async {
                      final result = await cubit.repository.getProfitLoss(
                        report.range,
                        forExport: true,
                        fingerprint: report.fingerprint,
                      );
                      return result.fold((failure) => Left(failure), (data) {
                        if (data.instansiId != report.instansiId ||
                            data.range != report.range ||
                            data.fingerprint != report.fingerprint) {
                          return const Left(AuthFailure());
                        }
                        return Right(
                          PosReportExportDocument.profitLoss(data, l, locale),
                        );
                      });
                    },
                  ),
                IconButton(
                  tooltip: l.financialRefresh,
                  onPressed: state.status == FinancialReportStatus.loading
                      ? null
                      : cubit.initialize,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 18),
            if (state.options != null) ...[
              _notice(
                l.financialScope,
                l.financialScopeNote,
                icon: Icons.business_outlined,
              ),
              const SizedBox(height: 14),
              _filters(context, state),
              const SizedBox(height: 18),
            ],
            if (state.status == FinancialReportStatus.initial ||
                state.status == FinancialReportStatus.loading)
              PosMetricGrid(
                children: List.generate(
                  4,
                  (_) => const PosMetricCardSkeleton(),
                ),
              )
            else if (state.status == FinancialReportStatus.denied)
              _failure(
                context,
                state.failure is AuthFailure
                    ? l.financialSessionChanged
                    : l.financialDenied,
                state.failure is AuthFailure
                    ? l.financialSessionNote
                    : l.financialDeniedNote,
                Icons.lock_outline,
              )
            else if (state.status == FinancialReportStatus.failure)
              _failure(
                context,
                l.financialFailed,
                l.financialFailedNote,
                Icons.cloud_off_outlined,
              )
            else if (report != null) ...[
              _notice(l.financialRecorded, l.financialBasisNote),
              const SizedBox(height: 14),
              PosMetricGrid(
                children: [
                  PosMetricCard(
                    title: l.financialNetSales,
                    value: _money(report.netSales),
                    icon: Icons.payments_outlined,
                    description: report.netSales == null
                        ? l.financialUnavailable
                        : l.financialRecorded,
                  ),
                  PosMetricCard(
                    title: l.financialCogs,
                    value: _money(report.cogs),
                    icon: Icons.inventory_2_outlined,
                    description: report.cogs == null
                        ? l.financialUnavailable
                        : l.financialRecorded,
                  ),
                  PosMetricCard(
                    title: l.financialGrossProfit,
                    value: _money(report.grossProfit),
                    icon: Icons.analytics_outlined,
                    description: report.grossMarginPercent == null
                        ? (report.grossProfit == null
                              ? l.financialUnavailable
                              : l.financialRecorded)
                        : NumberFormat.decimalPercentPattern(
                            locale: Localizations.localeOf(
                              context,
                            ).toLanguageTag(),
                            decimalDigits: 1,
                          ).format(report.grossMarginPercent! / 100),
                  ),
                  PosMetricCard(
                    title: l.financialNetProfit,
                    value: _money(report.netProfit),
                    icon: Icons.balance_outlined,
                    description: report.netProfit == null
                        ? l.financialUnavailable
                        : l.financialRecorded,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                l.financialCostNote,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: Color(0xFF667085),
                ),
              ),
              if (report.issues.isNotEmpty) ...[
                const SizedBox(height: 16),
                _notice(
                  l.financialReview,
                  report.issues
                      .map((issue) => _issue(context, issue))
                      .join('\n'),
                  icon: Icons.info_outline,
                ),
              ],
              const SizedBox(height: 20),
              Text(
                l.financialDetails,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              if (report.sections.every((section) => section.accounts.isEmpty))
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(l.financialNoEntries),
                ),
              for (final section in report.sections.where(
                (section) => section.accounts.isNotEmpty,
              ))
                _section(context, section, report),
              const SizedBox(height: 10),
              _total(l.financialTotalRevenue, _money(report.totalRevenue)),
              _total(l.financialTotalExpenses, _money(report.totalExpenses)),
              const SizedBox(height: 16),
              Text(
                '${l.financialUpdated}: ${DateFormat('dd MMM yyyy, HH:mm', Localizations.localeOf(context).toLanguageTag()).format(report.generatedAt.toUtc().add(const Duration(hours: 7)))} WIB',
                style: const TextStyle(fontSize: 11, color: Color(0xFF667085)),
              ),
            ],
          ],
        ),
      );
    },
  );

  Widget _filters(BuildContext context, PosFinancialReportState state) {
    final l = posLocale(context);
    final options = state.options!;
    final range = state.range;
    final selected = FinancialPeriod.values.firstWhere(
      (period) =>
          period != FinancialPeriod.custom &&
          FinancialReportRange.forPeriod(period, options.today) == range,
      orElse: () => FinancialPeriod.custom,
    );
    final labels = [
      l.financialToday,
      l.financialSevenDays,
      l.financialThisMonth,
      l.financialLastMonth,
      l.financialCustomPeriod,
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InputDecorator(
          decoration: InputDecoration(
            labelText: l.financialPeriod,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<FinancialPeriod>(
              value: selected,
              isExpanded: true,
              isDense: true,
              items: [
                for (final period in FinancialPeriod.values)
                  DropdownMenuItem(
                    value: period,
                    child: Text(labels[period.index]),
                  ),
              ],
              onChanged: (period) async {
                if (period == null) return;
                final cubit = context.read<PosFinancialReportCubit>();
                if (period != FinancialPeriod.custom) {
                  await cubit.load(
                    FinancialReportRange.forPeriod(period, options.today),
                  );
                  return;
                }
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2000),
                  lastDate: reportDate(options.today),
                  initialDateRange: range == null
                      ? null
                      : DateTimeRange(
                          start: reportDate(range.start),
                          end: reportDate(range.end),
                        ),
                );
                if (!context.mounted ||
                    picked == null ||
                    cubit.isClosed ||
                    cubit.state.options != options) {
                  return;
                }
                final requested = FinancialReportRange(
                  reportDateText(picked.start),
                  reportDateText(picked.end),
                );
                if (!requested.validFor(options)) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l.financialInvalidRange)),
                  );
                  return;
                }
                await cubit.load(requested);
              },
            ),
          ),
        ),
        if (range != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              '${_date(context, range.start)} – ${_date(context, range.end)} · WIB',
              style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
            ),
          ),
      ],
    );
  }

  Widget _notice(
    String title,
    String message, {
    IconData icon = Icons.receipt_long_outlined,
  }) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE4E7EC)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: const Color(0xFF667085)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 5),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 12,
                  height: 1.6,
                  color: Color(0xFF667085),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Widget _failure(
    BuildContext context,
    String title,
    String message,
    IconData icon,
  ) => Column(
    children: [
      _notice(title, message, icon: icon),
      const SizedBox(height: 14),
      OutlinedButton(
        onPressed: context.read<PosFinancialReportCubit>().initialize,
        child: Text(posLocale(context).financialRetry),
      ),
    ],
  );
  Widget _total(String label, String amount) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      spacing: 16,
      runSpacing: 4,
      children: [
        Text(label),
        Text(amount, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    ),
  );
  String _sectionLabel(BuildContext context, String key) {
    final l = posLocale(context);
    return switch (key) {
      'net_sales' => l.financialNetSales,
      'cogs' => l.financialCogs,
      'operating_expenses' => l.financialOperatingExpenses,
      'other_revenue' => l.financialOtherRevenue,
      'other_expenses' => l.financialOtherExpenses,
      'unclassified_revenue' => l.financialUnclassifiedRevenue,
      _ => l.financialUnclassifiedExpenses,
    };
  }

  Widget _section(
    BuildContext context,
    FinancialReportSection section,
    PosProfitLossReport report,
  ) => Card(
    elevation: 0,
    color: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: const BorderSide(color: Color(0xFFE4E7EC)),
    ),
    margin: const EdgeInsets.only(bottom: 10),
    child: ExpansionTile(
      title: Text(
        _sectionLabel(context, section.key),
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      subtitle: Text(_money(section.amount)),
      children: [
        for (final account in section.accounts)
          ExpansionTile(
            key: ValueKey(
              '${report.instansiId}:${report.range}:${account.code}',
            ),
            title: Text(
              '${account.code} · ${account.name}',
              style: const TextStyle(fontSize: 13),
            ),
            subtitle: Text(_money(account.amount)),
            children: [
              FinancialAccountEntries(
                repository: context.read<PosFinancialReportCubit>().repository,
                code: account.code,
                instansiId: report.instansiId,
                range: report.range,
              ),
            ],
          ),
      ],
    ),
  );
  String _issue(BuildContext context, FinancialReportIssue issue) {
    final l = posLocale(context);
    final label = switch (issue.code) {
      'cogs_not_configured' => l.financialMissingCogs,
      'unclassified_accounts' || 'missing_account' => l.financialMissingMapping,
      'header_posting' => l.financialHeaderPosting,
      'pos_sales_not_posted' => l.financialUnpostedSales,
      'pos_returns_not_posted' => l.financialUnpostedReturns,
      'pos_cogs_not_posted' => l.financialUnpostedCogs,
      'pos_cogs_amount_mismatch' => l.financialCogsMismatch,
      'draft_journals' => l.financialDraftJournals,
      _ => l.financialUnknownIssue,
    };
    return '• $label (${issue.count})';
  }
}

/// Inline drill-down is disposed with its report when the operator or tenant changes.
class FinancialAccountEntries extends StatefulWidget {
  const FinancialAccountEntries({
    super.key,
    required this.repository,
    required this.code,
    required this.instansiId,
    required this.range,
  });
  final PosFinancialReportRepository repository;
  final String code, instansiId;
  final FinancialReportRange range;
  @override
  State<FinancialAccountEntries> createState() =>
      _FinancialAccountEntriesState();
}

class _FinancialAccountEntriesState extends State<FinancialAccountEntries> {
  FinancialLedgerPage? _data;
  Failure? _failure;
  bool _loading = true;
  int _page = 1, _request = 0;
  @override
  void initState() {
    super.initState();
    _load(1);
  }

  Future<void> _load(int page) async {
    final ticket = ++_request;
    setState(() {
      _loading = true;
      _data = null;
      _failure = null;
    });
    final result = await widget.repository.getAccountEntries(
      code: widget.code,
      range: widget.range,
      instansiId: widget.instansiId,
      page: page,
    );
    if (!mounted || ticket != _request) return;
    setState(() {
      _loading = false;
      result.fold((failure) => _failure = failure, (data) {
        _data = data;
        _page = page;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = posLocale(context);
    final money = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    );
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l.financialLedger,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_failure != null) ...[
            Text(
              _failure is FinancialReportAccessFailure ||
                      _failure is AuthFailure
                  ? l.financialLedgerDenied
                  : l.financialFailedNote,
            ),
            TextButton(
              onPressed: () => _load(_page),
              child: Text(l.financialRetry),
            ),
          ] else if (_data case final data?) ...[
            if (data.entries.isEmpty) Text(l.financialNoEntries),
            for (final entry in data.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.number,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    Text(
                      '${DateFormat.yMMMd(Localizations.localeOf(context).toLanguageTag()).format(entry.date.toUtc().add(const Duration(hours: 7)))} · ${entry.reference}',
                      style: const TextStyle(fontSize: 11),
                    ),
                    if (entry.description.isNotEmpty)
                      Text(
                        entry.description,
                        style: const TextStyle(fontSize: 12),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      '${l.financialDebit}: ${money.format(entry.debit)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      '${l.financialCredit}: ${money.format(entry.credit)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ),
            Wrap(
              spacing: 10,
              children: [
                TextButton(
                  onPressed: _page > 1 ? () => _load(_page - 1) : null,
                  child: Text(l.financialPrevious),
                ),
                TextButton(
                  onPressed: _page * 20 < data.total
                      ? () => _load(_page + 1)
                      : null,
                  child: Text(l.financialNext),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
