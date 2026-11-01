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
  final nativeLaunchPayload = await _prayerNotificationsChannel
      .invokeMethod<String>('takePendingNotificationPayload');
  PrayerNotificationEvents.handlePayload(nativeLaunchPayload);
  // A notification may launch the app before any widget exists. Initialise
  // first so its payload is retained and the app can open the full audio.
  await prayerNotificationsService.initialize();
  runApp(const MuathAlsuraihiApp());
}

