import 'dart:convert';

import 'package:http/http.dart' as http;

enum PrayerName { fajr, dhuhr, asr, maghrib, isha }

extension PrayerNameText on PrayerName {
  String get arabicName => switch (this) {
        PrayerName.fajr => 'الفجر',
        PrayerName.dhuhr => 'الظهر',
        PrayerName.asr => 'العصر',
        PrayerName.maghrib => 'المغرب',
        PrayerName.isha => 'العشاء',
      };

  Duration get iqamaDelay => switch (this) {
        PrayerName.fajr => const Duration(minutes: 25),
        PrayerName.dhuhr ||
        PrayerName.asr ||
        PrayerName.isha =>
          const Duration(minutes: 20),
        PrayerName.maghrib => const Duration(minutes: 10),
      };
}

class PrayerDay {
  const PrayerDay({
    required this.date,
    required this.times,
  });

  final DateTime date;
  final Map<PrayerName, DateTime> times;

  DateTime timeFor(PrayerName prayer) => times[prayer]!;
}

class PrayerTimesService {
  PrayerTimesService({http.Client? client}) : _client = client ?? http.Client();

  static const jeddahLatitude = 21.4858;
  static const jeddahLongitude = 39.1925;
  final http.Client _client;

  Future<PrayerDay> fetchDay({
    required DateTime date,
    required double latitude,
    required double longitude,
  }) async {
    final timestamp =
        DateTime(date.year, date.month, date.day).millisecondsSinceEpoch ~/
            1000;
    final uri = Uri.https('api.aladhan.com', '/v1/timings/$timestamp', {
      'latitude': latitude.toStringAsFixed(5),
      'longitude': longitude.toStringAsFixed(5),
      'method': '4',
      'school': '0',
    });
    final response =
        await _client.get(uri).timeout(const Duration(seconds: 12));
    if (response.statusCode != 200) {
      throw StateError('تعذر جلب مواقيت الصلاة الآن.');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>?;
    final rawTimes = data?['timings'] as Map<String, dynamic>?;
    if (rawTimes == null) throw StateError('بيانات المواقيت غير مكتملة.');

    DateTime parse(String key) {
      final value = rawTimes[key]?.toString() ?? '';
      final match = RegExp(r'^(\d{1,2}):(\d{2})').firstMatch(value);
      if (match == null) throw StateError('تعذر قراءة وقت $key.');
      return DateTime(date.year, date.month, date.day,
          int.parse(match.group(1)!), int.parse(match.group(2)!));
    }

    return PrayerDay(date: DateTime(date.year, date.month, date.day), times: {
      PrayerName.fajr: parse('Fajr'),
      PrayerName.dhuhr: parse('Dhuhr'),
      PrayerName.asr: parse('Asr'),
      PrayerName.maghrib: parse('Maghrib'),
      PrayerName.isha: parse('Isha'),
    });
  }
}
