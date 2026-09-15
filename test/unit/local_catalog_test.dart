import 'package:flutter_test/flutter_test.dart';
import 'package:http/testing.dart';
import 'package:muath_alsuraihi/data/repositories/recitations_repository.dart';

void main() {
  test('returns the bundled catalog without using the network', () async {
    const fallback = '''
{
  "surahs": [
    {
      "number": 1,
      "name": "Al-Fatihah",
      "audio_path": "assets/audio/001.mp3",
      "available": true,
      "bundled": true
    }
  ],
  "special_recitations": []
}
''';
    final repository = RecitationsRepository(
      client: MockClient((_) async => throw Exception('network must not be used')),
      fallbackLoader: () async => fallback,
    );

    final catalog = await repository.getLocalCatalog();

    expect(catalog.surahs, hasLength(1));
    expect(catalog.surahs.single.isBundled, isTrue);
    expect(catalog.surahs.single.remoteAudioUrl, isNull);
  });
}
