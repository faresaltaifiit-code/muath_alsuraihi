import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
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
    // Prayer times are currently provided for Saudi Arabia. Initializing the
    // database before making a TZDateTime is required for reliable iOS
    // scheduling; without it tz.local falls back to UTC.
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
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

  Future<bool> notificationsAreEnabled() async {
    await initialize();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    final permissions = await ios?.checkPermissions();
    return permissions?.isEnabled == true && permissions?.isAlertEnabled == true;
  }

  Future<void> openNotificationSettings() async {
    await initialize();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.openAppNotificationSettings();
  }

  Future<void> cancelPrayerNotifications() async {
    await initialize();
    for (var index = 0; index < _notificationCount; index++) {
      await _plugin.cancel(id: _notificationIdBase + index);
    }
  }

  Future<DateTime> scheduleTestNotification() async {
    await initialize();
    if (!await notificationsAreEnabled()) {
      throw StateError('الإشعارات محجوبة من إعدادات iPhone.');
    }
    const testId = _notificationIdBase + _notificationCount;
    final scheduledAt =
        tz.TZDateTime.now(tz.local).add(const Duration(seconds: 10));
    const details = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
        threadIdentifier: 'prayer-times',
      ),
    );
    await _plugin.cancel(id: testId);
    await _plugin.zonedSchedule(
      id: testId,
      title: 'تنبيه تجريبي لمواقيت الصلاة',
      body: 'التنبيهات مفعّلة وستصلك عند الأذان والإقامة.',
      scheduledDate: scheduledAt,
      notificationDetails: details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    return scheduledAt;
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
