import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../models/idea_model.dart';
import '../services/claude_service.dart';
import '../services/firestore_service.dart';
import '../services/rate_limiter.dart';
import '../services/app_preferences.dart';
import '../utils/input_validator.dart';
import '../widgets/app_background.dart';
import '../widgets/app_tab_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/rm_chip.dart';
import 'workspace_screen.dart';

class GeneratorScreen extends StatefulWidget {
  final String? extraDirection;
  final List<String> initialTags;
  const GeneratorScreen({
    super.key,
    this.extraDirection,
    this.initialTags = const [],
  });

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  IdeaModel? _idea;
  bool _isLoading = true;
  bool _hasSignals = false;
  bool _generationFailed = false;
  Map<String, dynamic>? _signals;

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadAndGenerate();
  }

  Future<void> _loadAndGenerate({String? extraDirection}) async {
    setState(() {
      _isLoading = true;
      _generationFailed = false;
    });
    final uid = _uid;
    if (uid == null) {
      setState(() => _isLoading = false);
      return;
    }

    // Fetch signals, existing ideas, and stored advice in parallel.
    final signalsFuture = _signals != null
        ? Future.value(_signals)
        : FirestoreService.getSignals(uid);
    final ideasFuture = FirestoreService.ideasStream(uid).first;
    final adviceFuture = FirestoreService.getAIAdvice(uid);

    final signals = await signalsFuture;
    if (signals == null) {
      setState(() {
        _hasSignals = false;
        _isLoading = false;
      });
      return;
    }

    setState(() {
      _signals = signals;
      _hasSignals = true;
    });

    final existingIdeas = await ideasFuture;
    final storedAdvice = await adviceFuture;

    final existingSummaries = existingIdeas
        .where((i) => i.title.isNotEmpty)
        .map((i) {
          final firstBullet = i.script.isNotEmpty
              ? i.script
                    .split('\n')
                    .firstWhere((l) => l.trim().isNotEmpty, orElse: () => '')
                    .replaceFirst(RegExp(r'^•\s*'), '')
                    .trim()
              : '';
          return firstBullet.isNotEmpty ? '${i.title} — $firstBullet' : i.title;
        })
        .toList();

    final direction = extraDirection ?? widget.extraDirection;

    final result = await ClaudeService.generateIdeaAvoidingExisting(
      signals: signals,
      existingSummaries: existingSummaries,
      extraDirection: direction,
      aiAdvice: storedAdvice,
    );

    if (!mounted) return;

    // Surface rate-limit and error states with actionable messages.
    if (!result.isOk) {
      String msg;
      if (result.error == ClaudeErrorKind.rateLimitedLocally) {
        final wait = result.retryAfter != null
            ? RateLimiter.waitMessage(result.retryAfter!)
            : 'in a moment';
        msg = 'Generation limit reached. $wait.';
      } else if (result.error == ClaudeErrorKind.rateLimitedByApi) {
        msg = 'AI generation limit reached. Try again later.';
      } else {
        msg =
            'Could not generate an idea. Check your connection and try again.';
      }

      setState(() {
        _isLoading = false;
        _generationFailed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red.shade700),
      );
      return;
    }

    final idea = _withInitialTags(result.value);
    setState(() {
      _idea = idea;
      _isLoading = false;
    });

    // Auto-navigate to workspace if preload setting is on.
    if (idea != null && AppPreferences.preloadScripts.value && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => WorkspaceScreen(idea: idea)),
      );
    }
  }

  IdeaModel? _withInitialTags(IdeaModel? idea) {
    if (idea == null || widget.initialTags.isEmpty) return idea;
    final tags = {
      ...idea.tags,
      ...widget.initialTags.where((tag) => tag.trim().isNotEmpty),
    }.toList();
    return IdeaModel(
      id: idea.id,
      title: idea.title,
      script: idea.script,
      status: idea.status,
      tags: tags,
      isAIGenerated: idea.isAIGenerated,
      archived: idea.archived,
      createdAt: idea.createdAt,
      updatedAt: idea.updatedAt,
    );
  }

  void _showRegenerateSheet() {
    final promptCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
        ),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F4F0),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFCBD5E1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Text(
                'Generate another',
                style: GoogleFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Claude will generate a new idea using your saved signals. Add an optional direction to guide it.',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kMuted,
                ),
              ),
              const SizedBox(height: 20),
              // SECURITY: maxLength enforced in UI and re-validated before use.
              TextField(
                controller: promptCtrl,
                maxLines: 3,
                maxLength: 200,
                style: GoogleFonts.manrope(fontSize: 14, color: kText),
                decoration: InputDecoration(
                  hintText:
                      'Optional — add a topic, direction, or constraint...',
                  hintStyle: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kMuted.withValues(alpha: 0.6),
                  ),
                  filled: true,
                  fillColor: const Color(0xB8FFFFFF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: Color(0x140F172A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: kBrand, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kNavy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () {
                    final direction = promptCtrl.text.trim();
                    // Validate length before forwarding to the API.
                    final err = InputValidator.validateExtraDirection(
                      direction,
                    );
                    if (err != null) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text(err)));
                      return;
                    }
                    Navigator.pop(context);
                    _loadAndGenerate(
                      extraDirection: direction.isEmpty ? null : direction,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Generate',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: _isLoading
                ? _loadingView()
                : !_hasSignals
                ? _noSignalsView(context)
                : _generationFailed
                ? _errorView()
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 130),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _heroCard(),
                        const SizedBox(height: 16),
                        _generatedScript(),
                        const SizedBox(height: 16),
                        _signalsSummary(),
                        const SizedBox(height: 16),
                        _actions(context),
                      ],
                    ),
                  ),
          ),
          const AppTabBar(
            active: TabDest.none,
            fabRoute: '/generator',
            fabIcon: Icons.auto_awesome,
          ),
        ],
      ),
    );
  }

  Widget _errorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48, color: kMuted),
            const SizedBox(height: 16),
            Text(
              'Generation failed',
              style: GoogleFonts.fraunces(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Check your connection and try again. Your signals are saved.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: kMuted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _loadAndGenerate,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [kBrand, Color(0xFFFF7A4C)],
                  ),
                ),
                child: Text(
                  'Try again',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _showRegenerateSheet,
              child: Text(
                'Add a direction instead',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kBrandDeep,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _loadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: kBrand, strokeWidth: 2.5),
          const SizedBox(height: 20),
          Text(
            'Generating your idea...',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: kMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _noSignalsView(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 48, color: kMuted),
            const SizedBox(height: 16),
            Text(
              'No signals imported yet',
              style: GoogleFonts.fraunces(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Go to the Import tab and add your captions, topics, and creator references so Claude knows what to generate.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: kMuted,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () => Navigator.pushReplacementNamed(context, '/connect'),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                    colors: [kBrand, Color(0xFFFF7A4C)],
                  ),
                ),
                child: Text(
                  'Import signals',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _heroCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              RmChip(
                label: 'AI Generated',
                style: ChipStyle.brand,
                icon: Icons.auto_awesome,
              ),
              RmChip(label: 'Claude'),
            ],
          ),
          const SizedBox(height: 16),
          Text('GENERATED FOR YOU', style: eyebrowStyle),
          const SizedBox(height: 10),
          Text(_idea?.title ?? 'Generating...', style: displayTitle(32)),
          const SizedBox(height: 14),
          Text(
            'Based on your imported captions, creator references, and topic tags. Pre-loaded into the editor for quick tweaking.',
            style: mutedBodyStyle,
          ),
        ],
      ),
    );
  }

  Widget _generatedScript() {
    final bullets =
        _idea?.script.split('\n').where((l) => l.trim().isNotEmpty).toList() ??
        [];

    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Generated script', style: sectionTitle),
                    const SizedBox(height: 2),
                    Text(
                      '${bullets.length} talking points, ready to refine.',
                      style: sectionSubtitle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const RmChip(label: 'Script Ready', style: ChipStyle.teal),
            ],
          ),
          const SizedBox(height: 16),
          ...bullets.asMap().entries.expand((entry) {
            final i = entry.key;
            final text = entry.value.replaceFirst(RegExp(r'^•\s*'), '').trim();
            return [if (i > 0) _divider(), _bulletRow('${i + 1}', text)];
          }),
        ],
      ),
    );
  }

  Widget _bulletRow(String number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0x1FFF6B57),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Center(
              child: Text(
                number,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: kBrandDeep,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(height: 1, color: const Color(0x140F172A));

  Widget _signalsSummary() {
    final topics = List<String>.from(_signals?['topics'] ?? []);
    final rawCreators = List<dynamic>.from(_signals?['creators'] ?? []);
    final creators = rawCreators
        .map((c) {
          if (c is String) return c;
          if (c is Map) return (c['name'] ?? '').toString();
          return c.toString();
        })
        .where((s) => s.isNotEmpty)
        .toList();
    final captions = List<String>.from(_signals?['captions'] ?? []);

    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Signals used', style: sectionTitle),
                    const SizedBox(height: 2),
                    Text(
                      'What Claude based this idea on.',
                      style: sectionSubtitle,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const RmChip(label: 'Your profile'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ContentCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'TOPICS',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        topics.isEmpty
                            ? 'None added'
                            : topics.take(3).join(', '),
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: kText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ContentCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'CREATORS',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        creators.isEmpty
                            ? 'None added'
                            : creators.take(2).join(', '),
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: kText,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (captions.isNotEmpty) ...[
            const SizedBox(height: 12),
            ContentCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CAPTIONS',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${captions.length} caption${captions.length == 1 ? '' : 's'} analyzed',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: kText,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _actions(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 26,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: _idea == null
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WorkspaceScreen(idea: _idea),
                      ),
                    ),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 15),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    colors: [
                      kBrand.withValues(alpha: _idea == null ? 0.5 : 1.0),
                      const Color(
                        0xFFFF7A4C,
                      ).withValues(alpha: _idea == null ? 0.5 : 1.0),
                    ],
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x47FF6B57),
                      blurRadius: 28,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.edit_outlined,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Tweak in editor',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: GestureDetector(
              onTap: _showRegenerateSheet,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xB8FFFFFF),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0x140F172A)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.refresh, color: kText, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Generate another',
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: kText,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
