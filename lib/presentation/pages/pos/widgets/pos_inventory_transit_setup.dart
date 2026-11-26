import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/l10n/pos_inventory_flow_copy.dart';

class PosInventoryTransitSetup extends StatelessWidget {
  final bool editable, canCreate, prepared;
  final int existingCount;
  final ValueChanged<bool> onPrepare;
  final VoidCallback onUseExisting;
  const PosInventoryTransitSetup({
    super.key,
    required this.editable,
    required this.canCreate,
    required this.prepared,
    required this.existingCount,
    required this.onPrepare,
    required this.onUseExisting,
  });
  @override
  Widget build(BuildContext context) {
    String t(String key) => inventoryFlowText(context, key);
    final colors = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: DefaultTextStyle.merge(
          style: TextStyle(color: colors.onPrimaryContainer),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t('transitSetupTitle'),
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(t('transitSetupHelp')),
              if (existingCount == 1) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  key: const Key('flow-use-transit'),
                  onPressed: editable ? onUseExisting : null,
                  icon: const Icon(Icons.check_circle_outline),
                  label: Text(t('transitUseExisting')),
                ),
              ] else if (existingCount > 1) ...[
                const SizedBox(height: 8),
                Text(t('transitSelectExisting')),
              ] else if (canCreate)
                CheckboxListTile(
                  key: const Key('flow-prepare-transit'),
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  value: prepared,
                  onChanged: editable
                      ? (value) => onPrepare(value == true)
                      : null,
                  title: Text(t('transitPrepareOnSave')),
                  subtitle: Text(t('transitPrepareHint')),
                )
              else ...[
                const SizedBox(height: 8),
                Text(t('transitSetupPermission')),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
