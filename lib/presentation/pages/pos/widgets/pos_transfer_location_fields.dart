import 'package:flutter/material.dart';
import '../../../../domain/models/pos_transfer.dart';

class PosTransferLocationFields extends StatelessWidget {
  final String title;
  final List<Map<String, dynamic>> warehouses;
  final Map<String, dynamic> value;
  final ValueChanged<Map<String, dynamic>> onChanged;
  final bool disabled;
  const PosTransferLocationFields({
    super.key,
    required this.title,
    required this.warehouses,
    required this.value,
    required this.onChanged,
    this.disabled = false,
  });
  @override
  Widget build(BuildContext context) {
    final id = value['cabang_id']?.toString() ?? '';
    final source = warehouses
        .where((w) => w['_id']?.toString() == id)
        .firstOrNull;
    final buildings = transferMaps(source?['gedung']);
    final building = buildings
        .where((r) => r['kode_gedung'] == value['gedung_kode'])
        .firstOrNull;
    final rooms = transferMaps(building?['ruangan']);
    final room = rooms
        .where((r) => r['kode_ruangan'] == value['ruangan_kode'])
        .firstOrNull;
    Widget select(
      String label,
      String current,
      List<(String, String)> options,
      void Function(String) update,
    ) {
      final unique = <String, String>{
        '': 'Tanpa detail',
        for (final option in options) option.$1: option.$2,
      };
      if (current.isNotEmpty && !unique.containsKey(current)) {
        unique[current] = current;
      }
      return Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: DropdownButtonFormField<String>(
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          key: ValueKey('$title:$label:$current'),
          initialValue: current,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          items: unique.entries
              .map(
                (r) => DropdownMenuItem(
                  value: r.key,
                  child: Text(r.value, overflow: TextOverflow.ellipsis),
                ),
              )
              .toList(),
          onChanged: disabled ? null : (v) => update(v ?? ''),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        select(
          'Lokasi stok $title',
          id,
          warehouses
              .map((w) => (w['_id'].toString(), w['nama_cabang'].toString()))
              .toList(),
          (id) {
            final warehouse = warehouses
                .where((w) => w['_id'].toString() == id)
                .firstOrNull;
            onChanged({
              'cabang_id': id,
              'cabang_nama': warehouse?['nama_cabang'] ?? '',
              'gedung_kode': '',
              'gedung_nama': '',
              'ruangan_kode': '',
              'ruangan_nama': '',
              'rak_nama': '',
            });
          },
        ),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Gedung, ruangan & rak (opsional)'),
          initiallyExpanded: [
            'gedung_kode',
            'ruangan_kode',
            'rak_nama',
          ].any((k) => (value[k]?.toString() ?? '').isNotEmpty),
          children: [
            select(
              'Gedung $title',
              value['gedung_kode']?.toString() ?? '',
              buildings
                  .map(
                    (b) => (
                      b['kode_gedung'].toString(),
                      (b['nama_gedung'] ?? b['kode_gedung']).toString(),
                    ),
                  )
                  .toList(),
              (v) => onChanged({
                ...value,
                'gedung_kode': v,
                'gedung_nama':
                    buildings
                        .where((b) => b['kode_gedung'] == v)
                        .firstOrNull?['nama_gedung'] ??
                    '',
                'ruangan_kode': '',
                'ruangan_nama': '',
                'rak_nama': '',
              }),
            ),
            select(
              'Ruangan $title',
              value['ruangan_kode']?.toString() ?? '',
              rooms
                  .map(
                    (r) => (
                      r['kode_ruangan'].toString(),
                      (r['nama_ruangan'] ?? r['kode_ruangan']).toString(),
                    ),
                  )
                  .toList(),
              (v) => onChanged({
                ...value,
                'ruangan_kode': v,
                'ruangan_nama':
                    rooms
                        .where((r) => r['kode_ruangan'] == v)
                        .firstOrNull?['nama_ruangan'] ??
                    '',
                'rak_nama': '',
              }),
            ),
            select(
              'Rak $title',
              value['rak_nama']?.toString() ?? '',
              transferMaps(room?['rak'])
                  .map(
                    (r) => (r['nama_rak'].toString(), r['nama_rak'].toString()),
                  )
                  .toList(),
              (v) => onChanged({...value, 'rak_nama': v}),
            ),
          ],
        ),
      ],
    );
  }
}
