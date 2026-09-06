import 'package:flutter/material.dart';

import '../../../../domain/models/pos_customer.dart';
import '../../../../domain/repositories/pos_repository.dart';
import '../../../../injections.dart';
import '../../../widgets/app_toast.dart';

Future<PosCustomer?> showPosQuickCustomerDialog(BuildContext context) async {
  final repository = sl<PosRepository>();
  final runtimeConfig = await repository.getRuntimeConfig();
  if (!context.mounted) return null;
  final priceLevelOptions =
      <dynamic>[
            ...((runtimeConfig['price_level_options'] as List?) ??
                const ['retail']),
          ]
          .map((value) => value.toString())
          .where((value) => value.isNotEmpty)
          .toSet()
          .toList();
  if (!priceLevelOptions.contains('retail')) {
    priceLevelOptions.insert(0, 'retail');
  }
  final nameController = TextEditingController();
  final phoneController = TextEditingController();
  final emailController = TextEditingController();
  final addressController = TextEditingController();
  final noteController = TextEditingController();
  final formKey = GlobalKey<FormState>();

  final customer = await showDialog<PosCustomer>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) {
      var saving = false;
      var membershipStatus = 'non_member';
      var membershipTier = 'regular';
      var customerType = 'personal';
      var priceLevel =
          runtimeConfig['default_price_level']?.toString() ?? 'retail';
      if (!priceLevelOptions.contains(priceLevel)) priceLevel = 'retail';
      final screenSize = MediaQuery.sizeOf(dialogContext);
      final dialogWidth = (screenSize.width - 80).clamp(280.0, 760.0);
      final fieldWidth = dialogWidth >= 620
          ? (dialogWidth - 12) / 2
          : dialogWidth;
      Widget field(String label, Widget child, {bool required = false}) =>
          SizedBox(
            width: fieldWidth,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 2, bottom: 7),
                  child: Text.rich(
                    TextSpan(
                      text: label,
                      children: required
                          ? const [
                              TextSpan(
                                text: ' *',
                                style: TextStyle(color: Colors.red),
                              ),
                            ]
                          : const [],
                    ),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
                child,
              ],
            ),
          );
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
          content: SizedBox(
            width: dialogWidth,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: screenSize.height * 0.72),
              child: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      field(
                        'Nama pelanggan',
                        TextFormField(
                          controller: nameController,
                          autofocus: true,
                          textCapitalization: TextCapitalization.words,
                          decoration: const InputDecoration(
                            hintText: 'Contoh: Budi Santoso',
                            prefixIcon: Icon(Icons.person_outline),
                          ),
                          validator: (value) => (value ?? '').trim().isEmpty
                              ? 'Nama pelanggan wajib diisi'
                              : null,
                        ),
                        required: true,
                      ),
                      field(
                        'Nomor telepon',
                        TextFormField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: const InputDecoration(
                            hintText: 'Contoh: 081234567890',
                            prefixIcon: Icon(Icons.phone_outlined),
                          ),
                        ),
                      ),
                      field(
                        'Email',
                        TextFormField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            hintText: 'nama@email.com (opsional)',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          validator: (value) {
                            final email = (value ?? '').trim();
                            if (email.isEmpty) return null;
                            return RegExp(
                                  r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
                                ).hasMatch(email)
                                ? null
                                : 'Format email tidak valid';
                          },
                        ),
                      ),
                      field(
                        'Alamat',
                        TextFormField(
                          controller: addressController,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 2,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Alamat lengkap pelanggan',
                            prefixIcon: Icon(Icons.location_on_outlined),
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                      field(
                        'Catatan',
                        TextFormField(
                          controller: noteController,
                          textCapitalization: TextCapitalization.sentences,
                          minLines: 2,
                          maxLines: 3,
                          decoration: const InputDecoration(
                            hintText: 'Catatan tambahan (opsional)',
                            prefixIcon: Icon(Icons.notes_outlined),
                            alignLabelWithHint: true,
                          ),
                        ),
                      ),
                      field(
                        'Status keanggotaan',
                        DropdownButtonFormField<String>(
                          initialValue: membershipStatus,
                          decoration: const InputDecoration(
                            prefixIcon: Icon(Icons.card_membership_outlined),
                          ),
                          items:
                              const {
                                    'non_member': 'Non Member',
                                    'member': 'Member',
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
                              : (value) => setDialogState(() {
                                  membershipStatus = value ?? 'non_member';
                                  if (membershipStatus == 'non_member') {
                                    membershipTier = 'regular';
                                  }
                                }),
                        ),
                      ),
                      field(
                        'Level harga',
                        DropdownButtonFormField<String>(
                          initialValue: priceLevel,
                          decoration: const InputDecoration(
                            helperText:
                                'Menentukan daftar harga produk pelanggan ini',
                            prefixIcon: Icon(Icons.price_change_outlined),
                          ),
                          items: priceLevelOptions
                              .map(
                                (value) => DropdownMenuItem(
                                  value: value,
                                  child: Text(
                                    value
                                        .split('_')
                                        .map(
                                          (part) => part.isEmpty
                                              ? part
                                              : '${part[0].toUpperCase()}${part.substring(1)}',
                                        )
                                        .join(' '),
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: saving
                              ? null
                              : (value) => setDialogState(
                                  () => priceLevel = value ?? 'retail',
                                ),
                        ),
                      ),
                      field(
                        'Tier member',
                        DropdownButtonFormField<String>(
                          initialValue: membershipTier,
                          decoration: InputDecoration(
                            helperText: membershipStatus == 'member'
                                ? null
                                : 'Aktif setelah status diubah menjadi Member',
                            prefixIcon: const Icon(
                              Icons.workspace_premium_outlined,
                            ),
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
                          onChanged: saving || membershipStatus != 'member'
                              ? null
                              : (value) => setDialogState(
                                  () => membershipTier = value ?? 'regular',
                                ),
                        ),
                      ),
                      field(
                        'Tipe pelanggan',
                        DropdownButtonFormField<String>(
                          initialValue: customerType,
                          decoration: const InputDecoration(
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
                      ),
                    ],
                  ),
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
                      final address = addressController.text.trim();
                      final note = noteController.text.trim();
                      final result = await repository.createCustomer({
                        'name': name,
                        'phone': phone,
                        if (email.isNotEmpty) 'email': email,
                        if (address.isNotEmpty) 'address': address,
                        if (note.isNotEmpty) 'catatan': note,
                        'type': 'Customer',
                        'sumber_kontak': 'mobile_pos',
                        'price_level': priceLevel,
                        // Dipertahankan hanya untuk kompatibilitas API lama;
                        // seluruh resolusi harga menggunakan price_level.
                        'customer_segment': 'regular',
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
                            address: data['address']?.toString() ?? address,
                            note: data['catatan']?.toString() ?? note,
                            priceLevel:
                                data['price_level']?.toString() ?? priceLevel,
                            customerSegment:
                                data['customer_segment']?.toString() ??
                                'regular',
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
  addressController.dispose();
  noteController.dispose();
  return customer;
}
