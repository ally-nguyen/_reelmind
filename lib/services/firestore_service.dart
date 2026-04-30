import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/idea_model.dart';
import '../models/saved_advice_model.dart';
import '../models/try_next_insight.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;

  // ── User ──────────────────────────────────────────────────────────────────

  static Future<void> createUserDoc(String uid, String email) async {
    await _db.collection('users').doc(uid).set({
      'email': email,
      'createdAt': FieldValue.serverTimestamp(),
      'tutorialSeen':
          false, // only set on first creation; merge won't overwrite later
    }, SetOptions(merge: true));
  }

  static Future<bool> hasTutorialBeenSeen(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    final data = doc.data();
    if (data == null || !data.containsKey('tutorialSeen')) {
      return true; // existing user — skip
    }
    return data['tutorialSeen'] == true;
  }

  static Future<void> markTutorialSeen(String uid) async {
    await _db.collection('users').doc(uid).update({'tutorialSeen': true});
  }

  // ── Signals ───────────────────────────────────────────────────────────────

  // Full save (used by ImportSignalsScreen after editing)
  static Future<void> saveSignals(
    String uid, {
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
  static Future<void> saveSurveyTopics(String uid, List<String> topics) async {
    await _db.collection('users').doc(uid).update({
      'signals.topics': topics,
      'signals.updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> saveSurveyCaptions(
    String uid,
    List<String> captions,
  ) async {
    await _db.collection('users').doc(uid).update({
      'signals.captions': captions,
      'signals.updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> saveSurveyCreators(
    String uid,
    List<Map<String, String>> creators,
  ) async {
    await _db.collection('users').doc(uid).update({
      'signals.creators': creators,
      'signals.updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> saveSurveyVideos(
    String uid,
    List<Map<String, String>> videos,
  ) async {
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

  static Future<void> saveAIAdvice(String uid, String advice) async {
    await _db.collection('users').doc(uid).set({
      'aiAdvice': advice,
    }, SetOptions(merge: true));
  }

  static Future<String?> getAIAdvice(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data()?['aiAdvice'] as String?;
  }

  static Future<void> saveTryNextInsight(
    String uid,
    TryNextInsight insight,
  ) async {
    await _db.collection('users').doc(uid).set({
      'tryNextInsight': {
        ...insight.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }

  static Future<TryNextInsight?> getTryNextInsight(String uid) async {
    final doc = await _db.collection('users').doc(uid).get();
    final raw = doc.data()?['tryNextInsight'];
    if (raw is! Map) return null;
    return TryNextInsight.fromJson({
      for (final entry in raw.entries) entry.key.toString(): entry.value,
    });
  }

  static CollectionReference<Map<String, dynamic>> _savedAdviceRef(
    String uid,
  ) => _db.collection('users').doc(uid).collection('savedAdvice');

  static Future<void> addSavedAdvice(String uid, String text) async {
    await _savedAdviceRef(
      uid,
    ).add({'text': text, 'savedAt': FieldValue.serverTimestamp()});
  }

  static Stream<List<SavedAdviceModel>> savedAdviceStream(String uid) {
    return _savedAdviceRef(uid)
        .orderBy('savedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(SavedAdviceModel.fromDoc).toList());
  }

  static Future<List<String>> getSavedAdviceTexts(String uid) async {
    final snap = await _savedAdviceRef(
      uid,
    ).orderBy('savedAt', descending: true).limit(8).get();
    return snap.docs
        .map((d) => (d.data()['text'] as String?) ?? '')
        .where((t) => t.isNotEmpty)
        .toList();
  }

  static Future<int> getSavedAdviceCount(String uid) async {
    final snap = await _savedAdviceRef(uid).count().get();
    return snap.count ?? 0;
  }

  static Future<void> deleteSavedAdvice(String uid, String docId) async {
    await _savedAdviceRef(uid).doc(docId).delete();
  }

  // ── Ideas ─────────────────────────────────────────────────────────────────

  static CollectionReference<Map<String, dynamic>> _ideasRef(String uid) =>
      _db.collection('users').doc(uid).collection('ideas');

  static Stream<List<IdeaModel>> ideasStream(String uid) {
    return _ideasRef(uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map(IdeaModel.fromDoc)
              .where((i) => !i.archived)
              .toList(),
        );
  }

  static Stream<List<IdeaModel>> archivedIdeasStream(String uid) {
    return _ideasRef(uid).where('archived', isEqualTo: true).snapshots().map((
      snap,
    ) {
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
    String uid,
    String ideaId,
    Map<String, dynamic> data,
  ) async {
    await _ideasRef(
      uid,
    ).doc(ideaId).update({...data, 'updatedAt': FieldValue.serverTimestamp()});
  }

  static Future<void> deleteIdea(String uid, String ideaId) async {
    await _ideasRef(uid).doc(ideaId).delete();
  }

  // ── Account deletion ──────────────────────────────────────────────────────

  /// Permanently deletes all data belonging to [uid]:
  ///   1. Every document in the ideas subcollection.
  ///   2. The top-level user document (signals, preferences, rate-limit data).
  ///   3. All files under Storage path users/{uid}/.
  ///
  /// Does NOT delete the Firebase Auth account — the caller must do that
  /// separately (after re-authentication if required).
  static Future<void> deleteAllUserData(String uid) async {
    // Run Firestore and Storage deletions in parallel.
    await Future.wait([_deleteFirestoreData(uid), _deleteStorageData(uid)]);
  }

  static Future<void> _deleteFirestoreData(String uid) async {
    final ideasSnap = await _ideasRef(uid).get();

    // Batch all deletes into single requests (max 500 per batch).
    final refs = [
      ...ideasSnap.docs.map((d) => d.reference),
      _db.collection('users').doc(uid),
    ];

    const batchSize = 500;
    final batches = <WriteBatch>[];
    for (var i = 0; i < refs.length; i += batchSize) {
      final batch = _db.batch();
      for (final ref in refs.skip(i).take(batchSize)) {
        batch.delete(ref);
      }
      batches.add(batch);
    }

    await Future.wait(batches.map((b) => b.commit()));
  }

  static Future<void> _deleteStorageData(String uid) async {
    try {
      final storageRef = FirebaseStorage.instance.ref().child('users/$uid');
      final list = await storageRef.listAll();
      await Future.wait([
        ...list.items.map((item) => item.delete()),
        ...list.prefixes.map((prefix) async {
          final sub = await prefix.listAll();
          await Future.wait(sub.items.map((item) => item.delete()));
        }),
      ]);
    } catch (_) {
      // Best-effort — don't block if folder doesn't exist.
    }
  }
}
