import '../models/idea_model.dart';
import '../models/try_next_insight.dart';

class TryNextAnalyzer {
  TryNextAnalyzer._();

  static List<IdeaModel> postedIdeas(List<IdeaModel> ideas) {
    return ideas
        .where((idea) => idea.status == 'Posted' && !idea.archived)
        .toList();
  }

  static List<String> normalizeTopics(List<String> topics) {
    final seen = <String>{};
    final normalized = <String>[];
    for (final topic
        in topics.map((t) => t.trim()).where((t) => t.isNotEmpty)) {
      if (seen.add(topic)) normalized.add(topic);
    }
    return normalized;
  }

  static List<String> savedTopicTags(IdeaModel idea, List<String> topics) {
    final topicSet = normalizeTopics(topics).toSet();
    return idea.tags.where(topicSet.contains).toList();
  }

  static bool lacksSavedTopic(IdeaModel idea, List<String> topics) {
    return savedTopicTags(idea, topics).isEmpty;
  }

  static List<IdeaModel> ideasNeedingInference(
    List<IdeaModel> ideas,
    List<String> topics,
  ) {
    return postedIdeas(ideas)
        .where((idea) => idea.id != null && lacksSavedTopic(idea, topics))
        .toList();
  }

  static Map<String, int> topicCounts(
    List<IdeaModel> postedIdeas,
    List<String> topics,
  ) {
    final normalizedTopics = normalizeTopics(topics);
    final counts = {for (final topic in normalizedTopics) topic: 0};
    for (final idea in postedIdeas) {
      for (final tag in savedTopicTags(idea, normalizedTopics).toSet()) {
        counts[tag] = (counts[tag] ?? 0) + 1;
      }
    }
    return counts;
  }

  static String anchorTopic(List<IdeaModel> postedIdeas, List<String> topics) {
    final normalizedTopics = normalizeTopics(topics);
    if (normalizedTopics.isEmpty) return '';

    final counts = topicCounts(postedIdeas, normalizedTopics);
    final sorted = [...normalizedTopics]
      ..sort((a, b) {
        final countCompare = (counts[b] ?? 0).compareTo(counts[a] ?? 0);
        if (countCompare != 0) return countCompare;

        final aLatest = _latestUseMillis(postedIdeas, a);
        final bLatest = _latestUseMillis(postedIdeas, b);
        final latestCompare = bLatest.compareTo(aLatest);
        if (latestCompare != 0) return latestCompare;

        return normalizedTopics
            .indexOf(a)
            .compareTo(normalizedTopics.indexOf(b));
      });

    final top = sorted.first;
    if ((counts[top] ?? 0) == 0) return normalizedTopics.first;
    return top;
  }

  static List<IdeaModel> applyInferredTags(
    List<IdeaModel> postedIdeas,
    List<String> topics,
    List<TryNextInferredTag> inferredTags,
  ) {
    final topicSet = normalizeTopics(topics).toSet();
    final byId = {
      for (final inferred in inferredTags)
        if (topicSet.contains(inferred.topic)) inferred.ideaId: inferred.topic,
    };

    return postedIdeas.map((idea) {
      final id = idea.id;
      final topic = id == null ? null : byId[id];
      if (topic == null || !lacksSavedTopic(idea, topics)) return idea;
      return IdeaModel(
        id: idea.id,
        title: idea.title,
        script: idea.script,
        status: idea.status,
        tags: [...idea.tags, topic],
        isAIGenerated: idea.isAIGenerated,
        archived: idea.archived,
        createdAt: idea.createdAt,
        updatedAt: idea.updatedAt,
      );
    }).toList();
  }

  static List<TryNextHook> normalizeHooks({
    required List<TryNextHook> hooks,
    required List<String> topics,
    required String anchorTopic,
    required Map<String, int> counts,
  }) {
    final normalizedTopics = normalizeTopics(topics);
    if (normalizedTopics.isEmpty) return const [];
    final topicSet = normalizedTopics.toSet();
    final anchor = topicSet.contains(anchorTopic)
        ? anchorTopic
        : normalizedTopics.first;

    final valid = <TryNextHook>[];
    for (final hook in hooks) {
      final target = topicSet.contains(hook.targetTopic)
          ? hook.targetTopic
          : anchor;
      final bridge =
          hook.bridgeTopic != null && topicSet.contains(hook.bridgeTopic)
          ? hook.bridgeTopic
          : null;
      final cleaned = TryNextHook(
        type: hook.type.isEmpty
            ? (bridge == null ? 'sameTopic' : 'bridge')
            : hook.type,
        label: hook.label,
        hook: hook.hook,
        targetTopic: target,
        bridgeTopic: bridge,
        reason: hook.reason,
        generationDirection: hook.generationDirection,
      );
      if (!valid.any((h) => h.hook == cleaned.hook)) valid.add(cleaned);
      if (valid.length == 4) return valid;
    }

    for (final fallback in fallbackHooks(
      topics: normalizedTopics,
      anchorTopic: anchor,
      counts: counts,
    )) {
      if (!valid.any((h) => h.hook == fallback.hook)) valid.add(fallback);
      if (valid.length == 4) break;
    }
    return valid;
  }

  static List<TryNextHook> fallbackHooks({
    required List<String> topics,
    required String anchorTopic,
    required Map<String, int> counts,
  }) {
    final normalizedTopics = normalizeTopics(topics);
    if (normalizedTopics.isEmpty) return const [];
    final anchor = normalizedTopics.contains(anchorTopic)
        ? anchorTopic
        : normalizedTopics.first;

    final hooks = <TryNextHook>[
      TryNextHook(
        type: 'sameTopic',
        label: 'Push $anchor further',
        hook: 'The part of $anchor nobody talks about',
        targetTopic: anchor,
        reason:
            'This stays close to what you already post while giving it a sharper angle.',
        generationDirection:
            'Generate a fresh short-form idea under "$anchor" using this hook: "The part of $anchor nobody talks about." Keep it specific and different from my posted scripts.',
      ),
    ];

    final bridgeTopics = [...normalizedTopics.where((t) => t != anchor)]
      ..sort((a, b) {
        final countCompare = (counts[a] ?? 0).compareTo(counts[b] ?? 0);
        if (countCompare != 0) return countCompare;
        return normalizedTopics
            .indexOf(a)
            .compareTo(normalizedTopics.indexOf(b));
      });

    for (final topic in bridgeTopics.take(3)) {
      hooks.add(
        TryNextHook(
          type: 'bridge',
          label: '$topic x $anchor',
          hook: 'What $topic taught me about $anchor',
          targetTopic: topic,
          bridgeTopic: anchor,
          reason:
              'This connects an underused topic to the theme your posted content already proves you return to.',
          generationDirection:
              'Generate a short-form idea that connects "$topic" to "$anchor" using this hook: "What $topic taught me about $anchor." Make the connection feel natural, not forced.',
        ),
      );
    }

    const fallbackAngles = [
      ('Story angle', 'The mistake that changed how I think about'),
      ('Myth-busting angle', 'Stop believing this about'),
      ('Hot take angle', 'I think we are looking at this wrong:'),
    ];
    for (final angle in fallbackAngles) {
      if (hooks.length == 4) break;
      hooks.add(
        TryNextHook(
          type: 'fallback',
          label: angle.$1,
          hook: '${angle.$2} $anchor',
          targetTopic: anchor,
          reason:
              'This gives your strongest topic a new format without needing a new category.',
          generationDirection:
              'Generate a short-form idea under "$anchor" using this hook: "${angle.$2} $anchor." Make it practical, specific, and easy to film.',
        ),
      );
    }

    return hooks.take(4).toList();
  }

  static String sourceSignature(
    List<IdeaModel> postedIdeas,
    List<String> topics,
  ) {
    final sorted = [...postedIdeas]
      ..sort((a, b) {
        final aKey = a.id ?? a.title;
        final bKey = b.id ?? b.title;
        return aKey.compareTo(bKey);
      });
    final parts = [
      'topics:${normalizeTopics(topics).join('|')}',
      for (final idea in sorted)
        [
          idea.id ?? '',
          _hash(idea.title),
          _hash(idea.script),
          _hash(_sortedTags(idea.tags).join('|')),
        ].join(':'),
    ];
    return _hash(parts.join('||'));
  }

  static List<String> _sortedTags(List<String> tags) {
    return [...tags]..sort();
  }

  static int _latestUseMillis(List<IdeaModel> postedIdeas, String topic) {
    var latest = 0;
    for (final idea in postedIdeas) {
      if (!idea.tags.contains(topic)) continue;
      final millis = idea.updatedAt.millisecondsSinceEpoch;
      if (millis > latest) latest = millis;
    }
    return latest;
  }

  static String _hash(String value) {
    var hash = 0x811c9dc5;
    for (final unit in value.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }
}
