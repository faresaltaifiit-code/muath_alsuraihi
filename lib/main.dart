import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart';

import 'app.dart';
import 'core/services/prayer_notifications_service.dart';

const _prayerNotificationsChannel = MethodChannel(
  'com.faresaltaifi.muath_alsuraihi/prayer_notifications',
);

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _prayerNotificationsChannel.setMethodCallHandler((call) async {
    if (call.method == 'notificationTapped') {
      PrayerNotificationEvents.handlePayload(call.arguments as String?);
    }
  });
  runApp(const MuathAlsuraihiApp());
  // Never delay the first screen for a platform response. The callback stores
  // its action locally, so it is safe to recover it after the app is visible.
  _restoreNativeNotificationTap();
}

Future<void> _restoreNativeNotificationTap() async {
  try {
    final payload = await _prayerNotificationsChannel
        .invokeMethod<String>('takePendingNotificationPayload');
    PrayerNotificationEvents.handlePayload(payload);
  } catch (_) {
    // The normal Flutter notification callback remains available as fallback.
  }
}

