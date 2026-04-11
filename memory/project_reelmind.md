---
name: Reel Mind project context
description: Flutter app using Firebase Auth + Firestore + Claude AI (Anthropic). Security hardening applied April 2026.
type: project
---

Flutter mobile app (iOS + Android) that helps short-form video creators generate content ideas using Claude AI.

Stack: Flutter/Dart, Firebase Auth, Cloud Firestore, Firebase Storage, Anthropic Claude API (claude-sonnet-4-6).

**Why:** CS 4750 school project.

**Security hardening applied (April 2026):**
- API key moved from bundled `.env` asset → `--dart-define=ANTHROPIC_API_KEY=...` at build time
- `flutter_dotenv` dependency removed; `dotenv.load()` removed from main.dart
- New `lib/services/rate_limiter.dart` — sliding-window limiter (5 logins/15min, 3 signups/hr, 10 Claude calls/hr, 3 resets/hr)
- New `lib/utils/input_validator.dart` — centralised email regex, password complexity, per-field length caps
- All user inputs in import_signals_screen, generator_screen, login, signup wired to validator
- Claude service now returns `ClaudeResult<T>` typed result with `rateLimitedLocally`, `rateLimitedByApi`, `networkError` error kinds
- 30-second HTTP timeout added to Claude API calls
- `.env.json.example` added; `.env.json` added to `.gitignore`

**How to apply:** Run app with: `flutter run --dart-define=ANTHROPIC_API_KEY=sk-ant-...`
Or build: `flutter build apk --dart-define=ANTHROPIC_API_KEY=sk-ant-...`

**Remaining ideal improvement (not done — requires backend):** Move Claude API calls to a Firebase Cloud Function proxy so the API key is never in the client binary at all.
