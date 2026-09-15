import 'package:flutter/foundation.dart';

import '../core/services/audio_download_service.dart';
import '../data/models/surah_model.dart';

class DownloadsProvider extends ChangeNotifier {
  final Map<String, _DownloadProgress> _progress = {};
  Set<String> _downloadedIds = {};
  String? _error;

  bool get isReady => _ready;
  bool _ready = false;
  String? get error => _error;
  bool isDownloaded(SurahModel surah) => _downloadedIds.contains(surah.id);
  bool isDownloading(SurahModel surah) => _progress.containsKey(surah.id);
  double? progressFor(SurahModel surah) => _progress[surah.id]?.fraction;

  Future<void> load() async {
    _downloadedIds = await AudioDownloadService.downloadedAudioIds();
    _ready = true;
    notifyListeners();
  }

  Future<void> download(SurahModel surah) async {
    if (isDownloaded(surah) || isDownloading(surah)) return;
    _error = null;
    _progress[surah.id] = const _DownloadProgress(0, null);
    notifyListeners();
    try {
      await AudioDownloadService.download(surah, onProgress: (received, total) {
        _progress[surah.id] = _DownloadProgress(received, total);
        notifyListeners();
      });
      _downloadedIds = {..._downloadedIds, surah.id};
    } catch (_) {
      _error = 'تعذر تنزيل سورة ${surah.name}. تحقق من الاتصال ثم أعد المحاولة.';
    } finally {
      _progress.remove(surah.id);
      notifyListeners();
    }
  }

  Future<void> delete(SurahModel surah) async {
    await AudioDownloadService.delete(surah.id);
    _downloadedIds = {..._downloadedIds}..remove(surah.id);
    notifyListeners();
  }
}

class _DownloadProgress {
  const _DownloadProgress(this.received, this.total);
  final int received;
  final int? total;
  double? get fraction => total == null || total == 0 ? null : received / total!;
}
