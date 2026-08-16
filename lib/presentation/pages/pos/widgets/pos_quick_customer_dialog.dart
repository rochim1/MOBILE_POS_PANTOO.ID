import 'package:flutter/material.dart';

import '../../../../domain/models/pos_customer.dart';
import '../../../../domain/repositories/pos_repository.dart';
import '../../../../injections.dart';
import '../../../widgets/app_toast.dart';

Future<PosCustomer?> showPosQuickCustomerDialog(BuildContext context) async {
  final repository = sl<PosRepository>();
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final customer = await showDialog<PosCustomer>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      var saving = false;
      var membershipStatus = 'non_member';
      var membershipTier = 'regular';
      var customerType = 'personal';
      return StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 22, 16, 8),
          title: Row(
            children: [
              const Expanded(child: Text('Tambah Pelanggan')),
              IconButton(
                tooltip: 'Tutup',
                onPressed: saving ? null : () => Navigator.pop(dialogContext),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: nameController,
                      autofocus: true,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(
                        labelText: 'Nama pelanggan *',
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                      validator: (value) => (value ?? '').trim().isEmpty
                          ? 'Nama pelanggan wajib diisi'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Nomor telepon',
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email (opsional)',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: membershipStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status keanggotaan',
                        prefixIcon: Icon(Icons.card_membership_outlined),
                      ),
                      items:
                          const {'non_member': 'Non Member', 'member': 'Member'}
                              .entries
                              .map(
                                (entry) => DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ),
                              )
                              .toList(),
                      onChanged: saving
                          ? null
                          : (value) => setDialogState(() {
                              membershipStatus = value ?? 'non_member';
                              if (membershipStatus == 'non_member') {
                                membershipTier = 'regular';
                              }
                            }),
                    ),
                    if (membershipStatus == 'member') ...[
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        initialValue: membershipTier,
                        decoration: const InputDecoration(
                          labelText: 'Tier member',
                          prefixIcon: Icon(Icons.workspace_premium_outlined),
                        ),
                        items:
                            const {
                                  'regular': 'Regular',
                                  'silver': 'Silver',
                                  'gold': 'Gold',
                                  'vip': 'VIP',
                                }.entries
                                .map(
                                  (entry) => DropdownMenuItem(
                                    value: entry.key,
                                    child: Text(entry.value),
                                  ),
                                )
                                .toList(),
                        onChanged: saving
                            ? null
                            : (value) => setDialogState(
                                () => membershipTier = value ?? 'regular',
                              ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: customerType,
                      decoration: const InputDecoration(
                        labelText: 'Tipe pelanggan',
                        prefixIcon: Icon(Icons.business_center_outlined),
                      ),
                      items:
                          const {
                                'personal': 'Personal',
                                'reseller': 'Reseller',
                                'corporate': 'Corporate',
                              }.entries
                              .map(
                                (entry) => DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ),
                              )
                              .toList(),
                      onChanged: saving
                          ? null
                          : (value) => setDialogState(
                              () => customerType = value ?? 'personal',
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
          actions: [
            TextButton(
              onPressed: saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton.icon(
              onPressed: saving
                  ? null
                  : () async {
                      if (!formKey.currentState!.validate()) return;
                      setDialogState(() => saving = true);
                      final name = nameController.text.trim();
                      final phone = phoneController.text.trim();
                      final email = emailController.text.trim();
                      final customerSegment = switch (customerType) {
                        'reseller' => 'reseller',
                        'corporate' => 'corporate',
                        _ when membershipStatus == 'non_member' => 'non_member',
                        _ when membershipTier == 'vip' => 'vip',
                        _ => 'member',
                      };
                      final priceLevel = switch (customerType) {
                        'reseller' => 'reseller',
                        'corporate' => 'corporate',
                        _ when membershipStatus == 'non_member' => 'retail',
                        _ when membershipTier == 'vip' => 'vip',
                        _ => 'member',
                      };
                      final result = await repository.createCustomer({
                        'name': name,
                        'phone': phone,
                        if (email.isNotEmpty) 'email': email,
                        'type': 'customer',
                        'sumber_kontak': 'mobile_pos',
                        'price_level': priceLevel,
                        'customer_segment': customerSegment,
                        'membership_status': membershipStatus,
                        'membership_tier': membershipTier,
                        'customer_type': customerType,
                      });
                      if (!dialogContext.mounted) return;
                      result.fold(
                        (failure) {
                          setDialogState(() => saving = false);
                          AppToast.error(dialogContext, failure.message);
                        },
                        (data) {
                          final created = PosCustomer(
                            id: data['_id']?.toString() ?? '',
                            name: data['name']?.toString() ?? name,
                            phone: data['phone']?.toString() ?? phone,
                            email: data['email']?.toString() ?? email,
                            priceLevel:
                                data['price_level']?.toString() ?? priceLevel,
                            customerSegment:
                                data['customer_segment']?.toString() ??
                                customerSegment,
                            membershipStatus:
                                data['membership_status']?.toString() ??
                                membershipStatus,
                            membershipTier:
                                data['membership_tier']?.toString() ??
                                membershipTier,
                            customerType:
                                data['customer_type']?.toString() ??
                                customerType,
                          );
                          if (created.id.isEmpty) {
                            setDialogState(() => saving = false);
                            AppToast.error(
                              dialogContext,
                              'Pelanggan tersimpan, tetapi ID pelanggan tidak diterima',
                            );
                            return;
                          }
                          Navigator.pop(dialogContext, created);
                        },
                      );
                    },
              icon: saving
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.person_add_alt_1),
              label: Text(saving ? 'Menyimpan...' : 'Simpan & Pilih'),
            ),
          ],
        ),
      );
    },
  );

  nameController.dispose();
  phoneController.dispose();
  emailController.dispose();
  return customer;
}
