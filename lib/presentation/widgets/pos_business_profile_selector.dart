import 'package:flutter/material.dart';
import '../../domain/models/pos_remote_profile_catalog.dart';
import '../../l10n/pos_localization.dart';

/// Shared by first-time business creation and recovery of older POS setup.
class PosBusinessProfileSelector extends StatelessWidget {
  const PosBusinessProfileSelector({
    super.key,
    required this.value,
    required this.catalog,
    required this.onChanged,
  });

  final String value;
  final PosRemoteProfileCatalog catalog;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<String>(
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: 'Profil usaha'.tr(context),
      floatingLabelBehavior: FloatingLabelBehavior.always,
      prefixIcon: const Icon(Icons.category_outlined),
      helperText: value == 'travel'
          ? 'Booking Travel: jadwal, kuota, DP dan pelunasan.'
          : null,
    ),
    items: catalog
        .ids(current: value)
        .map(
          (id) => DropdownMenuItem(
            value: id,
            child: PosText(
              catalog.profile(id)?.label ?? id,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        )
        .toList(),
    onChanged: onChanged == null
        ? null
        : (value) {
            if (value != null) onChanged!(value);
          },
  );
}
