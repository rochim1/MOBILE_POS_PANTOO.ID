import 'package:dartz/dartz.dart' hide State;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:mobile_pos_pantoo/core/error/failures.dart';
import 'package:mobile_pos_pantoo/core/reports/pos_report_export.dart';
import 'package:mobile_pos_pantoo/domain/repositories/pos_financial_report_repository.dart';
import 'package:mobile_pos_pantoo/l10n/pos_localization.dart';

class FinancialReportExportButton extends StatefulWidget {
  const FinancialReportExportButton({
    super.key,
    required this.load,
    required this.isCurrent,
    required this.enabled,
    this.share,
  });
  final Future<Either<Failure, PosReportExportDocument>> Function() load;
  final bool Function() isCurrent;
  final bool enabled;
  final Future<ShareResult> Function(ShareParams)? share;
  @override
  State<FinancialReportExportButton> createState() =>
      _FinancialReportExportButtonState();
}

class _FinancialReportExportButtonState
    extends State<FinancialReportExportButton> {
  bool _busy = false;
  Future<void> _export(bool pdf) async {
    final load = widget.load,
        current = widget.isCurrent,
        l = posLocale(context);
    if (_busy || !widget.enabled || !current()) return;
    setState(() => _busy = true);
    try {
      final result = await load();
      if (!mounted || !current()) return;
      final document = result.fold(
        (failure) => throw failure,
        (document) => document,
      );
      final bytes = pdf ? await document.pdf() : document.csv();
      if (!mounted || !current()) return;
      final render = context.findRenderObject();
      final origin = render is RenderBox
          ? render.localToGlobal(Offset.zero) & render.size
          : const Rect.fromLTWH(0, 0, 1, 1);
      await (widget.share ?? SharePlus.instance.share)(
        ShareParams(
          files: [
            XFile.fromData(
              bytes,
              mimeType: pdf ? 'application/pdf' : 'text/csv',
              name: '${document.fileStem}.${pdf ? 'pdf' : 'csv'}',
            ),
          ],
          fileNameOverrides: ['${document.fileStem}.${pdf ? 'pdf' : 'csv'}'],
          sharePositionOrigin: origin,
        ),
      );
    } catch (error) {
      if (mounted && current()) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              error is FinancialReportChangedFailure
                  ? l.businessExportChanged
                  : error is ReportExportSizeFailure ||
                        error is FinancialReportExportLimitFailure
                  ? l.businessExportLimit
                  : error is ReportExportUnsupportedGlyph
                  ? l.businessPdfGlyph
                  : l.businessExportFailed,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => _busy
      ? const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        )
      : PopupMenuButton<bool>(
          enabled: widget.enabled,
          tooltip: posLocale(context).businessExport,
          icon: const Icon(Icons.file_download_outlined),
          onSelected: _export,
          itemBuilder: (context) => [
            PopupMenuItem(
              value: false,
              child: Text(posLocale(context).businessCsv),
            ),
            PopupMenuItem(
              value: true,
              child: Text(posLocale(context).businessPdf),
            ),
          ],
        );
}
