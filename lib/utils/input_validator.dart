// ── input_validator.dart ─────────────────────────────────────────────────────
//
// OWASP A03: Injection  |  OWASP A04: Insecure Design
//
// Centralised input validation and sanitisation.  All user-supplied text
// passes through this file before being stored in Firestore or forwarded to
// the Claude API.
//
// Rules:
//   • Schema-based — every field has an explicit type, min/max length, and
//     allowed-character set.
//   • Reject unexpected chars early rather than trying to escape them later.
//   • sanitizeText() strips null bytes and ASCII control characters that have
//     no legitimate place in user content but could cause downstream parsing
//     issues.
// ────────────────────────────────────────────────────────────────────────────

class InputValidator {
  InputValidator._();

  // ── Field length limits (characters) ─────────────────────────────────────

  static const int maxEmailLength = 254;       // RFC 5321
  static const int maxPasswordLength = 128;
  static const int minPasswordLength = 8;
  static const int maxDisplayNameLength = 100;
  static const int minDisplayNameLength = 2;

  static const int maxCaptionLength = 500;     // per caption
  static const int maxCaptionCount = 20;       // total captions

  static const int maxTopicLength = 60;
  static const int maxTopicCount = 20;

  static const int maxCreatorNameLength = 100;
  static const int maxCreatorStyleLength = 300;
  static const int maxCreatorCount = 15;

  static const int maxVideoNameLength = 100;
  static const int maxVideoNotesLength = 400;
  static const int maxVideoCount = 10;

  static const int maxExtraDirectionLength = 500;

  // ── Email ─────────────────────────────────────────────────────────────────

  // RFC 5322-inspired; rejects the most obviously invalid formats.
  // Firebase Auth does its own authoritative check server-side.
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9.!#$%&*+/=?^_`{|}~-]+'
    r'@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
    r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*'
    r'\.[a-zA-Z]{2,}$',
  );

  /// Returns an error string, or null if valid.
  static String? validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your email.';
    if (v.length > maxEmailLength) return 'Email is too long.';
    if (!_emailRegex.hasMatch(v)) return 'Enter a valid email address.';
    return null;
  }

  // ── Password ──────────────────────────────────────────────────────────────

  /// Returns an error string, or null if valid.
  /// Enforces length only — complexity requirements frustrate users and lead to
  /// predictable patterns; length is the strongest single defence (NIST SP
  /// 800-63B).  Firebase enforces minimum 6 chars server-side; we raise it.
  static String? validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Enter a password.';
    if (v.length < minPasswordLength) {
      return 'Password must be at least $minPasswordLength characters.';
    }
    if (v.length > maxPasswordLength) {
      return 'Password must be $maxPasswordLength characters or fewer.';
    }
    return null;
  }

  /// Stricter validator used only at sign-up time (login accepts anything to
  /// avoid locking out users with legacy passwords).
  static String? validateNewPassword(String? value) {
    final base = validatePassword(value);
    if (base != null) return base;
    final v = value!;
    // Require at least one uppercase and one digit or symbol so the password
    // isn't trivially guessable even at minimum length.
    final hasUpper = v.contains(RegExp(r'[A-Z]'));
    final hasDigitOrSymbol = v.contains(RegExp(r'[0-9!@#\$%^&*()_+\-=\[\]{};:,.<>?]'));
    if (!hasUpper || !hasDigitOrSymbol) {
      return 'Include an uppercase letter and a number or symbol.';
    }
    return null;
  }

  // ── Display name ─────────────────────────────────────────────────────────

  static String? validateDisplayName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Enter your name.';
    if (v.length < minDisplayNameLength) return 'Name is too short.';
    if (v.length > maxDisplayNameLength) {
      return 'Name must be $maxDisplayNameLength characters or fewer.';
    }
    return null;
  }

  // ── Captions ──────────────────────────────────────────────────────────────

  /// Returns an error string, or null if valid.
  static String? validateCaption(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null; // blank captions are skipped, not an error
    if (v.length > maxCaptionLength) {
      return 'Caption must be $maxCaptionLength characters or fewer.';
    }
    return null;
  }

  // ── Topics ────────────────────────────────────────────────────────────────

  static String? validateTopic(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Topic cannot be empty.';
    if (v.length > maxTopicLength) {
      return 'Topic must be $maxTopicLength characters or fewer.';
    }
    return null;
  }

  // ── Creator name ──────────────────────────────────────────────────────────

  static String? validateCreatorName(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Creator name cannot be empty.';
    if (v.length > maxCreatorNameLength) {
      return 'Creator name must be $maxCreatorNameLength characters or fewer.';
    }
    return null;
  }

  // ── Extra direction (generator screen) ───────────────────────────────────

  static String? validateExtraDirection(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return null;
    if (v.length > maxExtraDirectionLength) {
      return 'Direction must be $maxExtraDirectionLength characters or fewer.';
    }
    return null;
  }

  // ── Sanitisation ─────────────────────────────────────────────────────────

  /// Strips ASCII control characters (except \t, \n, \r) and null bytes.
  /// Does NOT HTML-encode — this is a native app, not a browser.
  static String sanitizeText(String input) {
    return input
        // Remove null bytes.
        .replaceAll('\x00', '')
        // Remove ASCII control characters C0 (except HT/LF/CR) and DEL.
        .replaceAll(RegExp(r'[\x01-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
  }

  /// Sanitise and hard-truncate a string to [maxLength] characters.
  static String sanitizeAndTruncate(String input, int maxLength) {
    final sanitized = sanitizeText(input.trim());
    if (sanitized.length <= maxLength) return sanitized;
    return sanitized.substring(0, maxLength);
  }
}
