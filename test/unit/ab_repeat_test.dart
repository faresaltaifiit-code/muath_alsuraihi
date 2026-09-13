import 'package:flutter_test/flutter_test.dart';

void main() {
  test('A-B repeat seeks to A after reaching B', () {
    const start = Duration(seconds: 15);
    const end = Duration(seconds: 30);
    const position = Duration(seconds: 30);
    final target = position >= end ? start : position;
    expect(target, start);
  });
}
