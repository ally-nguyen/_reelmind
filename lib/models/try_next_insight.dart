class TryNextInferredTag {
  final String ideaId;
  final String topic;
  final double confidence;

  const TryNextInferredTag({
    required this.ideaId,
    required this.topic,
    required this.confidence,
  });

  factory TryNextInferredTag.fromJson(Map<String, dynamic> json) {
    return TryNextInferredTag(
      ideaId: (json['ideaId'] ?? '').toString(),
      topic: (json['topic'] ?? '').toString(),
      confidence: _toDouble(json['confidence']).clamp(0.0, 1.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() => {
    'ideaId': ideaId,
    'topic': topic,
    'confidence': confidence,
  };
}

class TryNextHook {
  final String type;
  final String label;
  final String hook;
  final String targetTopic;
  final String? bridgeTopic;
  final String reason;
  final String generationDirection;

  const TryNextHook({
    required this.type,
    required this.label,
    required this.hook,
    required this.targetTopic,
    this.bridgeTopic,
    required this.reason,
    required this.generationDirection,
  });

  factory TryNextHook.fromJson(Map<String, dynamic> json) {
    final bridge = (json['bridgeTopic'] ?? '').toString().trim();
    return TryNextHook(
      type: (json['type'] ?? '').toString(),
      label: (json['label'] ?? '').toString(),
      hook: (json['hook'] ?? '').toString(),
      targetTopic: (json['targetTopic'] ?? '').toString(),
      bridgeTopic: bridge.isEmpty ? null : bridge,
      reason: (json['reason'] ?? '').toString(),
      generationDirection: (json['generationDirection'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toMap() => {
    'type': type,
    'label': label,
    'hook': hook,
    'targetTopic': targetTopic,
    if (bridgeTopic != null) 'bridgeTopic': bridgeTopic,
    'reason': reason,
    'generationDirection': generationDirection,
  };
}

class TryNextInsight {
  final String pattern;
  final String anchorTopic;
  final Map<String, int> topicCounts;
  final List<TryNextInferredTag> inferredTags;
  final List<TryNextHook> hooks;
  final String sourceSignature;

  const TryNextInsight({
    required this.pattern,
    required this.anchorTopic,
    required this.topicCounts,
    required this.inferredTags,
    required this.hooks,
    required this.sourceSignature,
  });

  factory TryNextInsight.fromJson(
    Map<String, dynamic> json, {
    String fallbackSourceSignature = '',
  }) {
    final rawCounts = _asStringMap(json['topicCounts']);
    final rawInferred = _asList(json['inferredTags']);
    final rawHooks = _asList(json['hooks']);

    return TryNextInsight(
      pattern: (json['pattern'] ?? '').toString(),
      anchorTopic: (json['anchorTopic'] ?? '').toString(),
      topicCounts: {
        for (final entry in rawCounts.entries)
          entry.key: _toInt(entry.value).clamp(0, 999).toInt(),
      },
      inferredTags: rawInferred
          .whereType<Map>()
          .map((m) => TryNextInferredTag.fromJson(_dynamicMap(m)))
          .where((t) => t.ideaId.isNotEmpty && t.topic.isNotEmpty)
          .toList(),
      hooks: rawHooks
          .whereType<Map>()
          .map((m) => TryNextHook.fromJson(_dynamicMap(m)))
          .where(
            (h) =>
                h.label.isNotEmpty &&
                h.hook.isNotEmpty &&
                h.targetTopic.isNotEmpty &&
                h.generationDirection.isNotEmpty,
          )
          .toList(),
      sourceSignature: (json['sourceSignature'] ?? fallbackSourceSignature)
          .toString(),
    );
  }

  TryNextInsight copyWith({
    String? pattern,
    String? anchorTopic,
    Map<String, int>? topicCounts,
    List<TryNextInferredTag>? inferredTags,
    List<TryNextHook>? hooks,
    String? sourceSignature,
  }) {
    return TryNextInsight(
      pattern: pattern ?? this.pattern,
      anchorTopic: anchorTopic ?? this.anchorTopic,
      topicCounts: topicCounts ?? this.topicCounts,
      inferredTags: inferredTags ?? this.inferredTags,
      hooks: hooks ?? this.hooks,
      sourceSignature: sourceSignature ?? this.sourceSignature,
    );
  }

  Map<String, dynamic> toMap() => {
    'pattern': pattern,
    'anchorTopic': anchorTopic,
    'topicCounts': topicCounts,
    'inferredTags': inferredTags.map((t) => t.toMap()).toList(),
    'hooks': hooks.map((h) => h.toMap()).toList(),
    'sourceSignature': sourceSignature,
  };
}

Map<String, dynamic> _dynamicMap(Map map) => {
  for (final entry in map.entries) entry.key.toString(): entry.value,
};

Map<String, dynamic> _asStringMap(Object? value) {
  if (value is Map) return _dynamicMap(value);
  return const {};
}

List<dynamic> _asList(Object? value) {
  if (value is List) return value;
  return const [];
}

double _toDouble(Object? value) {
  if (value is num) return value.toDouble();
  return double.tryParse((value ?? '').toString()) ?? 0;
}

int _toInt(Object? value) {
  if (value is num) return value.round();
  return int.tryParse((value ?? '').toString()) ?? 0;
}
