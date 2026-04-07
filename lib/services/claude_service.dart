import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/idea_model.dart';

class ClaudeService {
  static String get _apiKey => dotenv.env['ANTHROPIC_API_KEY'] ?? '';
  static const _endpoint = 'https://api.anthropic.com/v1/messages';
  static const _model = 'claude-sonnet-4-6';

  // ── Generate idea from import signals ────────────────────────────────────

  static Future<IdeaModel?> generateIdeaFromSignals({
    required List<String> captions,
    required List<String> topics,
    required List<String> creators,
  }) async {
    final parts = <String>[];

    final caps = captions.where((c) => c.trim().isNotEmpty).toList();
    if (caps.isNotEmpty) {
      parts.add(
          'VOICE SAMPLES — real captions written by this creator. Study their sentence rhythm, vocabulary, phrasing habits, and emotional tone. The script bullets must sound like this person, not like a generic AI:\n'
          '${caps.map((c) => '- $c').join('\n')}');
    }

    if (topics.isNotEmpty) {
      parts.add('Topics they create content around: ${topics.join(', ')}');
    }

    if (creators.isNotEmpty) {
      parts.add(
          'Creators they follow for inspiration: ${creators.join(', ')}');
    }

    if (parts.isEmpty) return null;

    final prompt = '''You are a content strategy AI helping a short-form video creator develop their next short-form video idea.

${parts.join('\n\n')}

Using the signals above, generate ONE compelling video idea. Follow these rules strictly:

1. CONTENT FORMAT — Choose whichever format fits the signals best. Do NOT default to finance or tips unless the signals clearly point there. Formats to consider:
   - Day in the life / vlog-style
   - Storytime or personal experience
   - Hot take or opinion
   - Behind the scenes
   - Tutorial or how-to
   - "Things I wish I knew" reflection
   - Reaction or response to a trend
   - Routine or habit breakdown

2. CREATOR INSPIRATION — If creators are listed, mirror the style, pacing, and tone those creators are known for.

3. SCRIPT BULLETS — Write 5-6 bullet points that sound like natural spoken lines for short-form video. Each bullet must vary in structure and feel conversational, not like a listicle.

4. VOICE — If voice samples are provided, each script bullet must reflect the creator's actual sentence rhythm, vocabulary, and phrasing. Do not write in a polished or generic AI voice. Write the way those captions sound.

5. AUTHENTICITY — The idea should feel specific and personal to this creator, not generic.

Return ONLY valid JSON — no markdown, no explanation:
{
  "title": "a compelling, specific video title that matches the chosen format",
  "script": "• natural spoken bullet one\\n• natural spoken bullet two\\n• natural spoken bullet three\\n• natural spoken bullet four\\n• natural spoken bullet five"
}''';

    final raw = await _call(prompt);
    if (raw == null) return null;
    return _parseIdea(raw);
  }

  // ── Generate idea avoiding existing titles ───────────────────────────────

  static Future<IdeaModel?> generateIdeaAvoidingExisting({
    required Map<String, dynamic> signals,
    required List<String> existingSummaries,
    String? extraDirection,
  }) async {
    final captions = List<String>.from(signals['captions'] ?? []);
    final topics = List<String>.from(signals['topics'] ?? []);
    final rawCreators = List<dynamic>.from(signals['creators'] ?? []);

    final parts = <String>[];
    if (captions.isNotEmpty) {
      parts.add(
          'VOICE SAMPLES — real captions written by this creator. Study their sentence rhythm, vocabulary, phrasing habits, and emotional tone. The script bullets must sound like this person, not like a generic AI:\n'
          '${captions.map((c) => '- $c').join('\n')}');
    }
    if (topics.isNotEmpty) {
      parts.add('Topics they create content around: ${topics.join(', ')}');
    }
    if (rawCreators.isNotEmpty) {
      parts.add('Creators they follow for inspiration:\n${_buildCreatorLines(rawCreators)}');
    }
    if (extraDirection != null && extraDirection.trim().isNotEmpty) {
      parts.add('Additional direction from the creator: ${extraDirection.trim()}');
    }
    if (parts.isEmpty) return null;

    final avoidSection = existingSummaries.isNotEmpty
        ? '\n\nIDEAS TO AVOID — the creator already has every one of these. Do NOT generate an idea that shares the same format, topic angle, opening emotion, key message, or talking-point structure as any entry below. Each entry shows "title — first talking point" so you can see the exact angle used:\n${existingSummaries.map((s) => '- $s').join('\n')}\n\nIf you find yourself writing something that resembles any entry above — even loosely — stop and choose a completely different format, angle, and emotional entry point.'
        : '';

    final prompt =
        '''You are a content strategy AI helping a short-form video creator develop their next short-form video idea.

${parts.join('\n\n')}
$avoidSection

Using the signals above, generate ONE compelling video idea. Follow these rules strictly:

1. NO OVERLAP — Cross-check your idea against every entry in the avoid list before finalising. If your title, format, opening hook, or core message resembles any of them — even from a different angle — reject it and start over with a genuinely different concept.

2. CONTENT FORMAT — Look at the formats already used in the avoid list and deliberately choose a DIFFERENT one. Rotate through:
   - Day in the life / vlog-style
   - Storytime or personal experience
   - Hot take or unpopular opinion
   - Behind the scenes
   - Tutorial or how-to
   - "Things I wish I knew" reflection
   - Reaction or response to a trend
   - Routine or habit breakdown
   - Challenge or experiment
   - Q&A or myth-busting

3. ANGLE — Even if the topic overlaps with an existing idea, the angle must be fresh: a different perspective, emotion, audience, or moment in time.

4. CREATOR INSPIRATION — If creators are listed with style descriptions, use those descriptions directly to shape tone, pacing, and hook structure.

5. SCRIPT BULLETS — Write 5-6 bullet points that sound like natural spoken lines for short-form video. Conversational, varied in structure, not a listicle.

6. VOICE — If voice samples are provided, each script bullet must mirror the creator's actual sentence rhythm, vocabulary, and phrasing from those samples. Do not write in a polished or generic AI voice — write the way those captions sound.

7. AUTHENTICITY — Specific and personal to this creator. Avoid generic hooks like "Here are X tips" unless the signals strongly call for it.

Return ONLY valid JSON — no markdown, no explanation:
{
  "title": "a compelling, specific video title that matches the chosen format",
  "script": "• natural spoken bullet one\\n• natural spoken bullet two\\n• natural spoken bullet three\\n• natural spoken bullet four\\n• natural spoken bullet five"
}''';

    final raw = await _call(prompt);
    if (raw == null) return null;
    return _parseIdea(raw);
  }

  // ── AI assist — elaborate on existing title and script ───────────────────

  static Future<String?> assistWithScript({
    required String title,
    required String currentScript,
    Map<String, dynamic>? signals,
  }) async {
    final captions =
        List<String>.from(signals?['captions'] ?? []);
    final topics = List<String>.from(signals?['topics'] ?? []);
    final rawCreators =
        List<dynamic>.from(signals?['creators'] ?? []);

    final contextParts = <String>[];
    if (topics.isNotEmpty) {
      contextParts.add('Creator topics: ${topics.join(', ')}');
    }
    if (rawCreators.isNotEmpty) {
      contextParts.add(
          'Creator inspirations:\n${_buildCreatorLines(rawCreators)}');
    }
    if (captions.isNotEmpty) {
      contextParts.add(
          'VOICE SAMPLES — real captions written by this creator. Every bullet you write must match their sentence rhythm, vocabulary, phrasing habits, and emotional tone. Do not default to generic AI phrasing:\n${captions.take(3).map((c) => '- $c').join('\n')}');
    }

    final hasScript = currentScript.trim().isNotEmpty;
    final scriptSection = hasScript
        ? 'Existing bullet points already written:\n$currentScript\n\nAdd 2-3 more bullet points that elaborate on or continue from the existing ones. Do NOT repeat anything already written.'
        : 'No bullet points written yet. Generate 5-6 bullet points for this title.';

    final contextSection = contextParts.isNotEmpty
        ? '\n\nCreator background context:\n${contextParts.join('\n')}'
        : '';

    final prompt =
        '''You are helping a content creator write natural, spoken bullet points for a short-form video.

Video title: "$title"
$scriptSection$contextSection

Rules:
- Read the title carefully and match its format (storytime, day-in-life, opinion, tutorial, etc.)
- If voice samples are provided above, write bullets that sound like those captions — same rhythm, same vocabulary level, same emotional register. Do not ignore them.
- Write bullets that sound like something the creator would actually say out loud, not a blog post or listicle
- Keep each bullet concise — one spoken thought, not a paragraph
- Vary the sentence structure; don't start every bullet the same way
- Do NOT default to finance or generic productivity tips unless the title clearly calls for it
- Match the energy and tone the title implies (casual, reflective, hype, etc.)

Return ONLY the bullet points, one per line, each starting with "• ". No title, no explanation, no JSON — just the bullet points.''';

    return _call(prompt);
  }

  // ── Generate idea from previously saved Firestore signals ────────────────

  static Future<IdeaModel?> generateIdeaWithSavedSignals({
    required Map<String, dynamic> signals,
    String? extraDirection,
  }) async {
    final captions = List<String>.from(signals['captions'] ?? []);
    final topics = List<String>.from(signals['topics'] ?? []);
    final rawCreators = List<dynamic>.from(signals['creators'] ?? []);

    final parts = <String>[];
    if (captions.isNotEmpty) {
      parts.add(
          'VOICE SAMPLES — real captions written by this creator. Study their sentence rhythm, vocabulary, phrasing habits, and emotional tone. The script bullets must sound like this person, not like a generic AI:\n'
          '${captions.map((c) => '- $c').join('\n')}');
    }
    if (topics.isNotEmpty) {
      parts.add('Topics they create content around: ${topics.join(', ')}');
    }
    if (rawCreators.isNotEmpty) {
      parts.add('Creators they follow for inspiration:\n${_buildCreatorLines(rawCreators)}');
    }
    if (extraDirection != null && extraDirection.trim().isNotEmpty) {
      parts.add('Additional direction from the creator: ${extraDirection.trim()}');
    }
    if (parts.isEmpty) return null;

    final prompt = '''You are a content strategy AI helping a short-form video creator develop their next short-form video idea.

${parts.join('\n\n')}

Using the signals above, generate ONE compelling video idea. Follow these rules strictly:

1. CONTENT FORMAT — Choose whichever format fits the signals best. Do NOT default to finance or tips unless the signals clearly point there. Formats to consider:
   - Day in the life / vlog-style
   - Storytime or personal experience
   - Hot take or opinion
   - Behind the scenes
   - Tutorial or how-to
   - "Things I wish I knew" reflection
   - Reaction or response to a trend
   - Routine or habit breakdown

2. CREATOR INSPIRATION — If creators are listed, mirror the style, pacing, and tone those creators are known for.

3. SCRIPT BULLETS — Write 5-6 bullet points that sound like natural spoken lines for short-form video. Each bullet must vary in structure and feel conversational, not like a listicle.

4. VOICE — If voice samples are provided, each script bullet must reflect the creator's actual sentence rhythm, vocabulary, and phrasing. Do not write in a polished or generic AI voice. Write the way those captions sound.

5. AUTHENTICITY — The idea should feel specific and personal to this creator, not generic.

Return ONLY valid JSON — no markdown, no explanation:
{
  "title": "a compelling, specific video title that matches the chosen format",
  "script": "• natural spoken bullet one\\n• natural spoken bullet two\\n• natural spoken bullet three\\n• natural spoken bullet four\\n• natural spoken bullet five"
}''';

    final raw = await _call(prompt);
    if (raw == null) return null;
    return _parseIdea(raw);
  }

  // ── Predict best next move from existing drafted ideas ───────────────────

  static Future<String?> predictNextMove(List<IdeaModel> ideas) async {
    if (ideas.isEmpty) return null;

    final ideaList = ideas.take(10).map((i) {
      final preview = i.script.isNotEmpty
          ? i.script.substring(0, i.script.length.clamp(0, 120))
          : '';
      return '- "${i.title}" [${i.status}]${preview.isNotEmpty ? ': $preview...' : ''}';
    }).join('\n');

    final prompt =
        '''You are a content strategy AI helping a short-form video creator figure out their next move.

Here are the video ideas this creator has drafted so far:

$ideaList

Based on the patterns, topics, and gaps you notice, write a 2-3 sentence recommendation for their single best next content move. Be specific and actionable. Do not use bullet points or headers — flowing sentences only.''';

    return _call(prompt);
  }

  // ── Format creator list from signals (handles old string + new map format) ─

  static String _buildCreatorLines(List<dynamic> raw) {
    return raw.map((c) {
      if (c is String) return '- $c';
      if (c is Map) {
        final name = (c['name'] ?? '').toString().trim();
        final style = (c['style'] ?? '').toString().trim();
        if (name.isEmpty) return '';
        return style.isNotEmpty ? '- $name: $style' : '- $name';
      }
      return '- ${c.toString()}';
    }).where((s) => s.isNotEmpty).join('\n');
  }

  // ── Shared HTTP call ─────────────────────────────────────────────────────

  static Future<String?> _call(String userMessage) async {
    try {
      final res = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': _apiKey,
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': _model,
          'max_tokens': 1024,
          'messages': [
            {'role': 'user', 'content': userMessage},
          ],
        }),
      );
      if (res.statusCode != 200) return null;
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return (data['content'] as List).first['text'] as String;
    } catch (_) {
      return null;
    }
  }

  static IdeaModel? _parseIdea(String raw) {
    try {
      // Strip any accidental markdown code fences
      final cleaned =
          raw.replaceAll('```json', '').replaceAll('```', '').trim();
      final json = jsonDecode(cleaned) as Map<String, dynamic>;
      return IdeaModel(
        title: json['title'] as String,
        script: json['script'] as String,
        isAIGenerated: true,
      );
    } catch (_) {
      return null;
    }
  }
}
