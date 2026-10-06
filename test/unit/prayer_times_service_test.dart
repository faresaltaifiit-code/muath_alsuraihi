import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:muath_alsuraihi/core/services/prayer_times_service.dart';

void main() {
  test('reads the five daily prayer times returned by the timetable service',
      () async {
    final service = PrayerTimesService(
      client: MockClient((request) async {
        expect(request.url.queryParameters['method'], '4');
        return http.Response(
          jsonEncode({
            'data': {
              'timings': {
                'Fajr': '04:57 (+03)',
                'Dhuhr': '12:15 (+03)',
                'Asr': '15:27 (+03)',
                'Maghrib': '18:00 (+03)',
                'Isha': '19:20 (+03)',
              }
            }
          }),
          200,
        );
      }),
    );

    final day = await service.fetchDay(
      date: DateTime(2026, 10, 6),
      latitude: PrayerTimesService.jeddahLatitude,
      longitude: PrayerTimesService.jeddahLongitude,
    );

    expect(day.timeFor(PrayerName.fajr), DateTime(2026, 10, 6, 4, 57));
    expect(day.timeFor(PrayerName.isha), DateTime(2026, 10, 6, 19, 20));
    expect(PrayerName.maghrib.iqamaDelay, const Duration(minutes: 10));
  });
}
