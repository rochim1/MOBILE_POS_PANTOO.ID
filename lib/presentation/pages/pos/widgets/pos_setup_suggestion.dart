import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';

/// Local presentation preference only: dismissal never completes server setup.
class PosSetupSuggestion extends StatefulWidget {
  const PosSetupSuggestion({
    super.key,
    required this.preferences,
    required this.onOpenGuide,
  });
  final SharedPreferences preferences;
  final VoidCallback onOpenGuide;

  @override
  State<PosSetupSuggestion> createState() => _PosSetupSuggestionState();
}

class _PosSetupSuggestionState extends State<PosSetupSuggestion> {
  late String _scope;
  late bool _dismissed;
  String get _preferenceKey =>
      'pos_setup_suggestion_dismissed_v1:${widget.preferences.getString('instansi_id') ?? ''}:${widget.preferences.getString('user_id') ?? ''}';

  @override
  void initState() {
    super.initState();
    _restore();
  }

  void _restore() {
    _scope = _preferenceKey;
    _dismissed = widget.preferences.getBool(_scope) == true;
  }

  @override
  void didUpdateWidget(covariant PosSetupSuggestion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_scope != _preferenceKey) _restore();
  }

  Future<void> _dismiss() async {
    setState(() => _dismissed = true);
    try {
      await widget.preferences.setBool(_scope, true);
    } catch (_) {
      /* Still dismiss for this session. */
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();
    return Card(
      margin: EdgeInsets.zero,
      color: const Color(0xFFEAF5F3),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const PosText(
                    'Panduan mulai berjualan',
                    style: TextStyle(
                      color: Color(0xFF164E47),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const PosText(
                    'Opsional. Tambahkan produk atau layanan; pengaturan lainnya bisa menyusul.',
                    style: TextStyle(color: Color(0xFF355D57)),
                  ),
                  TextButton(
                    onPressed: widget.onOpenGuide,
                    child: const PosText('Lihat panduan'),
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Sembunyikan panduan',
              onPressed: _dismiss,
              icon: const Icon(Icons.close, color: Color(0xFF164E47)),
            ),
          ],
        ),
      ),
    );
  }
}
