// ── rate_limiter.dart ────────────────────────────────────────────────────────
//
// OWASP A07: Identification & Authentication Failures
//
// Client-side sliding-window rate limiter.  Because this app calls the Claude
// API directly from the device (no backend proxy), rate limiting lives here.
// This prevents runaway charges from bugs or accidental rapid taps; it is not
// a substitute for server-side enforcement.
//
// Each [RateLimitBucket] tracks timestamps of recent events in a sliding
// window.  Old timestamps outside the window are pruned on every check.
// ────────────────────────────────────────────────────────────────────────────

class RateLimitResult {
  final bool allowed;

  // How long the caller must wait before retrying (null when allowed == true).
  final Duration? retryAfter;

  const RateLimitResult.ok() : allowed = true, retryAfter = null;
  const RateLimitResult.blocked(this.retryAfter) : allowed = false;

  @override
  String toString() => allowed
      ? 'RateLimitResult(allowed)'
      : 'RateLimitResult(blocked, retryAfter: $retryAfter)';
}

class _RateLimitBucket {
  final int maxEvents;
  final Duration window;
  final List<DateTime> _timestamps = [];

  _RateLimitBucket({required this.maxEvents, required this.window});

  RateLimitResult check() {
    final now = DateTime.now();
    final cutoff = now.subtract(window);

    // Prune events outside the sliding window.
    _timestamps.removeWhere((t) => t.isBefore(cutoff));

    if (_timestamps.length < maxEvents) {
      _timestamps.add(now);
      return const RateLimitResult.ok();
    }

    // Oldest event still inside the window tells us when the window clears.
    final oldestInWindow = _timestamps.first;
    final retryAfter = oldestInWindow.add(window).difference(now);
    return RateLimitResult.blocked(retryAfter);
  }

  void reset() => _timestamps.clear();
}

// ── Singleton ────────────────────────────────────────────────────────────────

class RateLimiter {
  RateLimiter._();
  static final RateLimiter instance = RateLimiter._();

  // Login: 5 attempts per 15-minute window.
  // Mirrors Firebase Auth's own lockout as a first-party guard.
  final _loginBucket = _RateLimitBucket(
    maxEvents: 5,
    window: const Duration(minutes: 15),
  );

  // Sign-up: 3 new accounts per hour to reduce account-farming abuse.
  final _signupBucket = _RateLimitBucket(
    maxEvents: 3,
    window: const Duration(hours: 1),
  );

  // Claude API: 10 generations per hour.  This caps unintentional charges from
  // rapid regeneration taps.  Adjust if your usage pattern requires more.
  final _claudeBucket = _RateLimitBucket(
    maxEvents: 10,
    window: const Duration(hours: 1),
  );

  // Password-reset emails: 3 per hour to prevent email-flooding a victim.
  final _passwordResetBucket = _RateLimitBucket(
    maxEvents: 3,
    window: const Duration(hours: 1),
  );

  // ── Public API ──────────────────────────────────────────────────────────────

  /// Call before every login attempt.
  RateLimitResult checkLogin() => _loginBucket.check();

  /// Call before every sign-up attempt.
  RateLimitResult checkSignup() => _signupBucket.check();

  /// Call before every Claude API call.
  RateLimitResult checkClaudeApi() => _claudeBucket.check();

  /// Call before sending a password-reset email.
  RateLimitResult checkPasswordReset() => _passwordResetBucket.check();

  /// Reset the login bucket on successful authentication so a legitimate user
  /// who mis-typed their password several times starts fresh after logging in.
  void onLoginSuccess() => _loginBucket.reset();

  // ── Human-readable wait message ─────────────────────────────────────────────

  /// Returns a user-facing string like "Try again in 4 minutes".
  static String waitMessage(Duration d) {
    final minutes = d.inMinutes;
    if (minutes >= 60) {
      final hours = d.inHours;
      return 'Try again in $hours hour${hours == 1 ? '' : 's'}';
    }
    if (minutes >= 1) return 'Try again in $minutes minute${minutes == 1 ? '' : 's'}';
    final seconds = d.inSeconds.clamp(1, 59);
    return 'Try again in $seconds second${seconds == 1 ? '' : 's'}';
  }
}
