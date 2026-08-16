class PosReceiptQueries {
  static const String getReceipt = r'''
    query GetPOSReceiptData {
      GetPOSReceiptData {
       template {
        show_logo
        header_title
        header_subtitle
        header_line3
        header_line4
        show_invoice
        show_tanggal
        show_kasir
        show_toko
        show_pelanggan
        show_channel
        show_segment
        show_promo
        footer_line1
        footer_line2
        footer_line3
        paper_width
        font_size
        custom_css
       }
       instansi {
        nama_instansi
        nama_resmi
        email
        website
        alamat
        telpon_number
        provinsi
        kabupaten
        NPWP
       }
      }
    }
  ''';

  static const String updateReceipt = r'''
    mutation UpdatePOSReceiptTemplate($input: POSReceiptTemplateInput!) {
      UpdatePOSReceiptTemplate(input: $input) {
       pos_receipt_template {
        show_logo
        header_title
        header_subtitle
        header_line3
        header_line4
        show_invoice
        show_tanggal
        show_kasir
        show_toko
        show_pelanggan
        show_channel
        show_segment
        show_promo
        footer_line1
        footer_line2
        footer_line3
        paper_width
        font_size
        custom_css
       }
      }
    }
  ''';
}
