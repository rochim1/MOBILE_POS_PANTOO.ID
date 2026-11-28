import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../domain/repositories/pos_travel_repository.dart';
import '../../../widgets/pos_keyboard_stable_dialog.dart';
import '../utils/pos_travel_copy.dart';

String travelMoney(dynamic amount) => NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
).format(amount is num ? amount : 0);

class PosTravelReferencePicker extends StatefulWidget {
  const PosTravelReferencePicker({
    super.key,
    required this.repository,
    required this.storeId,
    required this.kind,
  });
  final PosTravelRepository repository;
  final String storeId, kind;
  @override
  State<PosTravelReferencePicker> createState() => _ReferenceState();
}

class _ReferenceState extends State<PosTravelReferencePicker> {
  String search = '', error = '';
  int page = 1, total = 0, generation = 0;
  bool loading = false;
  List<Map<String, dynamic>> rows = [];
  late final owner = widget.repository.scope;
  @override
  void initState() {
    super.initState();
    if (widget.kind != 'Customers') load(1);
  }

  Future<void> load(int next) async {
    if (widget.kind == 'Customers' && search.trim().length < 2) return;
    final seq = ++generation;
    setState(() {
      loading = true;
      error = '';
      rows = [];
    });
    try {
      final data = await widget.repository.read(
        'Travel${widget.kind}',
        widget.kind == 'Customers'
            ? {'toko_id': widget.storeId, 'search': search.trim(), 'page': next}
            : {
                'input': {
                  'toko_id': widget.storeId,
                  'search': search.trim(),
                  'page': next,
                  'limit': 20,
                },
              },
      );
      if (!mounted || seq != generation || widget.repository.scope != owner) {
        return;
      }
      setState(() {
        rows = (data['items'] as List)
            .map((v) => Map<String, dynamic>.from(v as Map))
            .toList();
        total = data['totalCount'] as int;
        page = next;
      });
    } catch (e) {
      if (mounted && seq == generation) setState(() => error = travelError(e));
    } finally {
      if (mounted && seq == generation) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => PosKeyboardStableFormDialog(
    width: 620,
    height: 620,
    title: Text(travelText(context, 'Pilih referensi', 'Select reference')),
    content: Column(
      children: [
        TextField(
          decoration: InputDecoration(
            labelText: travelText(
              context,
              'Cari nama / kode',
              'Search name / code',
            ),
            suffixIcon: IconButton(
              tooltip: travelText(context, 'Cari', 'Search'),
              onPressed: loading ? null : () => load(1),
              icon: const Icon(Icons.search),
            ),
          ),
          onChanged: (v) => search = v,
          onSubmitted: (_) => load(1),
        ),
        if (loading) const LinearProgressIndicator(),
        if (error.isNotEmpty)
          Text(error, style: const TextStyle(color: Colors.red)),
        Expanded(
          child: ListView(
            children: [
              if (rows.isEmpty && !loading)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    travelText(
                      context,
                      'Cari minimal 2 karakter atau persempit pencarian.',
                      'Enter at least 2 characters or refine the search.',
                    ),
                  ),
                ),
              for (final row in rows)
                ListTile(
                  title: Text('${row['name'] ?? row['code']}'),
                  subtitle: widget.kind == 'Departures'
                      ? Text(
                          '${travelDate(row['starts_at'])} · ${row['available_seats']} ${travelText(context, 'kursi', 'seats')}',
                        )
                      : null,
                  onTap: loading || widget.repository.scope != owner
                      ? null
                      : () => Navigator.pop(context, row),
                ),
            ],
          ),
        ),
        Row(
          children: [
            IconButton(
              onPressed: !loading && page > 1 ? () => load(page - 1) : null,
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(child: Text('$page · $total')),
            IconButton(
              onPressed: !loading && page * 20 < total
                  ? () => load(page + 1)
                  : null,
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ],
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(travelText(context, 'Tutup', 'Close')),
      ),
    ],
  );
}

Future<Map<String, dynamic>?> pickTravelReference(
  BuildContext context,
  PosTravelRepository repository,
  String store,
  String kind,
) => showDialog<Map<String, dynamic>>(
  context: context,
  builder: (_) => PosTravelReferencePicker(
    repository: repository,
    storeId: store,
    kind: kind,
  ),
);

/// Initial-value fields own their controllers for the full route lifecycle.
class PosTravelMoneyDialog extends StatefulWidget {
  const PosTravelMoneyDialog({
    super.key,
    required this.booking,
    required this.options,
    this.refund = false,
  });
  final Map<String, dynamic> booking, options;
  final bool refund;
  @override
  State<PosTravelMoneyDialog> createState() => _MoneyState();
}

class _MoneyState extends State<PosTravelMoneyDialog> {
  final form = GlobalKey<FormState>();
  late int amount =
      (widget.refund
              ? widget.booking['paid_amount']
              : widget.booking['outstanding_amount'] as num)
          .toInt();
  String method = 'tunai', bank = '', reference = '', reason = '';
  @override
  Widget build(BuildContext context) => PosKeyboardStableFormDialog(
    width: 540,
    height: 620,
    title: Text(
      widget.refund
          ? travelText(context, 'Refund booking', 'Booking refund')
          : travelText(context, 'DP / Pelunasan', 'Deposit / Settlement'),
    ),
    content: Form(
      key: form,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              '${widget.booking['number']} · ${widget.booking['customer_name']}',
            ),
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('travel-amount'),
              initialValue: '$amount',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: travelText(context, 'Nominal (Rp)', 'Amount (IDR)'),
              ),
              onChanged: (v) => amount = int.tryParse(v) ?? 0,
              validator: (_) =>
                  amount > 0 &&
                      amount <=
                          (widget.refund
                              ? widget.booking['paid_amount']
                              : widget.booking['outstanding_amount'])
                  ? null
                  : travelText(
                      context,
                      'Nominal harus sesuai saldo',
                      'Amount must be within the balance',
                    ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: method,
              isExpanded: true,
              decoration: InputDecoration(
                labelText: travelText(context, 'Metode', 'Method'),
              ),
              items: [
                DropdownMenuItem(
                  value: 'tunai',
                  child: Text(
                    travelText(
                      context,
                      'Tunai · shift aktif',
                      'Cash · active shift',
                    ),
                  ),
                ),
                DropdownMenuItem(
                  value: 'transfer',
                  child: Text(
                    travelText(
                      context,
                      'Transfer manual',
                      'Manual bank transfer',
                    ),
                  ),
                ),
              ],
              onChanged: (v) => setState(() {
                method = v!;
                bank = '';
              }),
            ),
            if (method == 'transfer') ...[
              const SizedBox(height: 16),
              Text(
                travelText(
                  context,
                  'Catat hanya setelah dana benar-benar diterima/dikembalikan. Tidak ada pengecekan bank otomatis.',
                  'Record only after funds are actually received/refunded. No automatic bank verification.',
                ),
              ),
              DropdownButtonFormField<String>(
                key: ValueKey(method),
                isExpanded: true,
                decoration: InputDecoration(
                  labelText: travelText(context, 'Rekening', 'Bank account'),
                ),
                items: [
                  for (final row in widget.options['accounts'] as List? ?? [])
                    DropdownMenuItem(
                      value: '${row['_id']}',
                      child: Text('${row['name']} · ${row['account_last4']}'),
                    ),
                ],
                onChanged: (v) => bank = v ?? '',
                validator: (_) => bank.isNotEmpty
                    ? null
                    : travelText(
                        context,
                        'Pilih rekening',
                        'Choose an account',
                      ),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              key: const Key('travel-reference'),
              maxLength: 300,
              decoration: InputDecoration(
                labelText: travelText(
                  context,
                  'Bukti / referensi pembayaran',
                  'Payment reference / evidence',
                ),
              ),
              onChanged: (v) => reference = v.trim(),
              validator: (_) => reference.isNotEmpty
                  ? null
                  : travelText(context, 'Wajib diisi', 'Required'),
            ),
            if (widget.refund)
              TextFormField(
                maxLength: 500,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: travelText(
                    context,
                    'Alasan refund',
                    'Refund reason',
                  ),
                ),
                onChanged: (v) => reason = v.trim(),
                validator: (_) => reason.isNotEmpty
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
        key: const Key('travel-money-save'),
        onPressed: () {
          if (form.currentState!.validate()) {
            Navigator.pop(context, {
              'amount': amount,
              'method': method,
              if (method == 'transfer') 'bank_account_id': bank,
              'reference': reference,
              if (widget.refund) 'reason': reason,
            });
          }
        },
        child: Text(travelText(context, 'Catat pembayaran', 'Record payment')),
      ),
    ],
  );
}

class PosTravelDraftPage extends StatefulWidget {
  const PosTravelDraftPage({
    super.key,
    required this.repository,
    required this.storeId,
  });
  final PosTravelRepository repository;
  final String storeId;
  @override
  State<PosTravelDraftPage> createState() => _DraftState();
}

class _DraftState extends State<PosTravelDraftPage> {
  final form = GlobalKey<FormState>();
  final participants = <Map<String, dynamic>>[
    {'name': '', 'category': 'adult'},
  ];
  Map<String, dynamic>? departure, customer;
  String phone = '', pickup = '', error = '';
  bool busy = false;
  late final owner = widget.repository.scope;
  bool get pending {
    try {
      return widget.repository.pending() != null;
    } catch (_) {
      return true;
    }
  }

  Future<void> save() async {
    if (busy || !form.currentState!.validate()) return;
    if (departure == null ||
        customer == null ||
        !participants.any((r) => r['category'] == 'adult')) {
      setState(
        () => error = travelText(
          context,
          'Pilih keberangkatan dan pelanggan; minimal satu peserta dewasa.',
          'Select a departure and customer; at least one adult is required.',
        ),
      );
      return;
    }
    setState(() {
      busy = true;
      error = '';
    });
    try {
      final result = await widget.repository.submit('createBooking', {
        'toko_id': widget.storeId,
        'departure_id': departure!['_id'],
        'customer_id': customer!['_id'],
        'contact_phone': phone,
        'pickup_point': pickup,
        'participants': participants,
      });
      if (mounted && widget.repository.scope == owner) {
        Navigator.pop(context, result);
      }
    } catch (e) {
      if (mounted) setState(() => error = travelError(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(
        travelText(context, 'Buat booking Travel', 'Create travel booking'),
      ),
    ),
    body: Form(
      key: form,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (error.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(error, style: const TextStyle(color: Colors.red)),
            ),
          if (pending)
            Text(
              travelText(
                context,
                'Permintaan tersimpan. Kembali ke Booking Travel untuk memulihkan; jangan buat booking pengganti.',
                'Request saved. Return to Travel to recover it; do not create a replacement booking.',
              ),
            ),
          OutlinedButton.icon(
            onPressed: busy
                ? null
                : () async {
                    final row = await pickTravelReference(
                      context,
                      widget.repository,
                      widget.storeId,
                      'Departures',
                    );
                    if (mounted && row != null) setState(() => departure = row);
                  },
            icon: const Icon(Icons.event),
            label: Text(
              departure == null
                  ? travelText(
                      context,
                      'Pilih keberangkatan',
                      'Choose departure',
                    )
                  : '${departure!['code']} · ${travelDate(departure!['starts_at'])}',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: busy
                ? null
                : () async {
                    final row = await pickTravelReference(
                      context,
                      widget.repository,
                      widget.storeId,
                      'Customers',
                    );
                    if (mounted && row != null) setState(() => customer = row);
                  },
            icon: const Icon(Icons.person_outline),
            label: Text(
              '${customer?['name'] ?? travelText(context, 'Pilih pelanggan', 'Choose customer')}',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            enabled: !busy,
            decoration: InputDecoration(
              labelText: travelText(
                context,
                'Nomor kontak pemesan',
                'Customer contact number',
              ),
            ),
            keyboardType: TextInputType.phone,
            onChanged: (v) => phone = v.replaceAll(RegExp(r'[ ()-]'), ''),
            validator: (_) => RegExp(r'^\+?\d{7,15}$').hasMatch(phone)
                ? null
                : travelText(
                    context,
                    'Isi nomor valid (7–15 digit)',
                    'Enter a valid number (7–15 digits)',
                  ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            enabled: !busy,
            maxLength: 300,
            decoration: InputDecoration(
              labelText: travelText(
                context,
                'Titik jemput (opsional)',
                'Pickup point (optional)',
              ),
            ),
            onChanged: (v) => pickup = v.trim(),
          ),
          for (final row in participants)
            Card(
              key: ObjectKey(row),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    TextFormField(
                      enabled: !busy,
                      initialValue: '${row['name']}',
                      maxLength: 120,
                      decoration: InputDecoration(
                        labelText: travelText(
                          context,
                          'Nama peserta',
                          'Participant name',
                        ),
                      ),
                      onChanged: (v) => row['name'] = v.trim(),
                      validator: (v) => v?.trim().isNotEmpty == true
                          ? null
                          : travelText(context, 'Wajib diisi', 'Required'),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: '${row['category']}',
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: travelText(
                          context,
                          'Kategori peserta',
                          'Participant category',
                        ),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'adult',
                          child: Text(travelText(context, 'Dewasa', 'Adult')),
                        ),
                        DropdownMenuItem(
                          value: 'child',
                          child: Text(travelText(context, 'Anak', 'Child')),
                        ),
                        DropdownMenuItem(
                          value: 'infant',
                          child: Text(travelText(context, 'Bayi', 'Infant')),
                        ),
                      ],
                      onChanged: busy
                          ? null
                          : (v) => setState(() => row['category'] = v),
                    ),
                    if (participants.length > 1)
                      TextButton(
                        onPressed: busy
                            ? null
                            : () => setState(() => participants.remove(row)),
                        child: Text(
                          travelText(
                            context,
                            'Hapus peserta',
                            'Remove participant',
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          OutlinedButton.icon(
            onPressed: busy || participants.length >= 200
                ? null
                : () => setState(
                    () => participants.add({'name': '', 'category': 'adult'}),
                  ),
            icon: const Icon(Icons.person_add_alt),
            label: Text(
              travelText(context, 'Tambah peserta', 'Add participant'),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            travelText(
              context,
              'Tarif dan pemakaian kursi dihitung server dari paket. Draf belum menahan kuota; pembayaran dilakukan pada booking yang sama setelah konfirmasi.',
              'The server calculates prices and seats from the package. Drafts do not hold seats; payment uses the same booking after confirmation.',
            ),
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: busy || pending || widget.repository.scope != owner
                ? null
                : save,
            child: busy
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(travelText(context, 'Buat booking', 'Create booking')),
          ),
        ],
      ),
    ),
  );
}

class PosTravelMasterDialog extends StatefulWidget {
  const PosTravelMasterDialog({
    super.key,
    required this.repository,
    required this.storeId,
    required this.departure,
  });
  final PosTravelRepository repository;
  final String storeId;
  final bool departure;
  @override
  State<PosTravelMasterDialog> createState() => _MasterState();
}

class _MasterState extends State<PosTravelMasterDialog> {
  final form = GlobalKey<FormState>();
  String error = '';
  final input = <String, dynamic>{
    'code': '',
    'name': '',
    'adult_price': 0,
    'child_price': 0,
    'infant_price': 0,
    'infant_uses_seat': false,
    'hold_minutes': 15,
    'terms': '',
    'capacity': 1,
  };
  Map<String, dynamic>? package;
  DateTime? start, close;
  Widget field(
    String key,
    String id,
    String en, {
    bool number = false,
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      initialValue: '${input[key]}',
      maxLines: lines,
      maxLength: lines > 1
          ? 6000
          : key == 'code'
          ? 40
          : 180,
      keyboardType: number ? TextInputType.number : TextInputType.text,
      inputFormatters: number ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: InputDecoration(labelText: travelText(context, id, en)),
      onChanged: (v) => input[key] = number ? int.tryParse(v) ?? 0 : v.trim(),
      validator: (v) => v?.trim().isNotEmpty == true
          ? null
          : travelText(context, 'Wajib diisi', 'Required'),
    ),
  );
  Future<DateTime?> date() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now(),
        day = await showDatePicker(
          context: context,
          initialDate: DateTime.now().add(const Duration(days: 1)),
          firstDate: DateTime.now(),
          lastDate: DateTime(now.year + 5),
        );
    if (day == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
    );
    return time == null
        ? null
        : DateTime(day.year, day.month, day.day, time.hour, time.minute);
  }

  @override
  Widget build(BuildContext context) => PosKeyboardStableFormDialog(
    width: 600,
    height: 680,
    title: Text(
      widget.departure
          ? travelText(context, 'Tambah keberangkatan', 'Add departure')
          : travelText(context, 'Tambah paket', 'Add package'),
    ),
    content: Form(
      key: form,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (error.isNotEmpty)
              Text(error, style: const TextStyle(color: Colors.red)),
            field('code', 'Kode', 'Code'),
            if (widget.departure) ...[
              OutlinedButton(
                onPressed: () async {
                  final value = await pickTravelReference(
                    context,
                    widget.repository,
                    widget.storeId,
                    'Packages',
                  );
                  if (mounted && value != null) setState(() => package = value);
                },
                child: Text(
                  '${package?['name'] ?? travelText(context, 'Pilih paket', 'Choose package')}',
                ),
              ),
              field(
                'capacity',
                'Kapasitas kursi',
                'Seat capacity',
                number: true,
              ),
              OutlinedButton(
                onPressed: () async {
                  final value = await date();
                  if (mounted && value != null) setState(() => start = value);
                },
                child: Text(
                  '${travelText(context, 'Keberangkatan', 'Departure')}: ${travelDate(start?.toIso8601String())}',
                ),
              ),
              OutlinedButton(
                onPressed: () async {
                  final value = await date();
                  if (mounted && value != null) setState(() => close = value);
                },
                child: Text(
                  '${travelText(context, 'Batas booking', 'Booking deadline')}: ${travelDate(close?.toIso8601String())}',
                ),
              ),
            ] else ...[
              field('name', 'Nama paket / rute', 'Package / route name'),
              field(
                'adult_price',
                'Tarif dewasa (Rp)',
                'Adult fare (IDR)',
                number: true,
              ),
              field(
                'child_price',
                'Tarif anak (Rp)',
                'Child fare (IDR)',
                number: true,
              ),
              field(
                'infant_price',
                'Tarif bayi (Rp)',
                'Infant fare (IDR)',
                number: true,
              ),
              SwitchListTile(
                title: Text(
                  travelText(
                    context,
                    'Bayi menggunakan kursi',
                    'Infants use a seat',
                  ),
                ),
                value: input['infant_uses_seat'] == true,
                onChanged: (v) => setState(() => input['infant_uses_seat'] = v),
              ),
              field(
                'hold_minutes',
                'Tahan kuota (menit)',
                'Seat hold (minutes)',
                number: true,
              ),
              field('terms', 'Syarat booking', 'Booking terms', lines: 3),
            ],
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
        onPressed: () {
          if (!form.currentState!.validate()) return;
          if (widget.departure &&
              (package == null ||
                  start == null ||
                  close == null ||
                  !start!.isAfter(DateTime.now()) ||
                  close!.isAfter(start!) ||
                  !close!.isAfter(DateTime.now()) ||
                  (input['capacity'] as int) < 1)) {
            setState(
              () => error = travelText(
                context,
                'Pilih paket dan jadwal mendatang; batas booking sebelum keberangkatan dan kapasitas minimal 1.',
                'Choose a package and future dates; booking must close before departure and capacity must be at least 1.',
              ),
            );
            return;
          }
          if (!widget.departure &&
              ((input['hold_minutes'] as int) < 1 ||
                  (input['hold_minutes'] as int) > 120)) {
            setState(
              () => error = travelText(
                context,
                'Durasi tahan kuota harus 1–120 menit.',
                'Seat hold must be 1–120 minutes.',
              ),
            );
            return;
          }
          Navigator.pop(
            context,
            widget.departure
                ? {
                    'code': input['code'],
                    'package_id': package!['_id'],
                    'capacity': input['capacity'],
                    'starts_at': start!.toUtc().toIso8601String(),
                    'booking_closes_at': close!.toUtc().toIso8601String(),
                  }
                : {
                    for (final key in [
                      'code',
                      'name',
                      'adult_price',
                      'child_price',
                      'infant_price',
                      'infant_uses_seat',
                      'hold_minutes',
                      'terms',
                    ])
                      key: input[key],
                  },
          );
        },
        child: Text(travelText(context, 'Simpan', 'Save')),
      ),
    ],
  );
}
