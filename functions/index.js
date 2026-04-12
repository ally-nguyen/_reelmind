// ── functions/index.js ───────────────────────────────────────────────────────
//
// Firebase Cloud Function: callClaude
//
// SECURITY DESIGN
// ───────────────
// • The Anthropic API key lives ONLY in Firebase Secret Manager (set once via
//   `firebase functions:secrets:set ANTHROPIC_API_KEY`).  It is never in the
//   client binary, git history, or any config file.
//
// • Every call must carry a valid Firebase Auth ID token.  The function
//   verifies it before touching the Anthropic API (OWASP A01 / A07).
//
// • Server-side per-user rate limiting is enforced in Firestore so it
//   survives app restarts and works across devices (OWASP A04).
//
// • All user-supplied text fields are capped at the same limits used in the
//   Flutter client — defence in depth (OWASP A03).
//
// • The function only accepts the structured payload it expects.  Unexpected
//   fields are silently ignored (no pass-through of arbitrary data to Anthropic).
// ────────────────────────────────────────────────────────────────────────────

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { defineSecret } = require("firebase-functions/params");
const admin = require("firebase-admin");
const Anthropic = require("@anthropic-ai/sdk");

admin.initializeApp();

// The API key is resolved from Secret Manager at runtime — never hard-coded.
const anthropicApiKey = defineSecret("ANTHROPIC_API_KEY");

// ── Constants (must stay in sync with lib/utils/input_validator.dart) ────────

const LIMITS = {
  maxCaptionLength: 220,
  maxCaptionCount: 6,
  maxTopicLength: 40,
  maxTopicCount: 12,
  maxCreatorNameLength: 100,
  maxCreatorStyleLength: 120,
  maxCreatorCount: 8,
  maxExtraDirectionLength: 200,
  maxExistingSummaryLength: 140,
  maxExistingSummaryCount: 12,
  maxPromptLength: 32000, // hard cap on the assembled prompt before sending
};

// ── Rate limiting ─────────────────────────────────────────────────────────────
// 10 Claude API calls per user per hour — tracked in Firestore so it persists
// across sessions and devices (unlike the client-side limiter).

const RATE_LIMIT_MAX = 10;
const RATE_LIMIT_WINDOW_MS = 60 * 60 * 1000; // 1 hour

/**
 * Returns true if the call is allowed, false if the user is over limit.
 * Writes a new timestamp into users/{uid}/rateLimits.claudeApi.
 */
async function checkRateLimit(uid) {
  const db = admin.firestore();
  const ref = db.collection("users").doc(uid);

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data() || {};
    const now = Date.now();
    const cutoff = now - RATE_LIMIT_WINDOW_MS;

    // Prune timestamps outside the sliding window.
    const timestamps = ((data.rateLimits || {}).claudeApi || []).filter(
      (t) => t > cutoff
    );

    if (timestamps.length >= RATE_LIMIT_MAX) {
      return false; // over limit
    }

    timestamps.push(now);
    tx.set(
      ref,
      { rateLimits: { claudeApi: timestamps } },
      { merge: true }
    );
    return true;
  });
}

// ── Input sanitisation ────────────────────────────────────────────────────────

/** Strip null bytes and ASCII control characters (except HT, LF, CR). */
function sanitize(str) {
  if (typeof str !== "string") return "";
  return str
    .replace(/\x00/g, "")
    .replace(/[\x01-\x08\x0B\x0C\x0E-\x1F\x7F]/g, "");
}

function sanitizeTruncate(str, maxLen) {
  const s = sanitize(str).trim();
  return s.length > maxLen ? s.slice(0, maxLen) : s;
}

/** Validate and normalise the incoming payload. Throws HttpsError on bad input. */
function validatePayload(data) {
  if (!data || typeof data !== "object") {
    throw new HttpsError("invalid-argument", "Missing payload.");
  }

  const captions = (Array.isArray(data.captions) ? data.captions : [])
    .slice(0, LIMITS.maxCaptionCount)
    .map((c) => sanitizeTruncate(String(c), LIMITS.maxCaptionLength))
    .filter((c) => c.length > 0);

  const topics = (Array.isArray(data.topics) ? data.topics : [])
    .slice(0, LIMITS.maxTopicCount)
    .map((t) => sanitizeTruncate(String(t), LIMITS.maxTopicLength))
    .filter((t) => t.length > 0);

  const creators = (Array.isArray(data.creators) ? data.creators : [])
    .slice(0, LIMITS.maxCreatorCount)
    .map((c) => {
      if (typeof c === "string") {
        return { name: sanitizeTruncate(c, LIMITS.maxCreatorNameLength), style: "" };
      }
      if (typeof c === "object" && c !== null) {
        return {
          name: sanitizeTruncate(String(c.name || ""), LIMITS.maxCreatorNameLength),
          style: sanitizeTruncate(String(c.style || ""), LIMITS.maxCreatorStyleLength),
        };
      }
      return null;
    })
    .filter((c) => c && c.name.length > 0);

  const existingSummaries = (
    Array.isArray(data.existingSummaries) ? data.existingSummaries : []
  )
    .slice(0, LIMITS.maxExistingSummaryCount)
    .map((s) => sanitizeTruncate(String(s), LIMITS.maxExistingSummaryLength));

  const extraDirection =
    typeof data.extraDirection === "string"
      ? sanitizeTruncate(data.extraDirection, LIMITS.maxExtraDirectionLength)
      : null;

  // mode controls which prompt template to use
  const validModes = ["generateFromSignals", "generateAvoidingExisting", "assistScript"];
  const mode = validModes.includes(data.mode) ? data.mode : "generateAvoidingExisting";

  const title =
    typeof data.title === "string"
      ? sanitizeTruncate(data.title, 200)
      : "";

  const currentScript =
    typeof data.currentScript === "string"
      ? sanitizeTruncate(data.currentScript, 10000)
      : "";

  return { captions, topics, creators, existingSummaries, extraDirection, mode, title, currentScript };
}

// ── Prompt builders ───────────────────────────────────────────────────────────

function buildCreatorLines(creators) {
  return creators
    .map((c) => (c.style ? `- ${c.name}: ${c.style}` : `- ${c.name}`))
    .join("\n");
}

function buildSignalsParts({ captions, topics, creators, extraDirection }) {
  const parts = [];
  if (captions.length > 0) {
    parts.push(
      "VOICE SAMPLES — real captions written by this creator. Study their sentence rhythm, vocabulary, phrasing habits, and emotional tone. The script bullets must sound like this person, not like a generic AI:\n" +
        captions.map((c) => `- ${c}`).join("\n")
    );
  }
  if (topics.length > 0) {
    parts.push(`Topics they create content around: ${topics.join(", ")}`);
  }
  if (creators.length > 0) {
    parts.push(
      "Creators they follow for inspiration:\n" + buildCreatorLines(creators)
    );
  }
  if (extraDirection) {
    parts.push(`Additional direction from the creator: ${extraDirection}`);
  }
  return parts;
}

function promptGenerateIdea(parts, avoidSection) {
  return `You are a content strategy AI helping a short-form video creator develop their next short-form video idea.

${parts.join("\n\n")}
${avoidSection}

Using the signals above, generate ONE compelling video idea. Follow these rules strictly:

1. NO OVERLAP — Cross-check your idea against every entry in the avoid list before finalising. If your title, format, opening hook, or core message resembles any of them — even from a different angle — reject it and start over with a genuinely different concept.

2. CONTENT FORMAT — Rotate through: Day in the life, Storytime, Hot take, Behind the scenes, Tutorial, "Things I wish I knew", Reaction, Routine breakdown, Challenge, Q&A or myth-busting.

3. ANGLE — Even if the topic overlaps with an existing idea, the angle must be fresh.

4. CREATOR INSPIRATION — If creators are listed with style descriptions, use those directly.

5. SCRIPT BULLETS — Write 5-6 bullet points that sound like natural spoken lines. Conversational, varied in structure.

6. VOICE — If voice samples are provided, mirror the creator's sentence rhythm, vocabulary, and phrasing. Do not write in a generic AI voice.

7. AUTHENTICITY — Specific and personal to this creator.

Return ONLY valid JSON — no markdown, no explanation:
{
  "title": "a compelling, specific video title",
  "script": "• bullet one\\n• bullet two\\n• bullet three\\n• bullet four\\n• bullet five"
}`;
}

function promptAssistScript({ title, currentScript, captions, topics, creators }) {
  const contextParts = [];
  if (topics.length > 0) contextParts.push(`Creator topics: ${topics.join(", ")}`);
  if (creators.length > 0) {
    contextParts.push("Creator inspirations:\n" + buildCreatorLines(creators));
  }
  if (captions.length > 0) {
    contextParts.push(
      "VOICE SAMPLES — match rhythm, vocabulary, and emotional tone:\n" +
        captions.slice(0, 3).map((c) => `- ${c}`).join("\n")
    );
  }

  const hasScript = currentScript.trim().length > 0;
  const scriptSection = hasScript
    ? `Existing bullets:\n${currentScript}\n\nAdd 2-3 more that elaborate or continue. Do NOT repeat anything already written.`
    : "No bullets written yet. Generate 5-6.";

  const contextSection =
    contextParts.length > 0
      ? "\n\nCreator context:\n" + contextParts.join("\n")
      : "";

  return `You are helping a content creator write natural, spoken bullet points for a short-form video.

Video title: "${title}"
${scriptSection}${contextSection}

Rules:
- Match the title's format and tone
- If voice samples are provided, match their rhythm and vocabulary exactly
- Each bullet = one spoken thought, not a paragraph
- Vary sentence structure
- Return ONLY the bullet points, each starting with "• ". No title, no explanation.`;
}

// ── Main callable function ────────────────────────────────────────────────────

exports.callClaude = onCall(
  {
    secrets: [anthropicApiKey],
    // Require a verified Firebase App Check token in production to prevent
    // abuse from clients that are not your app.
    // enforceAppCheck: true,  // uncomment when App Check is configured
    timeoutSeconds: 60,
    memory: "256MiB",
    region: "us-central1",
  },
  async (request) => {
    // ── 1. Authentication check ─────────────────────────────────────────────
    // auth is null for unauthenticated callers.
    if (!request.auth) {
      throw new HttpsError(
        "unauthenticated",
        "You must be signed in to use this feature."
      );
    }
    const uid = request.auth.uid;

    // ── 2. Server-side rate limit ────────────────────────────────────────────
    const allowed = await checkRateLimit(uid);
    if (!allowed) {
      throw new HttpsError(
        "resource-exhausted",
        "Rate limit exceeded. You can generate up to 10 ideas per hour. Please try again later."
      );
    }

    // ── 3. Validate and sanitise the payload ─────────────────────────────────
    const {
      captions,
      topics,
      creators,
      existingSummaries,
      extraDirection,
      mode,
      title,
      currentScript,
    } = validatePayload(request.data);

    // ── 4. Build the prompt ──────────────────────────────────────────────────
    let userMessage;

    if (mode === "assistScript") {
      userMessage = promptAssistScript({ title, currentScript, captions, topics, creators });
    } else {
      const parts = buildSignalsParts({ captions, topics, creators, extraDirection });
      if (parts.length === 0) {
        throw new HttpsError("invalid-argument", "No signals provided.");
      }

      const avoidSection =
        existingSummaries.length > 0
          ? "\n\nIDEAS TO AVOID — do NOT generate anything that shares the format, topic angle, or key message of these:\n" +
            existingSummaries.map((s) => `- ${s}`).join("\n")
          : "";

      userMessage = promptGenerateIdea(parts, avoidSection);
    }

    // Hard cap on assembled prompt length — prevents unbounded API spend.
    if (userMessage.length > LIMITS.maxPromptLength) {
      throw new HttpsError("invalid-argument", "Prompt exceeds maximum length.");
    }

    // ── 5. Call Anthropic (key from Secret Manager) ───────────────────────────
    const client = new Anthropic.default({ apiKey: anthropicApiKey.value() });

    const response = await client.messages.create({
      model: "claude-sonnet-4-6",
      max_tokens: 1024,
      messages: [{ role: "user", content: userMessage }],
    });

    const text = response.content[0].text;

    // For assistScript mode return raw text; for idea modes return parsed JSON.
    if (mode === "assistScript") {
      return { text };
    }

    // Strip accidental markdown fences before parsing.
    const cleaned = text.replace(/```json/g, "").replace(/```/g, "").trim();
    try {
      const parsed = JSON.parse(cleaned);
      return { title: String(parsed.title), script: String(parsed.script) };
    } catch {
      throw new HttpsError("internal", "Failed to parse AI response.");
    }
  }
);
