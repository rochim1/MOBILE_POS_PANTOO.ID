import 'package:flutter/material.dart';
import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';

/// Only the buyer's payment plan; actual payments remain in Finance.
class PosPurchasePaymentPlanFields extends StatelessWidget {
  const PosPurchasePaymentPlanFields({
    super.key,
    required this.plan,
    required this.creditType,
    required this.onPlanChanged,
    required this.onCreditTypeChanged,
    this.dueDateField,
  });
  final String plan, creditType;
  final ValueChanged<String> onPlanChanged, onCreditTypeChanged;
  final Widget? dueDateField;
  @override
  Widget build(BuildContext context) {
    final en = posLocale(context).localeName.startsWith('en');
    String t(String id, String english) => en ? english : id;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DropdownButtonFormField<String>(
          key: ValueKey('po-plan-$plan'),
          initialValue: plan,
          isExpanded: true,
          decoration: InputDecoration(
            labelText: t('Rencana pembayaran', 'Payment plan'),
            border: const OutlineInputBorder(),
          ),
          items: [
            DropdownMenuItem(
              value: 'tunai',
              child: Text(t('Bayar langsung', 'Immediate payment')),
            ),
            DropdownMenuItem(
              value: 'saat_penerimaan',
              child: Text(t('Bayar saat barang diterima', 'Pay on receipt')),
            ),
            DropdownMenuItem(
              value: 'kredit',
              child: Text(t('Bayar nanti / tempo', 'Pay later / credit terms')),
            ),
            DropdownMenuItem(
              value: 'termin',
              child: Text(
                t('Bertahap / cicilan (lanjutan)', 'Installments (advanced)'),
              ),
            ),
          ],
          onChanged: (value) {
            if (value != null) onPlanChanged(value);
          },
        ),
        const SizedBox(height: 8),
        Text(
          t(
            'Rencana saja, bukan bukti pembayaran. Tagihan dan pembayaran tetap melalui Finance.',
            'A plan, not proof of payment. Bills and payments remain in Finance.',
          ),
          style: const TextStyle(fontSize: 12, color: Colors.black54),
        ),
        if (plan == 'kredit') ...[
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            key: ValueKey('po-tempo-$creditType'),
            initialValue: creditType,
            isExpanded: true,
            decoration: InputDecoration(
              labelText: t('Jangka waktu pembayaran', 'Payment term'),
              border: const OutlineInputBorder(),
            ),
            items: [
              for (final days in [7, 14, 30, 45, 60, 90])
                DropdownMenuItem(
                  value: 'net$days',
                  child: Text('$days ${t('hari', 'days')}'),
                ),
              DropdownMenuItem(
                value: 'custom',
                child: Text(t('Tanggal tertentu', 'Specific date')),
              ),
            ],
            onChanged: (value) {
              if (value != null) onCreditTypeChanged(value);
            },
          ),
          if (creditType == 'custom' && dueDateField != null) ...[
            const SizedBox(height: 12),
            dueDateField!,
          ],
        ],
        if (plan == 'termin')
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              t(
                'Atur jumlah dan jadwal cicilan di pengaturan lanjutan.',
                'Set installment amounts and dates in advanced settings.',
              ),
              style: const TextStyle(fontSize: 12),
            ),
          ),
      ],
    );
  }
}
