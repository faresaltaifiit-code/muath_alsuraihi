import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

import '../../data/models/surah_model.dart';

class AudioDownloadService {
  static Future<File?> localFileFor(String audioId) async {
    final file = File('${(await _downloadsDirectory()).path}/$audioId.mp3');
    return await file.exists() ? file : null;
  }

  static Future<Set<String>> downloadedAudioIds() async {
    final directory = await _downloadsDirectory();
    return directory
        .list()
        .where((item) => item is File && item.path.endsWith('.mp3'))
        .map((item) => item.uri.pathSegments.last.replaceFirst(RegExp(r'\.mp3$'), ''))
        .toSet();
  }

  static Future<void> download(
    SurahModel surah, {
    required void Function(int receivedBytes, int? totalBytes) onProgress,
    http.Client? client,
  }) async {
    final url = surah.remoteAudioUrl;
    if (url == null || url.isEmpty) {
      throw StateError('لا يوجد رابط تحميل لهذه التلاوة.');
    }

    final directory = await _downloadsDirectory();
    final target = File('${directory.path}/${surah.id}.mp3');
    final partial = File('${target.path}.part');
    var offset = await partial.exists() ? await partial.length() : 0;
    final request = http.Request('GET', Uri.parse(url));
    if (offset > 0) request.headers[HttpHeaders.rangeHeader] = 'bytes=$offset-';

    final activeClient = client ?? http.Client();
    try {
      final response = await activeClient.send(request);
      if (response.statusCode != HttpStatus.ok &&
          response.statusCode != HttpStatus.partialContent) {
        throw HttpException('تعذر تحميل التلاوة (رمز ${response.statusCode}).');
      }
      if (offset > 0 && response.statusCode == HttpStatus.ok) {
        await partial.delete();
        offset = 0;
      }

      final total = response.contentLength == null
          ? null
          : offset + response.contentLength!;
      final sink = partial.openWrite(mode: FileMode.append);
      var received = offset;
      try {
        await for (final chunk in response.stream) {
          sink.add(chunk);
          received += chunk.length;
          onProgress(received, total);
        }
      } finally {
        await sink.close();
      }
      await partial.rename(target.path);
      onProgress(total ?? received, total ?? received);
    } finally {
      if (client == null) activeClient.close();
    }
  }

  static Future<void> delete(String audioId) async {
    final target = await localFileFor(audioId);
    if (target != null) await target.delete();
    final partial = File('${(await _downloadsDirectory()).path}/$audioId.mp3.part');
    if (await partial.exists()) await partial.delete();
  }

  static Future<void> deleteAll() async {
    final directory = await _downloadsDirectory();
    await for (final item in directory.list()) {
      if (item is File && (item.path.endsWith('.mp3') || item.path.endsWith('.part'))) {
        await item.delete();
      }
    }
  }

  static Future<int> storageUsageBytes() async {
    final directory = await _downloadsDirectory();
    var total = 0;
    await for (final item in directory.list()) {
      if (item is File && item.path.endsWith('.mp3')) {
        total += await item.length();
      }
    }
    return total;
  }

  static Future<Directory> _downloadsDirectory() async {
    final root = await getApplicationDocumentsDirectory();
    return Directory('${root.path}/audio_downloads').create(recursive: true);
  }
}
