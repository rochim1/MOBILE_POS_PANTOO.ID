/// Display-only compatibility for old routing descriptions, never wire values
/// or customer-defined warehouse names.
String inventoryTransferReasonText(String reason) => reason
    .replaceAll(
      RegExp(r'\bwajib transit\b', caseSensitive: false),
      'wajib mencatat barang dalam perjalanan',
    )
    .replaceAll(
      RegExp(r'\bmelalui transit\b', caseSensitive: false),
      'melalui pencatatan barang dalam perjalanan',
    )
    .replaceAll(
      RegExp(r'\b(?:in transit|transit)\b', caseSensitive: false),
      'barang dalam perjalanan',
    );
