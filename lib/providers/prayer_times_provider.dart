import 'dart:async';

import 'package:flutter/foundation.dart';
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

  PrayerDay? get today => _today;
  bool get isLoaded => _isLoaded;
  bool get isRefreshing => _isRefreshing;
  bool get alertsEnabled => _alertsEnabled;
  String get locationLabel => _locationLabel;
  String? get error => _error;

  Future<void> load() async {
    final preferences = await SharedPreferences.getInstance();
    _alertsEnabled = preferences.getBool(_alertsKey) ?? false;
    _latitude = preferences.getDouble(_latitudeKey) ?? _latitude;
    _longitude = preferences.getDouble(_longitudeKey) ?? _longitude;
    _locationLabel = preferences.getString(_locationLabelKey) ?? _locationLabel;
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
      _locationLabel = 'موقعك الحالي';
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

  Future<void> sendTestNotification() async {
    if (!_alertsEnabled) {
      _error = 'فعّل تنبيهات الأذان والإقامة أولًا.';
      notifyListeners();
      return;
    }
    try {
      _error = null;
      await _notificationsService.showTestNotification();
    } catch (_) {
      _error = 'تعذّر إرسال التنبيه التجريبي. تحقّق من أذونات الإشعارات في إعدادات iPhone.';
    }
    notifyListeners();
  }

  Future<void> openNotificationSettings() async {
    await _notificationsService.openNotificationSettings();
  }

  Future<void> _scheduleUpcomingAlerts() async {
    final days = <PrayerDay>[];
    for (var offset = 0; offset < 6; offset++) {
      final day = DateTime.now().add(Duration(days: offset));
      final prayerDay = offset == 0 && _today != null
          ? _today!
          : await _prayerTimesService.fetchDay(
              date: day, latitude: _latitude, longitude: _longitude);
      days.add(prayerDay);
    }
    await _notificationsService.schedule(days: days);
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
      final iqama = adhan.add(prayer.iqamaDelay);
      if (!now.isBefore(adhan) && now.isBefore(iqama)) return prayer;
    }
    return null;
  }

  Duration? get timeUntilIqama {
    final prayer = currentIqamaPrayer;
    if (prayer == null || _today == null) return null;
    return _today!
        .timeFor(prayer)
        .add(prayer.iqamaDelay)
        .difference(DateTime.now());
  }
}
