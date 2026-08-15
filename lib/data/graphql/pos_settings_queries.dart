class PosSettingsQueries {
  static const String getSettings = '''
    query GetInventorySettings {
      GetInventorySettings {
       pos_defaults {
        pajak_persen
        default_metode_pembayaran
        default_channel_penjualan
        default_customer_segment
        default_discount_policy
        invoice_prefix
        auto_print_receipt
        allow_out_of_shift
        allow_kasir_price_edit
        default_catatan
        min_transaksi_tunai
        pembulatan_harga
       }
      }
    }
  ''';

  static const String updateDefaults = '''
    mutation UpdatePOSDefaults(\$input: POSDefaultsInput!) {
      UpdatePOSDefaults(input: \$input) {
       pos_defaults {
        pajak_persen
        default_metode_pembayaran
        default_channel_penjualan
        default_customer_segment
        default_discount_policy
        invoice_prefix
        auto_print_receipt
        allow_out_of_shift
        allow_kasir_price_edit
        default_catatan
        min_transaksi_tunai
        pembulatan_harga
       }
      }
    }
  ''';
}
