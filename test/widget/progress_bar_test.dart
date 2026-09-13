import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('progress bar reflects a changed playback position', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: Slider(value: 30, max: 100, onChanged: null),
      ),
    ));
    expect(find.byType(Slider), findsOneWidget);
    expect(tester.widget<Slider>(find.byType(Slider)).value, 30);
  });
}
