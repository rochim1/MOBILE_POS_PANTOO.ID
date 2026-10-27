import 'package:mobile_pos_pantoo/core/utils/rupiah_input_formatter.dart';
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:crypto/crypto.dart';
import 'package:printing/printing.dart';

import '../../../../injections.dart';
import '../../../core/utils/product_image_picker.dart';
import '../../../core/receipt/pos_receipt_print_service.dart';
import '../../../domain/repositories/pos_inventory_repository.dart';
import '../../../domain/repositories/pos_receipt_repository.dart';
import '../../widgets/app_toast.dart';
import '../../widgets/inventory_action_style.dart';
import '../../widgets/skeleton_loading.dart';
import 'utils/pos_purchase_payment_proof_document.dart';
import 'utils/pos_pdf_preview_bytes.dart';
import 'utils/pos_business_print_branding.dart';
import 'utils/pos_vendor_invoice_submission_session.dart';

class PosPurchasePayablePage extends StatefulWidget {
  final Map<String, dynamic> purchase;
  // Purchasing Mobile is deliberately read-only. There is no constructor
  // parameter that can re-enable supplier payment from a PO route.
  final bool canRecordPayment = false;
  final bool embedded;
  final VoidCallback? onFinished;
  final Future<PickedProductImage?> Function()? pickInvoiceImage;

  const PosPurchasePayablePage({
    super.key,
    required this.purchase,
    this.embedded = false,
    this.onFinished,
    this.pickInvoiceImage,
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
  List<Map<String, dynamic>> _vendorBills = const [];
  String? _vendorBillLoadError;
  final List<Map<String, dynamic>> _banks = const [];
  bool _loading = true;
  bool _saving = false;
  bool _submittingEvidence = false;
  late final PosVendorInvoiceSubmissionSession _invoiceSubmission;
  bool _paymentDataStale = false;
  String? _proofLoadingId;
  String? _cancelLoadingId;
  final bool _bankAccountsAvailable = true;
  String? _bankLoadError;
  String _method = 'transfer';
  String _bankId = '';
  String _paymentDate = DateTime.now().toIso8601String().split('T').first;
  int? _terminNumber;

  Future<void> _submitInvoiceEvidence() async {
    if (_submittingEvidence) return;
    setState(() => _submittingEvidence = true);
    try {
      final picked = await (widget.pickInvoiceImage ?? pickProductImage)();
      if (picked == null || !mounted) return;
      final number = TextEditingController();
      final note = TextEditingController();
      final invoiceDate = TextEditingController(
        text: DateTime.now().toIso8601String().split('T').first,
      );
      try {
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Kirim bukti invoice ke Finance'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Bukti ini hanya menjadi submission. Mobile tidak membuat utang atau Vendor Bill.',
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: number,
                    decoration: const InputDecoration(
                      labelText: 'Nomor invoice (opsional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: invoiceDate,
                    decoration: const InputDecoration(
                      labelText: 'Tanggal invoice (YYYY-MM-DD)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: note,
                    maxLength: 1000,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Catatan untuk Finance',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () {
                  if (!PosVendorInvoiceSubmissionSession.validInvoiceDate(
                    invoiceDate.text.trim(),
                  )) {
                    AppToast.error(
                      dialogContext,
                      'Tanggal invoice harus tanggal kalender valid (YYYY-MM-DD)',
                    );
                    return;
                  }
                  if (number.text.trim().length > 120) {
                    AppToast.error(
                      dialogContext,
                      'Nomor invoice maksimal 120 karakter',
                    );
                    return;
                  }
                  Navigator.pop(dialogContext, true);
                },
                child: const Text('Kirim'),
              ),
            ],
          ),
        );
        if (confirmed != true || !mounted) {
          return;
        }
        final fileHash = sha256.convert(picked.bytes).toString();
        var url = _invoiceSubmission.uploadedUrl(fileHash);
        if (url == null) {
          final upload = await _repository.uploadVendorInvoiceEvidence(
            picked.bytes,
            picked.name,
          );
          if (!mounted) return;
          upload.fold(
            (failure) => AppToast.error(context, failure.message),
            (value) => url = value,
          );
          if (url == null) return;
          _invoiceSubmission.rememberUpload(fileHash, url!);
        }
        final result = await _repository.submitVendorInvoiceEvidence({
          'purchase_id': widget.purchase['_id'],
          'request_id': _invoiceSubmission.requestId(
            fileHash: fileHash,
            invoiceNumber: number.text,
            invoiceDate: invoiceDate.text,
            note: note.text,
          ),
          'supplier_invoice_number': number.text.trim().isEmpty
              ? null
              : number.text.trim(),
          'invoice_date': invoiceDate.text.trim().isEmpty
              ? null
              : invoiceDate.text.trim(),
          'evidence_url': url,
          'evidence_hash': fileHash,
          'note': note.text.trim().isEmpty ? null : note.text.trim(),
        });
        if (!mounted) return;
        result.fold((failure) => AppToast.error(context, failure.message), (_) {
          AppToast.success(
            context,
            'Bukti terkirim. Finance akan memverifikasi sebelum membuat Vendor Bill.',
          );
        });
      } finally {
        number.dispose();
        invoiceDate.dispose();
        note.dispose();
      }
    } catch (error) {
      if (mounted) {
        AppToast.error(
          context,
          'Bukti belum terkirim. Periksa koneksi lalu coba lagi.',
        );
      }
    } finally {
      if (mounted) setState(() => _submittingEvidence = false);
    }
  }

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

  String _amountText(double amount) => formatRupiahAmount(amount);

  @override
  void initState() {
    super.initState();
    _invoiceSubmission = PosVendorInvoiceSubmissionSession(
      widget.purchase['_id'].toString(),
    );
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
      _repository.getVendorBillsForPurchase(purchaseId),
    ]);
    if (!mounted) return;
    final payableResult = results[0] as dynamic;
    final billResult = results[1] as dynamic;
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
    billResult.fold(
      (failure) {
        _vendorBills = const [];
        _vendorBillLoadError = failure.message;
      },
      (value) {
        _vendorBills = value as List<Map<String, dynamic>>;
        _vendorBillLoadError = null;
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
      'Rp ${formatRupiahAmount((value as num?) ?? 0)}';

  Future<void> _pay() async {
    if (_paymentDataStale) {
      AppToast.error(
        context,
        'Muat ulang tagihan sebelum mencatat pembayaran lagi.',
      );
      return;
    }
    final payable = _payable;
    final amount = parseRupiahAmount(_amountController.text);
    if (payable == null || amount <= 0) {
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

  Future<bool> _openPaymentProof(
    String paymentId, {
    bool directPrint = false,
  }) async {
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
      final buyerResult = await sl<PosReceiptRepository>().getReceiptPrintData(
        forceRefresh: true,
      );
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
      final active = PosPurchasePaymentProofDocument.canDistribute(payment);
      if (directPrint) {
        if (!active) {
          throw const _PaymentProofException(
            'Bukti pembayaran yang dibatalkan tidak dapat dicetak.',
          );
        }
      }
      final logo = await PosBusinessPrintBranding.loadCompanyLogo(
        company['logo'] ?? '',
      );
      if (!mounted) return false;
      final Uint8List bytes = await PosPurchasePaymentProofDocument.build(
        payable: payable,
        payment: payment,
        company: company,
        logoBytes: logo,
      );
      if (!mounted) return false;
      if (directPrint) {
        final printed = await PosReceiptPrintService(sl()).printDocumentPdf(
          bytes: bytes,
          name: 'Bukti-Pembayaran-$paymentId.pdf',
        );
        if (!printed) {
          throw const _PaymentProofException(
            'Pencetakan dibatalkan atau gagal.',
          );
        }
        return true;
      }
      final previewBytes = PosPdfPreviewBytes(bytes);
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Bukti Pembayaran')),
            body: PdfPreview(
              build: (_) async => previewBytes.freshBytes(),
              pdfFileName: 'Bukti-Pembayaran-$paymentId.pdf',
              // The preview's system-print action ignores the terminal's
              // Bluetooth printer. Printing goes through the explicit action.
              allowPrinting: false,
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
    } catch (error) {
      if (mounted) {
        AppToast.error(
          context,
          error is StateError
              ? error.message
              : 'Gagal membuka atau mencetak bukti pembayaran. Periksa printer dan coba lagi.',
        );
      }
      return false;
    } finally {
      if (mounted) setState(() => _proofLoadingId = null);
    }
  }

  Future<void> _cancelPayment(Map payment) async {
    if (!widget.canRecordPayment || _cancelLoadingId != null) return;
    final paymentId = payment['_id']?.toString() ?? '';
    final payableId = _payable?['_id']?.toString() ?? '';
    if (paymentId.isEmpty || payableId.isEmpty) {
      AppToast.error(context, 'Data pembayaran tidak lengkap');
      return;
    }

    final isRetry = payment['status'] == 'cancellation_pending';
    final reasonController = TextEditingController(
      text: payment['cancellation_reason']?.toString() ?? '',
    );
    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isRetry ? 'Lanjutkan pembatalan' : 'Batalkan pembayaran?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isRetry
                  ? 'Pembatalan sebelumnya belum selesai. Coba lagi untuk menyelesaikan jurnal pembalik.'
                  : 'Pembayaran ${_currency(payment['amount'])} akan dibalik di jurnal dan dihitung kembali sebagai hutang.',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              readOnly: isRetry,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Alasan pembatalan *',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Kembali'),
          ),
          FilledButton.icon(
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            onPressed: () =>
                Navigator.pop(dialogContext, reasonController.text.trim()),
            icon: Icon(isRetry ? Icons.refresh : Icons.cancel_outlined),
            label: Text(isRetry ? 'Coba lagi' : 'Batalkan'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (!mounted || reason == null) return;
    if (reason.trim().isEmpty) {
      AppToast.error(context, 'Alasan pembatalan wajib diisi');
      return;
    }

    setState(() => _cancelLoadingId = paymentId);
    final result = await _repository.cancelInventoryPayablePayment({
      'payable_id': payableId,
      'payment_id': paymentId,
      'reason': reason.trim(),
    });
    if (!mounted) return;
    result.fold(
      (failure) {
        setState(() => _cancelLoadingId = null);
        AppToast.error(context, failure.message);
        // A failed reversal can leave the payment pending; refresh so the
        // history offers a safe retry instead of appearing unchanged.
        unawaited(_load());
      },
      (value) {
        setState(() {
          _payable = value;
          _paymentDataStale = false;
          _cancelLoadingId = null;
          _terminNumber = null;
          _amountController.text = _amountText(
            (value['outstanding_amount'] as num? ?? 0).toDouble(),
          );
        });
        AppToast.success(context, 'Pembayaran dibatalkan dan jurnal dibalik');
        unawaited(_load());
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final content = _loading
        ? const _PayableSkeleton()
        : _payable == null
        ? _emptyState()
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
              'Tagihan ${widget.purchase['no_po'] ?? 'Pembelian'}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: const Text('Finance · Tagihan supplier'),
          ),
        ),
        const Divider(height: 1),
        Expanded(child: content),
      ],
    );
  }

  Widget _emptyState() => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.receipt_long_outlined,
            size: 42,
            color: Color(0xFF607D7B),
          ),
          const SizedBox(height: 12),
          const Text(
            'Tagihan untuk PO ini belum tersedia.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          const Text(
            'Jika invoice fisik sudah diterima, kirim fotonya untuk diverifikasi Finance.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _submittingEvidence ? null : _submitInvoiceEvidence,
            icon: _submittingEvidence
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_a_photo_outlined),
            label: const Text('Kirim foto invoice'),
          ),
        ],
      ),
    ),
  );

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
          child: ListTile(
            leading: const Icon(Icons.add_a_photo_outlined),
            title: const Text('Kirim bukti invoice lain'),
            subtitle: const Text(
              'Foto masuk antrean Finance dan tidak langsung membentuk utang.',
            ),
            trailing: _submittingEvidence
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _submittingEvidence ? null : _submitInvoiceEvidence,
          ),
        ),
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
        const SizedBox(height: 8),
        Text(
          'Invoice supplier',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (_vendorBillLoadError != null)
          Card(
            child: ListTile(
              leading: const Icon(Icons.sync_problem_outlined),
              title: const Text('Daftar invoice belum dapat dimuat'),
              subtitle: Text(_vendorBillLoadError!),
              trailing: IconButton(
                tooltip: 'Coba lagi',
                onPressed: _load,
                icon: const Icon(Icons.refresh),
              ),
            ),
          )
        else if (_vendorBills.isEmpty)
          const Card(
            child: ListTile(
              leading: Icon(Icons.receipt_long_outlined),
              title: Text('Belum ada Vendor Bill'),
              subtitle: Text(
                'Invoice yang sudah diverifikasi Finance akan tampil di sini.',
              ),
            ),
          )
        else
          ..._vendorBills.map(_vendorBillCard),
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
                'Tagihan ini bersifat baca-saja di workspace PO. Kelola pembayaran di Finance Web.',
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
            inputFormatters: const [RupiahInputFormatter(decimalDigits: 2)],
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

  Widget _vendorBillCard(Map<String, dynamic> bill) {
    final itemStatuses = (bill['items'] as List? ?? const [])
        .map((item) => (item as Map)['matching_status']?.toString() ?? '')
        .where((status) => status.isNotEmpty)
        .toSet();
    final matchLabel = itemStatuses.isEmpty
        ? 'Belum dinilai'
        : itemStatuses.length == 1
        ? itemStatuses.first
        : 'Campuran';
    final payable = bill['payable'] is Map
        ? Map<String, dynamic>.from(bill['payable'] as Map)
        : const <String, dynamic>{};
    return Card(
      child: ListTile(
        title: Text(bill['supplier_invoice_number']?.toString() ?? '-'),
        subtitle: Text(
          'Matching: $matchLabel · Jatuh tempo: ${bill['due_date'] ?? payable['due_date'] ?? '-'}\n'
          'Outstanding: ${_currency(payable['outstanding_amount'] ?? bill['total_amount'])}',
        ),
        isThreeLine: true,
        trailing: Text(
          bill['status']?.toString() ?? '-',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
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
            : _cancelLoadingId == paymentId
            ? const SizedBox(
                width: 48,
                height: 48,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : _proofLoadingId == paymentId
            ? const SizedBox(
                width: 48,
                height: 48,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            : PopupMenuButton<String>(
                tooltip: 'Opsi pembayaran',
                enabled:
                    _proofLoadingId == null &&
                    _cancelLoadingId == null &&
                    !_saving,
                onSelected: (action) {
                  if (action == 'cancel' || action == 'retry_cancel') {
                    unawaited(_cancelPayment(payment));
                  } else {
                    unawaited(
                      _openPaymentProof(
                        paymentId,
                        directPrint: action == 'print',
                      ),
                    );
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'preview',
                    child: Text('Pratinjau / Bagikan'),
                  ),
                  if (status == 'active')
                    const PopupMenuItem(
                      value: 'print',
                      child: Text('Cetak A4 (dialog perangkat)'),
                    ),
                  if (status == 'active' && widget.canRecordPayment)
                    const PopupMenuItem(
                      value: 'cancel',
                      child: Text('Batalkan pembayaran'),
                    ),
                  if (status == 'cancellation_pending' &&
                      widget.canRecordPayment)
                    const PopupMenuItem(
                      value: 'retry_cancel',
                      child: Text('Lanjutkan pembatalan'),
                    ),
                ],
                icon: const Icon(Icons.more_vert),
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
