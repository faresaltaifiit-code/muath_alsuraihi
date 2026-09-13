import 'package:flutter_test/flutter_test.dart';
import 'package:muath_alsuraihi/data/models/surah_model.dart';

void main() {
  test('next recitation has an independent duration value', () {
    final first = SurahModel.fromJson({'number': 1, 'duration_seconds': 10});
    final next = SurahModel.fromJson({'number': 2, 'duration_seconds': 20});
    expect(first.durationSeconds, 10);
    expect(next.durationSeconds, 20);
    expect(next.durationSeconds, isNot(first.durationSeconds));
  });
}
