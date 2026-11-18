import 'package:flutter/material.dart';
import '../../core/utils/product_image_picker.dart';
import '../../domain/repositories/pos_business_profile_repository.dart';
import '../../l10n/pos_localization.dart';

class PosBusinessLogoPicker extends StatefulWidget {
  const PosBusinessLogoPicker({
    super.key,
    this.value,
    this.imageUrl = '',
    this.enabled = true,
    required this.onChanged,
    required this.onRemove,
    this.pickImage,
  });
  final PickedProductImage? value;
  final String imageUrl;
  final bool enabled;
  final ValueChanged<PickedProductImage> onChanged;
  final VoidCallback onRemove;
  final Future<PickedProductImage?> Function()? pickImage;
  @override
  State<PosBusinessLogoPicker> createState() => _PosBusinessLogoPickerState();
}

class _PosBusinessLogoPickerState extends State<PosBusinessLogoPicker> {
  bool _picking = false;
  String? _error;
  Future<void> _pick() async {
    if (_picking || !widget.enabled) return;
    setState(() {
      _picking = true;
      _error = null;
    });
    try {
      final image = await (widget.pickImage ?? pickProductImage)().timeout(
        const Duration(minutes: 2),
      );
      if (!mounted || image == null) return;
      final error = businessLogoValidation(image);
      if (error != null) {
        setState(() => _error = error);
        return;
      }
      widget.onChanged(image);
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Logo belum dapat dipilih. Silakan coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = widget.value != null || widget.imageUrl.isNotEmpty;
    const placeholder = Icon(Icons.storefront_outlined, size: 38);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PosText(
          'Logo usaha',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 72,
              height: 72,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).dividerColor),
                borderRadius: BorderRadius.circular(12),
              ),
              child: widget.value != null
                  ? Image.memory(
                      widget.value!.bytes,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => placeholder,
                    )
                  : widget.imageUrl.isNotEmpty
                  ? Image.network(
                      widget.imageUrl,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => placeholder,
                    )
                  : placeholder,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const PosText('Opsional · JPG, PNG, WebP · maksimal 5 MB'),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      Tooltip(
                        message: 'Pilih logo usaha'.tr(context),
                        child: OutlinedButton.icon(
                          onPressed: widget.enabled && !_picking ? _pick : null,
                          icon: _picking
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.upload_outlined, size: 18),
                          label: PosText(
                            hasImage ? 'Ganti logo' : 'Pilih logo',
                          ),
                        ),
                      ),
                      if (hasImage)
                        TextButton(
                          onPressed: widget.enabled && !_picking
                              ? () {
                                  setState(() => _error = null);
                                  widget.onRemove();
                                }
                              : null,
                          child: const PosText('Hapus logo'),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: PosText(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
      ],
    );
  }
}
