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
  int _downloadAllCurrentReceived = 0;
  int? _downloadAllCurrentTotal;

  bool get isReady => _ready;
  bool _ready = false;
  String? get error => _error;
  int get storageBytes => _storageBytes;
  bool get wifiOnly => _wifiOnly;
  bool get isDownloadingAll => _isDownloadingAll;
  double? get downloadAllProgress {
    if (_downloadAllTotal == 0) return null;
    final currentFraction = _downloadAllCurrentTotal == null || _downloadAllCurrentTotal == 0
        ? 0.0
        : _downloadAllCurrentReceived / _downloadAllCurrentTotal!;
    return ((_downloadAllCompleted + currentFraction) / _downloadAllTotal)
        .clamp(0.0, 1.0)
        .toDouble();
  }
  int get downloadAllTotal => _downloadAllTotal;
  int get downloadAllCompleted => _downloadAllCompleted;
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

  Future<void> download(
    SurahModel surah, {
    void Function(int received, int? total)? onProgress,
  }) async {
    if (isDownloaded(surah) || isDownloading(surah)) return;
    if (_wifiOnly) {
      final networks = await Connectivity().checkConnectivity();
      if (!networks.contains(ConnectivityResult.wifi)) {
        _isDownloadingAll = false;
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
        onProgress?.call(received, total);
        notifyListeners();
      });
      final savedFile = await AudioDownloadService.localFileFor(surah.id);
      if (savedFile == null) {
        throw StateError('The downloaded file was not found after completion.');
      }
      _downloadedIds = {..._downloadedIds, surah.id};
      _storageBytes = await AudioDownloadService.storageUsageBytes();
    } catch (_) {
      // The platform can report a late filesystem error after the final rename.
      // Reconcile with disk so a completed download is shown immediately.
      final savedFile = await AudioDownloadService.localFileFor(surah.id);
      if (savedFile != null) {
        _downloadedIds = {..._downloadedIds, surah.id};
        try {
          _storageBytes = await AudioDownloadService.storageUsageBytes();
        } catch (_) {
          // The downloaded state is still correct; refresh storage next launch.
        }
        _error = null;
      } else {
        _error = 'تعذر تنزيل سورة ${surah.name}. تحقق من الاتصال ثم أعد المحاولة.';
      }
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
    if (pending.isEmpty) {
      _error = 'All available recitations are already downloaded.';
      notifyListeners();
      return;
    }

    // Give immediate feedback while checking Wi-Fi and free device storage.
    _error = null;
    _isDownloadingAll = true;
    _downloadAllTotal = pending.length;
    _downloadAllCompleted = 0;
    _downloadAllExpectedBytes = 0;
    _downloadAllCurrentReceived = 0;
    _downloadAllCurrentTotal = null;
    notifyListeners();

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
      _isDownloadingAll = false;
      _error = 'لا تتوفر مساحة كافية لتنزيل جميع التلاوات.';
      notifyListeners();
      return;
    }
    _isDownloadingAll = true;
    _downloadAllTotal = pending.length;
    _downloadAllCompleted = 0;
    _downloadAllExpectedBytes = requiredBytes;
    _downloadAllCurrentReceived = 0;
    _downloadAllCurrentTotal = null;
    notifyListeners();
    try {
      for (final item in pending) {
        _downloadAllCurrentReceived = 0;
        _downloadAllCurrentTotal = null;
        notifyListeners();
        await download(
          item,
          onProgress: (received, total) {
            _downloadAllCurrentReceived = received;
            _downloadAllCurrentTotal = total;
          },
        );
        if (isDownloaded(item)) _downloadAllCompleted += 1;
        notifyListeners();
      }
    } finally {
      _isDownloadingAll = false;
      _downloadAllCurrentReceived = 0;
      _downloadAllCurrentTotal = null;
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
