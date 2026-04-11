// ── claude_service.dart ──────────────────────────────────────────────────────
//
// SECURITY DESIGN
// ───────────────
// All calls to the Anthropic API are proxied through the Firebase Cloud
// Function `callClaude`.  The Anthropic API key lives ONLY in Firebase Secret
// Manager — it is never in the client binary, git history, or config files.
//
// The function verifies the caller's Firebase Auth token, enforces server-side
// per-user rate limiting, sanitises all inputs, and returns a structured
// response.  The Flutter client only ever sees the function result, never the
// Anthropic API directly.
//
// The client-side RateLimiter still runs as a first-pass guard to prevent
// unnecessary network round-trips (e.g. rapid button taps), but the
// authoritative limit is enforced server-side.
// ────────────────────────────────────────────────────────────────────────────

import 'package:cloud_functions/cloud_functions.dart';
import '../models/idea_model.dart';
import '../services/rate_limiter.dart';
import '../utils/input_validator.dart';

// ── Typed result ──────────────────────────────────────────────────────────────

enum ClaudeErrorKind { rateLimitedLocally, rateLimitedByApi, networkError, unknown }

class ClaudeResult<T> {
  final T? value;
  final ClaudeErrorKind? error;
  final Duration? retryAfter;

  const ClaudeResult.ok(this.value) : error = null, retryAfter = null;
  const ClaudeResult.err(this.error, {this.retryAfter}) : value = null;

  bool get isOk => error == null;
}

// ── Service ───────────────────────────────────────────────────────────────────

class ClaudeService {
  // Lazily obtain a reference to the deployed Cloud Function.
  static HttpsCallable get _fn =>
      FirebaseFunctions.instance.httpsCallable(
        'callClaude',
        options: HttpsCallableOptions(timeout: const Duration(seconds: 60)),
      );

  // ── Generate idea from import signals ──────────────────────────────────────

  static Future<ClaudeResult<IdeaModel>> generateIdeaFromSignals({
    required List<String> captions,
    required List<String> topics,
    required List<String> creators,
  }) async {
    // Sanitise client-side before sending (defence in depth — server sanitises
    // again, but we don't want to send garbage over the network).
    final safeCaps = captions
        .map((c) => InputValidator.sanitizeAndTruncate(c, InputValidator.maxCaptionLength))
        .where((c) => c.isNotEmpty)
        .take(InputValidator.maxCaptionCount)
        .toList();

    final safeTopics = topics
        .map((t) => InputValidator.sanitizeAndTruncate(t, InputValidator.maxTopicLength))
        .where((t) => t.isNotEmpty)
        .take(InputValidator.maxTopicCount)
        .toList();

    final safeCreators = creators
        .map((c) => InputValidator.sanitizeAndTruncate(c, InputValidator.maxCreatorNameLength))
        .where((c) => c.isNotEmpty)
        .take(InputValidator.maxCreatorCount)
        .toList();

    return _callIdeaFunction({
      'mode': 'generateFromSignals',
      'captions': safeCaps,
      'topics': safeTopics,
      'creators': safeCreators,
    });
  }

  // ── Generate idea avoiding existing ideas ──────────────────────────────────

  static Future<ClaudeResult<IdeaModel>> generateIdeaAvoidingExisting({
    required Map<String, dynamic> signals,
    required List<String> existingSummaries,
    String? extraDirection,
  }) async {
    final captions = List<String>.from(signals['captions'] ?? [])
        .map((c) => InputValidator.sanitizeAndTruncate(c, InputValidator.maxCaptionLength))
        .where((c) => c.isNotEmpty)
        .take(InputValidator.maxCaptionCount)
        .toList();

    final topics = List<String>.from(signals['topics'] ?? [])
        .map((t) => InputValidator.sanitizeAndTruncate(t, InputValidator.maxTopicLength))
        .where((t) => t.isNotEmpty)
        .take(InputValidator.maxTopicCount)
        .toList();

    // Creators may be String or Map — pass as-is; server normalises both forms.
    final rawCreators = List<dynamic>.from(signals['creators'] ?? [])
        .take(InputValidator.maxCreatorCount)
        .toList();

    final safeDirection = extraDirection != null
        ? InputValidator.sanitizeAndTruncate(extraDirection, InputValidator.maxExtraDirectionLength)
        : null;

    return _callIdeaFunction({
      'mode': 'generateAvoidingExisting',
      'captions': captions,
      'topics': topics,
      'creators': rawCreators,
      'existingSummaries': existingSummaries
          .map((s) => InputValidator.sanitizeAndTruncate(s, 300))
          .take(50)
          .toList(),
      if (safeDirection != null && safeDirection.isNotEmpty)
        'extraDirection': safeDirection,
    });
  }

  // ── AI assist ──────────────────────────────────────────────────────────────

  static Future<String?> assistWithScript({
    required String title,
    required String currentScript,
    Map<String, dynamic>? signals,
  }) async {
    final captions = List<String>.from(signals?['captions'] ?? [])
        .map((c) => InputValidator.sanitizeAndTruncate(c, InputValidator.maxCaptionLength))
        .where((c) => c.isNotEmpty)
        .take(3)
        .toList();

    final topics = List<String>.from(signals?['topics'] ?? [])
        .map((t) => InputValidator.sanitizeAndTruncate(t, InputValidator.maxTopicLength))
        .where((t) => t.isNotEmpty)
        .take(InputValidator.maxTopicCount)
        .toList();

    final rawCreators = List<dynamic>.from(signals?['creators'] ?? [])
        .take(InputValidator.maxCreatorCount)
        .toList();

    final result = await _callTextFunction({
      'mode': 'assistScript',
      'title': InputValidator.sanitizeAndTruncate(title, 200),
      'currentScript': InputValidator.sanitizeAndTruncate(currentScript, 10000),
      'captions': captions,
      'topics': topics,
      'creators': rawCreators,
    });

    return result.value;
  }

  // ── Generate idea with saved signals ──────────────────────────────────────

  static Future<ClaudeResult<IdeaModel>> generateIdeaWithSavedSignals({
    required Map<String, dynamic> signals,
    String? extraDirection,
  }) async {
    return generateIdeaAvoidingExisting(
      signals: signals,
      existingSummaries: const [],
      extraDirection: extraDirection,
    );
  }

  // ── Predict next move ──────────────────────────────────────────────────────

  static Future<String?> predictNextMove(List<IdeaModel> ideas) async {
    if (ideas.isEmpty) return null;

    final summaries = ideas.take(10).map((i) {
      final preview = i.script.isNotEmpty
          ? i.script.substring(0, i.script.length.clamp(0, 120))
          : '';
      return '"${i.title}" [${i.status}]${preview.isNotEmpty ? ': $preview...' : ''}';
    }).toList();

    final result = await _callTextFunction({
      'mode': 'assistScript',
      'title': 'PREDICT_NEXT_MOVE',
      'currentScript': summaries.join('\n'),
      'captions': <String>[],
      'topics': <String>[],
      'creators': <dynamic>[],
    });

    return result.value;
  }

  // ── Shared call helpers ────────────────────────────────────────────────────

  /// Call the function and expect an IdeaModel in the response.
  static Future<ClaudeResult<IdeaModel>> _callIdeaFunction(
      Map<String, dynamic> payload) async {
    final rl = RateLimiter.instance.checkClaudeApi();
    if (!rl.allowed) {
      return ClaudeResult.err(
        ClaudeErrorKind.rateLimitedLocally,
        retryAfter: rl.retryAfter,
      );
    }
    try {
      final result = await _fn.call(payload);
      final data = result.data as Map<dynamic, dynamic>;
      final idea = IdeaModel(
        title: data['title'] as String,
        script: data['script'] as String,
        isAIGenerated: true,
      );
      return ClaudeResult.ok(idea);
    } on FirebaseFunctionsException catch (e) {
      return ClaudeResult.err(_mapFnError(e.code));
    } catch (_) {
      return const ClaudeResult.err(ClaudeErrorKind.networkError);
    }
  }

  /// Call the function and expect a plain text string in the response.
  static Future<ClaudeResult<String>> _callTextFunction(
      Map<String, dynamic> payload) async {
    final rl = RateLimiter.instance.checkClaudeApi();
    if (!rl.allowed) {
      return ClaudeResult.err(
        ClaudeErrorKind.rateLimitedLocally,
        retryAfter: rl.retryAfter,
      );
    }
    try {
      final result = await _fn.call(payload);
      final data = result.data as Map<dynamic, dynamic>;
      return ClaudeResult.ok(data['text'] as String?);
    } on FirebaseFunctionsException catch (e) {
      return ClaudeResult.err(_mapFnError(e.code));
    } catch (_) {
      return const ClaudeResult.err(ClaudeErrorKind.networkError);
    }
  }

  static ClaudeErrorKind _mapFnError(String code) {
    switch (code) {
      case 'resource-exhausted':
        return ClaudeErrorKind.rateLimitedByApi;
      case 'unauthenticated':
      case 'permission-denied':
        return ClaudeErrorKind.unknown;
      default:
        return ClaudeErrorKind.networkError;
    }
  }
}
