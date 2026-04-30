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
  maxPostedIdeaTitleLength: 160,
  maxPostedIdeaScriptLength: 500,
  maxPostedIdeaCount: 20,
  maxPromptLength: 32000, // hard cap on the assembled prompt before sending
};

// ── Rate limiting ─────────────────────────────────────────────────────────────
// Two independent sliding-window buckets, mirroring the client-side split:
//   claudeApi  — idea generation (generateFromSignals, generateAvoidingExisting)
//   adviceApi  — advice + script assist (getAIAdvice, getTryNextInsight, assistScript)
// Tracked in Firestore so limits persist across sessions and devices.

const RATE_LIMITS = {
  claudeApi: { max: 10, windowMs: 60 * 60 * 1000 },
  adviceApi: { max: 20, windowMs: 60 * 60 * 1000 },
};

function bucketForMode(mode) {
  return mode === "getAIAdvice" ||
    mode === "assistScript" ||
    mode === "getTryNextInsight"
    ? "adviceApi"
    : "claudeApi";
}

/**
 * Returns true if the call is allowed, false if the user is over limit.
 * Writes a new timestamp into users/{uid}/rateLimits.<bucket>.
 */
async function checkRateLimit(uid, bucket) {
  const { max, windowMs } = RATE_LIMITS[bucket];
  const db = admin.firestore();
  const ref = db.collection("users").doc(uid);

  return db.runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const data = snap.data() || {};
    const now = Date.now();
    const cutoff = now - windowMs;

    // Prune timestamps outside the sliding window.
    const timestamps = ((data.rateLimits || {})[bucket] || []).filter(
      (t) => t > cutoff
    );

    if (timestamps.length >= max) {
      return false; // over limit
    }

    timestamps.push(now);
    tx.set(
      ref,
      { rateLimits: { [bucket]: timestamps } },
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

  const aiAdvice =
    typeof data.aiAdvice === "string"
      ? sanitizeTruncate(data.aiAdvice, 600)
      : null;

  const previousAdvice = (Array.isArray(data.previousAdvice) ? data.previousAdvice : [])
    .slice(0, 8)
    .map((a) => sanitizeTruncate(String(a), 300))
    .filter((a) => a.length > 0);

  const uncoveredTopics = (Array.isArray(data.uncoveredTopics) ? data.uncoveredTopics : [])
    .slice(0, 15)
    .map((t) => sanitizeTruncate(String(t), LIMITS.maxTopicLength))
    .filter((t) => t.length > 0);

  const postedIdeas = (Array.isArray(data.postedIdeas) ? data.postedIdeas : [])
    .slice(0, LIMITS.maxPostedIdeaCount)
    .map((idea) => {
      if (!idea || typeof idea !== "object") return null;
      const tags = (Array.isArray(idea.tags) ? idea.tags : [])
        .slice(0, 8)
        .map((t) => sanitizeTruncate(String(t), LIMITS.maxTopicLength))
        .filter((t) => t.length > 0);
      return {
        id: sanitizeTruncate(String(idea.id || ""), 80),
        title: sanitizeTruncate(String(idea.title || ""), LIMITS.maxPostedIdeaTitleLength),
        script: sanitizeTruncate(String(idea.script || ""), LIMITS.maxPostedIdeaScriptLength),
        tags,
      };
    })
    .filter((idea) => idea && idea.id.length > 0);

  const sourceSignature =
    typeof data.sourceSignature === "string"
      ? sanitizeTruncate(data.sourceSignature, 80)
      : "";

  // mode controls which prompt template to use
  const validModes = [
    "generateFromSignals",
    "generateAvoidingExisting",
    "assistScript",
    "getAIAdvice",
    "getTryNextInsight",
  ];
  const mode = validModes.includes(data.mode) ? data.mode : "generateAvoidingExisting";

  const title =
    typeof data.title === "string"
      ? sanitizeTruncate(data.title, 200)
      : "";

  const currentScript =
    typeof data.currentScript === "string"
      ? sanitizeTruncate(data.currentScript, 10000)
      : "";

  return {
    captions,
    topics,
    creators,
    existingSummaries,
    extraDirection,
    aiAdvice,
    previousAdvice,
    uncoveredTopics,
    postedIdeas,
    sourceSignature,
    mode,
    title,
    currentScript,
  };
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

function promptGenerateIdea(parts, avoidSection, aiAdvice) {
  const guidanceSection = aiAdvice
    ? `\n\nCREATOR INSIGHTS FOR THIS GENERATION — apply this as a creative direction rule, not as criticism of prior ideas:\n${aiAdvice}`
    : "";

  return `You are a content strategy AI helping a short-form video creator develop their next short-form video idea.

${parts.join("\n\n")}
${avoidSection}${guidanceSection}

Using the signals above, generate ONE compelling video idea. Follow these rules strictly:

1. NO OVERLAP — Cross-check your idea against every entry in the avoid list before finalising. If your title, format, opening hook, or core message resembles any of them — even from a different angle — reject it and start over with a genuinely different concept.

2. CONTENT FORMAT — Rotate through: Day in the life, Storytime, Hot take, Behind the scenes, Tutorial, "Things I wish I knew", Reaction, Routine breakdown, Challenge, Q&A or myth-busting.

3. ANGLE — Even if the topic overlaps with an existing idea, the angle must be fresh.

4. CREATOR INSPIRATION — If creators are listed with style descriptions, use those directly.

5. SCRIPT BULLETS — Write 5-6 bullet points that sound like natural spoken lines. Conversational, varied in structure.

6. VOICE — If voice samples are provided, mirror the creator's sentence rhythm, vocabulary, and phrasing. Do not write in a generic AI voice.

7. AUTHENTICITY — Specific and personal to this creator.

8. CREATOR INSIGHTS — If generation guidance is provided above, apply it to keep the next idea fresh, varied, and aligned with the creator's style.

Return ONLY valid JSON — no markdown, no explanation:
{
  "title": "a compelling, specific video title",
  "script": "• bullet one\\n• bullet two\\n• bullet three\\n• bullet four\\n• bullet five"
}`;
}

function promptGetAIAdvice({ ideaSummaries, topics, captions, previousAdvice, uncoveredTopics }) {
  const topicsLine = topics.length > 0 ? `Topics they create content around: ${topics.join(", ")}` : "";
  const captionsLine = captions.length > 0
    ? "Voice samples:\n" + captions.slice(0, 3).map((c) => `- ${c}`).join("\n")
    : "";
  const ideasSection = ideaSummaries.length > 0
    ? "Their recent ideas (title [status: script preview]):\n" + ideaSummaries.map((s) => `- ${s}`).join("\n")
    : "They have no ideas yet.";
  const previousSection = previousAdvice && previousAdvice.length > 0
    ? "\nPREVIOUS ADVICE ALREADY GIVEN — do NOT repeat any topic, angle, or suggestion from any of these:\n" +
      previousAdvice.map((a, i) => `[${i + 1}] ${a}`).join("\n")
    : "";

  const hasUncovered = uncoveredTopics && uncoveredTopics.length > 0;
  const contentGapInstruction = hasUncovered
    ? `Content gap: The creator has ${uncoveredTopics.length} topic(s) from their signals list with no content drafted yet: ${uncoveredTopics.join(", ")}. Write one sentence telling them to create at least one Draft idea for each of these topics before looking for new content gaps.`
    : `Content gap: Identify one topic or angle completely absent from ALL their ideas listed above AND from their topics list. This must be a genuinely new direction. Cross-check every idea title, script preview, and existing topic before suggesting. Has not been suggested in any previous advice above.`;

  return `You are a content strategy advisor for a short-form video creator. Analyse their content pipeline and give them three specific, actionable pieces of advice.

${topicsLine}
${captionsLine}
${ideasSection}
${previousSection}
Return exactly three pieces of advice in plain text using this format — no bullet points, no markdown, no preamble:

Next topic: [one sentence recommending the single best topic they should cover next and why it fits their niche. Must be a topic NOT already in their ideas list and NOT previously suggested above.]
Script tip: [one sentence identifying the most impactful improvement they could make to their current scripts or drafts. Must be a different angle from any script tips previously given above.]
${contentGapInstruction}

Be specific, not generic. Reference their actual topics and pipeline where possible.`;
}

function promptGetTryNextInsight({ postedIdeas, topics, captions, sourceSignature }) {
  const topicList = topics.join(", ");
  const captionsLine = captions.length > 0
    ? "Voice samples:\n" + captions.slice(0, 3).map((c) => `- ${c}`).join("\n")
    : "";
  const postedSection = postedIdeas
    .map((idea) => {
      const tagText = idea.tags.length > 0 ? idea.tags.join(", ") : "none selected";
      return `- id: ${idea.id}\n  title: ${idea.title}\n  saved topic tags: ${tagText}\n  script: ${idea.script}`;
    })
    .join("\n");

  return `You are a content strategy AI for a short-form video creator.

Saved topics you are allowed to use: ${topicList}
${captionsLine}

Posted scripts to analyze:
${postedSection}

Task:
1. For each posted script with no saved topic tag, infer exactly one topic from the allowed saved topics. Do not invent topics.
2. Count posted topic frequency using saved tags plus your inferred tags. If a script has multiple saved topic tags, count all of them.
3. Choose the anchor topic with the highest final frequency.
4. Create exactly 4 clickable directions:
   - one same-topic hook under the anchor topic.
   - three bridge hooks that connect a different saved topic to the anchor topic.
   - if there are fewer than 2 saved topics, create one same-topic hook plus three fallback angle hooks under the anchor topic.

Return ONLY valid JSON, no markdown:
{
  "sourceSignature": "${sourceSignature}",
  "pattern": "one specific sentence about what their posted scripts show",
  "anchorTopic": "one allowed saved topic",
  "topicCounts": { "Allowed Topic": 2 },
  "inferredTags": [
    { "ideaId": "posted idea id", "topic": "one allowed saved topic", "confidence": 0.82 }
  ],
  "hooks": [
    {
      "type": "sameTopic",
      "label": "short action label",
      "hook": "short hook the user could open with",
      "targetTopic": "allowed saved topic the new idea should be tagged with",
      "bridgeTopic": "",
      "reason": "short reason this direction helps",
      "generationDirection": "instruction for generating one new idea from this hook"
    }
  ]
}

Rules:
- Use only the exact allowed saved topic strings.
- generationDirection must include the hook and target topic.
- Hooks should be specific, not generic templates.
- Do not criticize the creator; frame this as a next move.`;
}

function normalizeTryNextResponse(parsed, { topics, postedIdeas, sourceSignature }) {
  const topicSet = new Set(topics);
  const postedIds = new Set(postedIdeas.map((idea) => idea.id));

  const rawCounts = parsed && typeof parsed.topicCounts === "object" && !Array.isArray(parsed.topicCounts)
    ? parsed.topicCounts
    : {};
  const topicCounts = {};
  topics.forEach((topic) => {
    const n = Number(rawCounts[topic] || 0);
    topicCounts[topic] = Number.isFinite(n) && n > 0 ? Math.min(Math.round(n), 999) : 0;
  });

  const inferredTags = (Array.isArray(parsed?.inferredTags) ? parsed.inferredTags : [])
    .slice(0, LIMITS.maxPostedIdeaCount)
    .map((tag) => ({
      ideaId: sanitizeTruncate(String(tag?.ideaId || ""), 80),
      topic: sanitizeTruncate(String(tag?.topic || ""), LIMITS.maxTopicLength),
      confidence: Number(tag?.confidence || 0),
    }))
    .filter((tag) => postedIds.has(tag.ideaId) && topicSet.has(tag.topic))
    .map((tag) => ({
      ...tag,
      confidence: Math.max(0, Math.min(1, tag.confidence)),
    }));

  const hooks = (Array.isArray(parsed?.hooks) ? parsed.hooks : [])
    .slice(0, 4)
    .map((hook) => {
      const targetTopic = sanitizeTruncate(String(hook?.targetTopic || ""), LIMITS.maxTopicLength);
      const bridgeTopic = sanitizeTruncate(String(hook?.bridgeTopic || ""), LIMITS.maxTopicLength);
      return {
        type: sanitizeTruncate(String(hook?.type || ""), 30),
        label: sanitizeTruncate(String(hook?.label || ""), 80),
        hook: sanitizeTruncate(String(hook?.hook || ""), 160),
        targetTopic,
        bridgeTopic,
        reason: sanitizeTruncate(String(hook?.reason || ""), 160),
        generationDirection: sanitizeTruncate(
          String(hook?.generationDirection || ""),
          LIMITS.maxExtraDirectionLength
        ),
      };
    })
    .filter((hook) =>
      hook.label &&
      hook.hook &&
      hook.generationDirection &&
      topicSet.has(hook.targetTopic) &&
      (!hook.bridgeTopic || topicSet.has(hook.bridgeTopic))
    );

  const anchorTopic = topicSet.has(parsed?.anchorTopic) ? parsed.anchorTopic : (topics[0] || "");

  return {
    sourceSignature,
    pattern: sanitizeTruncate(String(parsed?.pattern || ""), 220),
    anchorTopic,
    topicCounts,
    inferredTags,
    hooks,
  };
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

    // ── 2. Validate and sanitise the payload ────────────────────────────────
    const {
      captions,
      topics,
      creators,
      existingSummaries,
      extraDirection,
      aiAdvice,
      previousAdvice,
      uncoveredTopics,
      postedIdeas,
      sourceSignature,
      mode,
      title,
      currentScript,
    } = validatePayload(request.data);

    // ── 3. Server-side rate limit (per bucket) ───────────────────────────────
    const bucket = bucketForMode(mode);
    const allowed = await checkRateLimit(uid, bucket);
    if (!allowed) {
      const isIdea = bucket === "claudeApi";
      throw new HttpsError(
        "resource-exhausted",
        isIdea
          ? "Generation limit reached. You can generate up to 10 ideas per hour. Please try again later."
          : "Advice limit reached. Please try again later."
      );
    }

    // ── 4. Build the prompt ─────────────────────────────────────────────────
    let userMessage;

    if (mode === "assistScript") {
      userMessage = promptAssistScript({
        title,
        currentScript,
        captions,
        topics,
        creators,
      });
    } else if (mode === "getAIAdvice") {
      userMessage = promptGetAIAdvice({
        ideaSummaries: existingSummaries,
        topics,
        captions,
        previousAdvice,
        uncoveredTopics,
      });
    } else if (mode === "getTryNextInsight") {
      if (topics.length === 0 || postedIdeas.length === 0) {
        throw new HttpsError("invalid-argument", "Topics and posted ideas are required.");
      }
      userMessage = promptGetTryNextInsight({
        postedIdeas,
        topics,
        captions,
        sourceSignature,
      });
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

      userMessage = promptGenerateIdea(
        parts,
        avoidSection,
        aiAdvice,
      );
    }

    // Hard cap on assembled prompt length — prevents unbounded API spend.
    if (userMessage.length > LIMITS.maxPromptLength) {
      throw new HttpsError("invalid-argument", "Prompt exceeds maximum length.");
    }

    // ── 5. Call Anthropic (key from Secret Manager) ───────────────────────────
    const client = new Anthropic.default({ apiKey: anthropicApiKey.value() });

    let response;
    try {
      response = await client.messages.create({
        model: "claude-sonnet-4-6",
        max_tokens: 1024,
        messages: [{ role: "user", content: userMessage }],
      });
    } catch (e) {
      // Anthropic 429 → surface as resource-exhausted so client shows the
      // correct rate-limit message instead of a generic connection error.
      if (e?.status === 429) {
        throw new HttpsError(
          "resource-exhausted",
          "AI service rate limit reached. Please try again later."
        );
      }
      throw new HttpsError(
        "internal",
        "Failed to reach AI service. Please try again."
      );
    }

    const text = response.content[0].text;

    // For assistScript and getAIAdvice modes return raw text; for JSON modes parse below.
    if (mode === "assistScript" || mode === "getAIAdvice") {
      return { text };
    }

    // Strip accidental markdown fences before parsing.
    const cleaned = text.replace(/```json/g, "").replace(/```/g, "").trim();
    try {
      const parsed = JSON.parse(cleaned);
      if (mode === "getTryNextInsight") {
        return normalizeTryNextResponse(parsed, {
          topics,
          postedIdeas,
          sourceSignature,
        });
      }
      return { title: String(parsed.title), script: String(parsed.script) };
    } catch {
      throw new HttpsError("internal", "Failed to parse AI response.");
    }
  }
);
