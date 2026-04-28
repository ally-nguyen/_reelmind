import 'package:cloud_firestore/cloud_firestore.dart';

class SavedAdviceModel {
  final String id;
  final String text;
  final DateTime savedAt;

  const SavedAdviceModel({
    required this.id,
    required this.text,
    required this.savedAt,
  });

  factory SavedAdviceModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SavedAdviceModel(
      id: doc.id,
      text: data['text'] as String? ?? '',
      savedAt: (data['savedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
