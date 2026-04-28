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
  static const int _promptCaptionLength = 220;
  static const int _promptCaptionCount = 6;
  static const int _promptTopicLength = 40;
  static const int _promptTopicCount = 12;
  static const int _promptCreatorStyleLength = 120;
  static const int _promptCreatorCount = 8;
  static const int _promptExistingSummaryLength = 140;
  static const int _promptExistingSummaryCount = 12;
  static const int _promptExtraDirectionLength = 200;

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
        .map((c) => InputValidator.sanitizeAndTruncate(c, _promptCaptionLength))
        .where((c) => c.isNotEmpty)
        .take(_promptCaptionCount)
        .toList();

    final safeTopics = topics
        .map((t) => InputValidator.sanitizeAndTruncate(t, _promptTopicLength))
        .where((t) => t.isNotEmpty)
        .take(_promptTopicCount)
        .toList();

    final safeCreators = creators
        .map((c) => InputValidator.sanitizeAndTruncate(c, InputValidator.maxCreatorNameLength))
        .where((c) => c.isNotEmpty)
        .take(_promptCreatorCount)
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
    String? aiAdvice,
  }) async {
    final captions = List<String>.from(signals['captions'] ?? [])
        .map((c) => InputValidator.sanitizeAndTruncate(c, _promptCaptionLength))
        .where((c) => c.isNotEmpty)
        .take(_promptCaptionCount)
        .toList();

    final topics = List<String>.from(signals['topics'] ?? [])
        .map((t) => InputValidator.sanitizeAndTruncate(t, _promptTopicLength))
        .where((t) => t.isNotEmpty)
        .take(_promptTopicCount)
        .toList();

    final rawCreators = List<dynamic>.from(signals['creators'] ?? [])
        .take(_promptCreatorCount)
        .map((c) {
          if (c is String) {
            return InputValidator.sanitizeAndTruncate(
              c,
              InputValidator.maxCreatorNameLength,
            );
          }
          if (c is Map) {
            return {
              'name': InputValidator.sanitizeAndTruncate(
                (c['name'] ?? '').toString(),
                InputValidator.maxCreatorNameLength,
              ),
              'style': InputValidator.sanitizeAndTruncate(
                (c['style'] ?? '').toString(),
                _promptCreatorStyleLength,
              ),
            };
          }
          return c;
        })
        .toList();

    final safeDirection = extraDirection != null
        ? InputValidator.sanitizeAndTruncate(
            extraDirection,
            _promptExtraDirectionLength,
          )
        : null;

    final safeAdvice = aiAdvice != null
        ? InputValidator.sanitizeAndTruncate(aiAdvice, 600)
        : null;

    return _callIdeaFunction({
      'mode': 'generateAvoidingExisting',
      'captions': captions,
      'topics': topics,
      'creators': rawCreators,
      'existingSummaries': existingSummaries
          .map((s) => InputValidator.sanitizeAndTruncate(s, _promptExistingSummaryLength))
          .take(_promptExistingSummaryCount)
          .toList(),
      if (safeDirection != null && safeDirection.isNotEmpty)
        'extraDirection': safeDirection,
      if (safeAdvice != null && safeAdvice.isNotEmpty)
        'aiAdvice': safeAdvice,
    });
  }

  // ── AI assist ──────────────────────────────────────────────────────────────

  static Future<String?> assistWithScript({
    required String title,
    required String currentScript,
    Map<String, dynamic>? signals,
  }) async {
    final captions = List<String>.from(signals?['captions'] ?? [])
        .map((c) => InputValidator.sanitizeAndTruncate(c, _promptCaptionLength))
        .where((c) => c.isNotEmpty)
        .take(2)
        .toList();

    final topics = List<String>.from(signals?['topics'] ?? [])
        .map((t) => InputValidator.sanitizeAndTruncate(t, _promptTopicLength))
        .where((t) => t.isNotEmpty)
        .take(8)
        .toList();

    final rawCreators = List<dynamic>.from(signals?['creators'] ?? [])
        .take(5)
        .map((c) {
          if (c is String) {
            return InputValidator.sanitizeAndTruncate(
              c,
              InputValidator.maxCreatorNameLength,
            );
          }
          if (c is Map) {
            return {
              'name': InputValidator.sanitizeAndTruncate(
                (c['name'] ?? '').toString(),
                InputValidator.maxCreatorNameLength,
              ),
              'style': InputValidator.sanitizeAndTruncate(
                (c['style'] ?? '').toString(),
                _promptCreatorStyleLength,
              ),
            };
          }
          return c;
        })
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
    String? aiAdvice,
  }) async {
    return generateIdeaAvoidingExisting(
      signals: signals,
      existingSummaries: const [],
      extraDirection: extraDirection,
      aiAdvice: aiAdvice,
    );
  }

  // ── AI advice ──────────────────────────────────────────────────────────────

  static Future<ClaudeResult<String>> getAIAdviceResult({
    required List<IdeaModel> ideas,
    Map<String, dynamic>? signals,
    List<String>? previousAdvice,
    List<String>? uncoveredTopics,
  }) async {
    final summaries = ideas.take(15).map((i) {
      final preview = i.script.isNotEmpty
          ? i.script.substring(0, i.script.length.clamp(0, 100))
          : '';
      return '"${i.title}" [${i.status}]${preview.isNotEmpty ? ': $preview...' : ''}';
    }).toList();

    final topics = List<String>.from(signals?['topics'] ?? [])
        .map((t) => InputValidator.sanitizeAndTruncate(t, _promptTopicLength))
        .where((t) => t.isNotEmpty)
        .take(_promptTopicCount)
        .toList();

    final captions = List<String>.from(signals?['captions'] ?? [])
        .map((c) => InputValidator.sanitizeAndTruncate(c, _promptCaptionLength))
        .where((c) => c.isNotEmpty)
        .take(3)
        .toList();

    final safePrevious = (previousAdvice ?? [])
        .map((a) => InputValidator.sanitizeAndTruncate(a, 300))
        .where((a) => a.isNotEmpty)
        .take(8)
        .toList();

    final safeUncovered = (uncoveredTopics ?? [])
        .map((t) => InputValidator.sanitizeAndTruncate(t, _promptTopicLength))
        .where((t) => t.isNotEmpty)
        .toList();

    return _callTextFunction({
      'mode': 'getAIAdvice',
      'existingSummaries': summaries,
      'topics': topics,
      'captions': captions,
      'creators': <dynamic>[],
      if (safePrevious.isNotEmpty) 'previousAdvice': safePrevious,
      if (safeUncovered.isNotEmpty) 'uncoveredTopics': safeUncovered,
    });
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
