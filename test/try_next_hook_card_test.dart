import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:reel_mind/models/try_next_insight.dart';
import 'package:reel_mind/widgets/try_next_hook_card.dart';

void main() {
  testWidgets('TryNextHookCard renders hook details and handles taps', (
    tester,
  ) async {
    var tapped = false;
    const hook = TryNextHook(
      type: 'bridge',
      label: 'Mindset x Fitness',
      hook: 'What fitness taught me about mindset',
      targetTopic: 'Mindset',
      bridgeTopic: 'Fitness',
      reason: 'Connects a fresh topic to a proven pattern.',
      generationDirection: 'Generate this idea.',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TryNextHookCard(hook: hook, onTap: () => tapped = true),
        ),
      ),
    );

    expect(find.text('Mindset x Fitness'), findsOneWidget);
    expect(find.text('"What fitness taught me about mindset"'), findsOneWidget);
    expect(find.text('Generate this direction'), findsOneWidget);

    await tester.tap(find.byType(TryNextHookCard));
    expect(tapped, isTrue);
  });
}
