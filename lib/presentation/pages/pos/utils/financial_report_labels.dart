import 'package:intl/intl.dart';
import 'package:mobile_pos_pantoo/l10n/generated/app_localizations.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_business_report.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_financial_report.dart';

String businessReportLabel(AppLocalizations l, String key) =>
    {
      'cash_flow': l.businessCashFlow,
      'receivables': l.businessReceivables,
      'payables': l.businessPayables,
      'inventory': l.businessInventory,
      'movement': l.businessMovement,
      'restock': l.businessRestock,
      'opening_cash': l.businessOpeningCash,
      'cash_in': l.businessCashIn,
      'cash_out': l.businessCashOut,
      'closing_cash': l.businessClosingCash,
      'net_cash_change': l.businessCashChange,
      'reconciliation_difference': l.businessCashReconciliation,
      'outstanding': l.businessOutstanding,
      'overdue': l.businessOverdue,
      'not_due': l.businessNotDue,
      'unknown_due': l.businessUnknownDue,
      'open_documents': l.businessOpenDocuments,
      'excluded_documents': l.businessExcludedDocuments,
      'stock_value': l.businessStockValue,
      'stock_book_value': l.businessBookValue,
      'stock_difference': l.businessDifference,
      'evidenced_products': l.businessProductsEvidence,
      'opening_stock_value': l.businessOpeningStockValue,
      'closing_stock_value': l.businessClosingStockValue,
      'stock_value_change': l.businessStockValueChange,
      'stock_products': l.businessStockProducts,
      'low_stock': l.businessLowStock,
      'out_of_stock': l.businessOutOfStock,
      'reorder_products': l.businessReorderProducts,
      'reference': l.businessReference,
      'party': l.businessParty,
      'date': l.businessDate,
      'due_date': l.businessDueDate,
      'bucket': l.businessBucket,
      'amount': l.businessAmount,
      'paid': l.businessPaid,
      'credited': l.businessCredited,
      'withheld': l.businessWithheld,
      'name': l.businessName,
      'account': l.businessAccount,
      'quantity': l.businessQuantity,
      'value': l.businessValue,
      'status': l.businessStatus,
      'unit': l.businessUnit,
      'minimum': l.businessMinimum,
      'reorder': l.businessReorder,
      'opening_quantity': l.businessOpeningQuantity,
      'incoming': l.businessIncoming,
      'outgoing': l.businessOutgoing,
      'adjustment': l.businessAdjustment,
      'other_movement': l.businessOtherMovement,
      'closing_quantity': l.businessClosingQuantity,
      'opening_value': l.businessOpeningStockValue,
      'closing_value': l.businessClosingStockValue,
      'description': l.businessDescription,
      'activity': l.businessActivity,
      'operating': l.businessOperating,
      'investing': l.businessInvesting,
      'financing': l.businessFinancing,
      'unclassified': l.businessUnclassified,
      'current': l.businessCurrent,
      '0_30': l.businessDays30,
      '31_60': l.businessDays60,
      '61_90': l.businessDays90,
      '90_plus': l.businessDaysMore90,
      'pass': l.businessComplete,
      'complete': l.businessComplete,
      'partial': l.businessPartial,
      'unknown': l.businessUnknown,
      'discrepancy': l.businessDiscrepancy,
      'cash_accounts_missing': l.businessCashMissing,
      'cash_gross_ambiguous': l.businessGrossAmbiguous,
      'aging_cutoff': l.businessAgingBasis,
      'aging_exclusions': l.businessAgingExclusions,
      'pos_invoices_only': l.businessPosOnly,
      'trade_receivables_all': l.businessTradeAR,
      'trade_payables_all': l.businessTradeAP,
      'inventory_historical': l.businessHistoricalStock,
      'stock_evidence_missing': l.businessStockMissing,
      'stock_movement_basis': l.businessMovementBasis,
      'stock_movement_missing': l.businessMovementMissing,
      'restock_live_only': l.businessRestockLive,
    }[key] ??
    l.businessDetails;
String businessReportNumber(double? number, String unit, String locale) {
  if (number == null) return '—';
  if (unit == 'money') {
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }
  final formatter = NumberFormat.decimalPattern(locale)
    ..maximumFractionDigits = 6;
  return formatter.format(number);
}

String businessReportCell(
  AppLocalizations l,
  PosBusinessColumn column,
  PosBusinessCell cell,
  String locale,
) {
  if (['money', 'number'].contains(column.format)) {
    return businessReportNumber(cell.number, column.format, locale);
  }
  if (cell.text == null || cell.text!.isEmpty) return '—';
  if (column.format == 'label') return businessReportLabel(l, cell.text!);
  if (column.format == 'date') {
    try {
      return DateFormat.yMMMd(locale).format(reportDate(cell.text!));
    } on FormatException {
      return cell.text!;
    }
  }
  return cell.text!;
}

String profitLossIssueLabel(AppLocalizations l, FinancialReportIssue issue) {
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
  return '$label (${issue.count})';
}
