import '../../widgets/pos_record_skeletons.dart';
import '../../widgets/pos_collapsible_filters.dart';
import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos_pantoo/core/_core.dart';
import 'package:mobile_pos_pantoo/core/error/error_handler.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/core/network/pos_financial_request_store.dart';
import 'package:mobile_pos_pantoo/data/graphql/pos_receivable_queries.dart';
import 'package:mobile_pos_pantoo/injections.dart';

class PosReceivablesPage extends StatefulWidget {
  const PosReceivablesPage({
    super.key,
    required this.canCollect,
    required this.operatorId,
    this.initialInvoiceId,
  });
  final bool canCollect;
  final String operatorId;
  final String? initialInvoiceId;
  @override
  State<PosReceivablesPage> createState() => _PosReceivablesPageState();
}

class _PosReceivablesPageState extends State<PosReceivablesPage> {
  final _search = TextEditingController();
  final _amount = TextEditingController();
  final _reference = TextEditingController();
  final _provider = sl<GraphQLClientProvider>();
  late final _requests = PosFinancialRequestStore(
    _provider.sharedPreferences,
    '${_provider.endpointUrl}:${_provider.sharedPreferences.getString('instansi_id')}:${widget.operatorId}',
  );
  List<Map<String, dynamic>> _items = [], _cash = [], _banks = [];
  Map<String, dynamic>? _invoice, _pending;
  String _error = '', _message = '', _method = 'cash', _destination = '';
  bool _loading = true, _sending = false, _settled = false;
  int _page = 1, _total = 0, _generation = 0;
  String get _requestOwner =>
      '${_provider.endpointUrl}:${_provider.sharedPreferences.getString('instansi_id')}:${_provider.sharedPreferences.getString('user_id')}:${widget.operatorId}';
  late final String _initialOwner;
  String get _sessionIdentity =>
      '${identityHashCode(_provider.client)}:$_requestOwner';
  void _assertSession(String session) {
    if (session != _sessionIdentity || _initialOwner != _requestOwner) {
      throw StateError(
        'Sesi kasir berubah. Periksa penerimaan dengan akun asal; jangan menerima uang dua kali.',
      );
    }
  }

  String _errorMessage(Object error) => error is StateError
      ? error.message.toString()
      : error is TimeoutException
      ? 'Koneksi melewati batas waktu. Muat ulang; bukti yang belum terkonfirmasi tetap tersimpan.'
      : AppErrorHandler.handle(error).message;
  String _money(dynamic n) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp',
    decimalDigits: 0,
  ).format(n ?? 0);
  @override
  void initState() {
    super.initState();
    _initialOwner = _requestOwner;
    unawaited(
      widget.initialInvoiceId == null
          ? _load()
          : _open(widget.initialInvoiceId!),
    );
  }

  @override
  void dispose() {
    _generation++;
    _search.dispose();
    _amount.dispose();
    _reference.dispose();
    super.dispose();
  }

  Future<Map<String, dynamic>> _query(
    String query,
    Map<String, dynamic> variables,
  ) async {
    final session = _sessionIdentity;
    _assertSession(session);
    final result = await _provider.client
        .query(
          QueryOptions(
            document: gql(query),
            variables: variables,
            fetchPolicy: FetchPolicy.networkOnly,
          ),
        )
        .timeout(const Duration(seconds: 20));
    _assertSession(session);
    if (result.hasException) {
      throw StateError(AppErrorHandler.handle(result.exception!).message);
    }
    return result.data ?? {};
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = '';
      _invoice = null;
    });
    try {
      final data =
          (await _query(PosReceivableQueries.list, {
                'search': _search.text.trim(),
                'page': _page,
                'include_settled': _settled,
              }))['GetPOSReceivables']
              as Map;
      if (!mounted || generation != _generation) return;
      setState(() {
        _items = (data['items'] as List)
            .map((r) => Map<String, dynamic>.from(r as Map))
            .toList();
        _total = (data['totalCount'] as num).toInt();
      });
    } catch (e) {
      if (mounted && generation == _generation) {
        setState(() => _error = _errorMessage(e));
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _open(String id) async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _error = '';
      _message = '';
      _invoice = null;
      _pending = null;
    });
    try {
      final data = await _query(PosReceivableQueries.detail, {'_id': id});
      final pending = _requests.load(id);
      final options = widget.canCollect
          ? await _query(PosReceivableQueries.options, {})
          : <String, dynamic>{};
      if (!mounted || generation != _generation) return;
      setState(() {
        _invoice = Map<String, dynamic>.from(data['GetPOSReceivable'] as Map);
        _pending = pending;
        _cash =
            ((options['GetSalesInvoiceOptions']?['cash_accounts'] ?? [])
                    as List)
                .map((r) => Map<String, dynamic>.from(r as Map))
                .toList();
        _banks = ((options['GetSalesInvoiceOptions']?['banks'] ?? []) as List)
            .map((r) => Map<String, dynamic>.from(r as Map))
            .toList();
        _method = pending?['payment_method']?.toString() ?? 'cash';
        _destination =
            pending?[_method == 'cash'
                    ? 'cash_account_code'
                    : 'bank_account_id']
                ?.toString() ??
            '';
        _amount.text = (pending?['amount'] ?? _invoice!['outstanding_amount'])
            .toString();
        _reference.text = pending?['reference']?.toString() ?? '';
      });
    } catch (e) {
      if (mounted && generation == _generation) {
        setState(() => _error = _errorMessage(e));
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _collect() async {
    if (_sending || !widget.canCollect || _invoice == null) return;
    final id = _invoice!['_id'].toString();
    final session = _sessionIdentity;
    final value = num.tryParse(_amount.text.trim());
    if (_pending == null &&
        (value == null ||
            !value.isFinite ||
            value <= 0 ||
            value != value.round() ||
            value > (_invoice!['outstanding_amount'] as num) ||
            _destination.isEmpty ||
            _reference.text.trim().isEmpty)) {
      setState(
        () => _error =
            'Isi Rupiah bulat maksimal sisa tagihan, akun penerimaan dan nomor bukti.',
      );
      return;
    }
    setState(() {
      _sending = true;
      _error = '';
      _message = '';
    });
    try {
      _assertSession(session);
      final payload = await _requests.begin(id, {
        'invoice_id': id,
        'date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
        'amount': value,
        'payment_method': _method,
        if (_method == 'cash')
          'cash_account_code': _destination
        else
          'bank_account_id': _destination,
        'reference': _reference.text.trim(),
      });
      _assertSession(session);
      if (mounted) setState(() => _pending = payload);
      final result = await _provider.client
          .mutate(
            MutationOptions(
              document: gql(PosReceivableQueries.payment),
              variables: {'input': payload},
            ),
          )
          .timeout(const Duration(seconds: 25));
      _assertSession(session);
      final errors = [
        ...?result.exception?.graphqlErrors,
        if (result.exception?.linkException is ServerException)
          ...?((result.exception!.linkException as ServerException)
              .parsedResponse
              ?.errors),
      ];
      if (errors.any(
        (e) => e.extensions?['financial_write_rejected'] == true,
      )) {
        await _requests.acknowledge(id);
        if (mounted) setState(() => _pending = null);
      }
      final canonical = result.data?['RecordPOSReceivablePayment'];
      if (result.hasException || canonical is! Map || canonical['_id'] != id) {
        throw StateError(
          result.exception?.graphqlErrors
                      .map((e) => e.message)
                      .join('; ')
                      .isNotEmpty ==
                  true
              ? result.exception!.graphqlErrors.map((e) => e.message).join('; ')
              : 'Respons terputus. Jangan menerima uang dua kali; gunakan Kirim ulang bukti yang sama.',
        );
      }
      await _requests.acknowledge(id);
      if (!mounted) return;
      setState(() {
        _invoice = Map<String, dynamic>.from(canonical);
        _pending = null;
        _message = 'Penerimaan tercatat di Finance. Stok tidak berubah.';
        _amount.text = _invoice!['outstanding_amount'].toString();
        _reference.clear();
      });
    } catch (e) {
      if (mounted) setState(() => _error = _errorMessage(e));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final invoice = _invoice;
    return PopScope(
      canPop: !_sending,
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                if (invoice != null)
                  IconButton(
                    tooltip: ('Kembali ke daftar piutang').tr(context),
                    onPressed: _sending ? null : _load,
                    icon: const Icon(Icons.arrow_back),
                  ),
                const Expanded(
                  child: PosText(
                    'Piutang & Pelunasan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  tooltip: ('Muat ulang').tr(context),
                  onPressed: _sending || _loading
                      ? null
                      : () => invoice == null
                            ? _load()
                            : _open(invoice['_id'].toString()),
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const PosText(
              'Data Finance online. Penerimaan ke akun kas/bank terpilih, bukan penjualan baru atau uang laci shift.',
            ),
            const SizedBox(height: 12),
            if (invoice == null && _requests.pendingInvoiceIds.isNotEmpty) ...[
              const PosText(
                'Ada bukti belum terkonfirmasi, termasuk jika invoice sudah lunas. Jangan menerima uang dua kali.',
              ),
              for (final id in _requests.pendingInvoiceIds)
                TextButton(
                  onPressed: _loading || _sending ? null : () => _open(id),
                  child: Text(
                    posLocale(context).posc4171a22051c(
                      (id.substring(
                        id.length > 6 ? id.length - 6 : 0,
                      )).toString(),
                    ),
                  ),
                ),
            ],
            if (_error.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: PosText(
                  _error,
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            if (_message.isNotEmpty)
              PosText(
                _message,
                style: const TextStyle(color: AppColors.primary),
              ),
            if (_loading)
              PosTradeContentSkeleton(
                detail: invoice != null,
                showSummary: false,
              )
            else if (invoice == null) ...[
              PosCollapsibleFilters(
                toggleKey: const Key('receivable_filter_toggle'),
                activeCount: [
                  _search.text.trim().isNotEmpty,
                  _settled,
                ].where((active) => active).length,
                child: Column(
                  children: [
                    TextField(
                      controller: _search,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        labelText: ('Cari pelanggan / nomor invoice').tr(
                          context,
                        ),
                        suffixIcon: IconButton(
                          tooltip: ('Cari').tr(context),
                          onPressed: () {
                            _page = 1;
                            _load();
                          },
                          icon: const Icon(Icons.search),
                        ),
                      ),
                      onSubmitted: (_) {
                        _page = 1;
                        _load();
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const PosText('Termasuk lunas / dikreditkan'),
                      value: _settled,
                      onChanged: (v) {
                        _settled = v;
                        _page = 1;
                        _load();
                      },
                    ),
                  ],
                ),
              ),
              if (_items.isEmpty && _error.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: PosText(
                    'Tidak ada invoice POS sesuai pencarian. Pesanan belum dibayar bukan piutang Finance.',
                  ),
                ),
              for (final row in _items)
                Card(
                  child: ListTile(
                    title: Text(row['customer_name'].toString()),
                    subtitle: Text(
                      posLocale(context).pos36e433c66faa(
                        (row['source_context']?['receipt_number'] ??
                                row['invoice_number'])
                            .toString(),
                        (row['due_date'] ?? '-').toString(),
                      ),
                    ),
                    isThreeLine: true,
                    trailing: Text(
                      _money(row['outstanding_amount']),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () => _open(row['_id'].toString()),
                  ),
                ),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  TextButton(
                    onPressed: _page > 1
                        ? () {
                            _page--;
                            _load();
                          }
                        : null,
                    child: const PosText('Sebelumnya'),
                  ),
                  Text(
                    posLocale(
                      context,
                    ).posd4d98a649594((_page).toString(), (_total).toString()),
                  ),
                  TextButton(
                    onPressed: _page * 20 < _total
                        ? () {
                            _page++;
                            _load();
                          }
                        : null,
                    child: const PosText('Selanjutnya'),
                  ),
                ],
              ),
            ] else ...[
              Text(
                invoice['customer_name'].toString(),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              Text('${invoice['invoice_number']} · ${invoice['status']}'),
              Text(
                posLocale(context).pos708b9937b7f6(
                  (_money(invoice['total_amount'])).toString(),
                  (_money(invoice['paid_amount'])).toString(),
                  (_money(invoice['credited_amount'])).toString(),
                  (_money(invoice['outstanding_amount'])).toString(),
                ),
              ),
              const SizedBox(height: 16),
              if (_pending != null)
                const PosText(
                  'Ada bukti belum terkonfirmasi. Data dikunci; kirim ulang bukti yang sama untuk memeriksa hasil tanpa pembayaran ganda.',
                  style: TextStyle(color: Colors.deepOrange),
                ),
              if (widget.canCollect &&
                  ((_pending != null) ||
                      (invoice['outstanding_amount'] as num) > 0)) ...[
                TextField(
                  controller: _amount,
                  enabled: !_sending && _pending == null,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: ('Jumlah penerimaan (Rp)').tr(context),
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _method,
                  decoration: InputDecoration(
                    labelText: ('Metode penerimaan').tr(context),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: PosText('Tunai')),
                    DropdownMenuItem(
                      value: 'transfer',
                      child: PosText('Transfer'),
                    ),
                    DropdownMenuItem(value: 'qris', child: PosText('QRIS')),
                  ],
                  onChanged: _sending || _pending != null
                      ? null
                      : (v) {
                          FocusScope.of(context).unfocus();
                          setState(() {
                            _method = v!;
                            _destination = '';
                          });
                        },
                ),
                DropdownButtonFormField<String>(
                  key: ValueKey('$_method:$_destination'),
                  initialValue:
                      (_method == 'cash' ? _cash : _banks).any(
                        (r) =>
                            '${r[_method == 'cash' ? 'code' : '_id']}' ==
                            _destination,
                      )
                      ? _destination
                      : null,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: _method == 'cash'
                        ? ('Akun kas Finance').tr(context)
                        : ('Rekening bank').tr(context),
                  ),
                  items: (_method == 'cash' ? _cash : _banks)
                      .map(
                        (r) => DropdownMenuItem(
                          value: '${r[_method == 'cash' ? 'code' : '_id']}',
                          child: Text(
                            '${r['code'] ?? ''} ${r['name']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: _sending || _pending != null
                      ? null
                      : (v) {
                          FocusScope.of(context).unfocus();
                          setState(() => _destination = v!);
                        },
                ),
                TextField(
                  controller: _reference,
                  enabled: !_sending && _pending == null,
                  maxLength: 300,
                  decoration: InputDecoration(
                    labelText: ('Nomor bukti / referensi penerimaan').tr(
                      context,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _sending ? null : _collect,
                  icon: _sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.payments_outlined),
                  label: Text(
                    _sending
                        ? ('Memeriksa penerimaan...').tr(context)
                        : _pending != null
                        ? ('Kirim ulang bukti yang sama').tr(context)
                        : ('Catat penerimaan').tr(context),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              const PosText(
                'Riwayat penerimaan',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              for (final payment in invoice['payments'] as List? ?? [])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${_money(payment['amount'])} · ${payment['status']}',
                  ),
                  subtitle: Text(
                    '${payment['date']} · ${payment['reference'] ?? '-'}',
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
