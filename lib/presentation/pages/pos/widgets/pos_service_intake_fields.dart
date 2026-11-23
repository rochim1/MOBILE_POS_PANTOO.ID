import 'package:flutter/material.dart';
import '../../../../domain/models/pos_product.dart';
import '../../../../l10n/pos_localization.dart';
import '../../../widgets/pos_keyboard_stable_dialog.dart';
import '../utils/pos_service_intake.dart';

class PosServiceIntakeDraft {
  PosServiceIntakeDraft(
    this.cart,
    this.profile, {
    Map<String, dynamic>? initial,
    this.selectedUnits = const {},
  }) : initial = initial ?? {},
       subject = TextEditingController(
         text: initial?['service_subject']?.toString() ?? '',
       ),
       notes = TextEditingController(
         text:
             (initial?['complaint'] ?? initial?['condition_notes'])
                 ?.toString() ??
             '',
       ),
       technician = TextEditingController(
         text: initial?['technician_name']?.toString() ?? '',
       ),
       vehicle = TextEditingController(
         text: initial?['vehicle_no']?.toString() ?? '',
       ),
       model = TextEditingController(
         text: initial?['vehicle_model']?.toString() ?? '',
       ),
       tag = TextEditingController(text: initial?['bag_tag']?.toString() ?? '');

  final Map<PosProduct, double> cart;
  final String profile;
  final Map<String, dynamic> initial;
  final Map<String, String> selectedUnits;
  late final List<Map<String, dynamic>> lines =
      (buildPosServiceIntake(
                    cart,
                    profile,
                    existing: initial,
                    selectedUnits: selectedUnits,
                  )?['service_lines']
                  as List? ??
              [])
          .map((line) => Map<String, dynamic>.from(line as Map))
          .toList();
  final TextEditingController subject, notes, technician, vehicle, model, tag;
  bool get needsWork => posRequiresWorkIntake(cart, profile);
  bool get hasLaundry =>
      cart.keys.any((p) => posServiceIntakeMode(p, profile) == 'laundry');
  String? validate() {
    final data = build();
    return posServiceQuantityProblem(cart, data) ??
        (posHasWorkDetails(cart, profile, data)
            ? null
            : 'Isi objek layanan atau catatan pekerjaan.');
  }

  Map<String, dynamic>? build({bool reservation = false}) =>
      buildPosServiceIntake(
        cart,
        profile,
        reservation: reservation,
        selectedUnits: selectedUnits,
        existing: {
          ...initial,
          'service_lines': lines,
          if (needsWork)
            'service_subject': subject.text.trim().isNotEmpty
                ? subject.text.trim()
                : vehicle.text.trim(),
          'complaint': notes.text.trim(),
          'condition_notes': notes.text.trim(),
          if (needsWork) 'technician_name': technician.text.trim(),
          if (needsWork) 'vehicle_no': vehicle.text.trim().toUpperCase(),
          if (needsWork) 'vehicle_model': model.text.trim(),
          if (hasLaundry) 'bag_tag': tag.text.trim(),
        },
      );

  void dispose() {
    for (final controller in [
      subject,
      notes,
      technician,
      vehicle,
      model,
      tag,
    ]) {
      controller.dispose();
    }
  }
}

class PosServiceIntakeFields extends StatefulWidget {
  const PosServiceIntakeFields({
    super.key,
    required this.draft,
    this.features = const {},
  });
  final PosServiceIntakeDraft draft;
  final Map features;

  @override
  State<PosServiceIntakeFields> createState() => _PosServiceIntakeFieldsState();
}

class _PosServiceIntakeFieldsState extends State<PosServiceIntakeFields> {
  PosServiceIntakeDraft get draft => widget.draft;
  Map get features => widget.features;
  bool expanded = false;

  Widget _field(
    BuildContext context,
    TextEditingController controller,
    String label, {
    int lines = 1,
  }) => Padding(
    padding: const EdgeInsets.only(top: 12),
    child: TextField(
      controller: controller,
      maxLines: lines,
      decoration: InputDecoration(
        labelText: label.tr(context),
        floatingLabelBehavior: FloatingLabelBehavior.always,
        border: const OutlineInputBorder(),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    mainAxisSize: MainAxisSize.min,
    children: [
      for (final entry in draft.cart.entries.where(
        (entry) => entry.key.productType == 'service',
      ))
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(
            '${entry.key.name} · ${entry.value} ${entry.key.saleUnit}',
          ),
        ),
      if (draft.hasLaundry)
        const PosText(
          'Berat/jumlah mengikuti keranjang. Tidak perlu diisi ulang.',
        ),
      if (draft.needsWork) _field(context, draft.subject, 'Objek layanan'),
      if (draft.needsWork && features['use_vehicle_data'] == true) ...[
        _field(context, draft.vehicle, 'No. polisi / ID unit'),
        _field(context, draft.model, 'Model / tipe'),
      ],
      _field(
        context,
        draft.notes,
        draft.needsWork ? 'Keluhan / catatan layanan' : 'Catatan',
        lines: 2,
      ),
      if (draft.needsWork && features['use_technicians'] == true)
        _field(context, draft.technician, 'Teknisi / staf penanggung jawab'),
      if (draft.hasLaundry) _field(context, draft.tag, 'Tag kantong'),
      if (draft.needsWork || draft.hasLaundry) ...[
        TextButton.icon(
          onPressed: () => setState(() => expanded = !expanded),
          icon: const Icon(Icons.list_alt),
          label: PosText(
            expanded ? 'Tutup detail per objek' : 'Detail per objek (opsional)',
          ),
        ),
        if (expanded ||
            draft.lines.any(
              (line) =>
                  draft.lines
                      .where((row) => row['product_id'] == line['product_id'])
                      .length >
                  1,
            ))
          for (final line in draft.lines)
            KeyedSubtree(
              key: ObjectKey(line),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('${line['name']} · ${line['unit']}'),
                  TextFormField(
                    key: ValueKey(
                      '${identityHashCode(line)}-${line[line['pricing_basis'] == 'per_kg' ? 'weight_kg' : 'quantity']}',
                    ),
                    initialValue:
                        '${line[line['pricing_basis'] == 'per_kg' ? 'weight_kg' : 'quantity']}',
                    readOnly:
                        draft.lines
                            .where(
                              (row) => row['product_id'] == line['product_id'],
                            )
                            .length <
                        2,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: InputDecoration(
                      labelText:
                          (line['pricing_basis'] == 'per_kg'
                                  ? 'Berat objek (kg)'
                                  : 'Jumlah objek')
                              .tr(context),
                    ),
                    onChanged: (value) =>
                        line[line['pricing_basis'] == 'per_kg'
                                ? 'weight_kg'
                                : 'quantity'] =
                            double.tryParse(value) ?? 0,
                  ),
                  TextFormField(
                    initialValue: line['tag_code']?.toString() ?? '',
                    decoration: InputDecoration(
                      labelText: 'Identitas / tag objek'.tr(context),
                    ),
                    onChanged: (value) => line['tag_code'] = value.trim(),
                  ),
                  TextFormField(
                    initialValue: line['condition_notes']?.toString() ?? '',
                    decoration: InputDecoration(
                      labelText: 'Catatan objek'.tr(context),
                    ),
                    onChanged: (value) =>
                        line['condition_notes'] = value.trim(),
                  ),
                  TextButton(
                    onPressed: () {
                      final field = line['pricing_basis'] == 'per_kg'
                          ? 'weight_kg'
                          : 'quantity';
                      final quantity = (line[field] as num? ?? 0).toDouble();
                      if (quantity <= 1) return;
                      setState(() {
                        line[field] = quantity - 1;
                        draft.lines.insert(draft.lines.indexOf(line) + 1, {
                          ...line,
                          field: 1.0,
                          'tag_code': '',
                          'condition_notes': '',
                        });
                      });
                    },
                    child: const PosText('Pisahkan 1 ke objek lain'),
                  ),
                  if (draft.lines
                          .where(
                            (row) => row['product_id'] == line['product_id'],
                          )
                          .length >
                      1)
                    TextButton(
                      onPressed: () => setState(() {
                        draft.lines.remove(line);
                        final normalized = buildPosServiceIntake(
                          draft.cart,
                          draft.profile,
                          existing: {'service_lines': draft.lines},
                          selectedUnits: draft.selectedUnits,
                        )!;
                        draft.lines
                          ..clear()
                          ..addAll(
                            (normalized['service_lines'] as List).map(
                              (row) => Map<String, dynamic>.from(row as Map),
                            ),
                          );
                      }),
                      child: const PosText('Hapus detail objek ini'),
                    ),
                  const Divider(),
                ],
              ),
            ),
      ],
      if (draft.needsWork)
        const Padding(
          padding: EdgeInsets.only(top: 8),
          child: PosText('Isi objek layanan atau keluhan, minimal salah satu.'),
        ),
    ],
  );
}

Future<Map<String, dynamic>?> showPosServiceIntakeDialog(
  BuildContext context, {
  required Map<PosProduct, double> cart,
  required String profile,
  Map<String, dynamic>? initial,
  Map features = const {},
  Map<String, String> selectedUnits = const {},
}) async {
  final draft = PosServiceIntakeDraft(
    cart,
    profile,
    initial: initial,
    selectedUnits: selectedUnits,
  );
  ModalRoute<Map<String, dynamic>>? route;
  String? error;
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (dialogContext) {
      route = ModalRoute.of<Map<String, dynamic>>(dialogContext);
      return StatefulBuilder(
        builder: (context, update) => PosKeyboardStableFormDialog(
          width: 520,
          height: draft.needsWork
              ? (features['use_vehicle_data'] == true ? 540 : 410)
              : 320,
          title: PosText(draft.hasLaundry ? 'Detail cucian' : 'Detail layanan'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PosServiceIntakeFields(draft: draft, features: features),
                if (error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      error!.tr(context),
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const PosText('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final problem = draft.validate();
                if (problem != null) {
                  update(() => error = problem);
                  return;
                }
                Navigator.pop(dialogContext, draft.build());
              },
              child: const PosText('Simpan'),
            ),
          ],
        ),
      );
    },
  );
  await route?.completed;
  draft.dispose();
  return result;
}
