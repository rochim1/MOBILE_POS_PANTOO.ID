import '../../l10n/pos_localization.dart';

/// Reuses the mobile catalog; the local screen has no separate translations.
Map<String, String> localCustomerDisplayCopy() => {
  'title': 'Layar Pelanggan'.trCurrent(),
  'summary': 'Ringkasan belanja Anda'.trCurrent(),
  'connecting': 'Menghubungkan…'.trCurrent(),
  'fullscreen': 'Layar penuh'.trCurrent(),
  'exitFullscreen': 'Keluar layar penuh'.trCurrent(),
  'waiting': 'Menunggu kasir menambahkan produk.'.trCurrent(),
  'fullscreenError':
      'Layar penuh belum dapat dibuka. Coba lagi dari browser perangkat ini.'
          .trCurrent(),
  'connected': 'Terhubung'.trCurrent(),
  'disconnected': 'Koneksi terputus · mencoba ulang'.trCurrent(),
  'paymentSuccess': 'Pembayaran berhasil!'.trCurrent(),
  'completed': 'Transaksi Anda telah selesai.'.trCurrent(),
  'thanks': 'Terima kasih telah berbelanja.'.trCurrent(),
  'empty': 'Keranjang masih kosong'.trCurrent(),
  'dataError': 'Data belum dapat ditampilkan'.trCurrent(),
  'subtotal': 'Subtotal'.trCurrent(),
  'discount': 'Diskon'.trCurrent(),
  'total': 'Total'.trCurrent(),
};
