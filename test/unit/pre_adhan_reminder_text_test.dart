import 'package:flutter_test/flutter_test.dart';
import 'package:muath_alsuraihi/core/services/prayer_notifications_service.dart';
import 'package:muath_alsuraihi/core/services/prayer_times_service.dart';

void main() {
  test('pre-adhan reminders use the prayer name and correct Arabic unit', () {
    for (final prayer in PrayerName.values) {
      for (final minutes in [5, 10, 15]) {
        final text = preAdhanReminderText(prayer, minutes);
        expect(text.title, 'اقترب موعد صلاة ${prayer.arabicName}');
        final unit = minutes == 15 ? 'دقيقة' : 'دقائق';
        expect(text.body,
            'تبقّى على أذان ${prayer.arabicName} $minutes $unit، فتهيّأ للصلاة بقلب مطمئن.');
      }
    }
  });
}
