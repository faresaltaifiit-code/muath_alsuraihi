import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'prayer_times_service.dart';
import 'adhan_messages.dart';

enum PrayerNotificationAction { openAdhan, openIqama }

({String title, String body}) preAdhanReminderText(
    PrayerName prayer, int minutes) {
  final unit = minutes == 15 ? 'دقيقة' : 'دقائق';
  return (
    title: 'اقترب موعد صلاة ${prayer.arabicName}',
    body: 'تبقّى على أذان ${prayer.arabicName} $minutes $unit، فتهيّأ للصلاة بقلب مطمئن.',
  );
}

/// The app uses one instance from launch through scheduling and playback.
final prayerNotificationsService = PrayerNotificationsService();

/// Bridges an iOS notification tap to the app shell without coupling the
/// notification plugin to a particular screen.
class PrayerNotificationEvents {
  PrayerNotificationEvents._();

  static final _controller =
      StreamController<PrayerNotificationAction>.broadcast();
  // iOS can deliver a notification tap while Flutter is still constructing the
  // widget tree. Keep the last action as well as broadcasting it, so a cold
  // launch cannot lose the tap before the app shell starts listening.
  static PrayerNotificationAction? _pendingAction;
  static String? _lastPayload;
  static DateTime? _lastHandledAt;

  static Stream<PrayerNotificationAction> get actions => _controller.stream;

  static PrayerNotificationAction? takePendingAction() {
    final action = _pendingAction;
    _pendingAction = null;
    return action;
  }

  static void handle(NotificationResponse response) {
    handlePayload(response.payload);
  }

  static void handlePayload(String? payload) {
    final now = DateTime.now();
    if (payload == _lastPayload &&
        _lastHandledAt != null &&
        now.difference(_lastHandledAt!) < const Duration(seconds: 2)) {
      return;
    }
    final action = switch (payload) {
      'open_adhan' => PrayerNotificationAction.openAdhan,
      'open_iqama' => PrayerNotificationAction.openIqama,
      _ => null,
    };
    if (action != null) {
      _lastPayload = payload;
      _lastHandledAt = now;
      _pendingAction = action;
      _controller.add(action);
    }
  }
}

class PrayerNotificationsService {
  PrayerNotificationsService();

  static const _notificationIdBase = 41000;
  static const _notificationCount = 64;
  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  Future<void>? _initialization;
  Future<void> _scheduleQueue = Future<void>.value();

  Future<void> _serialize(Future<void> Function() operation) {
    final result = _scheduleQueue.then((_) => operation());
    _scheduleQueue = result.catchError((Object _) {});
    return result;
  }

  Future<void> initialize() => _initialization ??= _initialize();

  Future<void> _initialize() async {
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
    await _plugin.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: PrayerNotificationEvents.handle,
    );
    final launchDetails = await _plugin.getNotificationAppLaunchDetails();
    final response = launchDetails?.notificationResponse;
    if (launchDetails?.didNotificationLaunchApp == true && response != null) {
      // Allow the widget tree to subscribe before sending the launch action.
      scheduleMicrotask(() => PrayerNotificationEvents.handle(response));
    }
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
    return permissions?.isEnabled == true &&
        permissions?.isAlertEnabled == true;
  }

  Future<void> openNotificationSettings() async {
    await initialize();
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    await ios?.openAppNotificationSettings();
  }

  Future<void> cancelPrayerNotifications() => _serialize(_cancelPrayerNotifications);

  Future<void> _cancelPrayerNotifications() async {
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
        sound: 'adhan_notification.caf',
      ),
    );
    await _plugin.cancel(id: testId);
    await _plugin.zonedSchedule(
      id: testId,
      title: 'تنبيه تجريبي لمواقيت الصلاة',
      body: 'التنبيهات مفعّلة وستصلك عند الأذان والإقامة.',
      scheduledDate: scheduledAt,
      notificationDetails: details,
      payload: 'open_adhan',
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
    return scheduledAt;
  }

  Future<void> schedule({
    required List<PrayerDay> days,
    Map<PrayerName, Duration> iqamaDelays = const {},
    int preAdhanReminderMinutes = 0,
  }) => _serialize(() => _schedulePrayers(
        days: days,
        iqamaDelays: iqamaDelays,
        preAdhanReminderMinutes: preAdhanReminderMinutes,
      ));

  Future<void> _schedulePrayers({
    required List<PrayerDay> days,
    required Map<PrayerName, Duration> iqamaDelays,
    required int preAdhanReminderMinutes,
  }) async {
    await _cancelPrayerNotifications();
    var id = _notificationIdBase;
    final now = DateTime.now();
    const adhanDetails = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
        threadIdentifier: 'prayer-times',
        sound: 'adhan_notification.caf',
      ),
    );
    const iqamaDetails = NotificationDetails(
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentSound: true,
        presentBanner: true,
        presentList: true,
        threadIdentifier: 'prayer-times',
        sound: 'iqama_notification.caf',
      ),
    );
    const reminderDetails = NotificationDetails(
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
        final iqama = adhan.add(
          iqamaDelays[prayer] ?? prayer.defaultIqamaDelay,
        );
        final reminder =
            adhan.subtract(Duration(minutes: preAdhanReminderMinutes));
        if (preAdhanReminderMinutes > 0 &&
            reminder.isAfter(now) &&
            id < _notificationIdBase + _notificationCount) {
          final text = preAdhanReminderText(prayer, preAdhanReminderMinutes);
          await _schedule(
            id: id++,
            title: text.title,
            body: text.body,
            time: reminder,
            details: reminderDetails,
          );
        }
        if (adhan.isAfter(now)) {
          await _schedule(
            id: id++,
            title: 'حان وقت صلاة ${prayer.arabicName}',
            body: adhanMessageFor(prayer, adhan),
            time: adhan,
            details: adhanDetails,
            payload: 'open_adhan',
          );
        }
        if (iqama.isAfter(now) &&
            id < _notificationIdBase + _notificationCount) {
          await _schedule(
            id: id++,
            title: 'إقامة صلاة ${prayer.arabicName}',
            body: 'قد قامت الصلاة',
            time: iqama,
            details: iqamaDetails,
            payload: 'open_iqama',
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
    String? payload,
  }) =>
      _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(time, tz.local),
        notificationDetails: details,
        payload: payload,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
}
