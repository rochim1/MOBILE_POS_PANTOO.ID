import 'package:flutter/material.dart';
import 'app_language_controller.dart';
import 'pos_localization.dart';

class LanguagePicker extends StatelessWidget {
  const LanguagePicker({super.key});
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Locale?>(
    valueListenable: AppLanguageController.instance,
    builder: (context, selected, _) {
      final l = posLocale(context);
      final code = Localizations.maybeLocaleOf(context)?.languageCode ?? 'id';
      return PopupMenuButton<String>(
        tooltip: l.languageTitle,
        initialValue: selected?.languageCode ?? 'system',
        onSelected: (value) async {
          try {
            await AppLanguageController.instance.select(value);
          } catch (_) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(l.languageSaveFailed)));
            }
          }
        },
        itemBuilder: (_) => [
          PopupMenuItem(value: 'system', child: Text(l.languageSystem)),
          const PopupMenuItem(value: 'id', child: Text('Bahasa Indonesia')),
          const PopupMenuItem(value: 'en', child: Text('English')),
        ],
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.language, size: 20),
              const SizedBox(width: 6),
              Text(code == 'en' ? 'EN' : 'ID'),
              const Icon(Icons.expand_more, size: 18),
            ],
          ),
        ),
      );
    },
  );
}
