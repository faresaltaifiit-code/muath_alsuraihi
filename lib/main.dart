import 'package:flutter/widgets.dart';

import 'app.dart';
import 'core/services/prayer_notifications_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // A notification may launch the app before any widget exists. Initialise
  // first so its payload is retained and the app can open the full audio.
  await prayerNotificationsService.initialize();
  runApp(const MuathAlsuraihiApp());
}

