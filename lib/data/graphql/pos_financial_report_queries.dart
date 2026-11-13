class PosFinancialReportQueries {
  static const options = r'''
    query POSFinancialReportOptions {
      GetPOSFinancialReportOptions { instansi_id scope currency timezone today max_period_days can_export }
    }
  ''';
  static const profitLoss = r'''
    query POSProfitLoss($start: String!, $end: String!, $scope: String!, $export: Boolean, $fingerprint: String) {
      GetPOSProfitLoss(period_start: $start, period_end: $end, scope: $scope, export: $export, expected_fingerprint: $fingerprint) {
        context { instansi_id scope currency }
        period_start period_end generated_at fingerprint
        net_sales cogs gross_profit gross_margin_percent net_profit total_revenue total_expenses
        classification_status cogs_configured source_coverage expenses_verified
        issues { code count }
        sections { key amount accounts { account_code account_name amount } }
      }
    }
  ''';
  static const business = r'''
    query POSBusinessReport($kind: POSBusinessReportKind!, $start: String!, $end: String!, $page: Int, $search: String, $source: String, $export: Boolean, $fingerprint: String) {
      GetPOSBusinessReport(kind: $kind, period_start: $start, period_end: $end, scope: "instansi", page: $page, limit: 20, search: $search, source_scope: $source, export: $export, expected_fingerprint: $fingerprint) {
        kind scope instansi_id currency period_start period_end generated_at source_scope search coverage fingerprint total_count page limit
        metrics { key value unit } columns { key format } rows { id cells { key text number } } notes note_codes
      }
    }
  ''';
  static const ledger = r'''
    query POSProfitLossLedger($code: String!, $start: String!, $end: String!, $page: Int!) {
      GetGeneralLedger(account_code: $code, date_from: $start, date_to: $end, pagination: { page: $page, limit: 20 }) {
        total_count context { instansi_id scope }
        entries { date journal_number reference_number description debit credit }
      }
    }
  ''';
}
