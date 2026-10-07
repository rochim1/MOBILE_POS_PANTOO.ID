import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:printing/printing.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/themes/colors_theme.dart';
import '../../../widgets/app_toast.dart';
import '../utils/pos_table_qr_document.dart';
import '../utils/pos_table_qr_branding.dart';
import '../utils/pos_table_qr_print_settings.dart';
import 'pos_table_qr_print_settings_dialog.dart';

class PosTableQrSheet extends StatefulWidget {
  const PosTableQrSheet({
    super.key,
    required this.entry,
    required this.preferences,
    required this.instansiId,
  });

  final PosTableQrEntry entry;
  final SharedPreferences preferences;
  final String instansiId;

  @override
  State<PosTableQrSheet> createState() => _PosTableQrSheetState();
}

class _PosTableQrSheetState extends State<PosTableQrSheet> {
  bool _printing = false;
  bool _sharing = false;
  late PosTableQrPrintSettings _settings;
  Future<Uint8List>? _logoFuture;

  @override
  void initState() {
    super.initState();
    _settings = PosTableQrPrintSettings.load(
      widget.preferences,
      widget.instansiId,
    );
    if (_settings.useLogo) _logoFuture = PosTableQrBranding.loadLogoPng();
  }

  Future<Uint8List> _buildPdf() async {
    final logo = _settings.useLogo
        ? await (_logoFuture ??= PosTableQrBranding.loadLogoPng())
        : null;
    return PosTableQrDocument.build(
      [widget.entry],
      settings: _settings,
      logoBytes: logo,
    );
  }

  Future<void> _editSettings() async {
    final updated = await showDialog<PosTableQrPrintSettings>(
      context: context,
      builder: (_) => PosTableQrPrintSettingsDialog(initial: _settings),
    );
    if (!mounted || updated == null) return;
    await updated.save(widget.preferences, widget.instansiId);
    if (!mounted) return;
    if (updated.useLogo && _logoFuture == null) {
      _logoFuture = PosTableQrBranding.loadLogoPng();
    }
    setState(() => _settings = updated);
  }

  String get _fileName {
    final safeTable = widget.entry.tableName
        .replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '-')
        .replaceAll(RegExp(r'-+'), '-');
    return 'QR-Meja-${safeTable.isEmpty ? 'Pantoo' : safeTable}.pdf';
  }

  Future<void> _print() async {
    if (_printing) return;
    setState(() => _printing = true);
    try {
      final bytes = await _buildPdf();
      await Printing.layoutPdf(
        name: 'QR-${widget.entry.tableName}',
        onLayout: (_) async => bytes,
      );
    } catch (_) {
      if (mounted) AppToast.error(context, 'Gagal menyiapkan cetak QR meja.');
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  Future<void> _share() async {
    if (_sharing) return;
    setState(() => _sharing = true);
    try {
      final bytes = await _buildPdf();
      if (!mounted) return;
      final box = context.findRenderObject() as RenderBox?;
      await SharePlus.instance.share(
        ShareParams(
          text:
              'Pesan dari ${widget.entry.tableName} di '
              '${widget.entry.storeName}: ${widget.entry.url}',
          subject: 'QR meja ${widget.entry.tableName}',
          files: [
            XFile.fromData(bytes, mimeType: 'application/pdf', name: _fileName),
          ],
          fileNameOverrides: [_fileName],
          sharePositionOrigin: box == null
              ? null
              : box.localToGlobal(Offset.zero) & box.size,
        ),
      );
    } catch (_) {
      if (mounted) AppToast.error(context, 'Gagal membagikan QR meja.');
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }

  Future<void> _open() async {
    if (!await launchUrl(
          widget.entry.url,
          mode: LaunchMode.externalApplication,
        ) &&
        mounted) {
      AppToast.error(context, 'Tautan Web Order tidak dapat dibuka.');
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'QR ${widget.entry.tableName}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 4),
          Text(
            [
              widget.entry.storeName,
              widget.entry.location,
            ].where((value) => value.isNotEmpty).join(' · '),
            textAlign: TextAlign.center,
            style: const TextStyle(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          _PosTableQrPreview(
            entry: widget.entry,
            settings: _settings,
            logoFuture: _logoFuture,
          ),
          const SizedBox(height: 12),
          SelectableText(
            widget.entry.url.toString(),
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppColors.body),
          ),
          const SizedBox(height: 12),
          const Text(
            'Uji tautan sebelum menempel QR. Pesanan masuk ke daftar pesanan aktif dengan sumber Web Order.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 6),
          const Text(
            'QR ini permanen. Pantau pesanan Web Order sebelum staf mulai menyiapkannya.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.warning),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _editSettings,
            icon: const Icon(Icons.tune_outlined),
            label: const Text('Pengaturan Cetak QR'),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: _open,
                icon: const Icon(Icons.open_in_new),
                label: const Text('Uji tautan'),
              ),
              OutlinedButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: widget.entry.url.toString()),
                  );
                  if (context.mounted) {
                    AppToast.success(context, 'Tautan meja disalin.');
                  }
                },
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Salin'),
              ),
              OutlinedButton.icon(
                onPressed: _sharing ? null : _share,
                icon: _sharing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.share_outlined),
                label: Text(_sharing ? 'Menyiapkan…' : 'Bagikan'),
              ),
              FilledButton.icon(
                onPressed: _printing ? null : _print,
                icon: _printing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.print_outlined),
                label: Text(_printing ? 'Menyiapkan…' : 'Cetak QR'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

class _PosTableQrPreview extends StatelessWidget {
  const _PosTableQrPreview({
    required this.entry,
    required this.settings,
    required this.logoFuture,
  });

  final PosTableQrEntry entry;
  final PosTableQrPrintSettings settings;
  final Future<Uint8List>? logoFuture;

  @override
  Widget build(BuildContext context) {
    final dark = settings.theme == 'dark';
    final background = dark
        ? const Color(0xFF2D2D2D)
        : settings.theme == 'primary'
        ? AppColors.primaryLight
        : Colors.white;
    final foreground = dark ? Colors.white : AppColors.heading;
    final muted = dark ? Colors.white70 : AppColors.textSecondary;
    final accent = dark ? const Color(0xFF6EE7D6) : AppColors.primary;
    final details = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (settings.useLogo && logoFuture != null)
          FutureBuilder<Uint8List>(
            future: logoFuture,
            builder: (context, snapshot) => snapshot.hasData
                ? Image.memory(snapshot.data!, height: 42, fit: BoxFit.contain)
                : const SizedBox.shrink(),
          ),
        Text(
          entry.storeName,
          textAlign: TextAlign.center,
          style: TextStyle(color: foreground, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 4),
        Text(
          settings.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: foreground,
            fontSize: 19,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (settings.subtitle.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            settings.subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ],
        const SizedBox(height: 10),
        Text(
          entry.tableName,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: accent,
            fontSize: 25,
            fontWeight: FontWeight.w900,
          ),
        ),
        if (entry.capacity > 0)
          Text(
            'Kapasitas: ${entry.capacity} Orang',
            style: TextStyle(color: muted, fontSize: 12),
          ),
        if (entry.location.isNotEmpty)
          Text(entry.location, style: TextStyle(color: muted, fontSize: 11)),
      ],
    );
    final qr = Container(
      color: Colors.white,
      padding: const EdgeInsets.all(8),
      child: QrImageView(data: entry.url.toString(), size: 154),
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide =
            settings.orientation == 'landscape' && constraints.maxWidth >= 480;
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: wide
              ? Row(
                  children: [
                    Expanded(child: details),
                    const SizedBox(width: 12),
                    qr,
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [details, const SizedBox(height: 12), qr],
                ),
        );
      },
    );
  }
}
