/// Validated against the server Travel SDL. Generic POS checkout stays blocked.
abstract final class PosTravelQueries {
  static const document = r'''
fragment TravelBookingFields on POSTravelBooking {
  _id toko_id departure_id customer_id customer_name contact_phone pickup_point number status version seats total_amount currency
  paid_amount refunded_amount outstanding_amount payment_status expires_at completed_at
  departure_snapshot { code starts_at booking_closes_at }
  participants { name category uses_seat price }
  package_snapshot { package_id code name terms terms_version hold_minutes }
  payments { _id kind amount method reference reason recorded_at actor_id journal_id shift_id bank_account_id }
  history { action at actor_id reason }
}
query TravelStores($page:Int,$selected_toko_id:ID) { GetPOSTravelStores(page:$page,selected_toko_id:$selected_toko_id) { business_profile permissions { create_booking update_booking manage_master } selected { _id nama_toko status } items { _id nama_toko status } totalCount } }
query TravelCustomers($toko_id:ID!,$search:String!,$page:Int) { SearchPOSTravelCustomers(toko_id:$toko_id,search:$search,page:$page) { items { _id name } totalCount } }
query TravelPackages($input:POSTravelListInput!) { GetPOSTravelPackages(input:$input) { items { _id code name adult_price child_price infant_price infant_uses_seat hold_minutes terms terms_version is_active } totalCount } }
query TravelDepartures($input:POSTravelListInput!) { GetPOSTravelDepartures(input:$input) { items { _id package_id code starts_at booking_closes_at capacity held_seats confirmed_seats available_seats version status } totalCount } }
query TravelBookings($input:POSTravelListInput!) { GetPOSTravelBookings(input:$input) { items { ...TravelBookingFields } totalCount } }
query TravelBooking($toko_id:ID!,$booking_id:ID!) { GetPOSTravelBooking(toko_id:$toko_id,booking_id:$booking_id) { ...TravelBookingFields } }
query TravelPaymentOptions($toko_id:ID!) { GetPOSTravelPaymentOptions(toko_id:$toko_id) { can_pay can_refund can_complete accounts { _id name account_last4 coa_code } } }
mutation TravelDraft($input:POSTravelBookingInput!) { CreatePOSTravelBooking(input:$input) { ...TravelBookingFields } }
mutation TravelHold($input:POSTravelBookingActionInput!) { HoldPOSTravelBooking(input:$input) { ...TravelBookingFields } }
mutation TravelConfirm($input:POSTravelBookingActionInput!) { ConfirmPOSTravelBooking(input:$input) { ...TravelBookingFields } }
mutation TravelCancel($input:POSTravelBookingActionInput!) { CancelPOSTravelBooking(input:$input) { ...TravelBookingFields } }
mutation TravelPayment($input:POSTravelPaymentInput!) { RecordPOSTravelPayment(input:$input) { ...TravelBookingFields } }
mutation TravelRefund($input:POSTravelPaymentInput!) { RefundPOSTravelBooking(input:$input) { ...TravelBookingFields } }
mutation TravelComplete($input:POSTravelBookingActionInput!) { CompletePOSTravelBooking(input:$input) { ...TravelBookingFields } }
mutation TravelRequestResolution($toko_id:ID!,$request_id:String!) { ResolvePOSTravelRequest(toko_id:$toko_id,request_id:$request_id) { status operation entity_id } }
mutation TravelPackage($input:POSTravelPackageInput!) { CreatePOSTravelPackage(input:$input) { _id toko_id code name } }
mutation TravelDeparture($input:POSTravelDepartureInput!) { CreatePOSTravelDeparture(input:$input) { _id toko_id code starts_at } }
''';
  static const writes = {
    'createBooking': 'TravelDraft',
    'hold': 'TravelHold',
    'confirm': 'TravelConfirm',
    'cancel': 'TravelCancel',
    'payment': 'TravelPayment',
    'refund': 'TravelRefund',
    'complete': 'TravelComplete',
    'createPackage': 'TravelPackage',
    'createDeparture': 'TravelDeparture',
  };
  static const fields = {
    'TravelStores': 'GetPOSTravelStores',
    'TravelCustomers': 'SearchPOSTravelCustomers',
    'TravelPackages': 'GetPOSTravelPackages',
    'TravelDepartures': 'GetPOSTravelDepartures',
    'TravelBookings': 'GetPOSTravelBookings',
    'TravelBooking': 'GetPOSTravelBooking',
    'TravelPaymentOptions': 'GetPOSTravelPaymentOptions',
    'TravelDraft': 'CreatePOSTravelBooking',
    'TravelHold': 'HoldPOSTravelBooking',
    'TravelConfirm': 'ConfirmPOSTravelBooking',
    'TravelCancel': 'CancelPOSTravelBooking',
    'TravelPayment': 'RecordPOSTravelPayment',
    'TravelRefund': 'RefundPOSTravelBooking',
    'TravelComplete': 'CompletePOSTravelBooking',
    'TravelPackage': 'CreatePOSTravelPackage',
    'TravelDeparture': 'CreatePOSTravelDeparture',
  };
}
