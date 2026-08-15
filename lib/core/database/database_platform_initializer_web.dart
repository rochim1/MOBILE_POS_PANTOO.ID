// Offline SQLite sengaja tidak digunakan di web. Jangan mengganti factory
// global sqflite karena seluruh operasi web dikirim langsung ke server.
void initializePlatformDatabase() {}

// Web worker/WASM tidak dijadikan syarat operasi kasir. Transaksi web harus
// mendapat konfirmasi server dan tidak boleh dianggap tersimpan offline bila
// browser tidak menyediakan database worker yang valid.
bool get supportsOfflineDatabase => false;
