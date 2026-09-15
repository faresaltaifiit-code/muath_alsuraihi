import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/constants/app_urls.dart';
import '../models/surah_model.dart';

class RecitationsRepository {
  RecitationsRepository({
    http.Client? client,
    Future<SharedPreferences> Function()? preferences,
  })  : _client = client ?? http.Client(),
        _preferences = preferences ?? SharedPreferences.getInstance;

  static const _manifestCacheKey = 'recitations_manifest_cache_v1';

  final http.Client _client;
  final Future<SharedPreferences> Function() _preferences;

  /// يحدّث بيانات القائمة من Manifest، ويحفظ آخر نسخة صالحة محليًا.
  /// تبقى مسارات الصوت المحلية كما هي في هذه المرحلة.
  Future<RecitationsCatalog> getCatalog() async {
    final source =
        await rootBundle.loadString('assets/data/recitations_fallback.json');
    final fallbackRoot = jsonDecode(source) as Map<String, dynamic>;

    final manifest = await _loadManifest();
    final root = manifest == null
        ? fallbackRoot
        : _mergeManifestWithFallback(fallbackRoot, manifest);

    return _catalogFromRoot(root);
  }

  Future<Map<String, dynamic>?> _loadManifest() async {
    try {
      final response = await _client
          .get(Uri.parse(AppUrls.manifestUrl))
          .timeout(const Duration(seconds: 10));
      if (response.statusCode != 200)
        throw StateError('Manifest request failed');

      final manifest = _decodeManifest(response.body);
      try {
        final preferences = await _preferences();
        await preferences.setString(_manifestCacheKey, response.body);
      } catch (_) {
        // لا تمنع مشكلة التخزين المؤقت استخدام Manifest السليم من الشبكة.
      }
      return manifest;
    } catch (_) {
      try {
        final preferences = await _preferences();
        return _decodeManifestOrNull(preferences.getString(_manifestCacheKey));
      } catch (_) {
        return null;
      }
    }
  }

  Map<String, dynamic>? _decodeManifestOrNull(String? source) {
    if (source == null || source.isEmpty) return null;
    try {
      return _decodeManifest(source);
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _decodeManifest(String source) {
    final value = jsonDecode(source);
    if (value is! Map || value['items'] is! List) {
      throw const FormatException('Invalid manifest');
    }
    return Map<String, dynamic>.from(value);
  }

  Map<String, dynamic> _mergeManifestWithFallback(
    Map<String, dynamic> fallbackRoot,
    Map<String, dynamic> manifest,
  ) {
    final items = manifest['items'] as List<dynamic>;
    final remoteBySurahNumber = <int, Map<String, dynamic>>{};
    final remoteByAudioId = <String, Map<String, dynamic>>{};

    for (final item in items) {
      if (item is! Map) continue;
      final remoteItem = Map<String, dynamic>.from(item);
      final id = remoteItem['audio_id'];
      if (id is String) remoteByAudioId[id] = remoteItem;
      final surahId = remoteItem['surah_id'];
      if (surahId is num) {
        remoteBySurahNumber[surahId.toInt()] = remoteItem;
      }
    }

    List<dynamic> mergeList(List<dynamic>? localItems, bool isSurah) {
      return (localItems ?? []).map((item) {
        final local = Map<String, dynamic>.from(item as Map<String, dynamic>);
        final localAudioId = (local['audio_path'] as String? ?? '')
            .split('/')
            .last
            .replaceFirst(RegExp(r'\.mp3$'), '');
        final remote = isSurah
            ? remoteBySurahNumber[(local['number'] as num?)?.toInt()] ??
                remoteByAudioId[localAudioId]
            : remoteByAudioId[local['id'] as String? ?? ''] ??
                remoteByAudioId[localAudioId];
        if (remote == null) return local;

        final url = remote['url'];
        if (url is String && url.isNotEmpty) local['remote_audio_url'] = url;
        final size = remote['size'];
        if (size is num) {
          local['file_size_bytes'] = size.toInt();
          local['file_size_text'] = _formatBytes(size.toInt());
        }
        final duration = remote['duration'];
        if (duration is num) {
          local['duration_seconds'] = duration.toInt();
          local['duration_text'] = _formatDuration(duration.toInt());
        }
        return local;
      }).toList();
    }

    return {
      ...fallbackRoot,
      'surahs': mergeList(fallbackRoot['surahs'] as List<dynamic>?, true),
      'special_recitations': mergeList(
          fallbackRoot['special_recitations'] as List<dynamic>?, false),
    };
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    return '${minutes}:${(seconds % 60).toString().padLeft(2, '0')}';
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  RecitationsCatalog _catalogFromRoot(Map<String, dynamic> root) {
    final rawSurahs = root['surahs'] as List<dynamic>? ?? [];
    final surahs = rawSurahs
        .map((item) => SurahModel.fromJson(item as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => a.number.compareTo(b.number));
    final rawSpecial = root['special_recitations'] as List<dynamic>? ?? [];
    final specialRecitations = rawSpecial
        .map((item) => SurahModel.fromJson(item as Map<String, dynamic>))
        .toList();
    return RecitationsCatalog(
      surahs: surahs,
      specialRecitations: specialRecitations,
    );
  }
}

class RecitationsCatalog {
  const RecitationsCatalog({
    required this.surahs,
    required this.specialRecitations,
  });

  final List<SurahModel> surahs;
  final List<SurahModel> specialRecitations;
}
