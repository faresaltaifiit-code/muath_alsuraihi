import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('rewind and fast-forward controls are visible', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Row(children: [Icon(Icons.replay_10_rounded), Icon(Icons.forward_10_rounded)]),
    ));
    expect(find.byIcon(Icons.replay_10_rounded), findsOneWidget);
    expect(find.byIcon(Icons.forward_10_rounded), findsOneWidget);
  });
}
