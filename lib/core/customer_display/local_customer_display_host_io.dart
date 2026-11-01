import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// A token-protected, read-only customer screen served directly by the POS.
/// No cloud, API credentials, or persistent customer data are exposed.
class LocalCustomerDisplayHost {
  HttpServer? _server;
  String _token = '';
  Map<String, dynamic>? _lastState;
  final Set<WebSocket> _viewers = {};
  void Function(int)? _onClientCountChanged;

  Future<String> start(
    String token, {
    required void Function(int) onClientCountChanged,
    String? advertisedHost,
  }) async {
    await stop();
    final interfaces = advertisedHost != null
        ? <NetworkInterface>[]
        : await NetworkInterface.list(
            includeLoopback: false,
            type: InternetAddressType.IPv4,
          );
    final candidates = <({String name, InternetAddress address})>[
      for (final network in interfaces)
        for (final address in network.addresses)
          if (_isPrivateIpv4(address.address))
            (name: network.name.toLowerCase(), address: address),
    ];
    candidates.sort(
      (a, b) => _interfaceRank(a.name).compareTo(_interfaceRank(b.name)),
    );
    if (candidates.isEmpty && advertisedHost == null) {
      throw StateError(
        'Sambungkan ponsel POS ke Wi-Fi atau nyalakan hotspot, lalu coba lagi.',
      );
    }
    // Do not advertise mobile-data/VPN IPs as if they were reachable on LAN.
    final local = candidates.where(
      (candidate) => _interfaceRank(candidate.name) < 2,
    );
    if (local.isEmpty && advertisedHost == null) {
      throw StateError(
        'Alamat Wi-Fi lokal tidak ditemukan. Sambungkan ponsel POS ke Wi-Fi atau nyalakan hotspot.',
      );
    }
    final server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    _server = server;
    _token = token;
    _onClientCountChanged = onClientCountChanged;
    server.listen((request) => unawaited(_handleRequest(request)));
    return 'http://${advertisedHost ?? local.first.address.address}:${server.port}/?pair=$token';
  }

  static bool _isPrivateIpv4(String address) {
    final parts = address.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((part) => part == null)) return false;
    final a = parts[0]!;
    final b = parts[1]!;
    return a == 10 ||
        (a == 172 && b >= 16 && b <= 31) ||
        (a == 192 && b == 168);
  }

  static int _interfaceRank(String name) {
    if (name.startsWith('wlan') ||
        name.startsWith('wifi') ||
        name.startsWith('wi-fi') ||
        name.startsWith('swlan')) {
      return 0;
    }
    if (name.startsWith('ap') ||
        name.startsWith('softap') ||
        name.startsWith('br') ||
        name.startsWith('eth') ||
        name.startsWith('en')) {
      return 1;
    }
    return 3;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final response = request.response;
    response.headers.set('Cache-Control', 'no-store');
    response.headers.set('X-Content-Type-Options', 'nosniff');
    final valid =
        request.uri.queryParameters['pair'] == _token && _token.isNotEmpty;
    if (!valid) {
      response.statusCode = HttpStatus.forbidden;
      response.write(
        'Tautan layar pelanggan tidak valid. Buat pairing baru di POS.',
      );
      await response.close();
      return;
    }
    if (request.method != 'GET') {
      response.statusCode = HttpStatus.methodNotAllowed;
      await response.close();
      return;
    }
    if (request.uri.path == '/') {
      response.headers.contentType = ContentType.html;
      response.write(_customerScreenHtml);
      await response.close();
    } else if (request.uri.path == '/ws') {
      final socket = await WebSocketTransformer.upgrade(request);
      socket.pingInterval = const Duration(seconds: 20);
      _viewers.add(socket);
      _onClientCountChanged?.call(_viewers.length);
      socket.listen(
        (_) {},
        onDone: () => _removeViewer(socket),
        onError: (_) => _removeViewer(socket),
        cancelOnError: true,
      );
      if (_lastState != null) _send(socket, _lastState!);
    } else {
      response.statusCode = HttpStatus.notFound;
      await response.close();
    }
  }

  void _send(WebSocket viewer, Map<String, dynamic> data) {
    try {
      viewer.add(jsonEncode(data));
    } catch (_) {
      _removeViewer(viewer);
    }
  }

  void _removeViewer(WebSocket viewer) {
    if (_viewers.remove(viewer)) {
      _onClientCountChanged?.call(_viewers.length);
    }
  }

  void publish(Map<String, dynamic> data) {
    _lastState = data;
    for (final viewer in _viewers.toList()) {
      _send(viewer, data);
    }
  }

  Future<void> stop() async {
    _token = '';
    _lastState = null;
    _onClientCountChanged = null;
    for (final viewer in _viewers.toList()) {
      try {
        await viewer.close().timeout(const Duration(seconds: 1));
      } catch (_) {}
    }
    _viewers.clear();
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }
}

const _customerScreenHtml = r'''<!doctype html>
<html lang="id"><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1">
<meta http-equiv="Content-Security-Policy" content="default-src 'none'; connect-src 'self' ws:; style-src 'unsafe-inline'; script-src 'unsafe-inline'">
<title>Layar Pelanggan · Pantoo POS</title>
<style>
*{box-sizing:border-box}body{margin:0;font:18px system-ui,sans-serif;background:#eef6f5;color:#172033}.shell{max-width:900px;min-height:100vh;margin:auto;background:white;display:flex;flex-direction:column;box-shadow:0 0 30px #0a51451c}header{padding:24px 30px;background:#087f75;color:white;display:flex;align-items:center;justify-content:space-between;gap:16px}h1{font-size:25px;margin:0}small{font-size:14px;opacity:.85}.status{font-size:14px;padding:7px 12px;border-radius:99px;background:#ffffff25}main{flex:1;padding:30px}.empty{color:#667085;text-align:center;padding:15vh 12px}.item{display:flex;align-items:center;gap:20px;padding:15px 0;border-bottom:1px solid #e5e7eb}.qty{min-width:46px;color:#087f75;font-weight:800}.name{flex:1;overflow-wrap:anywhere}.price{font-weight:700}footer{padding:20px 30px;background:#f7f9f9}footer div{display:flex;justify-content:space-between;margin:8px 0}.total{font-size:27px;font-weight:800;border-top:1px dashed #9ca3af;padding-top:15px}@media(max-width:600px){header,main,footer{padding:17px}h1{font-size:19px}.item{font-size:16px}.total{font-size:23px}}
</style></head><body><div class="shell"><header><div><h1 id="store">Pantoo POS</h1><small>Ringkasan belanja Anda</small></div><span class="status" id="status">Menghubungkan…</span></header><main id="items"><p class="empty">Menunggu kasir menambahkan produk.</p></main><footer id="footer" hidden><div><span>Subtotal</span><strong id="subtotal"></strong></div><div id="discount-row" hidden><span>Diskon</span><strong id="discount"></strong></div><div class="total"><span>Total</span><strong id="total"></strong></div></footer></div>
<script>
const token=new URLSearchParams(location.search).get('pair');
const money=n=>new Intl.NumberFormat('id-ID',{style:'currency',currency:'IDR',maximumFractionDigits:0}).format(Number(n)||0);
const items=document.getElementById('items'),footer=document.getElementById('footer'),status=document.getElementById('status');
function connect(){const socket=new WebSocket('ws://'+location.host+'/ws?pair='+encodeURIComponent(token||''));socket.onopen=()=>{status.textContent='Terhubung'};socket.onclose=()=>{status.textContent='Koneksi terputus · mencoba ulang';setTimeout(connect,3000)};socket.onerror=()=>socket.close();socket.onmessage=event=>{try{const data=JSON.parse(event.data);document.getElementById('store').textContent=data.store_name||'Pantoo POS';items.replaceChildren();if(data.status==='payment_success'){const p=document.createElement('p');p.className='empty';p.textContent='Pembayaran berhasil. Terima kasih telah berbelanja.';items.append(p);footer.hidden=true;return}for(const item of data.items||[]){const row=document.createElement('div');row.className='item';const qty=document.createElement('span');qty.className='qty';qty.textContent=(Number(item.quantity)||0)+'×';const name=document.createElement('span');name.className='name';name.textContent=item.name||'';const price=document.createElement('span');price.className='price';price.textContent=money(item.subtotal);row.append(qty,name,price);items.append(row)}if(!items.children.length){const p=document.createElement('p');p.className='empty';p.textContent='Keranjang masih kosong';items.append(p)}document.getElementById('subtotal').textContent=money(data.subtotal);document.getElementById('discount').textContent='− '+money(data.discount);document.getElementById('discount-row').hidden=!(Number(data.discount)>0);document.getElementById('total').textContent=money(data.total);footer.hidden=false}catch(e){status.textContent='Data belum dapat ditampilkan'}}}connect();
</script></body></html>''';
