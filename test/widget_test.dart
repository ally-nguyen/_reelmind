import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel_mind/widgets/reel_mind_logo.dart';

void main() {
  testWidgets('Reel Mind logo renders its image widget', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: ReelMindLogo(size: 120),
          ),
        ),
      ),
    );

    expect(find.byType(ReelMindLogo), findsOneWidget);
    expect(find.byType(Image), findsOneWidget);
  });
}
