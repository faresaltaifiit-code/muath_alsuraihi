import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/services/audio_download_service.dart';
import '../data/models/surah_model.dart';

class DownloadsProvider extends ChangeNotifier {
  static const _wifiOnlyKey = 'downloads_wifi_only';
  final Map<String, _DownloadProgress> _progress = {};
  Set<String> _downloadedIds = {};
  String? _error;
  int _storageBytes = 0;
  bool _wifiOnly = false;
  bool _isDownloadingAll = false;
  int _downloadAllTotal = 0;
  int _downloadAllCompleted = 0;
  int _downloadAllExpectedBytes = 0;

  bool get isReady => _ready;
  bool _ready = false;
  String? get error => _error;
  int get storageBytes => _storageBytes;
  bool get wifiOnly => _wifiOnly;
  bool get isDownloadingAll => _isDownloadingAll;
  double? get downloadAllProgress => _downloadAllTotal == 0
      ? null
      : _downloadAllCompleted / _downloadAllTotal;
  int get downloadAllExpectedBytes => _downloadAllExpectedBytes;
  bool isDownloaded(SurahModel surah) => _downloadedIds.contains(surah.id);
  bool isDownloading(SurahModel surah) => _progress.containsKey(surah.id);
  double? progressFor(SurahModel surah) => _progress[surah.id]?.fraction;

  Future<void> load() async {
    _downloadedIds = await AudioDownloadService.downloadedAudioIds();
    _storageBytes = await AudioDownloadService.storageUsageBytes();
    final preferences = await SharedPreferences.getInstance();
    _wifiOnly = preferences.getBool(_wifiOnlyKey) ?? false;
    _ready = true;
    notifyListeners();
  }

  Future<void> download(SurahModel surah) async {
    if (isDownloaded(surah) || isDownloading(surah)) return;
    if (_wifiOnly) {
      final networks = await Connectivity().checkConnectivity();
      if (!networks.contains(ConnectivityResult.wifi)) {
        _error = 'فعّل شبكة Wi-Fi للتحميل أو ألغِ خيار Wi-Fi فقط من الإعدادات.';
        notifyListeners();
        return;
      }
    }
    _error = null;
    _progress[surah.id] = const _DownloadProgress(0, null);
    notifyListeners();
    try {
      await AudioDownloadService.download(surah, onProgress: (received, total) {
        _progress[surah.id] = _DownloadProgress(received, total);
        notifyListeners();
      });
      _downloadedIds = {..._downloadedIds, surah.id};
      _storageBytes = await AudioDownloadService.storageUsageBytes();
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
    _storageBytes = await AudioDownloadService.storageUsageBytes();
    notifyListeners();
  }

  Future<void> deleteAll() async {
    await AudioDownloadService.deleteAll();
    _downloadedIds = {};
    _storageBytes = 0;
    notifyListeners();
  }

  Future<void> downloadAll(Iterable<SurahModel> items) async {
    if (_isDownloadingAll) return;
    final pending = items
        .where((item) =>
            item.available &&
            item.remoteAudioUrl?.isNotEmpty == true &&
            !isDownloaded(item))
        .toList();
    if (pending.isEmpty) return;

    if (_wifiOnly) {
      final networks = await Connectivity().checkConnectivity();
      if (!networks.contains(ConnectivityResult.wifi)) {
        _error = 'ÙØ¹Ù‘Ù„ Ø´Ø¨ÙƒØ© Wi-Fi Ù„Ù„ØªØ­Ù…ÙŠÙ„ Ø£Ùˆ Ø£Ù„ØºÙ Ø®ÙŠØ§Ø± Wi-Fi ÙÙ‚Ø· Ù…Ù† Ø§Ù„Ø¥Ø¹Ø¯Ø§Ø¯Ø§Øª.';
        notifyListeners();
        return;
      }
    }

    _error = null;
    final availableBytes = await AudioDownloadService.availableStorageBytes();
    final requiredBytes = pending.fold<int>(
      0,
      (total, item) => total + item.fileSizeBytes,
    );
    if (availableBytes != null && availableBytes < requiredBytes) {
      _error = 'لا تتوفر مساحة كافية لتنزيل جميع التلاوات.';
      notifyListeners();
      return;
    }
    _isDownloadingAll = true;
    _downloadAllTotal = pending.length;
    _downloadAllCompleted = 0;
    _downloadAllExpectedBytes = requiredBytes;
    notifyListeners();
    try {
      for (final item in pending) {
        await download(item);
        if (isDownloaded(item)) _downloadAllCompleted += 1;
        notifyListeners();
      }
    } finally {
      _isDownloadingAll = false;
      notifyListeners();
    }
  }

  Future<void> setWifiOnly(bool value) async {
    _wifiOnly = value;
    notifyListeners();
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_wifiOnlyKey, value);
  }
}

class _DownloadProgress {
  const _DownloadProgress(this.received, this.total);
  final int received;
  final int? total;
  double? get fraction => total == null || total == 0 ? null : received / total!;
}
