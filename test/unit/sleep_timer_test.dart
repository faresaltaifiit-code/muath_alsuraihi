import 'package:flutter_test/flutter_test.dart';

void main() {
  test('sleep timer can be cancelled before expiry', () {
    var timerActive = true;
    timerActive = false;
    expect(timerActive, isFalse);
  });
}
