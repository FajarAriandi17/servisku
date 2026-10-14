import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'data_service.dart';

/// Schedules local reminder notifications on Android.
/// On Web this is a no-op (the in-app dashboard still shows due items).
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;
  bool enabled = true;
  int notifyHour = 8;

  static const _channel = AndroidNotificationDetails(
    'servisku_reminders',
    'Pengingat Servis',
    channelDescription: 'Notifikasi jadwal servis kendaraan',
    importance: Importance.high,
    priority: Priority.high,
    color: Color(0xFF5B6CFF),
  );

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    enabled = prefs.getBool('notif_enabled') ?? true;
    notifyHour = prefs.getInt('notif_hour') ?? 8;
    if (kIsWeb) return;
    try {
      tzdata.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      _ready = true;
    } catch (e) {
      debugPrint('Notification init failed: $e');
    }
  }

  Future<bool> requestPermission() async {
    if (kIsWeb || !_ready) return false;
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    return await android?.requestNotificationsPermission() ?? false;
  }

  Future<void> setEnabled(bool v, DataService data) async {
    enabled = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_enabled', v);
    if (v) {
      await requestPermission();
      await scheduleAll(data);
    } else {
      await cancelAll();
    }
  }

  Future<void> setHour(int h, DataService data) async {
    notifyHour = h;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('notif_hour', h);
    await scheduleAll(data);
  }

  Future<void> cancelAll() async {
    if (kIsWeb || !_ready) return;
    await _plugin.cancelAll();
  }

  Future<void> showTest() async {
    if (kIsWeb || !_ready) return;
    await _plugin.show(
      id: 999999,
      title: 'ServisKu',
      body: 'Notifikasi pengingat servis aktif! 🔧',
      notificationDetails: const NotificationDetails(android: _channel),
    );
  }

  int _idFor(String reminderId, int slot) =>
      (reminderId.hashCode & 0x0FFFFFFF) * 4 + slot;

  Future<void> scheduleAll(DataService data) async {
    if (kIsWeb || !_ready) return;
    await _plugin.cancelAll();
    if (!enabled) return;
    final now = tz.TZDateTime.now(tz.local);
    for (final (r, v) in data.upcoming) {
      final due = r.estimatedDueDate(v);
      final dueAt = tz.TZDateTime(
        tz.local,
        due.year,
        due.month,
        due.day,
        notifyHour,
      );
      final early = dueAt.subtract(Duration(days: r.notifyDaysBefore));
      final slots = <(int, tz.TZDateTime, String)>[
        (0, early, 'akan jatuh tempo dalam ${r.notifyDaysBefore} hari'),
        (1, dueAt, 'jatuh tempo hari ini'),
      ];
      for (final (slot, at, msg) in slots) {
        if (!at.isAfter(now)) continue;
        try {
          await _plugin.zonedSchedule(
            id: _idFor(r.id, slot),
            title: '${r.title} • ${v.name}',
            body:
                'Jadwal servis ${v.plate.isEmpty ? '' : '(${v.plate}) '}$msg.',
            scheduledDate: at,
            notificationDetails: const NotificationDetails(android: _channel),
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          );
        } catch (e) {
          debugPrint('Schedule failed: $e');
        }
      }
    }
  }
}
