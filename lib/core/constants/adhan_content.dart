import '../../data/models/surah_model.dart';

/// Full prayer sounds opened from their corresponding notifications.
/// They intentionally stay outside the recitation manifest.
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

const kIqamaAudio = SurahModel(
  id: 'prayer_iqama',
  number: 0,
  name: 'الإقامة',
  reciterName: 'مواقيت الصلاة',
  durationSeconds: 48,
  durationText: '0:48',
  audioPath: 'assets/audio/iqama_full.m4a',
  available: true,
  fileSizeBytes: 595829,
  fileSizeText: '582 KB',
  isBundled: true,
);
