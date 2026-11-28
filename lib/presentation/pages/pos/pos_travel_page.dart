import 'package:flutter/material.dart';
import '../../../core/network/graphql_client_provider.dart';
import '../../../domain/repositories/pos_travel_repository.dart';
import '../../../injections.dart';
import '../../widgets/pos_keyboard_stable_dialog.dart';
import '../../widgets/pos_operational_toolbar.dart';
import 'utils/pos_travel_copy.dart';
import 'widgets/pos_travel_forms.dart';

class PosTravelPage extends StatefulWidget {
  const PosTravelPage({super.key, this.repository, this.initialStoreId});
  final PosTravelRepository? repository;
  final String? initialStoreId;
  @override
  State<PosTravelPage> createState() => _TravelState();
}

class _TravelState extends State<PosTravelPage> {
  late final repo =
      widget.repository ?? PosTravelRepository(sl<GraphQLClientProvider>());
  late final owner = repo.scope;
  final search = TextEditingController();
  List<Map<String, dynamic>> stores = [], rows = [];
  Map<String, dynamic> permissions = {};
  Map<String, dynamic>? pending;
  String store = '', kind = 'Bookings', error = '';
  int page = 1, total = 0, storePage = 1, storeTotal = 0, seq = 0;
  bool loading = true,
      busy = false,
      active = false,
      travel = false,
      corrupt = false;
  bool get current => mounted && owner == repo.scope;
  bool get locked =>
      busy ||
      loading ||
      pending != null ||
      corrupt ||
      !active ||
      !travel ||
      !current;
  @override
  void initState() {
    super.initState();
    store = widget.initialStoreId ?? '';
    initialize();
  }

  @override
  void dispose() {
    seq++;
    search.dispose();
    super.dispose();
  }

  Future<void> initialize({int? storesPage}) async {
    final generation = ++seq;
    setState(() => loading = true);
    try {
      pending = repo.pending();
      store = pending?['input']['toko_id']?.toString() ?? store;
      final data = await repo.read('TravelStores', {
        'page': storesPage ?? storePage,
        if (store.isNotEmpty) 'selected_toko_id': store,
      });
      if (!current || generation != seq) return;
      stores = (data['items'] as List)
          .map((v) => Map<String, dynamic>.from(v as Map))
          .toList();
      final selected = data['selected'] is Map
          ? Map<String, dynamic>.from(data['selected'] as Map)
          : null;
      if (selected != null && !stores.any((r) => r['_id'] == selected['_id'])) {
        stores.insert(0, selected);
      }
      if (store.isEmpty || !stores.any((r) => r['_id'] == store)) {
        store = stores.firstOrNull?['_id']?.toString() ?? '';
      }
      active = stores.any((r) => r['_id'] == store && r['status'] == 'active');
      travel = data['business_profile'] == 'travel';
      permissions = Map<String, dynamic>.from(
        data['permissions'] as Map? ?? {},
      );
      storePage = storesPage ?? storePage;
      storeTotal = data['totalCount'] as int;
      corrupt = false;
      if (store.isNotEmpty) await load();
    } catch (e) {
      if (mounted) {
        setState(() {
          error = travelError(e);
          corrupt = true;
        });
      }
    } finally {
      if (current && generation == seq) setState(() => loading = false);
    }
  }

  Future<void> load() async {
    final generation = ++seq;
    setState(() {
      loading = true;
      rows = [];
      error = '';
    });
    try {
      final result = await repo.read('Travel$kind', {
        'input': {
          'toko_id': store,
          'page': page,
          'limit': 20,
          'search': search.text.trim(),
        },
      });
      if (!current || generation != seq) return;
      setState(() {
        rows = (result['items'] as List)
            .map((v) => Map<String, dynamic>.from(v as Map))
            .toList();
        total = result['totalCount'] as int;
        pending = repo.pending();
      });
    } catch (e) {
      if (current && generation == seq) setState(() => error = travelError(e));
    } finally {
      if (current && generation == seq) setState(() => loading = false);
    }
  }

  Future<void> recovery(bool resolve) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = '';
    });
    try {
      final previous = pending;
      final result = resolve ? await repo.resolve() : await repo.recover();
      if (!current) return;
      pending = repo.pending();
      await initialize();
      if (!current) return;
      final booking =
          result['booking_id'] ??
          previous?['input']['booking_id'] ??
          (previous?['operation'] == 'createBooking' ? result['_id'] : null);
      if (booking != null && result['status'] != 'cancelled') {
        await detail('$booking');
      }
    } catch (e) {
      if (mounted) setState(() => error = travelError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> detail(String id) async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => PosTravelBookingPage(
          repository: repo,
          storeId: store,
          bookingId: id,
        ),
      ),
    );
    if (current) await initialize();
  }

  Future<void> create() async {
    if (locked) return;
    if (kind == 'Bookings') {
      final result = await Navigator.push<Map<String, dynamic>>(
        context,
        MaterialPageRoute(
          builder: (_) => PosTravelDraftPage(repository: repo, storeId: store),
        ),
      );
      if (!current) return;
      await initialize();
      if (current && result != null) await detail('${result['_id']}');
    } else {
      final input = await showDialog<Map<String, dynamic>>(
        context: context,
        builder: (_) => PosTravelMasterDialog(
          repository: repo,
          storeId: store,
          departure: kind == 'Departures',
        ),
      );
      if (input == null || !current) return;
      setState(() => busy = true);
      try {
        await repo.submit(
          kind == 'Departures' ? 'createDeparture' : 'createPackage',
          {'toko_id': store, ...input},
        );
        if (current) await initialize();
      } catch (e) {
        if (mounted) {
          setState(() {
            error = travelError(e);
            pending = repo.pending();
          });
        }
      } finally {
        if (mounted) setState(() => busy = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!current) {
      return Center(
        child: Text(
          travelText(
            context,
            'Sesi berubah. Buka ulang Booking Travel.',
            'Session changed. Reopen Travel.',
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: initialize,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (error.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      error,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                if (error.isNotEmpty)
                  TextButton(
                    onPressed: busy || loading ? null : initialize,
                    child: Text(travelText(context, 'Muat ulang', 'Retry')),
                  ),
                if (pending != null)
                  PosTravelRecovery(
                    busy: busy,
                    onRetry: () => recovery(false),
                    onResolve: () => recovery(true),
                  ),
                if (stores.isNotEmpty)
                  DropdownButtonFormField<String>(
                    key: ValueKey(store),
                    initialValue: store,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: travelText(
                        context,
                        'Toko Travel',
                        'Travel store',
                      ),
                    ),
                    items: [
                      for (final row in stores)
                        DropdownMenuItem(
                          value: '${row['_id']}',
                          child: Text('${row['nama_toko']}'),
                        ),
                    ],
                    onChanged: busy || loading || pending != null
                        ? null
                        : (v) {
                            setState(() {
                              store = v!;
                              page = 1;
                              active = stores.any(
                                (r) =>
                                    r['_id'] == store &&
                                    r['status'] == 'active',
                              );
                            });
                            load();
                          },
                  ),
                if (storeTotal > 20)
                  Row(
                    children: [
                      IconButton(
                        onPressed: !busy && pending == null && storePage > 1
                            ? () => initialize(storesPage: storePage - 1)
                            : null,
                        icon: const Icon(Icons.chevron_left),
                      ),
                      Expanded(child: Text('$storePage · $storeTotal')),
                      IconButton(
                        onPressed:
                            !busy &&
                                pending == null &&
                                storePage * 20 < storeTotal
                            ? () => initialize(storesPage: storePage + 1)
                            : null,
                        icon: const Icon(Icons.chevron_right),
                      ),
                    ],
                  ),
                if (!travel || !active)
                  Text(
                    travelText(
                      context,
                      'Riwayat dapat dibaca. Aktifkan profil Travel dan toko untuk mengubah booking.',
                      'History is readable. An active Travel profile and store are required for changes.',
                    ),
                  ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: kind,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: travelText(
                      context,
                      'Bagian Travel',
                      'Travel section',
                    ),
                  ),
                  items: [
                    DropdownMenuItem(
                      value: 'Bookings',
                      child: Text(travelText(context, 'Booking', 'Bookings')),
                    ),
                    DropdownMenuItem(
                      value: 'Departures',
                      child: Text(
                        travelText(context, 'Keberangkatan', 'Departures'),
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'Packages',
                      child: Text(
                        travelText(
                          context,
                          'Paket / Rute',
                          'Packages / Routes',
                        ),
                      ),
                    ),
                  ],
                  onChanged: busy || loading
                      ? null
                      : (v) {
                          setState(() {
                            kind = v!;
                            page = 1;
                            search.clear();
                          });
                          if (store.isNotEmpty) load();
                        },
                ),
                const SizedBox(height: 12),
                PosOperationalToolbar(
                  search: TextField(
                    controller: search,
                    decoration: InputDecoration(
                      labelText: travelText(
                        context,
                        'Cari booking / nama / kode',
                        'Search booking / name / code',
                      ),
                      suffixIcon: IconButton(
                        tooltip: travelText(context, 'Cari', 'Search'),
                        onPressed: store.isEmpty || loading
                            ? null
                            : () {
                                page = 1;
                                load();
                              },
                        icon: const Icon(Icons.search),
                      ),
                    ),
                    onSubmitted: (_) {
                      page = 1;
                      if (store.isNotEmpty) load();
                    },
                  ),
                  primaryAction:
                      (kind == 'Bookings'
                              ? permissions['create_booking']
                              : permissions['manage_master']) ==
                          true
                      ? FilledButton.icon(
                          onPressed: locked ? null : create,
                          icon: const Icon(Icons.add),
                          label: Text(travelText(context, 'Tambah', 'Add')),
                        )
                      : null,
                ),
              ],
            ),
          ),
          if (loading) const LinearProgressIndicator(),
          ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            physics: const NeverScrollableScrollPhysics(),
            children: [
              if (rows.isEmpty && !loading)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    travelText(
                      context,
                      'Belum ada data sesuai pencarian.',
                      'No matching records.',
                    ),
                  ),
                ),
              for (final row in rows)
                Card(
                  color: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: const BorderSide(color: Color(0xFFE1E5E9)),
                  ),
                  child: ListTile(
                    title: Text(
                      '${row['number'] ?? row['name'] ?? row['code']}',
                    ),
                    isThreeLine: true,
                    subtitle: Text(
                      kind == 'Bookings'
                          ? '${row['customer_name']} · ${travelStatus(context, row['status'])}\n${travelStatus(context, row['payment_status'])} · ${travelMoney(row['outstanding_amount'] ?? row['total_amount'])}'
                          : kind == 'Departures'
                          ? '${travelDate(row['starts_at'])}\n${row['available_seats']} ${travelText(context, 'kursi tersedia', 'seats available')}'
                          : '${travelMoney(row['adult_price'])} · ${travelText(context, 'dewasa', 'adult')}\n${travelMoney(row['child_price'])} · ${travelText(context, 'anak', 'child')}',
                    ),
                    trailing: kind == 'Bookings'
                        ? const Icon(Icons.chevron_right)
                        : null,
                    onTap: kind == 'Bookings' && !busy
                        ? () => detail('${row['_id']}')
                        : null,
                  ),
                ),
              Row(
                children: [
                  IconButton(
                    onPressed: !loading && page > 1
                        ? () {
                            page--;
                            load();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(child: Text('$page · $total')),
                  IconButton(
                    onPressed: !loading && page * 20 < total
                        ? () {
                            page++;
                            load();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PosTravelRecovery extends StatelessWidget {
  const PosTravelRecovery({
    super.key,
    required this.busy,
    required this.onRetry,
    required this.onResolve,
  });
  final bool busy;
  final VoidCallback onRetry, onResolve;
  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFFFFF3D1),
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            travelText(
              context,
              'Hasil permintaan belum dipastikan. Jangan menerima dana dua kali. Pulihkan permintaan yang sama; atau periksa/hentikan permintaan yang belum tersimpan.',
              'The outcome is unconfirmed. Do not collect funds twice. Recover the same request, or resolve/stop a request not yet committed.',
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: busy ? null : onRetry,
                child: Text(
                  travelText(context, 'Pulihkan permintaan', 'Recover request'),
                ),
              ),
              TextButton(
                onPressed: busy ? null : onResolve,
                child: Text(
                  travelText(
                    context,
                    'Periksa / hentikan permintaan',
                    'Resolve / stop request',
                  ),
                ),
              ),
            ],
          ),
          if (busy) const LinearProgressIndicator(),
        ],
      ),
    ),
  );
}

class PosTravelBookingPage extends StatefulWidget {
  const PosTravelBookingPage({
    super.key,
    required this.repository,
    required this.storeId,
    required this.bookingId,
  });
  final PosTravelRepository repository;
  final String storeId, bookingId;
  @override
  State<PosTravelBookingPage> createState() => _BookingState();
}

class _BookingState extends State<PosTravelBookingPage> {
  Map<String, dynamic>? booking;
  Map<String, dynamic> options = {};
  bool loading = true, busy = false;
  String error = '';
  late final owner = widget.repository.scope;
  int sequence = 0;
  bool get current => mounted && owner == widget.repository.scope;
  bool get pending {
    try {
      return widget.repository.pending() != null;
    } catch (_) {
      return true;
    }
  }

  @override
  void initState() {
    super.initState();
    load();
  }

  Future<void> load() async {
    final generation = ++sequence;
    setState(() => loading = true);
    try {
      final result = await Future.wait([
        widget.repository.read('TravelBooking', {
          'toko_id': widget.storeId,
          'booking_id': widget.bookingId,
        }),
        widget.repository.read('TravelPaymentOptions', {
          'toko_id': widget.storeId,
        }),
      ]);
      if (current && generation == sequence) {
        setState(() {
          booking = result[0];
          options = result[1];
          error = '';
        });
      }
    } catch (e) {
      if (current && generation == sequence) {
        setState(() => error = travelError(e));
      }
    } finally {
      if (current && generation == sequence) setState(() => loading = false);
    }
  }

  Future<void> write(
    String operation, {
    Map<String, dynamic> extra = const {},
  }) async {
    if (busy || loading || !current || booking == null || pending) return;
    final input = {
      'toko_id': widget.storeId,
      'booking_id': booking!['_id'],
      'expected_version': booking!['version'],
      ...extra,
    };
    setState(() {
      busy = true;
      error = '';
    });
    try {
      await widget.repository.submit(operation, input);
      if (current) await load();
    } catch (e) {
      if (current) setState(() => error = travelError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> recover(bool resolve) async {
    if (busy || !current) return;
    setState(() => busy = true);
    try {
      if (resolve) {
        await widget.repository.resolve();
      } else {
        await widget.repository.recover();
      }
      if (current) await load();
    } catch (e) {
      if (current) setState(() => error = travelError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> money(bool refund) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => PosTravelMoneyDialog(
        booking: booking!,
        options: options,
        refund: refund,
      ),
    );
    if (data != null && current) {
      await write(refund ? 'refund' : 'payment', extra: data);
    }
  }

  Future<void> reason(String operation) async {
    final data = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (_) => _TravelActionDialog(
        operation: operation,
        terms: '${booking!['package_snapshot']['terms']}',
      ),
    );
    if (data != null && current) {
      await write(
        operation,
        extra: {
          ...data,
          if (operation == 'confirm')
            'terms_version': booking!['package_snapshot']['terms_version'],
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!current) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Text(
            travelText(
              context,
              'Sesi berubah. Buka ulang Travel.',
              'Session changed. Reopen Travel.',
            ),
          ),
        ),
      );
    }
    final row = booking, locked = busy || loading || pending;
    return Scaffold(
      appBar: AppBar(
        title: Text(travelText(context, 'Rincian booking', 'Booking details')),
      ),
      body: RefreshIndicator(
        onRefresh: load,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (error.isNotEmpty)
              Text(error, style: const TextStyle(color: Colors.red)),
            if (pending)
              PosTravelRecovery(
                busy: busy,
                onRetry: () => recover(false),
                onResolve: () => recover(true),
              ),
            if (loading || busy) const LinearProgressIndicator(),
            if (row == null && !loading)
              FilledButton(
                onPressed: load,
                child: Text(travelText(context, 'Muat ulang', 'Retry')),
              ),
            if (row != null) ...[
              Text(
                '${row['number']}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text('${row['customer_name']} · ${row['contact_phone'] ?? '—'}'),
              const SizedBox(height: 16),
              Text(
                '${row['package_snapshot']['name']}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              Text(
                '${travelText(context, 'Keberangkatan', 'Departure')}: ${travelDate(row['departure_snapshot']?['starts_at'])}',
              ),
              if ('${row['pickup_point'] ?? ''}'.isNotEmpty)
                Text(
                  '${travelText(context, 'Titik jemput', 'Pickup')}: ${row['pickup_point']}',
                ),
              Text(
                '${travelStatus(context, row['status'])} · ${row['seats']} ${travelText(context, 'kursi', 'seats')}',
              ),
              const SizedBox(height: 12),
              for (final item in [
                ('Total booking', 'Booking total', row['total_amount']),
                ('Diterima (neto)', 'Received (net)', row['paid_amount']),
                ('Sisa tagihan', 'Outstanding', row['outstanding_amount']),
              ])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(travelText(context, item.$1, item.$2)),
                  trailing: Text(travelMoney(item.$3)),
                ),
              Text(
                travelStatus(context, row['payment_status']),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              for (final participant in row['participants'] as List? ?? [])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.person_outline),
                  title: Text('${participant['name']}'),
                  subtitle: Text(
                    '${travelCategory(context, participant['category'])} · ${travelMoney(participant['price'])}',
                  ),
                ),
              const Divider(),
              Text(
                travelText(context, 'Riwayat pembayaran', 'Payment history'),
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if ((row['payments'] as List? ?? []).isEmpty)
                Text(
                  travelText(
                    context,
                    'Belum ada pembayaran.',
                    'No payments yet.',
                  ),
                ),
              for (final payment in row['payments'] as List? ?? [])
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    '${payment['kind'] == 'refund' ? travelText(context, 'Refund', 'Refund') : travelText(context, 'Pembayaran', 'Payment')} · ${travelMoney(payment['amount'])}',
                  ),
                  subtitle: Text(
                    '${payment['reference']} · ${travelMethod(context, payment['method'])}\n${travelDate(payment['recorded_at'])}',
                  ),
                ),
              ExpansionTile(
                title: Text(
                  travelText(context, 'Syarat booking', 'Booking terms'),
                ),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('${row['package_snapshot']['terms']}'),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (options['can_complete'] == true &&
                  ['draft', 'expired'].contains(row['status']))
                FilledButton(
                  onPressed: locked ? null : () => write('hold'),
                  child: Text(travelText(context, 'Tahan kuota', 'Hold seats')),
                ),
              if (options['can_complete'] == true && row['status'] == 'held')
                FilledButton(
                  onPressed: locked ? null : () => reason('confirm'),
                  child: Text(
                    travelText(
                      context,
                      'Konfirmasi booking',
                      'Confirm booking',
                    ),
                  ),
                ),
              if (row['status'] == 'confirmed' &&
                  options['can_pay'] == true &&
                  (row['outstanding_amount'] as num) > 0)
                FilledButton(
                  key: const Key('travel-pay'),
                  onPressed: locked ? null : () => money(false),
                  child: Text(
                    (row['paid_amount'] as num) > 0
                        ? travelText(
                            context,
                            'Cicilan / Pelunasan',
                            'Installment / Settlement',
                          )
                        : travelText(
                            context,
                            'Terima DP / Lunas',
                            'Receive deposit / Full payment',
                          ),
                  ),
                ),
              if (row['status'] == 'confirmed' &&
                  options['can_refund'] == true &&
                  (row['paid_amount'] as num) > 0)
                OutlinedButton(
                  onPressed: locked ? null : () => money(true),
                  child: Text(
                    travelText(context, 'Refund dana', 'Refund payment'),
                  ),
                ),
              if (row['status'] == 'confirmed' &&
                  options['can_complete'] == true &&
                  DateTime.tryParse(
                        '${row['departure_snapshot']?['starts_at']}',
                      )?.isAfter(DateTime.now()) ==
                      false &&
                  row['payment_status'] == 'paid')
                OutlinedButton(
                  onPressed: locked ? null : () => reason('complete'),
                  child: Text(
                    travelText(
                      context,
                      'Selesaikan perjalanan',
                      'Complete trip',
                    ),
                  ),
                ),
              if (options['can_complete'] == true &&
                  !['completed', 'cancelled'].contains(row['status']) &&
                  (row['paid_amount'] as num) == 0)
                TextButton(
                  onPressed: locked ? null : () => reason('cancel'),
                  child: Text(
                    travelText(context, 'Batalkan booking', 'Cancel booking'),
                  ),
                ),
              if (row['status'] == 'confirmed' &&
                  (row['paid_amount'] as num) > 0)
                Text(
                  travelText(
                    context,
                    'Untuk membatalkan, refund dana melalui petugas berwenang terlebih dahulu.',
                    'Before cancellation, an authorized operator must refund the received funds.',
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TravelActionDialog extends StatefulWidget {
  const _TravelActionDialog({required this.operation, required this.terms});
  final String operation, terms;
  @override
  State<_TravelActionDialog> createState() => _ActionState();
}

class _ActionState extends State<_TravelActionDialog> {
  final form = GlobalKey<FormState>();
  String note = '';
  bool accepted = false;
  @override
  Widget build(BuildContext context) => PosKeyboardStableFormDialog(
    width: 520,
    height: 460,
    title: Text(travelText(context, 'Konfirmasi tindakan', 'Confirm action')),
    content: Form(
      key: form,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (widget.operation == 'confirm') ...[
              Text(widget.terms),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: accepted,
                onChanged: (v) => setState(() => accepted = v == true),
                title: Text(
                  travelText(
                    context,
                    'Pelanggan menyetujui syarat booking',
                    'Customer accepts the booking terms',
                  ),
                ),
              ),
            ],
            if (widget.operation == 'complete')
              Text(
                travelText(
                  context,
                  'Konfirmasikan hanya setelah perjalanan benar-benar selesai. Jadwal harus sudah berangkat dan pembayaran lunas.',
                  'Confirm only after the trip has actually been completed. Departure must have occurred and payment must be settled.',
                ),
              ),
            TextFormField(
              maxLength: 500,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: travelText(
                  context,
                  'Catatan / alasan',
                  'Notes / reason',
                ),
              ),
              onChanged: (v) => note = v.trim(),
              validator: (_) => note.isNotEmpty
                  ? null
                  : travelText(context, 'Wajib diisi', 'Required'),
            ),
          ],
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(travelText(context, 'Batal', 'Cancel')),
      ),
      FilledButton(
        onPressed: widget.operation == 'confirm' && !accepted
            ? null
            : () {
                if (form.currentState!.validate()) {
                  Navigator.pop(
                    context,
                    widget.operation == 'confirm'
                        ? {'terms_accepted': true, 'terms_note': note}
                        : {'reason': note},
                  );
                }
              },
        child: Text(travelText(context, 'Lanjutkan', 'Continue')),
      ),
    ],
  );
}
