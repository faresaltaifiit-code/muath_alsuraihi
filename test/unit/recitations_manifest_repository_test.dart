import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:muath_alsuraihi/data/repositories/recitations_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const fallback = '''
{
  "surahs": [
    {
      "number": 1,
      "name": "الفاتحة",
      "audio_path": "assets/audio/001_الفاتحة.mp3",
      "available": true
    }
  ],
  "special_recitations": []
}
''';

  const manifest = '''
{
  "items": [
    {
      "audio_id": "001_الفاتحة",
      "surah_id": 1,
      "name": "الفاتحة",
      "number": 1,
      "url": "https://example.test/001.mp3",
      "size": 648722,
      "duration": 42,
      "type": "surah"
    }
  ]
}
''';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('reads the remote manifest and keeps the local playback path', () async {
    var requestCount = 0;
    final repository = RecitationsRepository(
      client: MockClient((_) async {
        requestCount++;
        return http.Response(manifest, 200);
      }),
      fallbackLoader: () async => fallback,
    );

    final catalog = await repository.getCatalog();
    final fatiha = catalog.surahs.firstWhere((surah) => surah.number == 1);

    expect(requestCount, 1);
    expect(
      fatiha.remoteAudioUrl,
      'https://example.test/001.mp3',
      reason: 'number=${fatiha.number}, path=${fatiha.audioPath}',
    );
    expect(fatiha.audioPath, 'assets/audio/001_الفاتحة.mp3');
    expect(fatiha.durationText, '0:42');
    expect(fatiha.fileSizeText, '633.5 KB');
  });

  test('uses the saved manifest when the network is unavailable', () async {
    final onlineRepository = RecitationsRepository(
      client: MockClient((_) async => http.Response(manifest, 200)),
      fallbackLoader: () async => fallback,
    );
    await onlineRepository.getCatalog();

    final offlineRepository = RecitationsRepository(
      client: MockClient((_) async => throw Exception('offline')),
      fallbackLoader: () async => fallback,
    );
    final catalog = await offlineRepository.getCatalog();
    final fatiha = catalog.surahs.firstWhere((surah) => surah.number == 1);

    expect(fatiha.remoteAudioUrl, 'https://example.test/001.mp3');
  });
}
