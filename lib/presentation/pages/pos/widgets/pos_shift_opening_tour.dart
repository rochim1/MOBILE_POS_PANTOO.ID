import 'pos_setup_tour.dart';

/// Descriptions only. No step submits a financial operation for the user.
List<PosSetupTourStage> posShiftOpeningTourStages(
  PosSetupTourTargets targets,
) => [
  PosSetupTourStage(
    title: 'Periksa toko dan kasir',
    description:
        'Pastikan toko yang dipilih adalah tempat Anda bertugas. Shift aktif akan dipakai kembali; tidak perlu membuat shift kedua.',
    target: targets.shiftStore,
  ),
  PosSetupTourStage(
    title: 'Isi kas awal',
    description:
        'Hitung uang tunai di laci sebelum mulai berjualan. Masukkan nilainya di sini; boleh nol sesuai aturan toko. Kas awal bukan omzet atau tambahan stok.',
    target: targets.shiftOpeningCash,
  ),
  PosSetupTourStage(
    title: 'Tambahkan catatan bila perlu',
    description:
        'Catatan bersifat opsional, misalnya serah terima laci atau keterangan modal awal. Biarkan kosong jika tidak diperlukan.',
    target: targets.shiftOpeningNotes,
  ),
  PosSetupTourStage(
    title: 'Periksa lalu buka shift',
    description:
        'Tutup panduan, periksa isian lalu ketuk Buka Shift Sekarang. Tunggu proses berhasil. Pada persiapan awal, aplikasi melanjutkan ke kasir. Jika gagal, periksa pesan dan coba lagi; jangan membuat shift kedua.',
    target: targets.shiftOpen,
  ),
];
