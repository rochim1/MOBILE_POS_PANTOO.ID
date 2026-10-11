import 'package:intl/intl.dart';

/// Compact ESC/POS text for 58/80 mm printers. The A4 PDF remains the
/// authoritative document for preview, sharing, and document printers.
class PosPurchaseThermalDocument {
  const PosPurchaseThermalDocument._();

  static String purchaseOrder({
    required Map<String, dynamic> purchase,
    required Map<String, String> company,
    required int charactersPerLine,
  }) {
    final lines = <String>[
      _companyName(company),
      'PURCHASE ORDER',
      _divider(charactersPerLine),
      'No PO: ${_text(purchase['no_po'])}',
      'Tanggal: ${_date(purchase['tanggal_po'])}',
      'Supplier: ${_text(purchase['supplier_name'])}',
      'Status: ${_text(purchase['status']).toUpperCase()}',
      if (_text(purchase['tanggal_pengiriman']).isNotEmpty)
        'Kirim: ${_date(purchase['tanggal_pengiriman'])}',
      if (_text(purchase['alamat_pengiriman']).isNotEmpty)
        'Alamat: ${_text(purchase['alamat_pengiriman'])}',
      _divider(charactersPerLine),
    ];

    final items = (purchase['items'] as List? ?? const []).whereType<Map>();
    var index = 0;
    for (final item in items) {
      index++;
      lines.add('$index. ${_text(item['nama_inventaris'])}');
      if (_text(item['kode_inventaris']).isNotEmpty) {
        lines.add('   ${_text(item['kode_inventaris'])}');
      }
      lines.add(
        '   ${_quantity(item['qty_ordered'])} ${_text(item['unit'])} x ${_money(item['harga_beli'])}',
      );
      lines.add(_amountLine('Subtotal', item['subtotal'], charactersPerLine));
      if (_text(item['catatan_item']).isNotEmpty) {
        lines.add('   Catatan: ${_text(item['catatan_item'])}');
      }
    }
    lines.add(_divider(charactersPerLine));
    lines.add(
      _amountLine('Total item', purchase['total_amount'], charactersPerLine),
    );
    final subtotal = _amount(purchase['total_amount']);
    final discount = purchase['diskon_type'] == 'fixed'
        ? _amount(purchase['diskon_fixed'])
        : subtotal * _amount(purchase['diskon_persen']) / 100;
    if (discount > 0) {
      lines.add(_amountLine('Diskon', -discount, charactersPerLine));
    }
    if (_amount(purchase['ppn_amount']) > 0) {
      lines.add(_amountLine('PPN', purchase['ppn_amount'], charactersPerLine));
    }
    final costs = (purchase['biaya_tambahan'] as List? ?? const [])
        .whereType<Map>()
        .toList();
    if (costs.isNotEmpty) {
      for (final cost in costs) {
        lines.add(
          _amountLine(
            _text(cost['deskripsi']).isNotEmpty
                ? _text(cost['deskripsi'])
                : _text(cost['jenis_biaya']),
            cost['nominal'],
            charactersPerLine,
          ),
        );
      }
    } else if (_amount(purchase['biaya_pengiriman']) > 0) {
      lines.add(
        _amountLine(
          'Ongkos kirim',
          purchase['biaya_pengiriman'],
          charactersPerLine,
        ),
      );
    }
    lines.add(
      _amountLine('GRAND TOTAL', purchase['grand_total'], charactersPerLine),
    );
    if (_text(purchase['syarat_pembayaran']).isNotEmpty) {
      lines.add('Pembayaran: ${_text(purchase['syarat_pembayaran'])}');
    }
    if (_text(purchase['due_date']).isNotEmpty) {
      lines.add('Jatuh tempo: ${_date(purchase['due_date'])}');
    }
    final terms = (purchase['jadwal_termin'] as List? ?? const [])
        .whereType<Map>();
    for (final term in terms) {
      lines.add(
        'Termin ${_text(term['no_termin'])}: ${_money(term['amount'])} / ${_date(term['due_date'])}',
      );
    }
    if (_text(purchase['catatan']).isNotEmpty) {
      lines.add('Catatan: ${_text(purchase['catatan'])}');
    }
    lines.add(_divider(charactersPerLine));
    lines.add('Salinan thermal - PDF memuat detail lengkap.');
    return lines.join('\n');
  }

  static String paymentProof({
    required Map<String, dynamic> payable,
    required Map<String, dynamic> payment,
    required Map<String, String> company,
    required int charactersPerLine,
  }) {
    final status = _text(payment['status']).isEmpty
        ? 'active'
        : _text(payment['status']);
    return [
      _companyName(company),
      'BUKTI PENCATATAN PEMBAYARAN',
      _divider(charactersPerLine),
      'PO: ${_text(payable['no_po'])}',
      'Supplier: ${_text(payable['supplier_name'])}',
      'Tanggal: ${_date(payment['payment_date'])}',
      'Metode: ${_text(payment['payment_method'])}',
      if (_text(payment['reference_number']).isNotEmpty)
        'Referensi: ${_text(payment['reference_number'])}',
      if (payment['no_termin'] != null)
        'Termin: ${_text(payment['no_termin'])}',
      _amountLine('DIBAYAR', payment['amount'], charactersPerLine),
      _amountLine(
        'Sisa tagihan',
        payable['outstanding_amount'],
        charactersPerLine,
      ),
      if (_text(payment['notes']).isNotEmpty)
        'Catatan: ${_text(payment['notes'])}',
      if (status != 'active') 'STATUS: ${status.toUpperCase()}',
      _divider(charactersPerLine),
      'Dicatat oleh pembeli; bukan kuitansi supplier.',
    ].join('\n');
  }

  static String _companyName(Map<String, String> company) {
    for (final name in [company['nama_resmi'], company['nama_instansi']]) {
      if (name?.trim().isNotEmpty == true) return name!.trim();
    }
    return 'PEMBELI';
  }

  static String _text(Object? value) => value?.toString().trim() ?? '';
  static double _amount(Object? value) =>
      value is num ? value.toDouble() : double.tryParse(_text(value)) ?? 0;
  static String _money(Object? value) =>
      'Rp ${NumberFormat.decimalPattern('id_ID').format(_amount(value))}';
  static String _quantity(Object? value) =>
      NumberFormat.decimalPattern('id_ID').format(_amount(value));
  static String _date(Object? value) {
    final raw = _text(value);
    final parsed = DateTime.tryParse(raw);
    return parsed == null
        ? raw
        : DateFormat('dd/MM/yyyy').format(parsed.toLocal());
  }

  static String _divider(int width) => '-' * width;
  static String _amountLine(String label, Object? value, int width) {
    final amount = _money(value);
    final available = width - amount.length - 1;
    if (label.length > available) return '$label\n$amount';
    return '$label${' ' * (width - label.length - amount.length)}$amount';
  }
}
