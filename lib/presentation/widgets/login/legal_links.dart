import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

const pantooPrivacyUrl = 'https://app.pantoo.id/kebijakan-privasi/pos';
const pantooTermsUrl = 'https://app.pantoo.id/ketentuan-layanan';

Future<void> openPantooLegalUrl(BuildContext context, String url) async {
  final opened = await launchUrl(
    Uri.parse(url),
    mode: LaunchMode.externalApplication,
  );
  if (!opened && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Halaman legal tidak dapat dibuka.')),
    );
  }
}

class PantooLegalLinks extends StatefulWidget {
  final bool includePrefix;
  const PantooLegalLinks({super.key, this.includePrefix = true});

  @override
  State<PantooLegalLinks> createState() => _PantooLegalLinksState();
}

class _PantooLegalLinksState extends State<PantooLegalLinks> {
  late final TapGestureRecognizer _privacyRecognizer;
  late final TapGestureRecognizer _termsRecognizer;

  @override
  void initState() {
    super.initState();
    _privacyRecognizer = TapGestureRecognizer()
      ..onTap = () => openPantooLegalUrl(context, pantooPrivacyUrl);
    _termsRecognizer = TapGestureRecognizer()
      ..onTap = () => openPantooLegalUrl(context, pantooTermsUrl);
  }

  @override
  void dispose() {
    _privacyRecognizer.dispose();
    _termsRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(
      context,
    ).textTheme.bodySmall?.copyWith(color: Colors.grey.shade600);
    final linkStyle = style?.copyWith(
      color: const Color(0xFF0F8177),
      decoration: TextDecoration.underline,
      decorationColor: const Color(0xFF0F8177),
    );

    return Text.rich(
      TextSpan(
        style: style,
        children: [
          if (widget.includePrefix)
            const TextSpan(text: 'Dengan melanjutkan, Anda menyetujui\n'),
          TextSpan(
            text: 'Kebijakan Privasi',
            style: linkStyle,
            recognizer: _privacyRecognizer,
          ),
          const TextSpan(text: '   dan   '),
          TextSpan(
            text: 'Ketentuan Layanan',
            style: linkStyle,
            recognizer: _termsRecognizer,
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
