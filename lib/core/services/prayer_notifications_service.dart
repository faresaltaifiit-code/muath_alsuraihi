import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import 'prayer_times_service.dart';

class PrayerNotificationsService {
  PrayerNotificationsService();

  static const _notificationIdBase = 41000;
  static const _notificationCount = 64;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    const settings = InitializationSettings(
      iOS: DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
        defaultPresentAlert: true,
        defaultPresentBadge: false,
        defaultPresentSound: true,
        defaultPresentBanner: true,
        defaultPresentList: true,
      ),
    );
    await _plugin.initialize(settings: settings);
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    return await ios?.requestPermissions(
            alert: true, badge: false, sound: true) ??
        false;
  }

  Future<void> cancelPrayerNotifications() async {
    await initialize();
    for (var index = 0; index < _notificationCount; index++) {
      await _plugin.cancel(id: _notificationIdBase + index);
    }
  }

  Future<void> schedule({required List<PrayerDay> days}) async {
    await cancelPrayerNotifications();
    var id = _notificationIdBase;
    final now = DateTime.now();
    const details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
        threadIdentifier: 'prayer-times',
      ),
    );
    for (final day in days) {
      for (final prayer in PrayerName.values) {
        final adhan = day.timeFor(prayer);
        final iqama = adhan.add(prayer.iqamaDelay);
        if (adhan.isAfter(now)) {
          await _schedule(
            id: id++,
            title: 'حان الآن موعد صلاة ${prayer.arabicName}',
            body: 'تقبل الله طاعتكم.',
            time: adhan,
            details: details,
          );
        }
        if (iqama.isAfter(now) &&
            id < _notificationIdBase + _notificationCount) {
          await _schedule(
            id: id++,
            title: 'إقامة صلاة ${prayer.arabicName}',
            body: 'هذا وقت إقامة تقريبي حسب إعداداتك.',
            time: iqama,
            details: details,
          );
        }
      }
    }
  }

  Future<void> _schedule({
    required int id,
    required String title,
    required String body,
    required DateTime time,
    required NotificationDetails details,
  }) =>
      _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(time, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
}
