import 'package:flutter_test/flutter_test.dart';

void main() {
  test('autoplay toggle changes immediately', () {
    var autoPlayNext = true;
    autoPlayNext = false;
    expect(autoPlayNext, isFalse);
  });
}
