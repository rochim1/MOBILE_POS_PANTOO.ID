import 'package:mobile_pos_pantoo/injections.dart';
import '../../widgets/pos_collapsible_filters.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_inventory_repository.dart';
import 'pos_receivables_page.dart';
import 'pos_purchase_payable_page.dart';
import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/reports/pos_report_export.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_business_report.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_financial_report.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_financial_report_repository.dart';
import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_financial_report/pos_business_report_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/bloc/pos_financial_report/pos_financial_report_cubit.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_metric_card.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/financial_report_export_button.dart';
import 'utils/financial_report_labels.dart';

class PosBusinessReportPage extends StatelessWidget {
  const PosBusinessReportPage({
    super.key,
    required this.repository,
    required this.initialKind,
  });
  final PosFinancialReportRepository repository;
  final PosBusinessReportKind initialKind;
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) =>
        PosBusinessReportCubit(repository, initialKind)..initialize(),
    child: ColoredBox(
      color: const Color(0xFFF7F8FA),
      child: _BusinessView(initialKind: initialKind),
    ),
  );
}

class _BusinessView extends StatefulWidget {
  const _BusinessView({required this.initialKind});
  final PosBusinessReportKind initialKind;
  @override
  State<_BusinessView> createState() => _BusinessViewState();
}

class _BusinessViewState extends State<_BusinessView> {
  final _search = TextEditingController();
  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String get _locale => Localizations.localeOf(context).toLanguageTag();
  String _date(String text) =>
      DateFormat.yMMMd(_locale).format(reportDate(text));
  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<PosBusinessReportCubit, PosBusinessReportState>(
    builder: (context, state) {
      final l = posLocale(context),
          cubit = context.read<PosBusinessReportCubit>(),
          report = state.report;
      final locale = _locale;
      final kind = state.filter?.kind ?? widget.initialKind;
      final tabs = widget.initialKind == PosBusinessReportKind.cashFlow
          ? <PosBusinessReportKind>[]
          : [
              PosBusinessReportKind.receivables,
              PosBusinessReportKind.payables,
            ].contains(widget.initialKind)
          ? [PosBusinessReportKind.receivables, PosBusinessReportKind.payables]
          : [
              PosBusinessReportKind.inventory,
              PosBusinessReportKind.movement,
              PosBusinessReportKind.restock,
            ];
      return RefreshIndicator(
        onRefresh: cubit.initialize,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    businessReportLabel(l, kind.code),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF182230),
                    ),
                  ),
                ),
                if (state.options?.canExport == true && report != null)
                  FinancialReportExportButton(
                    enabled: true,
                    isCurrent: () =>
                        mounted && identical(cubit.state.report, report),
                    load: () async {
                      final result = await cubit.repository.getBusinessReport(
                        report.filter,
                        forExport: true,
                        fingerprint: report.fingerprint,
                      );
                      return result.fold((failure) => Left(failure), (data) {
                        if (data.instansiId != report.instansiId ||
                            data.filter != report.filter ||
                            data.fingerprint != report.fingerprint ||
                            data.rows.length != data.totalCount) {
                          return const Left(AuthFailure());
                        }
                        return Right(
                          PosReportExportDocument.business(data, l, locale),
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
            const SizedBox(height: 14),
            if (tabs.isNotEmpty)
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final tab in tabs)
                    ChoiceChip(
                      label: Text(businessReportLabel(l, tab.code)),
                      selected: tab == kind,
                      onSelected: state.options == null
                          ? null
                          : (_) {
                              _search.clear();
                              cubit.changeKind(tab);
                            },
                    ),
                ],
              ),
            if (state.options != null) ...[
              const SizedBox(height: 14),
              _note(l.financialScope, l.financialScopeNote),
              const SizedBox(height: 14),
              PosCollapsibleFilters(
                toggleKey: const Key('business_report_filter_toggle'),
                activeCount: [
                  state.filter!.search.isNotEmpty,
                  state.filter!.sourceScope != 'all',
                ].where((active) => active).length,
                child: _filters(context, state),
              ),
              const SizedBox(height: 16),
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
              _error(l.financialDenied, l.businessDenied, cubit.initialize)
            else if (state.status == FinancialReportStatus.failure)
              _error(l.financialFailed, l.financialFailedNote, cubit.initialize)
            else if (report != null) ...[
              _note(
                businessReportLabel(l, report.coverage),
                report.noteCodes
                    .map((code) => businessReportLabel(l, code))
                    .join('\n'),
              ),
              const SizedBox(height: 14),
              PosMetricGrid(
                children: report.metrics
                    .map(
                      (metric) => PosMetricCard(
                        title: businessReportLabel(l, metric.key),
                        value: businessReportNumber(
                          metric.value,
                          metric.unit,
                          _locale,
                        ),
                        icon: metric.unit == 'money'
                            ? Icons.account_balance_wallet_outlined
                            : Icons.bar_chart_outlined,
                        description: metric.value == null
                            ? l.financialUnavailable
                            : businessReportLabel(l, report.coverage),
                      ),
                    )
                    .toList(),
              ),
              if (report.notes.isNotEmpty)
                Card(
                  elevation: 0,
                  child: ExpansionTile(
                    title: Text(l.businessSourceNotes),
                    children: [
                      for (final note in report.notes)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              note,
                              style: const TextStyle(fontSize: 12, height: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              Text(
                l.businessDetails,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              if (report.rows.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Text(l.businessEmpty),
                ),
              for (final row in report.rows)
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE4E7EC)),
                  ),
                  child: ExpansionTile(
                    key: ValueKey('${report.fingerprint}:${row.id}'),
                    title: Text(
                      row.cell('reference').text ?? row.cell('name').text ?? '',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      [
                        row.cell('party').text ??
                            row.cell('name').text ??
                            row.cell('description').text ??
                            '',
                        for (final key in [
                          report.filter.kind ==
                                      PosBusinessReportKind.receivables ||
                                  report.filter.kind ==
                                      PosBusinessReportKind.payables
                              ? 'outstanding'
                              : report.filter.kind ==
                                    PosBusinessReportKind.inventory
                              ? 'value'
                              : report.filter.kind ==
                                    PosBusinessReportKind.movement
                              ? 'closing_quantity'
                              : report.filter.kind ==
                                    PosBusinessReportKind.restock
                              ? 'quantity'
                              : 'amount',
                        ])
                          '${businessReportLabel(l, key)}: ${businessReportNumber(row.cell(key).number, key == 'quantity' || key == 'closing_quantity' ? 'number' : 'money', locale)}',
                      ].where((text) => text.isNotEmpty).join('\n'),
                      style: const TextStyle(height: 1.5),
                    ),
                    children: [
                      if (row.cell('pos_invoice_id').text != null ||
                          row.cell('purchase_id').text != null)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () => _openSource(report, row),
                            icon: const Icon(Icons.open_in_new, size: 16),
                            label: Text(l.businessOpenSource),
                          ),
                        ),
                      for (final column in report.columns)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              '${businessReportLabel(l, column.key)}: ${businessReportCell(l, column, row.cell(column.key), _locale)}',
                              style: const TextStyle(fontSize: 12, height: 1.5),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    '${l.businessPage} ${report.page} · ${report.totalCount} ${l.businessRows}',
                  ),
                  TextButton(
                    onPressed: report.page > 1
                        ? () => cubit.load(report.filter, page: report.page - 1)
                        : null,
                    child: Text(l.financialPrevious),
                  ),
                  TextButton(
                    onPressed: report.page * report.limit < report.totalCount
                        ? () => cubit.load(report.filter, page: report.page + 1)
                        : null,
                    child: Text(l.financialNext),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '${l.financialUpdated}: ${DateFormat('dd MMM yyyy, HH:mm', _locale).format(report.generatedAt.toUtc().add(const Duration(hours: 7)))} WIB',
                style: const TextStyle(fontSize: 11, color: Color(0xFF667085)),
              ),
              if (state.options?.canExport == true)
                Text(
                  l.businessExportAllRows,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Color(0xFF667085),
                  ),
                ),
            ],
          ],
        ),
      );
    },
  );
  Future<void> _openSource(PosBusinessReport report, PosBusinessRow row) async {
    final cubit = context.read<PosBusinessReportCubit>();
    final l = posLocale(context);
    final invoice = row.cell('pos_invoice_id').text;
    if (invoice != null) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PosReceivablesPage(
            canCollect: false,
            operatorId: 'financial-report:${report.instansiId}',
            initialInvoiceId: invoice,
          ),
        ),
      );
      return;
    }
    final purchase = row.cell('purchase_id').text;
    if (purchase == null) return;
    final result = await sl<PosInventoryRepository>().getPurchaseForPrint(
      purchase,
    );
    if (!mounted || cubit.isClosed || !identical(cubit.state.report, report)) {
      return;
    }
    result.fold(
      (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.businessSourceFailed))),
      (data) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => PosPurchasePayablePage(purchase: data),
          ),
        );
      },
    );
  }

  Widget _filters(BuildContext context, PosBusinessReportState state) {
    final l = posLocale(context),
        cubit = context.read<PosBusinessReportCubit>(),
        options = state.options!,
        filter = state.filter!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (filter.kind == PosBusinessReportKind.restock)
          Text('${l.businessCutoff}: ${_date(options.today)} · WIB')
        else if (filter.kind.cutoff)
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text('${l.businessCutoff}: ${_date(filter.range.end)}'),
            onPressed: () async {
              final picked = await showDatePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: reportDate(options.today),
                initialDate: reportDate(filter.range.end),
              );
              if (!context.mounted ||
                  picked == null ||
                  cubit.isClosed ||
                  cubit.state.options != options) {
                return;
              }
              final day = reportDateText(picked);
              await cubit.load(
                filter.copyWith(range: FinancialReportRange(day, day)),
              );
            },
          )
        else ...[
          DropdownButtonFormField<FinancialPeriod>(
            key: ValueKey(filter.range),
            initialValue: FinancialPeriod.values.firstWhere(
              (period) =>
                  period != FinancialPeriod.custom &&
                  FinancialReportRange.forPeriod(period, options.today) ==
                      filter.range,
              orElse: () => FinancialPeriod.custom,
            ),
            decoration: InputDecoration(
              labelText: l.businessRange,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            isExpanded: true,
            items: [
              for (final period in FinancialPeriod.values)
                DropdownMenuItem(
                  value: period,
                  child: Text(
                    [
                      l.financialToday,
                      l.financialSevenDays,
                      l.financialThisMonth,
                      l.financialLastMonth,
                      l.financialCustomPeriod,
                    ][period.index],
                  ),
                ),
            ],
            onChanged: (period) async {
              if (period == null) return;
              if (period != FinancialPeriod.custom) {
                await cubit.load(
                  filter.copyWith(
                    range: FinancialReportRange.forPeriod(
                      period,
                      options.today,
                    ),
                  ),
                );
                return;
              }
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2000),
                lastDate: reportDate(options.today),
                initialDateRange: DateTimeRange(
                  start: reportDate(filter.range.start),
                  end: reportDate(filter.range.end),
                ),
              );
              if (!context.mounted ||
                  picked == null ||
                  cubit.isClosed ||
                  cubit.state.options != options) {
                return;
              }
              final range = FinancialReportRange(
                reportDateText(picked.start),
                reportDateText(picked.end),
              );
              if (!range.validFor(options)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l.financialInvalidRange)),
                );
                return;
              }
              await cubit.load(filter.copyWith(range: range));
            },
          ),
          const SizedBox(height: 6),
          Text(
            '${_date(filter.range.start)} – ${_date(filter.range.end)} · WIB',
            style: const TextStyle(fontSize: 12, color: Color(0xFF667085)),
          ),
        ],
        if (filter.kind == PosBusinessReportKind.receivables) ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('source:${filter.sourceScope}'),
            initialValue: filter.sourceScope,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: l.businessSources,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            items: [
              DropdownMenuItem(value: 'all', child: Text(l.businessAllSources)),
              DropdownMenuItem(value: 'pos', child: Text(l.businessPosSources)),
            ],
            onChanged: (source) {
              if (source != null) {
                cubit.load(filter.copyWith(sourceScope: source));
              }
            },
          ),
        ],
        if (filter.kind.searchable) ...[
          const SizedBox(height: 12),
          TextField(
            controller: _search,
            decoration: InputDecoration(
              labelText: l.businessSearch,
              suffixIcon: IconButton(
                tooltip: l.businessSearch,
                icon: const Icon(Icons.search),
                onPressed: () =>
                    cubit.load(filter.copyWith(search: _search.text.trim())),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onSubmitted: (value) =>
                cubit.load(filter.copyWith(search: value.trim())),
          ),
        ],
      ],
    );
  }

  Widget _note(String title, String message) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE4E7EC)),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        if (message.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              fontSize: 12,
              height: 1.6,
              color: Color(0xFF667085),
            ),
          ),
        ],
      ],
    ),
  );
  Widget _error(String title, String note, Future<void> Function() retry) =>
      Column(
        children: [
          _note(title, note),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: retry,
            child: Text(posLocale(context).financialRetry),
          ),
        ],
      );
}
