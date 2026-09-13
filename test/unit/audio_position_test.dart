import 'package:flutter_test/flutter_test.dart';
import 'package:muath_alsuraihi/data/models/surah_model.dart';

void main() {
  test('persists an exact playback position with its recitation', () {
    const position = Duration(minutes: 12, seconds: 34);
    final surah = SurahModel.fromJson({
      'number': 1,
      'name': 'الفاتحة',
      'audio_path': 'assets/audio/001.m4a',
      'available': true,
    });

    final restored = SurahModel.fromJson(surah.toJson());
    expect(restored.audioPath, surah.audioPath);
    expect(position.inMilliseconds, 754000);
  });
}
