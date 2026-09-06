import 'package:flutter/material.dart';

import '../../../../injections.dart';
import '../../../core/_core.dart';
import '../../../domain/repositories/pos_notification_repository.dart';
import '../../widgets/app_toast.dart';

class PosNotificationPage extends StatefulWidget {
  const PosNotificationPage({super.key});

  @override
  State<PosNotificationPage> createState() => _PosNotificationPageState();
}

class _PosNotificationPageState extends State<PosNotificationPage> {
  final _repository = sl<PosNotificationRepository>();
  List<Map<String, dynamic>> _items = const [];
  String _module = '';
  bool _loading = true;
  int _unread = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = _module.isEmpty
        ? await _repository.getOperationalNotifications(limit: 100)
        : await _repository.getNotifications(limit: 100, module: _module);
    if (!mounted) return;
    result.fold((failure) => AppToast.error(context, failure.message), (data) {
      _items = data.items;
      _unread = data.unreadCount;
    });
    setState(() => _loading = false);
  }

  Future<void> _read(Map<String, dynamic> item) async {
    final id = item['_id']?.toString() ?? '';
    if (id.isEmpty || item['is_read'] == true) return;
    setState(() {
      item['is_read'] = true;
      if (_unread > 0) _unread--;
    });
    final result = await _repository.markAsRead(id);
    if (!mounted) return;
    result.fold((failure) {
      item['is_read'] = false;
      _unread++;
      AppToast.error(context, failure.message);
      setState(() {});
    }, (_) {});
  }

  Future<void> _readAll() async {
    final result = await _repository.markAllAsRead();
    if (!mounted) return;
    result.fold(
      (failure) => AppToast.error(context, failure.message),
      (_) => setState(() {
        for (final item in _items) {
          item['is_read'] = true;
        }
        _unread = 0;
      }),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFFF4F7FA),
    appBar: AppBar(
      title: const Text('Notifikasi'),
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      actions: [
        if (_unread > 0)
          TextButton(
            onPressed: _readAll,
            child: const Text(
              'Tandai dibaca',
              style: TextStyle(color: Colors.white),
            ),
          ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: DropdownButtonFormField<String>(
                initialValue: _module,
                decoration: const InputDecoration(
                  labelText: 'Kategori notifikasi',
                  prefixIcon: Icon(Icons.filter_list),
                  border: OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.white,
                ),
                items: const [
                  DropdownMenuItem(value: '', child: Text('Semua')),
                  DropdownMenuItem(value: 'POS', child: Text('POS')),
                  DropdownMenuItem(
                    value: 'inventory',
                    child: Text('Inventori'),
                  ),
                ],
                onChanged: (value) {
                  _module = value ?? '';
                  _load();
                },
              ),
            ),
          ),
          if (_loading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_items.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.notifications_none,
                      size: 58,
                      color: Colors.black26,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Belum ada notifikasi',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              sliver: SliverList.separated(
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final item = _items[index];
                  final unread = item['is_read'] != true;
                  return Material(
                    color: unread
                        ? AppColors.primary.withValues(alpha: .07)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(14),
                      onTap: () => _read(item),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primary.withValues(
                                alpha: .12,
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: AppColors.primary,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item['title']?.toString() ??
                                              'Notifikasi',
                                          style: TextStyle(
                                            fontWeight: unread
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (unread)
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: AppColors.primary,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['body']?.toString() ?? '-',
                                    style: const TextStyle(
                                      color: Colors.black54,
                                    ),
                                  ),
                                  const SizedBox(height: 7),
                                  Text(
                                    _dateLabel(
                                      item['tanggal_notifikasi'] ??
                                          item['createdAt'],
                                    ),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    ),
  );

  String _dateLabel(dynamic raw) {
    final date = DateTime.tryParse(raw?.toString() ?? '')?.toLocal();
    if (date == null) return '';
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(date.day)}/${two(date.month)}/${date.year} • ${two(date.hour)}:${two(date.minute)}';
  }
}
