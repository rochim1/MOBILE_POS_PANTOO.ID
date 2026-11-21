import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../domain/repositories/pos_product_import_repository.dart';

class PosImportFile {
  final String name;
  final Uint8List bytes;
  const PosImportFile(this.name, this.bytes);
}

class PosProductImportPage extends StatefulWidget {
  final PosProductImportRepository repository;
  final bool canImport, offline;
  final Future<PosImportFile?> Function()? pickFile;
  final Future<void> Function()? saveTemplate;
  const PosProductImportPage({
    super.key,
    required this.repository,
    required this.canImport,
    this.offline = false,
    this.pickFile,
    this.saveTemplate,
  });
  @override
  State<PosProductImportPage> createState() => _PosProductImportPageState();
}

class _PosProductImportPageState extends State<PosProductImportPage> {
  PosImportFile? _file;
  PosProductImportResult? _preview, _result;
  String? _error;
  bool _busy = false, _templateBusy = false;
  Future<void> _pick() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      PosImportFile? selected;
      if (widget.pickFile != null) {
        selected = await widget.pickFile!();
      } else {
        final picked = await FilePicker.platform.pickFiles(
          type: FileType.custom,
          allowedExtensions: ['csv', 'xlsx', 'xls'],
          withData: true,
        );
        final row = picked?.files.single;
        if (row != null && row.bytes != null) {
          selected = PosImportFile(row.name, row.bytes!);
        }
      }
      if (selected == null || !mounted) return;
      setState(() {
        _file = selected;
        _preview = null;
        _result = null;
        _error = null;
      });
      if (widget.repository.pending == null) {
        final preview = await widget.repository.upload(
          bytes: selected.bytes,
          filename: selected.name,
          preview: true,
        );
        if (mounted) setState(() => _preview = preview);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _import() async {
    final file = _file;
    if (_busy || file == null || !widget.canImport || widget.offline) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await widget.repository.upload(
        bytes: file.bytes,
        filename: file.name,
        preview: false,
      );
      if (mounted) setState(() => _result = result);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _template() async {
    if (_templateBusy) return;
    setState(() => _templateBusy = true);
    try {
      if (widget.saveTemplate != null) {
        await widget.saveTemplate!();
      } else {
        await FilePicker.platform.saveFile(
          dialogTitle: 'Simpan template produk',
          fileName: 'template_import_barang_dagangan.csv',
          bytes: Uint8List.fromList(
            utf8.encode(PosProductImportRepository.template),
          ),
        );
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _templateBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pending = widget.repository.pending;
    final result = _result ?? _preview;
    return PopScope(
      canPop: !_busy && _result == null,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && !_busy && _result != null) {
          Navigator.pop(context, _result);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Import produk'),
          automaticallyImplyLeading: false,
          leading: _busy
              ? null
              : IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context, _result),
                ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Excel / CSV · maksimal 5 MB dan 1000 baris',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const ExpansionTile(
                    title: Text('Petunjuk kolom file'),
                    tilePadding: EdgeInsets.zero,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(bottom: 12),
                        child: Text(
                          'nama_inventaris wajib. kode_inventaris boleh kosong untuk kode otomatis. unit, harga_beli, harga_jual, sku dan barcode mengikuti template. Format SKU/barcode sebagai teks agar angka nol di depan tidak hilang. pos_product_type: product atau service; service_price_mode: fixed atau flexible. HPP layanan opsional. Stok di file diabaikan; isi melalui Stok Awal. Paket/BOM disiapkan lewat form. Pratinjau menampilkan maksimal 30 baris valid.',
                        ),
                      ),
                    ],
                  ),
                  const Text(
                    'Menggunakan master Inventory yang sama dengan web. Import tidak mengisi stok. Setelah produk tersimpan, lanjutkan Stok Awal. Hapus baris contoh jika memakai template web. Template mobile hanya berisi header.',
                  ),
                  const SizedBox(height: 12),
                  if (!widget.canImport)
                    const Text(
                      'Anda belum memiliki izin import inventaris. Minta pengelola memberi akses import.',
                    ),
                  if (widget.offline)
                    const Text(
                      'Import memerlukan koneksi. Template tetap dapat disimpan saat offline.',
                    ),
                  if (pending != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        'Hasil import sebelumnya belum pasti. Pilih kembali file ${pending['filename']} lalu periksa hasilnya. Jangan mengganti file untuk mengulang.',
                      ),
                    ),
                  OutlinedButton.icon(
                    onPressed: _busy || _templateBusy ? null : _template,
                    icon: _templateBusy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download_outlined),
                    label: const Text('Simpan template CSV'),
                  ),
                  OutlinedButton.icon(
                    onPressed: _busy || !widget.canImport || widget.offline
                        ? null
                        : _pick,
                    icon: const Icon(Icons.upload_file),
                    label: Text(_file?.name ?? 'Pilih file Excel / CSV'),
                  ),
                  if (_busy)
                    const Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          SizedBox.square(
                            dimension: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Expanded(child: Text('Memproses file…')),
                        ],
                      ),
                    ),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ),
                  if (result != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _result == null ? 'Pratinjau import' : 'Hasil import',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    if (result.message.isNotEmpty) Text(result.message),
                    Text(
                      '${_result == null ? 'Siap' : 'Berhasil'}: ${result.importedCount} · Gagal: ${result.failedCount} · Dilewati: ${result.skippedCount}',
                    ),
                    if (result.previewRows.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('Baris')),
                            DataColumn(label: Text('Nama')),
                            DataColumn(label: Text('Satuan')),
                            DataColumn(label: Text('Harga jual')),
                          ],
                          rows: result.previewRows
                              .map(
                                (row) => DataRow(
                                  cells: [
                                    DataCell(Text('${row['row']}')),
                                    DataCell(Text('${row['name']}')),
                                    DataCell(Text('${row['unit']}')),
                                    DataCell(Text('${row['price']}')),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    for (final row in [...result.errors, ...result.warnings])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Baris ${row['row']} · ${row['field']}: ${row['message']}',
                        ),
                      ),
                  ],
                  const SizedBox(height: 16),
                  if (_result == null)
                    FilledButton.icon(
                      onPressed:
                          _busy ||
                              _file == null ||
                              !widget.canImport ||
                              widget.offline ||
                              (_preview?.importedCount ?? 0) == 0 &&
                                  pending == null
                          ? null
                          : _import,
                      icon: const Icon(Icons.file_download_done),
                      label: Text(
                        pending != null
                            ? 'Periksa hasil import'
                            : 'Import produk yang valid',
                      ),
                    ),
                  if (_result != null)
                    FilledButton(
                      onPressed: _busy
                          ? null
                          : () => Navigator.pop(context, _result),
                      child: Text(
                        _result!.importedCount > 0
                            ? 'Selesai & lanjutkan'
                            : 'Kembali ke katalog',
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
