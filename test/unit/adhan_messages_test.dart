import 'package:flutter_test/flutter_test.dart';
import 'package:muath_alsuraihi/core/services/adhan_messages.dart';
import 'package:muath_alsuraihi/core/services/prayer_times_service.dart';

void main() {
  test('each prayer and weekday has a distinct stable message', () {
    final monday = DateTime(2026, 11, 9);
    final messages = <String>{};
    for (var day = 0; day < 7; day++) {
      final date = monday.add(Duration(days: day));
      for (final prayer in PrayerName.values) {
        final message = adhanMessageFor(prayer, date);
        expect(message, isNotEmpty);
        expect(messages.add(message), isTrue);
        expect(adhanMessageFor(prayer, date.add(const Duration(days: 7))), message);
      }
    }
    expect(messages, hasLength(35));
  });
}
