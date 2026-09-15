import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:muath_alsuraihi/data/repositories/recitations_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
      "type": "surah"
    }
  ]
}
''';

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
  });

  test('reads the remote manifest and keeps the local playback path', () async {
    final repository = RecitationsRepository(
      client: MockClient((_) async => http.Response(manifest, 200)),
    );

    final catalog = await repository.getCatalog();
    final fatiha = catalog.surahs.firstWhere((surah) => surah.number == 1);

    expect(fatiha.remoteAudioUrl, 'https://example.test/001.mp3');
    expect(fatiha.audioPath, 'assets/audio/001_الفاتحة.mp3');
  });

  test('uses the saved manifest when the network is unavailable', () async {
    final onlineRepository = RecitationsRepository(
      client: MockClient((_) async => http.Response(manifest, 200)),
    );
    await onlineRepository.getCatalog();

    final offlineRepository = RecitationsRepository(
      client: MockClient((_) async => throw Exception('offline')),
    );
    final catalog = await offlineRepository.getCatalog();
    final fatiha = catalog.surahs.firstWhere((surah) => surah.number == 1);

    expect(fatiha.remoteAudioUrl, 'https://example.test/001.mp3');
  });
}
