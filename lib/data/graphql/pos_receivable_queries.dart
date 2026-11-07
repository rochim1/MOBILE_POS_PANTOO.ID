class PosReceivableQueries {
  static const fields = r'''
    _id invoice_number customer_name invoice_date due_date status total_amount
    paid_amount credited_amount outstanding_amount source_context { receipt_number store_name }
    payments { _id date amount payment_method reference status reversal_reason }
  ''';
  static const list =
      '''query POSReceivables(\$search: String, \$page: Int, \$include_settled: Boolean) {
    GetPOSReceivables(search: \$search, page: \$page, limit: 20, include_settled: \$include_settled) {
      totalCount items { $fields } summary { outstanding_amount }
    }
  }''';
  static const detail =
      '''query POSReceivable(\$_id: ID!) { GetPOSReceivable(_id: \$_id) { $fields } }''';
  static const options = r'''query POSReceiptOptions { GetSalesInvoiceOptions {
    cash_accounts { code name } banks { _id name account_number coa_code }
  } }''';
  static const payment =
      '''mutation POSCollect(\$input: SalesInvoicePaymentInput!) {
    RecordPOSReceivablePayment(input: \$input) { $fields }
  }''';
}
