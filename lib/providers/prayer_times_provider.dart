import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/prayer_notifications_service.dart';
import '../core/services/prayer_times_service.dart';

class PrayerTimesProvider extends ChangeNotifier {
  PrayerTimesProvider({
    PrayerTimesService? prayerTimesService,
    PrayerNotificationsService? notificationsService,
  })  : _prayerTimesService = prayerTimesService ?? PrayerTimesService(),
        _notificationsService =
            notificationsService ?? PrayerNotificationsService();

  static const _alertsKey = 'prayer_alerts_enabled';
  static const _latitudeKey = 'prayer_latitude';
  static const _longitudeKey = 'prayer_longitude';
  static const _locationLabelKey = 'prayer_location_label';
  static const _iqamaDelayKeyPrefix = 'prayer_iqama_delay_minutes_';
  static const _preAdhanReminderKey = 'prayer_pre_adhan_reminder_minutes';
  static const _widgetChannel = MethodChannel('com.faresaltaifi.muath_alsuraihi/prayer_widget');

  final PrayerTimesService _prayerTimesService;
  final PrayerNotificationsService _notificationsService;
  PrayerDay? _today;
  PrayerDay? _tomorrow;
  bool _isLoaded = false;
  bool _isRefreshing = false;
  bool _alertsEnabled = false;
  String _locationLabel = 'جدة';
  double _latitude = PrayerTimesService.jeddahLatitude;
  double _longitude = PrayerTimesService.jeddahLongitude;
  String? _error;
  DateTime? _testNotificationScheduledAt;
  Future<void> _alertScheduleQueue = Future<void>.value();
  int _preAdhanReminderMinutes = 0;
  final Map<PrayerName, int> _iqamaDelayMinutes = {
    for (final prayer in PrayerName.values)
      prayer: prayer.defaultIqamaDelay.inMinutes,
  };

  PrayerDay? get today => _today;
  bool get isLoaded => _isLoaded;
  bool get isRefreshing => _isRefreshing;
  bool get alertsEnabled => _alertsEnabled;
  String get locationLabel => _locationLabel;
  String? get error => _error;
  DateTime? get testNotificationScheduledAt => _testNotificationScheduledAt;
  int get preAdhanReminderMinutes => _preAdhanReminderMinutes;
  int get scheduledDaysCount => _preAdhanReminderMinutes > 0 ? 4 : 6;

  int iqamaDelayMinutesFor(PrayerName prayer) =>
      _iqamaDelayMinutes[prayer] ?? prayer.defaultIqamaDelay.inMinutes;

  Duration iqamaDelayFor(PrayerName prayer) =>
      Duration(minutes: iqamaDelayMinutesFor(prayer));

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _alertsEnabled = preferences.getBool(_alertsKey) ?? false;
    _latitude = preferences.getDouble(_latitudeKey) ?? _latitude;
    _longitude = preferences.getDouble(_longitudeKey) ?? _longitude;
    _locationLabel = preferences.getString(_locationLabelKey) ?? _locationLabel;
    _preAdhanReminderMinutes =
        preferences.getInt(_preAdhanReminderKey) ?? _preAdhanReminderMinutes;
    for (final prayer in PrayerName.values) {
      _iqamaDelayMinutes[prayer] = preferences.getInt(
            '$_iqamaDelayKeyPrefix${prayer.name}',
          ) ??
          prayer.defaultIqamaDelay.inMinutes;
    }
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> refreshPrayerTimes() async {
    _isRefreshing = true;
    _error = null;
    notifyListeners();
    try {
      _today = await _prayerTimesService.fetchDay(
        date: DateTime.now(),
        latitude: _latitude,
        longitude: _longitude,
      );
      _tomorrow = await _prayerTimesService.fetchDay(
        date: DateTime.now().add(const Duration(days: 1)),
        latitude: _latitude,
        longitude: _longitude,
      );
      await _updatePrayerWidget();
      if (_alertsEnabled) await _scheduleUpcomingAlerts();
    } catch (_) {
      _error = 'تعذر تحديث المواقيت الآن. تحقق من اتصال الإنترنت.';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> useCurrentLocation() async {
    _isRefreshing = true;
    _error = null;
    notifyListeners();
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('خدمة الموقع غير مفعلة على الجهاز.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('لم يتم السماح بالوصول إلى الموقع.');
      }
      final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.medium,
              timeLimit: Duration(seconds: 15)));
      _latitude = position.latitude;
      _longitude = position.longitude;
      _locationLabel = await _cityNameFor(position) ?? 'موقعك الحالي';
      final preferences = await SharedPreferences.getInstance();
      await preferences.setDouble(_latitudeKey, _latitude);
      await preferences.setDouble(_longitudeKey, _longitude);
      await preferences.setString(_locationLabelKey, _locationLabel);
      await refreshPrayerTimes();
    } on TimeoutException {
      _error = 'تعذر تحديد موقعك الآن. حاول مرة أخرى.';
    } on StateError catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'تعذر تحديد موقعك الآن. حاول مرة أخرى.';
    } finally {
      _isRefreshing = false;
      notifyListeners();
    }
  }

  Future<void> setAlertsEnabled(bool enabled) async {
    if (!enabled) {
      _alertsEnabled = false;
      await _notificationsService.cancelPrayerNotifications();
      final preferences = await SharedPreferences.getInstance();
      await preferences.setBool(_alertsKey, false);
      notifyListeners();
      return;
    }

    // Turning on prayer alerts is the clear user action that asks to use GPS.
    // If location is declined, the saved city (Jeddah on first use) remains a
    // usable fallback instead of blocking the notification permission prompt.
    await useCurrentLocation();
    final granted = await _notificationsService.requestPermission();
    if (!granted) {
      _error = 'يلزم السماح بالإشعارات لتفعيل تنبيهات الصلاة.';
      notifyListeners();
      return;
    }
    _alertsEnabled = true;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_alertsKey, true);
    if (_today == null) await refreshPrayerTimes();
    await _scheduleUpcomingAlerts();
    notifyListeners();
  }

  /// Applies the initial permission choice without overriding a saved choice.
  Future<void> enableAlertsIfNotConfigured() async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.containsKey(_alertsKey)) return;
    _alertsEnabled = true;
    await preferences.setBool(_alertsKey, true);
    notifyListeners();
    try {
      if (_today == null) {
        await refreshPrayerTimes();
      } else {
        await _scheduleUpcomingAlerts();
      }
    } catch (_) {
      _error = 'تعذر تحديث التنبيهات الآن. حاول مرة أخرى.';
      notifyListeners();
    }
  }

  /// Saves mosque-specific iqama offsets in minutes. The approximate values
  /// remain the default for listeners who never change this setting.
  Future<void> setIqamaDelays(Map<PrayerName, int> delays) async {
    for (final prayer in PrayerName.values) {
      final minutes = (delays[prayer] ?? prayer.defaultIqamaDelay.inMinutes)
          .clamp(0, 120)
          .toInt();
      _iqamaDelayMinutes[prayer] = minutes;
    }
    notifyListeners();

    final preferences = await SharedPreferences.getInstance();
    for (final prayer in PrayerName.values) {
      await preferences.setInt(
        '$_iqamaDelayKeyPrefix${prayer.name}',
        iqamaDelayMinutesFor(prayer),
      );
    }
    await _updatePrayerWidget();
    if (_alertsEnabled) _rescheduleAlertsInBackground();
  }

  Future<void> _updatePrayerWidget() async {
    if (!Platform.isIOS || _today == null) return;
    final days = <PrayerDay>[_today!, if (_tomorrow != null) _tomorrow!];
    final prayers = <Map<String, Object>>[];
    for (final day in days) {
      for (final prayer in PrayerName.values) {
        final adhan = day.timeFor(prayer);
        prayers.add({
          'name': prayer.arabicName,
          'adhan': adhan.millisecondsSinceEpoch / 1000,
          'iqama': adhan.add(iqamaDelayFor(prayer)).millisecondsSinceEpoch / 1000,
        });
      }
    }
    try {
      await _widgetChannel.invokeMethod<void>('savePrayerSnapshot', {'prayers': prayers});
    } on PlatformException catch (_) {
      // The app remains usable if the widget extension is not installed.
    } on MissingPluginException catch (_) {}
  }

  Future<void> setPreAdhanReminderMinutes(int minutes) async {
    _preAdhanReminderMinutes = minutes.clamp(0, 15).toInt();
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_preAdhanReminderKey, _preAdhanReminderMinutes);
    if (_alertsEnabled) _rescheduleAlertsInBackground();
  }

  void _rescheduleAlertsInBackground() {
    unawaited(_rescheduleAlertsSafely());
  }

  Future<void> _rescheduleAlertsSafely() async {
    try {
      await _scheduleUpcomingAlerts();
    } catch (_) {
      _error = 'تعذر تحديث التنبيهات الآن. حاول مرة أخرى.';
      notifyListeners();
    }
  }

  Future<void> sendTestNotification() async {
    if (!_alertsEnabled) {
      _error = 'فعّل تنبيهات الأذان والإقامة أولًا.';
      notifyListeners();
      return;
    }
    try {
      _error = null;
      _testNotificationScheduledAt =
          await _notificationsService.scheduleTestNotification();
    } catch (_) {
      _testNotificationScheduledAt = null;
      _error =
          'تعذّر إرسال التنبيه التجريبي. تحقّق من أذونات الإشعارات في إعدادات iPhone.';
    }
    notifyListeners();
  }

  Future<void> openNotificationSettings() async {
    await _notificationsService.openNotificationSettings();
  }

  Future<void> _scheduleUpcomingAlerts() {
    final result = _alertScheduleQueue.then((_) => _performScheduleUpcomingAlerts());
    _alertScheduleQueue = result.catchError((Object _) {});
    return result;
  }

  Future<void> _performScheduleUpcomingAlerts() async {
    if (!_alertsEnabled) return;
    final days = <PrayerDay>[];
    for (var offset = 0; offset < scheduledDaysCount; offset++) {
      final day = DateTime.now().add(Duration(days: offset));
      final prayerDay = offset == 0 && _today != null
          ? _today!
          : await _prayerTimesService.fetchDay(
              date: day, latitude: _latitude, longitude: _longitude);
      days.add(prayerDay);
    }
    if (!_alertsEnabled) return;
    await _notificationsService.schedule(
      days: days,
      iqamaDelays: {
        for (final prayer in PrayerName.values) prayer: iqamaDelayFor(prayer),
      },
      preAdhanReminderMinutes: _preAdhanReminderMinutes,
    );
  }

  PrayerName? get nextPrayer {
    final day = _today;
    if (day == null) return null;
    final now = DateTime.now();
    for (final prayer in PrayerName.values) {
      if (day.timeFor(prayer).isAfter(now)) return prayer;
    }
    return _tomorrow == null ? null : PrayerName.fajr;
  }

  Duration? get timeUntilNextPrayer {
    final prayer = nextPrayer;
    if (prayer == null || _today == null) return null;
    final todayHasUpcomingPrayer = PrayerName.values
        .any((item) => _today!.timeFor(item).isAfter(DateTime.now()));
    final day = todayHasUpcomingPrayer ? _today : _tomorrow;
    return day?.timeFor(prayer).difference(DateTime.now());
  }

  PrayerName? get currentIqamaPrayer {
    final day = _today;
    if (day == null) return null;
    final now = DateTime.now();
    for (final prayer in PrayerName.values) {
      final adhan = day.timeFor(prayer);
      final iqama = adhan.add(iqamaDelayFor(prayer));
      if (!now.isBefore(adhan) && now.isBefore(iqama)) return prayer;
    }
    return null;
  }

  Duration? get timeUntilIqama {
    final prayer = currentIqamaPrayer;
    if (prayer == null || _today == null) return null;
    return _today!
        .timeFor(prayer)
        .add(iqamaDelayFor(prayer))
        .difference(DateTime.now());
  }

  Future<String?> _cityNameFor(Position position) async {
    try {
      await geocoding.setLocaleIdentifier('ar_SA');
      final places = await geocoding.placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (places.isEmpty) return null;
      final place = places.first;
      for (final candidate in [
        place.locality,
        place.subAdministrativeArea,
        place.administrativeArea,
      ]) {
        final city = candidate?.trim() ?? '';
        if (city.isNotEmpty) return city;
      }
    } catch (_) {
      // A city label improves the experience, but must not block prayer times.
    }
    return null;
  }
}
