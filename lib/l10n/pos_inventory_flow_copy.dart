import 'package:flutter/widgets.dart';
import 'pos_localization.dart';

/// Feature-specific copy; wire values and warehouse names are never translated.
const inventoryFlowCopy = <String, (String, String)>{
  'title': ('Alur stok inventori', 'Inventory flow'),
  'intro': (
    'Berlaku untuk seluruh instansi dan tersinkron dengan web. Tidak memindahkan stok atau mengubah lokasi toko.',
    'Applies across this business and syncs with the web. It does not move stock or change store locations.',
  ),
  'profile': ('Profil inventori', 'Inventory profile'),
  'flow': ('Alur stok', 'Stock flow'),
  'transitSetupTitle': ('Siapkan perpindahan stok', 'Prepare stock transfers'),
  'transitSetupHelp': (
    'Lokasi perjalanan menampung stok selama dikirim hingga diterima. Anda tidak perlu mengisi form gudang terpisah.',
    'The in-transit location holds dispatched stock until it is received. No separate warehouse form is needed.',
  ),
  'transitPrepareOnSave': (
    'Siapkan otomatis saat disimpan',
    'Prepare automatically when saving',
  ),
  'transitPrepareHint': (
    'Lokasi internal dibuat sekali. Stok dan transfer yang sudah ada tidak dipindahkan.',
    'The internal location is created once. Existing stock and transfers are not moved.',
  ),
  'transitPreparedOnSave': ('Disiapkan saat disimpan', 'Prepared when saving'),
  'transitConfirmPrepare': (
    'Lokasi internal Barang dalam perjalanan akan disiapkan bersama pengaturan ini. Jika penyimpanan gagal, lokasi baru tidak ditinggalkan.',
    'An internal in-transit location will be prepared with these settings. A failed save will not leave a new location behind.',
  ),
  'transitUseExisting': (
    'Gunakan lokasi perjalanan yang tersedia',
    'Use the existing in-transit location',
  ),
  'transitSelectExisting': (
    'Ada beberapa lokasi perjalanan. Pilih salah satu pada kolom lokasi perjalanan; lokasi baru tidak perlu dibuat.',
    'There are several in-transit locations. Select one in the location field; no new location is needed.',
  ),
  'transitSetupPermission': (
    'Minta admin menyiapkan lokasi perjalanan. Akun ini belum memiliki izin membuat lokasi gudang.',
    'Ask an administrator to prepare an in-transit location. This account cannot create warehouse locations.',
  ),
  'transitChooseMovement': (
    'Pilih Pakai perpindahan stok terlebih dahulu.',
    'Choose Use stock transfers first.',
  ),
  'directChoice': ('Stok langsung dijual', 'Sell stock directly'),
  'movementChoice': ('Pakai perpindahan stok', 'Use stock transfers'),
  'detailProfile': (
    'Konfigurasi rinci inventori',
    'Detailed inventory configuration',
  ),
  'movementHelp': (
    'Pindahkan stok antar toko/gudang atau antar lokasi sesuai kebutuhan. Aturan gudang, display, persetujuan, dan transit dapat diatur melalui Pengaturan lanjutan. Transfer antar cabang dengan aturan sistem memerlukan lokasi transit.',
    'Move stock between stores/warehouses or locations as needed. Warehouse, display, approval and transit rules are available in Advanced options. Inter-branch transfers using system defaults require a transit location.',
  ),
  'simple': ('Sederhana', 'Simple'),
  'centralized': ('Terpusat', 'Centralized'),
  'advanced': ('Lengkap', 'Advanced'),
  'custom': ('Kustom', 'Custom'),
  'simpleHelp': (
    'Stok diterima langsung pada lokasi utama. Tidak memakai alur transfer.',
    'Receive stock directly at the main location. No transfer workflow.',
  ),
  'centralizedHelp': (
    'Gudang pusat → transfer dengan persetujuan → penerimaan gudang toko. Siapkan gudang pusat dan lokasi transit terlebih dahulu.',
    'Central warehouse → approved transfer → store receiving. Set up a central warehouse and a transit location first.',
  ),
  'advancedHelp': (
    'Alur terpusat dengan stok display terpisah. Gudang toko dan display harus terhubung ke toko POS yang sama.',
    'Centralized flow with separate display stock. The store warehouse and display must be linked to the same POS store.',
  ),
  'customHelp': (
    'Pilih kebutuhan di pengaturan lanjutan. Transfer antar toko/gudang dan mutasi internal mengikuti aturan lokasi yang sama seperti web.',
    'Choose the options below. Inter-store/warehouse transfers and internal moves use the same location rules as the web.',
  ),
  'receiving': ('Lokasi penerimaan utama', 'Default receiving location'),
  'transit': ('Lokasi transit', 'Transit location'),
  'none': ('Belum dipilih', 'Not selected'),
  'unavailable': (
    'Lokasi tersimpan tidak tersedia',
    'Saved location is unavailable',
  ),
  'locationsHelp': (
    'Kelola jenis gudang dan tautan toko melalui Warehouse & Lokasi. Lokasi transit tidak boleh menjadi lokasi penjualan.',
    'Manage warehouse types and store links in Warehouse & Locations. Transit locations cannot be selling locations.',
  ),
  'advancedOptions': ('Pengaturan lanjutan', 'Advanced options'),
  'use_central_warehouse': ('Gudang pusat', 'Central warehouse'),
  'use_transfer_request': ('Permintaan transfer', 'Transfer requests'),
  'use_transfer_approval': ('Persetujuan transfer', 'Transfer approval'),
  'use_in_transit': ('Stok dalam perjalanan', 'In-transit stock'),
  'use_store_warehouse': ('Gudang toko', 'Store warehouse'),
  'use_display_stock': ('Stok display', 'Display stock'),
  'allow_direct_purchase_to_store': (
    'Pembelian langsung ke toko',
    'Direct purchases to stores',
  ),
  'allow_over_receipt': ('Izinkan penerimaan berlebih', 'Allow over-receiving'),
  'tolerance': (
    'Toleransi penerimaan berlebih (%)',
    'Over-receiving tolerance (%)',
  ),
  'transfer_cross_branch_rule': (
    'Transfer antar cabang pengelola',
    'Transfers across managing branches',
  ),
  'transfer_same_branch_rule': (
    'Transfer antar lokasi satu cabang',
    'Transfers within a managing branch',
  ),
  'transfer_store_display_rule': (
    'Gudang toko ↔ display toko yang sama',
    'Store warehouse ↔ display in the same store',
  ),
  'system_default': ('Ikuti aturan sistem', 'System default'),
  'direct': ('Langsung', 'Direct'),
  'transitRule': ('Kirim lalu terima', 'Dispatch then receive'),
  'routingHelp': (
    'Langsung: stok masuk tujuan saat dikirim, tanpa konfirmasi terima. Aturan sistem: antar cabang menggunakan transit; gudang toko ↔ display menggunakan langsung. Dokumen yang sudah dikirim tetap memakai aturan saat pengiriman.',
    'Direct: stock reaches its destination on dispatch without receiving confirmation. System default: inter-branch transfers use transit; store warehouse ↔ display uses direct transfer. Dispatched documents keep their original routing.',
  ),
  'readOnly': (
    'Anda hanya memiliki izin melihat pengaturan inventori.',
    'You have read-only access to inventory settings.',
  ),
  'save': ('Simpan alur stok', 'Save inventory flow'),
  'saving': ('Menyimpan…', 'Saving…'),
  'confirmTitle': (
    'Ubah alur stok instansi?',
    'Change the business inventory flow?',
  ),
  'confirmBody': (
    'Perubahan berlaku di mobile dan web. Tidak membuat transfer, memindahkan stok, atau mengubah konfigurasi lokasi lama. Periksa lokasi dan aturan pengiriman sebelum melanjutkan.',
    'This changes mobile and web settings. It does not create transfers, move stock, or change existing location configuration. Review the locations and dispatch rules before continuing.',
  ),
  'confirm': ('Ya, simpan', 'Yes, save'),
  'cancel': ('Batal', 'Cancel'),
  'reload': ('Muat ulang pengaturan', 'Reload settings'),
  'refresh': ('Sinkronkan menu', 'Sync menus'),
  'saved': (
    'Alur stok tersimpan dan menu diperbarui.',
    'Inventory flow saved and menus updated.',
  ),
  'refreshPending': (
    'Alur stok sudah tersimpan. Menu belum diperbarui; sinkronkan menu tanpa menyimpan ulang.',
    'Inventory flow is saved. Menus have not updated yet; sync menus without saving again.',
  ),
  'forbidden': (
    'Akun ini tidak memiliki izin pengaturan inventori. Minta admin memberikan izin yang sesuai, lalu muat ulang.',
    'This account does not have inventory settings permission. Ask an administrator for the required access, then reload.',
  ),
  'conflict': (
    'Pengaturan telah diubah dari perangkat lain. Muat ulang versi terbaru sebelum mengedit lagi.',
    'Settings changed on another device. Reload the latest version before editing again.',
  ),
  'uncertain': (
    'Hasil simpan belum dapat dipastikan. Jangan simpan ulang; muat ulang untuk memeriksa pengaturan di server.',
    'The save result is uncertain. Do not save again; reload to check the server settings.',
  ),
  'connection': (
    'Pengaturan belum dapat dimuat. Sambungkan internet lalu coba lagi. Perubahan alur stok tidak tersedia saat offline.',
    'Could not load settings. Connect to the internet and try again. Inventory flow cannot be changed offline.',
  ),
  'session': (
    'Akun atau instansi berubah. Muat ulang pengaturan untuk akun yang aktif.',
    'The account or business changed. Reload settings for the active account.',
  ),
  'validation': (
    'Pengaturan belum dapat diterapkan. Periksa pilihan alur stok.',
    'Settings could not be applied. Review the inventory flow options.',
  ),
  'displayRequiresStore': (
    'Stok display memerlukan gudang toko.',
    'Display stock requires a store warehouse.',
  ),
  'approvalRequiresRequest': (
    'Persetujuan transfer memerlukan permintaan transfer.',
    'Transfer approval requires transfer requests.',
  ),
  'transitRequiresRequest': (
    'Stok dalam perjalanan memerlukan permintaan transfer.',
    'In-transit stock requires transfer requests.',
  ),
  'requestRequiresWarehouse': (
    'Permintaan transfer memerlukan gudang pusat atau gudang toko.',
    'Transfer requests require a central or store warehouse.',
  ),
  'trackingRequired': (
    'Aktifkan pelacakan stok di pengaturan Transaksi & Penjualan terlebih dahulu.',
    'Enable stock tracking in Sales & Transactions settings first.',
  ),
  'invalidTolerance': (
    'Toleransi harus berupa angka 0–100%.',
    'Tolerance must be a number between 0 and 100%.',
  ),
  'invalidRule': (
    'Pilih aturan transfer yang tersedia.',
    'Choose a supported transfer rule.',
  ),
  'transitRequired': (
    'Pilih lokasi transit aktif. Buat lokasi berjenis transit di Warehouse & Lokasi jika belum ada.',
    'Select an active transit location. Create a transit-type location in Warehouse & Locations if needed.',
  ),
  'centralRequired': (
    'Siapkan gudang pusat aktif di Warehouse & Lokasi terlebih dahulu.',
    'Set up an active central warehouse in Warehouse & Locations first.',
  ),
  'receivingInvalid': (
    'Lokasi penerimaan tidak sesuai alur yang dipilih. Pilih ulang lokasi yang tersedia.',
    'The receiving location is not compatible with this flow. Choose an available location.',
  ),
  'receivingRequired': (
    'Ada beberapa lokasi stok. Pilih lokasi penerimaan utama untuk profil sederhana.',
    'There are multiple stock locations. Choose a default receiving location for the simple profile.',
  ),
  'Selesaikan atau batalkan transfer aktif sebelum beralih ke profil inventori sederhana. Periksa menu Mutasi Stok / Transfer.': (
    'Selesaikan atau batalkan transfer aktif sebelum beralih ke profil inventori sederhana. Periksa menu Mutasi Stok / Transfer.',
    'Complete or cancel active transfers before switching to the simple inventory profile. Check Stock Moves / Transfers.',
  ),
};

String inventoryFlowText(BuildContext context, String key) {
  if (key ==
      'Pilih Default Lokasi Receiving untuk Profil Inventory Simple yang memiliki lebih dari satu warehouse') {
    key = 'receivingRequired';
  }
  final copy = inventoryFlowCopy[key];
  if (copy == null) return key.tr(context); // Authoritative server validation.
  return posLocale(context).localeName.startsWith('en') ? copy.$2 : copy.$1;
}
