import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/idea_model.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // ── User ──────────────────────────────────────────────────────────────────

  static Future<void> createUserDoc(String uid, String email) async {
    await _db.collection('users').doc(uid).set({
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'tutorialSeen': false,   // only set on first creation; merge won't overwrite later
    }, SetOptions(merge: true));
  }

  static Future<bool> hasTutorialBeenSeen(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null || !data.containsKey('tutorialSeen')) return true; // existing user — skip
    return data['tutorialSeen'] == true;
  }

  static Future<void> markTutorialSeen(String uid) async {
    await _db.collection('users').doc(uid).update({'tutorialSeen': true});
  }

  // ── Signals ───────────────────────────────────────────────────────────────

  // Full save (used by ImportSignalsScreen after editing)
  static Future<void> saveSignals(String uid, {
    required List<String> captions,
    required List<String> topics,
    required List<Map<String, String>> creators,
    List<Map<String, String>> videos = const [],
  }) async {
    await _db.collection('users').doc(uid).set({
      'signals': {
        'captions': captions,
        'topics': topics,
        'creators': creators,
        'videos': videos,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }

  // Per-step saves (used by onboarding survey — dot-notation updates only
  // the targeted field, leaving all other signals fields intact)
  static Future<void> saveSurveyTopics(
      String uid, List<String> topics) async {
    await _db.collection('users').doc(uid).update({
      'signals.topics': topics,
      'signals.updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> saveSurveyCaptions(
      String uid, List<String> captions) async {
    await _db.collection('users').doc(uid).update({
      'signals.captions': captions,
      'signals.updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> saveSurveyCreators(
      String uid, List<Map<String, String>> creators) async {
    await _db.collection('users').doc(uid).update({
      'signals.creators': creators,
      'signals.updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> saveSurveyVideos(
      String uid, List<Map<String, String>> videos) async {
    await _db.collection('users').doc(uid).update({
      'signals.videos': videos,
      'signals.updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<Map<String, dynamic>?> getSignals(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()?['signals'] as Map<String, dynamic>?;
  }

  // ── Ideas ─────────────────────────────────────────────────────────────────

  static CollectionReference<Map<String, dynamic>> _ideasRef(String uid) =>
      _db.collection('users').doc(uid).collection('ideas');

  static Stream<List<IdeaModel>> ideasStream(String uid) {
    return _ideasRef(uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map(IdeaModel.fromDoc)
            .where((i) => !i.archived)
            .toList());
  }

  static Stream<List<IdeaModel>> archivedIdeasStream(String uid) {
    return _ideasRef(uid)
        .where('archived', isEqualTo: true)
        .snapshots()
        .map((snap) {
      final list = snap.docs.map(IdeaModel.fromDoc).toList();
      list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      return list;
    });
  }

  static Future<void> archiveIdea(String uid, String ideaId) async {
    await _ideasRef(uid).doc(ideaId).update({
      'archived': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> unarchiveIdea(String uid, String ideaId) async {
    await _ideasRef(uid).doc(ideaId).update({
      'archived': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Deletes archived ideas whose updatedAt is older than 30 days.
  static Future<void> deleteOldArchivedIdeas(String uid) async {
    final cutoff = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(days: 30)),
    );
    final snap = await _ideasRef(uid)
        .where('archived', isEqualTo: true)
        .where('updatedAt', isLessThan: cutoff)
        .get();
    await Future.wait(snap.docs.map((d) => d.reference.delete()));
  }

  static Future<String> addIdea(String uid, IdeaModel idea) async {
    final doc = await _ideasRef(uid).add(idea.toMap());
    return doc.id;
  }

  static Future<void> updateIdea(
      String uid, String ideaId, Map<String, dynamic> data) async {
    await _ideasRef(uid)
        .doc(ideaId)
        .update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  }

  static Future<void> deleteIdea(String uid, String ideaId) async {
    await _ideasRef(uid).doc(ideaId).delete();
  }
}
