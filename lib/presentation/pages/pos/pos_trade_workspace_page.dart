import '../../widgets/pos_record_skeletons.dart';
import '../../widgets/pos_collapsible_filters.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/network/graphql_client_provider.dart';
import 'package:mobile_pos_pantoo/core/network/pos_financial_request_store.dart';
import 'package:mobile_pos_pantoo/core/utils/rupiah_input_formatter.dart';
import 'package:mobile_pos_pantoo/domain/models/pos_trade.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_trade_repository.dart';
import 'package:mobile_pos_pantoo/injections.dart';
import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';
import 'package:mobile_pos_pantoo/presentation/widgets/pos_metric_card.dart';

class PosTradeWorkspacePage extends StatefulWidget {
  const PosTradeWorkspacePage({
    super.key,
    required this.operatorId,
    this.repository,
    this.requestStore,
    this.initialKind = PosTradeKind.receivable,
    this.initialDocumentId,
  });
  final String operatorId;
  final PosTradeRepository? repository;
  final PosFinancialRequestStore? requestStore;
  final PosTradeKind initialKind;
  final String? initialDocumentId;
  @override
  State<PosTradeWorkspacePage> createState() => _TradeWorkspaceState();
}

class _TradeWorkspaceState extends State<PosTradeWorkspacePage> {
  late final PosTradeRepository _repo;
  late final PosFinancialRequestStore _requests;
  late PosTradeKind _kind;
  final _search = TextEditingController();
  PosTradeOptions? _options;
  PosTradePage? _page;
  PosTradeDocument? _document;
  final Map<String, Map<String, dynamic>> _pending = {};
  bool _loading = true,
      _sending = false,
      _settled = false,
      _initialOpened = false;
  String _error = '', _message = '', _pendingError = '';
  bool _loadingDetail = false;
  int _generation = 0;
  @override
  void initState() {
    super.initState();
    _repo = widget.repository ?? sl<PosTradeRepository>();
    _kind = widget.initialKind;
    _requests = widget.requestStore ?? _defaultRequests();
    _refreshPending();
    unawaited(_load());
  }

  PosFinancialRequestStore _defaultRequests() {
    final p = sl<GraphQLClientProvider>();
    return PosFinancialRequestStore(
      p.sharedPreferences,
      '${p.endpointUrl}:${p.sharedPreferences.getString('instansi_id')}:${widget.operatorId}',
    );
  }

  @override
  void dispose() {
    _generation++;
    _search.dispose();
    super.dispose();
  }

  void _refreshPending() {
    _pending.clear();
    try {
      for (final key in _requests.pendingInvoiceIds) {
        final value = _requests.load(key);
        if (value != null) _pending[key] = value;
      }
      _pendingError = '';
    } catch (error) {
      _pendingError = error.toString();
    }
  }

  String _money(num value) => NumberFormat.currency(
    locale: 'id_ID',
    symbol: 'Rp ',
    decimalDigits: 0,
  ).format(value);
  String _date(String value) {
    try {
      return DateFormat.yMMMd(
        Localizations.localeOf(context).toLanguageTag(),
      ).format(DateTime.parse(value));
    } catch (_) {
      return value;
    }
  }

  Future<void> _load() async {
    if (_sending) return;
    final ticket = ++_generation;
    setState(() {
      _loading = true;
      _loadingDetail = false;
      _page = null;
      _document = null;
      _error = '';
    });
    final result = await _repo.options();
    if (!mounted || ticket != _generation) return;
    await result.fold(
      (failure) async {
        setState(() {
          _options = null;
          _loading = false;
          _error = failure is PosTradeAccessFailure
              ? posLocale(context).tradeNoAccess
              : failure.message;
        });
      },
      (options) async {
        if (!options.viewAR &&
            _kind == PosTradeKind.receivable &&
            options.viewAP) {
          _kind = PosTradeKind.payable;
        }
        if (!options.viewAP &&
            _kind == PosTradeKind.payable &&
            options.viewAR) {
          _kind = PosTradeKind.receivable;
        }
        _options = options;
        if (!_initialOpened && widget.initialDocumentId != null) {
          _initialOpened = true;
          await _open(widget.initialKind, widget.initialDocumentId!);
          return;
        }
        await _loadPage(1, ticket: ticket);
      },
    );
  }

  Future<void> _loadPage(int page, {int? ticket}) async {
    if (_sending) return;
    final generation = ticket ?? ++_generation;
    setState(() {
      _loading = true;
      _loadingDetail = false;
      _page = null;
      _document = null;
      _error = '';
    });
    final result = await _repo.list(
      _kind,
      search: _search.text.trim(),
      page: page,
      settled: _settled,
    );
    if (!mounted || generation != _generation) return;
    setState(() {
      _loading = false;
      result.fold(
        (failure) {
          _error = failure.message;
          if (failure is AuthFailure || failure is PosTradeAccessFailure) {
            _options = null;
          }
        },
        (page) {
          _page = page;
        },
      );
      _refreshPending();
    });
  }

  Future<void> _open(PosTradeKind kind, String id) async {
    if (_sending) return;
    final ticket = ++_generation;
    setState(() {
      _loading = true;
      _loadingDetail = true;
      _document = null;
      _error = '';
    });
    final result = await _repo.detail(kind, id);
    if (!mounted || ticket != _generation) return;
    setState(() {
      _loading = false;
      result.fold(
        (failure) {
          _error = failure.message;
        },
        (doc) {
          if (doc.kind != kind || doc.id != id) {
            _options = null;
            _error = posLocale(context).tradeNoAccess;
            return;
          }
          _kind = kind;
          _document = doc;
        },
      );
    });
  }

  Map<String, dynamic> _normalizePending(Map<String, dynamic> input) {
    // Upgrade old POS receipt attempts without changing their durable invoice
    // request ID, amount, reference or cash/bank destination.
    if (input['invoice_id'] != null) {
      return {
        'kind': 'receivable',
        'document_id': input['invoice_id'],
        'amount': input['amount'],
        'date': input['date'],
        'method': input['payment_method'],
        'reference': input['reference'],
        'request_id': input['request_id'],
        if (input['bank_account_id'] != null)
          'bank_id': input['bank_account_id'],
        if (input['cash_account_code'] != null)
          'cash_account': input['cash_account_code'],
      };
    }
    return input;
  }

  Future<void> _submit(String key, Map<String, dynamic> input) async {
    if (_sending || _pendingError.isNotEmpty) return;
    final ticket = _generation;
    setState(() {
      _sending = true;
      _error = '';
      _message = '';
    });
    try {
      final frozen = await _requests.begin(key, input),
          payload = _normalizePending(frozen);
      final creating = key.startsWith('create:');
      final result = creating
          ? await _repo.create(payload)
          : await _repo.pay(payload);
      if (!mounted || ticket != _generation) return;
      final failure = result.fold<Failure?>((f) => f, (_) => null);
      if (failure != null) {
        if (failure is PosTradeRejectedFailure) {
          await _requests.acknowledge(key);
        }
        if (!mounted) return;
        setState(() {
          _error = failure is PosTradeUnconfirmedFailure
              ? posLocale(context).tradeUnknown
              : failure.message;
          if (failure is AuthFailure || failure is PosTradeAccessFailure) {
            _options = null;
            _document = null;
            _page = null;
          }
        });
        return;
      }
      final doc = result.getOrElse(
        () => throw StateError('Missing trade response'),
      );
      await _requests.acknowledge(key);
      if (!mounted || ticket != _generation) return;
      setState(() {
        _document = doc;
        _kind = doc.kind;
        _message = creating
            ? posLocale(context).tradeCreateSuccess
            : posLocale(context).tradePaySuccess;
      });
    } catch (error) {
      if (mounted && ticket == _generation) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted && ticket == _generation) {
        setState(() {
          _sending = false;
          _refreshPending();
        });
      }
    }
  }

  Future<void> _create() async {
    final options = _options;
    if (options == null || !options.canCreate(_kind) || _sending) return;
    final key = 'create:${_kind.name}', pending = _requests.load(key);
    if (pending != null) {
      await _submit(key, pending);
      return;
    }
    final generation = _generation;
    final input = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _TradeEntryForm(options: options, kind: _kind),
    );
    if (!mounted || generation != _generation || input == null) return;
    await _submit(key, input);
  }

  Future<void> _pay() async {
    final doc = _document, options = _options;
    if (doc == null || options == null || !doc.canPay || _sending) return;
    final key = 'pay:${doc.kind.name}:${doc.id}';
    final legacy = doc.kind == PosTradeKind.receivable
        ? _requests.load(doc.id)
        : null;
    if (legacy != null) {
      await _submit(doc.id, legacy);
      return;
    }
    final pending = _requests.load(key);
    if (pending != null) {
      await _submit(key, pending);
      return;
    }
    final generation = _generation;
    final input = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => _TradePaymentForm(options: options, document: doc),
    );
    if (!mounted || generation != _generation || input == null) return;
    await _submit(key, input);
  }

  @override
  Widget build(BuildContext context) {
    final l = posLocale(context),
        options = _options,
        doc = _document,
        page = _page;
    return Material(
      color: const Color(0xFFF7F8FA),
      child: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l.tradeTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _sending ? null : _load,
                  tooltip: l.financialRefresh,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              l.tradePaymentNote,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF667085),
                height: 1.5,
              ),
            ),
            if (_pendingError.isNotEmpty) _notice(_pendingError),
            if (_pending.isNotEmpty) ...[
              const SizedBox(height: 12),
              _notice(l.tradePendingNote),
              for (final entry in _pending.entries)
                Card(
                  elevation: 0,
                  child: ListTile(
                    title: Text(l.tradePending),
                    subtitle: Text(entry.value['reference']?.toString() ?? ''),
                    trailing: TextButton(
                      onPressed: _sending
                          ? null
                          : () => _submit(entry.key, entry.value),
                      child: Text(l.tradeRetrySame),
                    ),
                  ),
                ),
            ],
            if (_message.isNotEmpty) _notice(_message),
            if (_error.isNotEmpty) ...[
              _notice(_error),
              TextButton(
                onPressed: _sending ? null : _load,
                child: Text(l.financialRetry),
              ),
            ],
            if (options != null) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (options.viewAR)
                    ChoiceChip(
                      label: Text(l.businessReceivables),
                      selected: _kind == PosTradeKind.receivable,
                      onSelected: _sending
                          ? null
                          : (_) {
                              _kind = PosTradeKind.receivable;
                              _search.clear();
                              _settled = false;
                              _message = '';
                              _loadPage(1);
                            },
                    ),
                  if (options.viewAP)
                    ChoiceChip(
                      label: Text(l.businessPayables),
                      selected: _kind == PosTradeKind.payable,
                      onSelected: _sending
                          ? null
                          : (_) {
                              _kind = PosTradeKind.payable;
                              _search.clear();
                              _settled = false;
                              _message = '';
                              _loadPage(1);
                            },
                    ),
                ],
              ),
              if (_kind == PosTradeKind.receivable && options.arScope == 'pos')
                _notice(l.tradePOSScope),
              if (doc == null && options.canCreate(_kind))
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: FilledButton.icon(
                    onPressed: _loading || _sending || _pendingError.isNotEmpty
                        ? null
                        : _create,
                    icon: const Icon(Icons.add),
                    label: Text(l.tradeCreate),
                  ),
                ),
            ],
            if (_loading)
              PosTradeContentSkeleton(
                detail:
                    _loadingDetail ||
                    (!_initialOpened && widget.initialDocumentId != null),
              ),
            if (_sending)
              const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (!_loading && options != null && doc == null) ...[
              const SizedBox(height: 16),
              PosCollapsibleFilters(
                toggleKey: const Key('trade_filter_toggle'),
                activeCount: [
                  _search.text.trim().isNotEmpty,
                  _settled,
                ].where((active) => active).length,
                child: Column(
                  children: [
                    TextField(
                      controller: _search,
                      enabled: !_sending,
                      onChanged: (_) => setState(() {}),
                      maxLength: 120,
                      decoration: InputDecoration(
                        labelText: l.tradeSearch,
                        counterText: '',
                        suffixIcon: IconButton(
                          onPressed: _sending ? null : () => _loadPage(1),
                          icon: const Icon(Icons.search),
                        ),
                      ),
                      onSubmitted: (_) => _loadPage(1),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l.tradeSettled),
                      value: _settled,
                      onChanged: _sending
                          ? null
                          : (value) {
                              _settled = value;
                              _loadPage(1);
                            },
                    ),
                  ],
                ),
              ),
              if (page != null) ...[
                PosMetricGrid(
                  children: [
                    PosMetricCard(
                      title: l.businessOutstanding,
                      value: _money(page.outstanding),
                      icon: Icons.account_balance_wallet_outlined,
                      description: l.businessAllSources,
                    ),
                    PosMetricCard(
                      title: l.businessOpenDocuments,
                      value: '${page.totalCount}',
                      icon: Icons.description_outlined,
                      description: l.businessAllSources,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (page.items.isEmpty) Text(l.businessEmpty),
                for (final item in page.items)
                  Card(
                    elevation: 0,
                    child: ListTile(
                      onTap: _sending ? null : () => _open(item.kind, item.id),
                      title: Text(item.party),
                      subtitle: Text(
                        '${item.reference.isEmpty ? item.number : item.reference}\n${l.businessOutstanding}: ${_money(item.outstanding)}',
                      ),
                      isThreeLine: true,
                      trailing: const Icon(Icons.chevron_right),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(child: Text('${l.businessPage} ${page.page}')),
                    TextButton(
                      onPressed: _sending || page.page <= 1
                          ? null
                          : () => _loadPage(page.page - 1),
                      child: Text(l.financialPrevious),
                    ),
                    TextButton(
                      onPressed:
                          _sending || page.page * page.limit >= page.totalCount
                          ? null
                          : () => _loadPage(page.page + 1),
                      child: Text(l.financialNext),
                    ),
                  ],
                ),
              ],
            ],
            if (!_loading && doc != null) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _sending
                      ? null
                      : () => _loadPage(_page?.page ?? 1),
                  icon: const Icon(Icons.arrow_back),
                  label: Text(l.businessDetails),
                ),
              ),
              Text(
                doc.party,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(doc.reference.isEmpty ? doc.number : doc.reference),
              Text(
                '${l.businessDate}: ${_date(doc.date)} · ${l.businessDueDate}: ${doc.dueDate == null ? '—' : _date(doc.dueDate!)}',
                style: const TextStyle(fontSize: 12, height: 1.6),
              ),
              if (doc.basis == 'opening') _notice(l.tradeOpeningNote),
              const SizedBox(height: 14),
              PosMetricGrid(
                children: [
                  PosMetricCard(
                    title: l.businessAmount,
                    value: _money(doc.amount),
                    icon: Icons.description_outlined,
                  ),
                  PosMetricCard(
                    title: l.businessOutstanding,
                    value: _money(doc.outstanding),
                    icon: Icons.account_balance_wallet_outlined,
                  ),
                  PosMetricCard(
                    title: l.businessPaid,
                    value: _money(doc.paid),
                    icon: Icons.payments_outlined,
                  ),
                  if (doc.credited > 0)
                    PosMetricCard(
                      title: l.businessCredited,
                      value: _money(doc.credited),
                      icon: Icons.undo_outlined,
                    ),
                  if (doc.withheld > 0)
                    PosMetricCard(
                      title: l.businessWithheld,
                      value: _money(doc.withheld),
                      icon: Icons.receipt_outlined,
                    ),
                ],
              ),
              if (doc.canPay && options?.canPay(doc.kind) == true)
                Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: FilledButton.icon(
                    onPressed: _sending || _pendingError.isNotEmpty
                        ? null
                        : _pay,
                    icon: const Icon(Icons.payments_outlined),
                    label: Text(
                      doc.kind == PosTradeKind.receivable
                          ? l.tradeReceive
                          : l.tradePay,
                    ),
                  ),
                ),
              if (doc.notes.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(doc.notes),
                ),
              const SizedBox(height: 24),
              Text(
                l.tradeHistory,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (doc.payments.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(l.tradeNoHistory),
                ),
              if (doc.paymentCount > doc.payments.length)
                Text(
                  '${doc.payments.length}/${doc.paymentCount} · ${l.tradeLastHistory}',
                  style: const TextStyle(fontSize: 12),
                ),
              for (final payment in doc.payments)
                Card(
                  elevation: 0,
                  child: ListTile(
                    title: Text(_money(payment.amount)),
                    subtitle: Text(
                      '${_date(payment.date)} · ${payment.reference}\n${posStatusLabel(payment.status, context)}',
                    ),
                    isThreeLine: true,
                    onTap: () => showDialog<void>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: Text(l.tradeProof),
                        content: SingleChildScrollView(
                          child: Text(
                            '${doc.party}\n${doc.reference.isEmpty ? doc.number : doc.reference}\n${_money(payment.amount)}\n${_date(payment.date)}\n${payment.reference}\n${posStatusLabel(payment.status, context)}\n${payment.verified ? '${l.tradeJournal}: ${payment.journalNumber}' : l.tradeUnverified}',
                          ),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: Text(l.tradeCancel),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _notice(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E7EC)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, height: 1.5)),
    ),
  );
}

class _TradeEntryForm extends StatefulWidget {
  const _TradeEntryForm({required this.options, required this.kind});
  final PosTradeOptions options;
  final PosTradeKind kind;
  @override
  State<_TradeEntryForm> createState() => _TradeEntryFormState();
}

class _TradeEntryFormState extends State<_TradeEntryForm> {
  final _form = GlobalKey<FormState>(),
      _party = TextEditingController(),
      _reference = TextEditingController(),
      _amount = TextEditingController(),
      _notes = TextEditingController();
  late String _date, _due;
  String _basis = 'transaction', _control = '', _counter = '', _customer = '';
  @override
  void initState() {
    super.initState();
    _date = widget.options.today;
    _due = _date;
  }

  @override
  void dispose() {
    _party.dispose();
    _reference.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pick(bool due) async {
    final day = await showDatePicker(
      context: context,
      initialDate: DateTime.parse(due ? _due : _date),
      firstDate: DateTime(2000),
      lastDate: due ? DateTime(2100) : DateTime.parse(widget.options.today),
    );
    if (!mounted || day == null) return;
    setState(() {
      final value = DateFormat('yyyy-MM-dd').format(day);
      if (due) {
        _due = value;
      } else {
        _date = value;
        if (_due.compareTo(_date) < 0) _due = _date;
      }
    });
  }

  Future<void> _save() async {
    final l = posLocale(context);
    if (!_form.currentState!.validate()) return;
    if (_due.compareTo(_date) < 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.tradeInvalidDate)));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.tradeConfirm),
        content: Text(
          '${l.tradeConfirmNote}\n\n${_customer.isEmpty ? _party.text : widget.options.list('customers').firstWhere((c) => c['id'] == _customer)['name']}\n${_reference.text}\nRp ${_amount.text}\n${_basis == 'opening' ? l.tradeOpeningNote : l.tradeNewBill}\n${l.businessDate}: $_date\n${l.businessDueDate}: $_due\n${l.tradeControl}: $_control\n${l.tradeCounter}: $_counter',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.tradeCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.tradeContinue),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    Navigator.pop(context, {
      'kind': widget.kind.name,
      'basis': _basis,
      if (_customer.isNotEmpty)
        'party_id': _customer
      else
        'party_name': _party.text.trim(),
      'reference': _reference.text.trim(),
      'date': _date,
      'due_date': _due,
      'amount': parseRupiahAmount(_amount.text),
      'control_account': _control,
      'counter_account': _counter,
      'notes': _notes.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = posLocale(context), ar = widget.kind == PosTradeKind.receivable;
    final controls = widget.options.list(ar ? 'ar_accounts' : 'ap_accounts'),
        counters = widget.options.list(
          _basis == 'opening'
              ? 'opening_accounts'
              : ar
              ? 'income_accounts'
              : 'expense_accounts',
        );
    if (!controls.any((a) => a['code'] == _control)) {
      _control = controls.firstOrNull?['code'] as String? ?? '';
    }
    if (!counters.any((a) => a['code'] == _counter)) {
      _counter = counters.firstOrNull?['code'] as String? ?? '';
    }
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l.tradeCreate,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                l.tradeManualNote,
                style: const TextStyle(fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _basis,
                isExpanded: true,
                decoration: InputDecoration(labelText: l.tradeDetails),
                items: [
                  DropdownMenuItem(
                    value: 'transaction',
                    child: Text(l.tradeNewBill),
                  ),
                  DropdownMenuItem(
                    value: 'opening',
                    child: Text(l.tradeOpening),
                  ),
                ],
                onChanged: (v) => setState(() => _basis = v!),
              ),
              if (_basis == 'opening')
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Text(
                    l.tradeOpeningNote,
                    style: const TextStyle(fontSize: 12, height: 1.5),
                  ),
                ),
              if (ar && widget.options.list('customers').isNotEmpty)
                DropdownButtonFormField<String>(
                  initialValue: '',
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: l.tradeExistingCustomer,
                  ),
                  items: [
                    DropdownMenuItem(
                      value: '',
                      child: Text(l.tradeNewCustomer),
                    ),
                    for (final c in widget.options.list('customers'))
                      DropdownMenuItem(
                        value: c['id'] as String,
                        child: Text(
                          '${c['name']}${(c['address'] as String?)?.isNotEmpty == true ? ' · ${c['address']}' : ''}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _customer = v ?? ''),
                ),
              if (_customer.isEmpty)
                TextFormField(
                  controller: _party,
                  decoration: InputDecoration(
                    labelText: ar ? l.tradeCustomer : l.tradeSupplier,
                  ),
                  maxLength: 200,
                  validator: (v) =>
                      v?.trim().isNotEmpty == true ? null : l.tradeRequired,
                ),
              TextFormField(
                controller: _reference,
                decoration: InputDecoration(labelText: l.businessReference),
                maxLength: 100,
                validator: (v) =>
                    v?.trim().isNotEmpty == true ? null : l.tradeRequired,
              ),
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                inputFormatters: const [RupiahInputFormatter()],
                decoration: InputDecoration(
                  labelText: l.businessAmount,
                  prefixText: 'Rp ',
                ),
                validator: (v) {
                  final n = parseRupiahAmount(v ?? '');
                  return n > 0 && n <= 9007199254740991 && n == n.round()
                      ? null
                      : l.tradeInvalidAmount;
                },
              ),
              Wrap(
                spacing: 8,
                children: [
                  TextButton.icon(
                    onPressed: () => _pick(false),
                    icon: const Icon(Icons.event_outlined),
                    label: Text('${l.businessDate}: $_date'),
                  ),
                  TextButton.icon(
                    onPressed: () => _pick(true),
                    icon: const Icon(Icons.event_outlined),
                    label: Text('${l.businessDueDate}: $_due'),
                  ),
                ],
              ),
              DropdownButtonFormField<String>(
                key: ValueKey('control:$_control'),
                initialValue: _control.isEmpty ? null : _control,
                isExpanded: true,
                decoration: InputDecoration(labelText: l.tradeControl),
                items: [
                  for (final a in controls)
                    DropdownMenuItem(
                      value: a['code'] as String,
                      child: Text(
                        a['name'] as String,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _control = v!),
              ),
              DropdownButtonFormField<String>(
                key: ValueKey('counter:$_basis:$_counter'),
                initialValue: _counter.isEmpty ? null : _counter,
                isExpanded: true,
                decoration: InputDecoration(labelText: l.tradeCounter),
                items: [
                  for (final a in counters)
                    DropdownMenuItem(
                      value: a['code'] as String,
                      child: Text(
                        a['name'] as String,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (v) => setState(() => _counter = v!),
              ),
              TextFormField(
                controller: _notes,
                decoration: InputDecoration(labelText: l.tradeNotes),
                maxLength: 1000,
                minLines: 1,
                maxLines: 3,
              ),
              if (_control.isEmpty || _counter.isEmpty)
                Text(l.tradeNoAccounts, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: _control.isEmpty || _counter.isEmpty ? null : _save,
                child: Text(l.tradeSave),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TradePaymentForm extends StatefulWidget {
  const _TradePaymentForm({required this.options, required this.document});
  final PosTradeOptions options;
  final PosTradeDocument document;
  @override
  State<_TradePaymentForm> createState() => _TradePaymentFormState();
}

class _TradePaymentFormState extends State<_TradePaymentForm> {
  final _form = GlobalKey<FormState>(),
      _amount = TextEditingController(),
      _reference = TextEditingController(),
      _notes = TextEditingController();
  late String _date;
  String _method = 'transfer', _bank = '', _cash = '';
  int? _term;
  double get _maximum => _term == null
      ? widget.document.outstanding
      : widget.document.terms
            .where((t) => t['number'] == _term)
            .map((t) => (t['outstanding'] as num).toDouble())
            .first;
  @override
  void initState() {
    super.initState();
    _date = widget.options.today;
    final terms = widget.document.terms
        .where((t) => (t['outstanding'] as num) > 0)
        .toList();
    _term = terms.firstOrNull?['number'] as int?;
    _amount.text = formatRupiahAmount(_maximum);
    final banks = widget.options.list('banks'),
        cash = widget.options.list('cash_accounts');
    _bank = banks.firstOrNull?['id'] as String? ?? '';
    _cash = cash.firstOrNull?['code'] as String? ?? '';
    if (_bank.isEmpty) _method = 'cash';
  }

  @override
  void dispose() {
    _amount.dispose();
    _reference.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final l = posLocale(context), doc = widget.document;
    if (!_form.currentState!.validate()) return;
    final n = parseRupiahAmount(_amount.text);
    if (n <= 0 || n > _maximum || n != n.round()) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l.tradeInvalidAmount)));
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l.tradeConfirm),
        content: Text(
          '${l.tradeConfirmNote}\n\n${doc.party}\n${doc.reference.isEmpty ? doc.number : doc.reference}\nRp ${_amount.text}\n$_date\n${_reference.text}\n${_method == 'transfer' ? '${l.tradeTransfer} · ${widget.options.list('banks').firstWhere((b) => b['id'] == _bank)['name']}' : '${l.tradeCash} · ${doc.kind == PosTradeKind.receivable ? _cash : widget.options.data['ap_cash_name'] ?? ''}'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l.tradeCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l.tradeContinue),
          ),
        ],
      ),
    );
    if (!mounted || confirmed != true) return;
    Navigator.pop(context, {
      'kind': doc.kind.name,
      'document_id': doc.id,
      if (_term != null) 'no_termin': _term,
      'amount': n,
      'date': _date,
      'method': _method,
      'reference': _reference.text.trim(),
      if (_method == 'transfer') 'bank_id': _bank,
      if (_method == 'cash' && doc.kind == PosTradeKind.receivable)
        'cash_account': _cash,
      'notes': _notes.text.trim(),
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = posLocale(context),
        doc = widget.document,
        ar = doc.kind == PosTradeKind.receivable,
        banks = widget.options.list('banks'),
        cash = widget.options.list('cash_accounts');
    final cashReady = ar ? cash.isNotEmpty : widget.options.apCashAvailable,
        ready = _method == 'transfer'
            ? _bank.isNotEmpty
            : cashReady && (!ar || _cash.isNotEmpty);
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.viewInsetsOf(context).bottom + 24,
      ),
      child: Form(
        key: _form,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                ar ? l.tradeReceive : l.tradePay,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(doc.party),
              Text(
                l.tradePaymentNote,
                style: const TextStyle(fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 16),
              if (doc.terms.isNotEmpty)
                DropdownButtonFormField<int>(
                  initialValue: _term,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Termin'),
                  items: [
                    for (final term in doc.terms.where(
                      (t) => (t['outstanding'] as num) > 0,
                    ))
                      DropdownMenuItem(
                        value: term['number'] as int,
                        child: Text(
                          'Termin ${term['number']} · Rp ${formatRupiahAmount((term['outstanding'] as num).toDouble())}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) => setState(() {
                    _term = value;
                    _amount.text = formatRupiahAmount(_maximum);
                  }),
                ),
              if (_method == 'cash' && !ar)
                Text(
                  '${l.tradeCashAccount}: ${widget.options.data['ap_cash_name'] ?? '—'}',
                ),
              TextFormField(
                controller: _amount,
                keyboardType: TextInputType.number,
                inputFormatters: const [RupiahInputFormatter()],
                decoration: InputDecoration(
                  labelText: l.businessAmount,
                  prefixText: 'Rp ',
                ),
                validator: (v) {
                  final n = parseRupiahAmount(v ?? '');
                  return n > 0 && n <= _maximum ? null : l.tradeInvalidAmount;
                },
              ),
              TextFormField(
                controller: _reference,
                maxLength: 300,
                decoration: InputDecoration(labelText: l.businessReference),
                validator: (v) =>
                    v?.trim().isNotEmpty == true ? null : l.tradeRequired,
              ),
              TextButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.parse(_date),
                    firstDate: DateTime.parse(doc.date),
                    lastDate: DateTime.parse(widget.options.today),
                  );
                  if (mounted && picked != null) {
                    setState(
                      () => _date = DateFormat('yyyy-MM-dd').format(picked),
                    );
                  }
                },
                icon: const Icon(Icons.event_outlined),
                label: Text('${l.businessDate}: $_date'),
              ),
              DropdownButtonFormField<String>(
                initialValue: _method,
                isExpanded: true,
                decoration: InputDecoration(labelText: l.businessDetails),
                items: [
                  DropdownMenuItem(
                    value: 'transfer',
                    child: Text(l.tradeTransfer),
                  ),
                  DropdownMenuItem(value: 'cash', child: Text(l.tradeCash)),
                ],
                onChanged: (v) => setState(() => _method = v!),
              ),
              if (_method == 'transfer')
                DropdownButtonFormField<String>(
                  initialValue: _bank.isEmpty ? null : _bank,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.tradeBank),
                  items: [
                    for (final b in banks)
                      DropdownMenuItem(
                        value: b['id'] as String,
                        child: Text(
                          '${b['name']} ${b['account_number']}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _bank = v!),
                ),
              if (_method == 'cash' && ar)
                DropdownButtonFormField<String>(
                  initialValue: _cash.isEmpty ? null : _cash,
                  isExpanded: true,
                  decoration: InputDecoration(labelText: l.tradeCashAccount),
                  items: [
                    for (final c in cash)
                      DropdownMenuItem(
                        value: c['code'] as String,
                        child: Text(
                          c['name'] as String,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) => setState(() => _cash = v!),
                ),
              TextFormField(
                controller: _notes,
                maxLength: 1000,
                minLines: 1,
                maxLines: 3,
                decoration: InputDecoration(labelText: l.tradeNotes),
              ),
              if (!ready)
                Text(l.tradeNoAccounts, style: const TextStyle(fontSize: 12)),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: ready ? _save : null,
                child: Text(ar ? l.tradeReceive : l.tradePay),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
