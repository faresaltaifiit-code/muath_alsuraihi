import '../../data/models/surah_model.dart';

/// The full adhan used after a person opens a prayer notification.
/// It intentionally stays outside the recitation manifest.
const kAdhanAudio = SurahModel(
  id: 'prayer_adhan',
  number: 0,
  name: 'الأذان',
  reciterName: 'مواقيت الصلاة',
  durationSeconds: 234,
  durationText: '3:54',
  audioPath: 'assets/audio/adhan_full.m4a',
  available: true,
  fileSizeBytes: 2937524,
  fileSizeText: '2.8 MB',
  isBundled: true,
);
