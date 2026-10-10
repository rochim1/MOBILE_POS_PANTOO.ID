import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:printing/printing.dart';

import '../../../../injections.dart';
import '../../../domain/repositories/pos_inventory_repository.dart';
import '../../../domain/repositories/pos_receipt_repository.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/inventory_action_style.dart';
import '../../widgets/skeleton_loading.dart';
import 'utils/pos_purchase_payment_proof_document.dart';

class PosPurchasePayablePage extends StatefulWidget {
  final Map<String, dynamic> purchase;
  final bool canRecordPayment;
  final bool embedded;
  final VoidCallback? onFinished;

  const PosPurchasePayablePage({
    super.key,
    required this.purchase,
    this.canRecordPayment = false,
    this.embedded = false,
    this.onFinished,
  });

  @override
  State<PosPurchasePayablePage> createState() => _PosPurchasePayablePageState();
}

class _PosPurchasePayablePageState extends State<PosPurchasePayablePage> {
  final _repository = sl<PosInventoryRepository>();
  final _amountController = TextEditingController();
  final _referenceController = TextEditingController();
  final _notesController = TextEditingController();
  Map<String, dynamic>? _payable;
  List<Map<String, dynamic>> _banks = const [];
  bool _loading = true;
  bool _saving = false;
  bool _paymentDataStale = false;
  String? _proofLoadingId;
  bool _bankAccountsAvailable = true;
  String? _bankLoadError;
  String _method = 'transfer';
  String _bankId = '';
  String _paymentDate = DateTime.now().toIso8601String().split('T').first;
  int? _terminNumber;

  bool get _isTermin => _payable?['payment_term_type'] == 'termin';

  List<Map<String, dynamic>> get _terms =>
      ((_payable?['jadwal_termin'] as List?) ??
              (widget.purchase['jadwal_termin'] as List?) ??
              const [])
          .map((row) => Map<String, dynamic>.from(row as Map))
          .where((row) => _termOutstanding(row) > 0)
          .toList();

  double _termOutstanding(Map<String, dynamic> row) =>
      (((row['amount'] as num?)?.toDouble() ?? 0) -
              ((row['paid_amount'] as num?)?.toDouble() ?? 0))
          .clamp(0, double.infinity)
          .toDouble();

  String _amountText(double amount) {
    if ((amount - amount.roundToDouble()).abs() < 0.000001) {
      return amount.toStringAsFixed(0);
    }
    return amount.toStringAsFixed(2);
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _referenceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final purchaseId = widget.purchase['_id']?.toString() ?? '';
    final results = await Future.wait([
      _repository.getPayableForPurchase(purchaseId),
      _repository.getActiveBankAccounts(),
    ]);
    if (!mounted) return;
    final payableResult = results[0] as dynamic;
    final bankResult = results[1] as dynamic;
    payableResult.fold((failure) => AppToast.error(context, failure.message), (
      value,
    ) {
      _payable = value as Map<String, dynamic>?;
      _paymentDataStale = false;
      if (_payable != null) {
        _amountController.text = _amountText(
          (_payable!['outstanding_amount'] as num? ?? 0).toDouble(),
        );
      }
    });
    bankResult.fold(
      (failure) {
        _bankAccountsAvailable = false;
        _bankLoadError = failure.message;
        if (_method == 'transfer') {
          _method = 'cash';
          _bankId = '';
          AppToast.error(context, failure.message);
        }
      },
      (value) {
        _banks = value as List<Map<String, dynamic>>;
        _bankAccountsAvailable = true;
        _bankLoadError = null;
        if (_banks.isEmpty && _method == 'transfer') {
          _method = 'cash';
          _bankId = '';
        }
      },
    );
    if (_isTermin && _terms.isNotEmpty) {
      _terminNumber = (_terms.first['no_termin'] as num?)?.toInt();
      _setAmountForSelectedTerm();
    }
    setState(() => _loading = false);
  }

  void _setAmountForSelectedTerm() {
    final selected = _terms.where(
      (row) => (row['no_termin'] as num?)?.toInt() == _terminNumber,
    );
    if (selected.isNotEmpty) {
      _amountController.text = _amountText(_termOutstanding(selected.first));
    }
  }

  Future<void> _choosePaymentDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: DateTime.tryParse(_paymentDate) ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (selected == null || !mounted) return;
    setState(() => _paymentDate = selected.toIso8601String().split('T').first);
  }

  String _currency(dynamic value) =>
      'Rp ${((value as num?)?.toDouble() ?? 0).toStringAsFixed(0)}';

  Future<void> _pay() async {
    if (_paymentDataStale) {
      AppToast.error(
        context,
        'Muat ulang tagihan sebelum mencatat pembayaran lagi.',
      );
      return;
    }
    final payable = _payable;
    final amount = double.tryParse(_amountController.text.replaceAll(',', '.'));
    if (payable == null || amount == null || amount <= 0) {
      AppToast.error(context, 'Masukkan jumlah pembayaran yang valid.');
      return;
    }
    if (_method == 'transfer' && _bankId.isEmpty) {
      AppToast.error(
        context,
        _banks.isEmpty
            ? 'Tidak ada rekening bank aktif. Pilih tunai atau giro, atau aktifkan rekening bank.'
            : 'Pilih rekening bank untuk transfer.',
      );
      return;
    }
    if (_isTermin && _terminNumber == null) {
      AppToast.error(context, 'Pilih termin yang akan dibayar.');
      return;
    }
    if (_isTermin) {
      final selectedTerm = _terms.where(
        (row) => (row['no_termin'] as num?)?.toInt() == _terminNumber,
      );
      final termOutstanding = selectedTerm.isEmpty
          ? 0
          : _termOutstanding(selectedTerm.first);
      if (amount > termOutstanding + 0.01) {
        AppToast.error(
          context,
          'Jumlah melebihi sisa termin (${_currency(termOutstanding)}).',
        );
        return;
      }
    }
    final payableOutstanding =
        (payable['outstanding_amount'] as num?)?.toDouble() ?? 0;
    if (amount > payableOutstanding + 0.01) {
      AppToast.error(
        context,
        'Jumlah melebihi sisa hutang (${_currency(payableOutstanding)}).',
      );
      return;
    }
    setState(() => _saving = true);
    final result = await _repository.payInventoryPayable({
      'payable_id': payable['_id'],
      'amount': amount,
      'payment_date': _paymentDate,
      'payment_method': _method,
      if (_method == 'transfer') 'bank_account_id': _bankId,
      if (_referenceController.text.trim().isNotEmpty)
        'reference_number': _referenceController.text.trim(),
      if (_notesController.text.trim().isNotEmpty)
        'notes': _notesController.text.trim(),
      if (_isTermin) 'no_termin': _terminNumber,
    });
    if (!mounted) return;
    final paymentResult = result.fold<Map<String, dynamic>?>((failure) {
      AppToast.error(context, failure.message);
      return null;
    }, (value) => value);
    if (paymentResult == null) {
      setState(() {
        _saving = false;
        _paymentDataStale = true;
      });
      AppToast.info(
        context,
        'Muat ulang tagihan sebelum mencoba pembayaran lagi.',
      );
      return;
    }
    final previousIds = (_payable?['payment_history'] as List? ?? const [])
        .whereType<Map>()
        .map((entry) => entry['_id']?.toString())
        .whereType<String>()
        .toSet();
    final history = paymentResult['payment_history'] as List? ?? const [];
    final paymentId =
        history
            .whereType<Map>()
            .map((entry) => entry['_id']?.toString())
            .whereType<String>()
            .where((id) => !previousIds.contains(id))
            .lastOrNull ??
        '';
    setState(() {
      _payable = {...?_payable, ...paymentResult};
      _paymentDataStale = true;
      _saving = false;
      _amountController.text = _amountText(
        (paymentResult['outstanding_amount'] as num? ?? 0).toDouble(),
      );
      _terminNumber = null;
      _referenceController.clear();
      _notesController.clear();
    });
    final viewProof = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Pembayaran tercatat'),
        content: const Text(
          'Bukti pencatatan pembayaran dapat dibuka kembali dari riwayat pembayaran.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Selesai'),
          ),
          if (paymentId.isNotEmpty)
            FilledButton.icon(
              onPressed: () => Navigator.pop(dialogContext, true),
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Lihat bukti'),
            ),
        ],
      ),
    );
    if (!mounted) return;
    if (viewProof == true && !await _openPaymentProof(paymentId)) {
      if (mounted) await _load();
      return;
    }
    if (!mounted) return;
    if (widget.embedded) {
      widget.onFinished?.call();
    } else {
      Navigator.of(context).pop(true);
    }
  }

  Future<bool> _openPaymentProof(String paymentId) async {
    if (paymentId.isEmpty || _proofLoadingId != null) return false;
    final payableId = _payable?['_id']?.toString() ?? '';
    if (payableId.isEmpty) {
      AppToast.error(context, 'ID tagihan tidak tersedia');
      return false;
    }
    setState(() => _proofLoadingId = paymentId);
    try {
      final result = await _repository.getPayableForPaymentProof(payableId);
      if (!mounted) return false;
      final payable = result.fold<Map<String, dynamic>>(
        (failure) => throw _PaymentProofException(failure.message),
        (value) => value,
      );
      final matches = (payable['payment_history'] as List? ?? const [])
          .whereType<Map>()
          .where((row) => row['_id']?.toString() == paymentId);
      if (matches.isEmpty) {
        throw const _PaymentProofException('Pembayaran tidak ditemukan');
      }
      final payment = Map<String, dynamic>.from(matches.first);
      final buyerResult = await sl<PosReceiptRepository>()
          .getReceiptPrintData();
      if (!mounted) return false;
      final company = buyerResult.fold<Map<String, String>>(
        (failure) => throw _PaymentProofException(
          'Identitas pembeli tidak dapat dimuat: ${failure.message}',
        ),
        (data) => data.company,
      );
      if ((company['nama_resmi'] ?? '').trim().isEmpty &&
          (company['nama_instansi'] ?? '').trim().isEmpty) {
        throw const _PaymentProofException(
          'Nama instansi belum tersedia untuk bukti pembayaran',
        );
      }
      final Uint8List bytes = await PosPurchasePaymentProofDocument.build(
        payable: payable,
        payment: payment,
        company: company,
      );
      if (!mounted) return false;
      final active = PosPurchasePaymentProofDocument.canDistribute(payment);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Bukti Pembayaran')),
            body: PdfPreview(
              build: (_) async => bytes,
              pdfFileName: 'Bukti-Pembayaran-$paymentId.pdf',
              allowPrinting: active,
              allowSharing: active,
              canChangePageFormat: false,
              canChangeOrientation: false,
            ),
          ),
        ),
      );
      return true;
    } on _PaymentProofException catch (error) {
      if (mounted) {
        AppToast.error(context, error.message);
      }
      return false;
    } catch (_) {
      if (mounted) {
        AppToast.error(context, 'Gagal membuka bukti pembayaran. Coba lagi.');
      }
      return false;
    } finally {
      if (mounted) setState(() => _proofLoadingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final content = _loading
        ? const _PayableSkeleton()
        : _payable == null
        ? const Center(child: Text('Tagihan untuk PO ini belum tersedia.'))
        : _buildPayable();
    if (!widget.embedded) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Pembayaran PO ${widget.purchase['no_po'] ?? ''}'.trim()),
          backgroundColor: const Color(0xFF07877E),
          foregroundColor: Colors.white,
        ),
        body: content,
      );
    }
    return Column(
      children: [
        Material(
          color: Colors.white,
          child: ListTile(
            leading: IconButton(
              tooltip: 'Kembali ke pembelian',
              onPressed: widget.onFinished,
              icon: const Icon(Icons.arrow_back),
            ),
            title: Text(
              'Bayar ${widget.purchase['no_po'] ?? 'Pembelian'}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text('Pembelian & Penerimaan'),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: content),
      ],
    );
  }

  Widget _buildPayable() {
    final payable = _payable!;
    final payableStatus = payable['status']?.toString() ?? '';
    final outstanding =
        (payable['outstanding_amount'] as num?)?.toDouble() ?? 0;
    final canPay = !const {'paid', 'cancelled'}.contains(payableStatus);
    final history = (payable['payment_history'] as List? ?? const [])
        .map((row) => Map<String, dynamic>.from(row as Map))
        .toList()
        .reversed
        .toList();
    final waitingReceipt =
        widget.purchase['syarat_pembayaran'] == 'saat_penerimaan' &&
        (payable['due_date']?.toString().isEmpty ?? true);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  payable['supplier_name']?.toString() ?? '-',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                _summaryRow(
                  'Total tagihan',
                  _currency(payable['total_amount']),
                ),
                _summaryRow('Sudah dibayar', _currency(payable['paid_amount'])),
                _summaryRow('Sisa hutang', _currency(outstanding), bold: true),
                if (payableStatus == 'paid')
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Chip(
                      avatar: Icon(Icons.check_circle, size: 18),
                      label: Text('Lunas'),
                    ),
                  ),
                if (payableStatus == 'cancelled')
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Chip(
                      avatar: Icon(Icons.cancel_outlined, size: 18),
                      label: Text('Hutang dibatalkan'),
                    ),
                  ),
                _summaryRow(
                  'Jatuh tempo',
                  payable['due_date']?.toString().isNotEmpty == true
                      ? payable['due_date'].toString()
                      : (waitingReceipt ? 'Setelah penerimaan' : '-'),
                ),
              ],
            ),
          ),
        ),
        if (waitingReceipt)
          const Card(
            color: Color(0xFFFFF4D6),
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Pembayaran tersedia setelah penerimaan pertama dicatat.',
              ),
            ),
          ),
        if (canPay &&
            !waitingReceipt &&
            outstanding > 0 &&
            !widget.canRecordPayment)
          const Card(
            color: Color(0xFFEAF3F2),
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Anda dapat melihat hutang ini, tetapi tidak memiliki akses untuk mencatat pembayaran.',
              ),
            ),
          ),
        if (canPay &&
            !waitingReceipt &&
            outstanding > 0 &&
            widget.canRecordPayment &&
            (!_isTermin || _terms.isNotEmpty)) ...[
          const SizedBox(height: 8),
          Text(
            'Catat pembayaran',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 10),
          if (_isTermin)
            DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: _terminNumber,
              decoration: const InputDecoration(
                labelText: 'Termin',
                border: OutlineInputBorder(),
              ),
              items: _terms.map((row) {
                final number = (row['no_termin'] as num).toInt();
                return DropdownMenuItem(
                  value: number,
                  child: Text(
                    'Termin $number · sisa ${_currency(_termOutstanding(row))}',
                  ),
                );
              }).toList(),
              onChanged: (value) => setState(() {
                _terminNumber = value;
                _setAmountForSelectedTerm();
              }),
            ),
          if (_isTermin) const SizedBox(height: 10),
          TextField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Jumlah pembayaran *',
              prefixText: 'Rp ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextFormField(
            key: ValueKey(_paymentDate),
            initialValue: _paymentDate,
            readOnly: true,
            onTap: _choosePaymentDate,
            decoration: const InputDecoration(
              labelText: 'Tanggal pembayaran *',
              suffixIcon: Icon(Icons.calendar_month_outlined),
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _method,
            decoration: const InputDecoration(
              labelText: 'Metode pembayaran',
              border: OutlineInputBorder(),
            ),
            items: [
              if (_banks.isNotEmpty)
                const DropdownMenuItem(
                  value: 'transfer',
                  child: Text('Transfer bank'),
                ),
              DropdownMenuItem(value: 'cash', child: Text('Tunai')),
              DropdownMenuItem(value: 'giro', child: Text('Giro')),
              DropdownMenuItem(value: 'cek', child: Text('Cek')),
            ],
            onChanged: (value) => setState(() {
              _method = value ?? (_banks.isNotEmpty ? 'transfer' : 'cash');
              if (_method != 'transfer') _bankId = '';
            }),
          ),
          if (!_bankAccountsAvailable && _bankLoadError != null) ...[
            const SizedBox(height: 8),
            Text(
              'Rekening bank tidak dapat dimuat. Pembayaran tunai atau giro tetap tersedia.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
          if (_method == 'transfer') ...[
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _bankId.isEmpty ? null : _bankId,
              decoration: const InputDecoration(
                labelText: 'Rekening bank *',
                border: OutlineInputBorder(),
              ),
              items: _banks
                  .map(
                    (bank) => DropdownMenuItem(
                      value: bank['_id'].toString(),
                      child: Text(
                        '${bank['bank_name']} · ${bank['account_number']}',
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) => setState(() => _bankId = value ?? ''),
            ),
          ],
          const SizedBox(height: 10),
          TextField(
            controller: _referenceController,
            decoration: const InputDecoration(
              labelText: 'Nomor referensi (opsional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Catatan (opsional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: _saving || _paymentDataStale ? null : _pay,
            style: InventoryActionStyle.primary(),
            icon: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.payments_outlined),
            label: Text(_saving ? 'Menyimpan...' : 'Simpan pembayaran'),
          ),
          if (_paymentDataStale)
            TextButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh),
              label: const Text(
                'Muat ulang tagihan sebelum pembayaran berikutnya',
              ),
            ),
        ],
        if (canPay &&
            !waitingReceipt &&
            outstanding > 0 &&
            _isTermin &&
            _terms.isEmpty)
          const Card(
            color: Color(0xFFFFF4D6),
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Text(
                'Jadwal termin belum tersedia. Perbarui data PO atau hubungi admin sebelum mencatat pembayaran.',
              ),
            ),
          ),
        if (history.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            'Riwayat pembayaran',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          for (final payment in history) _paymentHistoryCard(payment),
        ],
      ],
    );
  }

  Widget _summaryRow(String label, String value, {bool bold = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  Widget _paymentHistoryCard(Map payment) {
    final paymentId = payment['_id']?.toString() ?? '';
    final status = payment['status']?.toString() ?? 'active';
    final cancelledBy = payment['cancelled_by'];
    final cancellationDetails = status == 'cancelled'
        ? 'DIBATALKAN · ${payment['cancellation_reason'] ?? 'Alasan tidak dicatat'}'
              '${payment['cancelled_at'] == null ? '' : '\n${payment['cancelled_at']}'}'
              '${cancelledBy is Map ? '\nOleh ${cancelledBy['name'] ?? cancelledBy['username'] ?? '-'}' : ''}'
        : status == 'cancellation_pending'
        ? 'PEMBATALAN DIPROSES'
        : '';
    final hasBankAccount =
        payment['bank_account_name']?.toString().isNotEmpty == true;

    return Card(
      child: ListTile(
        leading: Icon(
          status == 'cancelled'
              ? Icons.cancel_outlined
              : Icons.receipt_long_outlined,
          color: status == 'cancelled' ? Colors.red : null,
        ),
        title: Text(_currency(payment['amount'])),
        subtitle: Text(
          '${payment['payment_date'] ?? '-'} · ${payment['payment_method'] ?? '-'}'
          '${hasBankAccount ? '\n${payment['bank_account_name']}' : ''}'
          '${cancellationDetails.isEmpty ? '' : '\n$cancellationDetails'}',
        ),
        isThreeLine: hasBankAccount || cancellationDetails.isNotEmpty,
        trailing: paymentId.isEmpty
            ? null
            : IconButton(
                tooltip: status == 'active'
                    ? 'Lihat / bagikan bukti pembayaran'
                    : status == 'cancelled'
                    ? 'Lihat bukti pembayaran yang dibatalkan'
                    : 'Lihat bukti pembayaran yang menunggu pembatalan',
                onPressed: _proofLoadingId != null
                    ? null
                    : () => _openPaymentProof(paymentId),
                icon: _proofLoadingId == paymentId
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.picture_as_pdf_outlined),
              ),
      ),
    );
  }
}

class _PaymentProofException implements Exception {
  final String message;

  const _PaymentProofException(this.message);
}

class _PayableSkeleton extends StatelessWidget {
  const _PayableSkeleton();

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(16),
    children: const [
      SkeletonBox(height: 170, borderRadius: 14),
      SizedBox(height: 14),
      SkeletonBox(height: 52, borderRadius: 10),
      SizedBox(height: 10),
      SkeletonBox(height: 52, borderRadius: 10),
      SizedBox(height: 10),
      SkeletonBox(height: 52, borderRadius: 10),
    ],
  );
}
