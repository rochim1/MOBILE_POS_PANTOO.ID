import '../../../../domain/models/pos_order_detail.dart';

enum PosOrderAgeTone { normal, warning, critical }

class PosOrderAge {
  final String phase;
  final int? minutes;
  final PosOrderAgeTone tone;

  const PosOrderAge(this.phase, this.minutes, this.tone);

  String get durationLabel {
    final value = minutes;
    if (value == null) return '-';
    return value < 60 ? '$value mnt' : '${value ~/ 60}j ${value % 60}m';
  }

  String get label => minutes == null ? '-' : '$phase · $durationLabel';

  static PosOrderAge forOrder(
    PosOrderDetail order,
    DateTime now, {
    int warningMinutes = 15,
    int criticalMinutes = 25,
    String stationId = '',
  }) {
    final created = _parseTime(order.createdAt);
    final stationItems = order.items
        .where((item) =>
            item.preparationMode == 'station' &&
            (stationId.isEmpty || item.productionStationId == stationId))
        .toList();
    DateTime? started;
    String phase;

    if (order.status == 'Siap') {
      phase = 'Menunggu penyerahan';
      for (final row in order.statusHistory.reversed) {
        if (row['status']?.toString() == 'Siap') {
          started = _parseTime(row['at']?.toString());
          if (started != null) break;
        }
      }
      if (started == null && stationItems.isNotEmpty) {
        final readyTimes = stationItems
            .map((item) => _firstStatusAt(item, 'ready'))
            .whereType<DateTime>()
            .toList();
        if (readyTimes.length == stationItems.length) {
          readyTimes.sort();
          started = readyTimes.last;
        }
      }
      // Legacy orders may lack status history. Do not mistake their total age
      // for the time spent waiting after preparation.
    } else if (order.status == 'Baru' || order.status == 'Diproses') {
      final pending = stationItems
          .where((item) =>
              item.productionStatus == 'queued' ||
              item.productionStatus == 'preparing')
          .toList();
      if (pending.isNotEmpty) {
        phase = 'Menunggu dapur';
        final starts = pending
            .map((item) =>
                _firstStatusAt(item, 'queued') ??
                _firstStatusAt(item, 'preparing') ??
                created)
            .whereType<DateTime>()
            .toList();
        if (starts.isNotEmpty) {
          starts.sort();
          started = starts.first;
        }
      } else {
        phase = 'Menunggu proses';
        started = created;
      }
    } else {
      return const PosOrderAge('Selesai diproses', null, PosOrderAgeTone.normal);
    }

    if (started == null) return PosOrderAge(phase, null, PosOrderAgeTone.normal);
    final minutes = now.difference(started).inMinutes.clamp(0, 9999);
    final warning = warningMinutes > 0 ? warningMinutes : 15;
    final critical = criticalMinutes > warning
        ? criticalMinutes
        : (warning + 1 > 25 ? warning + 1 : 25);
    return PosOrderAge(
      phase,
      minutes,
      minutes >= critical
          ? PosOrderAgeTone.critical
          : minutes >= warning
          ? PosOrderAgeTone.warning
          : PosOrderAgeTone.normal,
    );
  }

  static DateTime? _firstStatusAt(PosOrderItem item, String status) {
    for (final row in item.productionStatusHistory) {
      if (row['status']?.toString() != status) continue;
      final value = _parseTime(row['at']?.toString());
      if (value != null) return value;
    }
    return null;
  }

  static DateTime? _parseTime(String? raw) {
    final value = raw?.trim() ?? '';
    if (value.isEmpty) return null;
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed.toLocal();
    final epoch = int.tryParse(value);
    if (epoch == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(
      value.length <= 10 ? epoch * 1000 : epoch,
    );
  }
}
