import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_table_qr_document.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_table_qr_link.dart';
import 'package:mobile_pos_pantoo/presentation/pages/pos/utils/pos_table_qr_print_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const instansiId = '6880deee12b28601774a5cd4';
  const storeId = '6880deee12b28601774a5cd5';
  const tableId = '6880deee12b28601774a5cd6';

  test('default Web Order URL matches web admin production', () {
    expect(PosTableQrLink.configuredBaseUrl, 'https://order.pantoo.id');
  });

  test('print preferences use web defaults and remain tenant-scoped', () async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final defaults = PosTableQrPrintSettings.load(preferences, instansiId);
    expect(defaults.title, 'Scan & Pesan');
    expect(defaults.useLogo, isTrue);
    expect(defaults.orientation, 'portrait');
    expect(defaults.theme, 'light');

    final custom = defaults.copyWith(
      title: 'Pesan di sini',
      orientation: 'landscape',
      theme: 'dark',
    );
    expect(await custom.save(preferences, instansiId), isTrue);
    expect(
      PosTableQrPrintSettings.load(preferences, instansiId).title,
      'Pesan di sini',
    );
    expect(
      PosTableQrPrintSettings.load(preferences, 'another-tenant').title,
      'Scan & Pesan',
    );
  });

  test('QR URL follows the Web Order table route', () {
    final link = PosTableQrLink.forTable(
      baseUrl: 'https://order.example.com/pantoo/',
      instansiId: instansiId,
      storeId: storeId,
      tableId: tableId,
    );
    expect(
      link.toString(),
      'https://order.example.com/pantoo/$instansiId/$storeId/$tableId',
    );
  });

  test('QR rejects non-public, insecure and invalid table URLs', () {
    expect(PosTableQrLink.parseBaseUrl('http://order.example.com'), isNull);
    expect(PosTableQrLink.parseBaseUrl('https://localhost:5174'), isNull);
    expect(
      PosTableQrLink.parseBaseUrl('https://order.example.com/?x=1'),
      isNull,
    );
    expect(
      PosTableQrLink.forTable(
        baseUrl: 'https://order.example.com',
        instansiId: instansiId,
        storeId: storeId,
        tableId: 'not-a-table-id',
      ),
      isNull,
    );
  });

  test(
    'print document includes a QR card and supports multiple tables',
    () async {
      final entries = [
        for (var index = 0; index < 5; index++)
          PosTableQrEntry(
            storeName: 'Toko Utama',
            tableName: 'Meja ${index + 1}',
            area: 'Outdoor',
            floor: 'Lantai 1',
            url: Uri.parse(
              'https://order.example.com/$instansiId/$storeId/$tableId',
            ),
          ),
      ];
      final bytes = await PosTableQrDocument.build(entries);
      expect(bytes.length, greaterThan(2000));
      expect(entries.first.location, 'Lantai 1 · Outdoor');
    },
  );

  test('all print themes and orientations build with logo', () async {
    final logo = await rootBundle.load('assets/images/pantoo.png');
    final entry = PosTableQrEntry(
      storeName: 'Toko Utama',
      tableName: 'Meja 1',
      capacity: 4,
      area: 'Outdoor',
      floor: 'Lantai 1',
      url: Uri.parse('https://order.pantoo.id/$instansiId/$storeId/$tableId'),
    );
    for (final orientation in ['portrait', 'landscape']) {
      for (final theme in ['light', 'dark', 'primary']) {
        final bytes = await PosTableQrDocument.build(
          [entry, entry, entry],
          settings: PosTableQrPrintSettings(
            orientation: orientation,
            theme: theme,
          ),
          logoBytes: logo.buffer.asUint8List(
            logo.offsetInBytes,
            logo.lengthInBytes,
          ),
        );
        expect(bytes.length, greaterThan(2000));
      }
    }
  });
}
