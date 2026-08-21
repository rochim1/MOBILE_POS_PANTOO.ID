class PosSettingsQueries {
  static const String getSettings = '''
    query GetInventorySettings {
      GetInventorySettings {
       pos_defaults {
        business_profile
        enabled_features { use_tables use_kitchen_flow use_service_order use_appointments use_technicians use_vehicle_data use_delivery require_customer track_stock }
        pajak_persen
        default_metode_pembayaran
        default_channel_penjualan
        default_tipe_pesanan
        sales_channel_options
        default_price_level
        price_level_options
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
        business_profile
        enabled_features { use_tables use_kitchen_flow use_service_order use_appointments use_technicians use_vehicle_data use_delivery require_customer track_stock }
        pajak_persen
        default_metode_pembayaran
        default_channel_penjualan
        default_tipe_pesanan
        sales_channel_options
        default_price_level
        price_level_options
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
