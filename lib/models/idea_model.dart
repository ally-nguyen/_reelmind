import 'package:cloud_firestore/cloud_firestore.dart';

class IdeaModel {
  final String? id;
  final String title;
  final String script;
  final String status;
  final List<String> tags;
  final bool isAIGenerated;
  final bool archived;
  final DateTime createdAt;
  final DateTime updatedAt;

  IdeaModel({
    this.id,
    required this.title,
    required this.script,
    this.status = 'Draft',
    this.tags = const [],
    this.isAIGenerated = false,
    this.archived = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  factory IdeaModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IdeaModel(
      id: doc.id,
      title: data['title'] ?? '',
      script: data['script'] ?? '',
      status: data['status'] ?? 'Draft',
      tags: List<String>.from(data['tags'] ?? []),
      isAIGenerated: data['isAIGenerated'] ?? false,
      archived: data['archived'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'script': script,
        'status': status,
        'tags': tags,
        'isAIGenerated': isAIGenerated,
        'archived': archived,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  String get timeAgoLabel {
    final diff = DateTime.now().difference(updatedAt);
    if (diff.inMinutes < 1) return 'Edited just now';
    if (diff.inMinutes < 60) return 'Edited ${diff.inMinutes}m ago';
    if (diff.inHours < 24) return 'Edited ${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Edited yesterday';
    return 'Edited ${diff.inDays} days ago';
  }
}
