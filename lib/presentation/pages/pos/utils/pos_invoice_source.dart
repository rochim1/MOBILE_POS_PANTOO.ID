import '../../../../data/graphql/pos_queries.dart';
import '../../../../data/graphql/pos_receivable_queries.dart';
import '../../../../domain/models/pos_order.dart';
import 'pos_customer_invoice_document.dart';

class PosInvoiceSource {
  const PosInvoiceSource._();
  static const pending =
      r'''query InvoicePendingSource($id:ID!){GetOnePOSOrder(_id:$id){
    _id order_no pelanggan_nama pelanggan_telepon pelanggan_id kasir_name
    tipe_pesanan grand_total subtotal diskon_amount pajak_amount catatan
    status status_pembayaran pos_transaction_id createdAt toko{nama_toko}
    items{nama qty unit harga_satuan subtotal}
  }}''';

  static Future<Map<String, dynamic>> load(
    PosOrder order,
    Future<Map<String, dynamic>> Function(String, Map<String, dynamic>) read,
  ) async {
    Future<Map<String, dynamic>> finance(String id) async {
      final data = await read(PosReceivableQueries.printDetail, {'_id': id});
      final invoice = data['GetPOSReceivable'];
      if (invoice is! Map || invoice['_id']?.toString() != id) {
        throw StateError('Invoice tidak sesuai. Muat ulang transaksi.');
      }
      return Map<String, dynamic>.from(invoice);
    }

    if (order.salesInvoiceId?.isNotEmpty == true) {
      return finance(order.salesInvoiceId!);
    }
    if (order.isInvoice) {
      final data = await read(pending, {'id': order.id});
      final raw = data['GetOnePOSOrder'];
      if (raw is! Map || raw['_id']?.toString() != order.id) {
        throw StateError('Pesanan tidak tersedia. Muat ulang transaksi.');
      }
      if (raw['pos_transaction_id'] != null ||
          raw['status_pembayaran'] != 'belum_bayar' ||
          ['Batal', 'Selesai'].contains(raw['status'])) {
        throw StateError(
          'Pesanan sudah berubah atau diproses. Muat ulang transaksi lalu cetak invoice terbaru.',
        );
      }
      return PosCustomerInvoiceDocument.fromOrder(
        PosOrder.fromPendingOrderJson(Map<String, dynamic>.from(raw)),
      );
    }
    final data = await read(PosQueries.getPOSPenjualan, {
      'filter': {'search': order.invoice},
      'pagination': {'page': 0, 'limit': 100},
    });
    final rows = data['GetPOSPenjualan']?['items'] as List? ?? const [];
    final matches = rows.whereType<Map>().where(
      (row) => row['_id']?.toString() == order.id,
    );
    if (matches.length != 1) {
      throw StateError(
        'Transaksi tidak tersedia. Muat ulang sebelum mencetak invoice.',
      );
    }
    final raw = matches.single;
    final id = raw['sales_invoice_id']?.toString() ?? '';
    if (id.isNotEmpty) return finance(id);
    return PosCustomerInvoiceDocument.fromOrder(
      PosOrder.fromJson(Map<String, dynamic>.from(raw)),
    );
  }
}
