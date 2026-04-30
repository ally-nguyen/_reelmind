import 'package:flutter_test/flutter_test.dart';
import 'package:reel_mind/models/idea_model.dart';
import 'package:reel_mind/models/try_next_insight.dart';
import 'package:reel_mind/services/try_next_analyzer.dart';

IdeaModel idea({
  String? id,
  String title = 'Idea',
  String script = 'Script',
  String status = 'Posted',
  List<String> tags = const [],
  bool archived = false,
  DateTime? updatedAt,
}) {
  return IdeaModel(
    id: id,
    title: title,
    script: script,
    status: status,
    tags: tags,
    archived: archived,
    updatedAt: updatedAt ?? DateTime(2026, 1, 1),
  );
}

void main() {
  group('TryNextAnalyzer', () {
    test('filters to non-archived posted ideas', () {
      final ideas = [
        idea(id: 'posted'),
        idea(id: 'draft', status: 'Draft'),
        idea(id: 'archived', archived: true),
      ];

      final posted = TryNextAnalyzer.postedIdeas(ideas);

      expect(posted.map((i) => i.id), ['posted']);
    });

    test('counts all saved topic tags on posted ideas', () {
      final ideas = [
        idea(id: 'one', tags: ['Fitness', 'Mindset']),
        idea(id: 'two', tags: ['Fitness']),
        idea(id: 'three', tags: ['Unknown']),
      ];

      final counts = TryNextAnalyzer.topicCounts(ideas, [
        'Fitness',
        'Mindset',
        'Food',
      ]);

      expect(counts, {'Fitness': 2, 'Mindset': 1, 'Food': 0});
    });

    test('identifies untagged posted ideas that need inference', () {
      final ideas = [
        idea(id: 'with-topic', tags: ['Fitness']),
        idea(id: 'custom-only', tags: ['Custom']),
        idea(id: 'blank'),
        idea(id: 'draft', status: 'Draft'),
      ];

      final needsInference = TryNextAnalyzer.ideasNeedingInference(ideas, [
        'Fitness',
        'Mindset',
      ]);

      expect(needsInference.map((i) => i.id), ['custom-only', 'blank']);
    });

    test('chooses anchor by count, then most recent use, then topic order', () {
      final ideas = [
        idea(id: 'older', tags: ['Fitness'], updatedAt: DateTime(2026, 1, 1)),
        idea(id: 'newer', tags: ['Mindset'], updatedAt: DateTime(2026, 1, 2)),
      ];

      expect(
        TryNextAnalyzer.anchorTopic(ideas, ['Fitness', 'Mindset']),
        'Mindset',
      );
      expect(
        TryNextAnalyzer.anchorTopic([], ['Fitness', 'Mindset']),
        'Fitness',
      );
    });

    test('applies inferred saved topic without removing custom tags', () {
      final ideas = [
        idea(id: 'one', tags: ['Custom']),
        idea(id: 'two', tags: ['Fitness']),
      ];

      final applied = TryNextAnalyzer.applyInferredTags(
        ideas,
        ['Fitness', 'Mindset'],
        const [
          TryNextInferredTag(ideaId: 'one', topic: 'Mindset', confidence: 0.8),
          TryNextInferredTag(ideaId: 'two', topic: 'Mindset', confidence: 0.8),
        ],
      );

      expect(applied.first.tags, ['Custom', 'Mindset']);
      expect(applied.last.tags, ['Fitness']);
    });
  });
}
