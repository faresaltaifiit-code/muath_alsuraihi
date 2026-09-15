import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:muath_alsuraihi/data/models/surah_model.dart';
import 'package:muath_alsuraihi/providers/player_provider.dart';

SurahModel _surah(int number) => SurahModel(
      id: 'surah_$number',
      number: number,
      name: 'سورة $number',
      reciterName: 'معاذ السريحي',
      durationSeconds: 60,
      durationText: '1:00',
      audioPath: 'assets/audio/$number.mp3',
      available: true,
      fileSizeBytes: 1,
      fileSizeText: '1 KB',
    );

void main() {
  test('shuffle chooses a different recitation when another is available', () {
    final current = _surah(1);
    final next = pickRandomSurah([current, _surah(2), _surah(3)], current,
        random: Random(1));

    expect(next, isNotNull);
    expect(next!.audioPath, isNot(current.audioPath));
  });
}
