class PosTradeQueries {
  static const fields = r'''
 instansi_id id kind number reference party date due_date amount paid credited withheld outstanding status source basis notes can_pay payment_count
 payments {id date amount method reference status journal_number verified}
 terms {number due_date amount paid outstanding}
 ''';
  static const options = r'''query POSTradeOptions { GetPOSTradeOptions {
 instansi_id today ar_scope view_ar view_ap create_ar create_ap receive_ar pay_ap ap_cash_available ap_cash_name
 ar_accounts {code name} ap_accounts {code name} income_accounts {code name} expense_accounts {code name}
 opening_accounts {code name} cash_accounts {code name} banks {id name account_number} customers {id name address}
 } }''';
  static const list =
      '''query POSTradeList(\$kind:POSTradeKind!,\$search:String,\$page:Int,\$settled:Boolean){GetPOSTradeDocuments(kind:\$kind,search:\$search,page:\$page,include_settled:\$settled){items {$fields} total_count outstanding page limit}}''';
  static const detail =
      '''query POSTradeDetail(\$kind:POSTradeKind!,\$id:ID!){GetPOSTradeDocument(kind:\$kind,id:\$id){$fields}}''';
  static const create =
      '''mutation POSManualTrade(\$input:POSManualTradeInput!){CreatePOSManualTrade(input:\$input){$fields}}''';
  static const pay =
      '''mutation POSTradePay(\$input:POSTradePaymentInput!){PayPOSTradeDocument(input:\$input){$fields}}''';
}
