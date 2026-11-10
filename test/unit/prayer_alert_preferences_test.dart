import 'package:flutter_test/flutter_test.dart';
import 'package:muath_alsuraihi/providers/prayer_times_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final saved in [true, false]) {
    test('restores prayer alert preference $saved', () async {
      SharedPreferences.setMockInitialValues({'prayer_alerts_enabled': saved});
      final provider = PrayerTimesProvider();
      await provider.load();
      expect(provider.isLoaded, isTrue);
      expect(provider.alertsEnabled, saved);
      await provider.enableAlertsIfNotConfigured();
      expect(provider.alertsEnabled, saved);
      provider.dispose();
    });
  }
}
