import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../models/idea_model.dart';
import '../services/claude_service.dart';
import '../services/firestore_service.dart';
import '../services/rate_limiter.dart';
import '../widgets/app_background.dart';
import '../widgets/app_tab_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/rm_chip.dart';
import '../widgets/tutorial_overlay.dart';
import 'archived_ideas_screen.dart';
import 'saved_advice_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? _aiAdvice;
  bool _loadingAdvice = false;
  bool _currentAdviceSaved = false;
  bool _savingAdvice = false;
  List<IdeaModel> _ideas = [];
  Map<String, dynamic>? _signals;
  int _archivedCount = 0;
  List<String> _savedAdviceTexts = [];
  int _savedAdviceCount = 0;

  // Tutorial
  bool _showTutorial = false;
  List<TutorialStep> _tutorialSteps = [];
  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _statsKey = GlobalKey();
  final GlobalKey _themesKey = GlobalKey();
  final GlobalKey _nextMoveKey = GlobalKey();
  final ScrollController _scrollCtrl = ScrollController();

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadIdeasAndGetAdvice();
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadIdeasAndGetAdvice() async {
    final uid = _uid;
    if (uid == null) return;
    setState(() { _loadingAdvice = true; _currentAdviceSaved = false; });
    try {
      final results = await Future.wait([
        FirestoreService.ideasStream(uid).first,
        FirestoreService.getSignals(uid),
        FirestoreService.archivedIdeasStream(uid).first,
        FirestoreService.getSavedAdviceTexts(uid),
      ]);
      final ideas = results[0] as List<IdeaModel>;
      final signals = results[1] as Map<String, dynamic>?;
      final archived = results[2] as List<IdeaModel>;
      final savedTexts = results[3] as List<String>;
      if (!mounted) return;

      // Topics from signals that have zero ideas tagged
      final signalTopics = List<String>.from(signals?['topics'] ?? []);
      final uncoveredTopics = signalTopics
          .where((t) => !ideas.any((i) => i.tags.contains(t)))
          .toList();

      // Fetch full count separately (getSavedAdviceTexts is capped at 8)
      final countSnap = await FirestoreService.getSavedAdviceCount(uid);

      setState(() {
        _ideas = ideas;
        _signals = signals;
        _archivedCount = archived.length;
        _savedAdviceTexts = savedTexts;
        _savedAdviceCount = countSnap;
      });
      final result = await ClaudeService.getAIAdviceResult(
        ideas: ideas,
        signals: signals,
        previousAdvice: savedTexts,
        uncoveredTopics: uncoveredTopics,
      );
      if (!mounted) return;
      if (result.isOk) {
        setState(() => _aiAdvice = result.value);
        if (result.value != null) {
          await FirestoreService.saveAIAdvice(uid, result.value!);
        }
      } else {
        final String msg;
        if (result.error == ClaudeErrorKind.rateLimitedLocally) {
          final wait = result.retryAfter != null
              ? RateLimiter.waitMessage(result.retryAfter!)
              : 'in a moment';
          msg = 'AI generation limit reached (10/hour). $wait.';
        } else if (result.error == ClaudeErrorKind.rateLimitedByApi) {
          msg = 'AI generation limit reached (10/hour). Try again later.';
        } else {
          msg = 'Could not load advice. Check your connection.';
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg,
                style: GoogleFonts.manrope(
                    fontSize: 13, fontWeight: FontWeight.w600)),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ));
        }
      }
    } finally {
      if (mounted) setState(() => _loadingAdvice = false);
    }
  }

  Future<void> _saveCurrentAdvice() async {
    final uid = _uid;
    final advice = _aiAdvice;
    if (uid == null || advice == null || _currentAdviceSaved || _savingAdvice) return;
    setState(() => _savingAdvice = true);
    try {
      await FirestoreService.addSavedAdvice(uid, advice);
      if (!mounted) return;
      setState(() {
        _currentAdviceSaved = true;
        _savedAdviceCount = _savedAdviceCount + 1;
        _savedAdviceTexts = [advice, ..._savedAdviceTexts];
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Advice saved!',
            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600)),
        backgroundColor: kNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
    } finally {
      if (mounted) setState(() => _savingAdvice = false);
    }
  }

  void _startTutorial() {
    _buildTutorialSteps();
    setState(() => _showTutorial = true);
  }

  void _buildTutorialSteps() {
    Rect? rectOf(GlobalKey key) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return null;
      final offset = box.localToGlobal(Offset.zero);
      return offset & box.size;
    }

    _tutorialSteps = [
      const TutorialStep(
        eyebrow: 'Profile',
        title: 'Your content-style overview.',
        body: 'This screen shows everything about your content style — stats, themes, and AI-powered suggestions — all in one place.',
      ),
      TutorialStep(
        eyebrow: 'Production Stats',
        title: 'Track your idea pipeline.',
        body: 'See how many ideas you have in total, how many are archived, and your saved advice by AI. Tap Archived to browse or restore old ideas.',
        spotlightRectBuilder: () => rectOf(_statsKey),
      ),
      TutorialStep(
        eyebrow: 'Content-Style Themes',
        title: 'Discover your strongest topics.',
        body: 'Each bar shows a topic from your signals and how many ideas you\'ve tagged with it. The longer the bar, the more you\'ve explored that theme.',
        spotlightRectBuilder: () => rectOf(_themesKey),
      ),
      TutorialStep(
        eyebrow: 'Advice by AI',
        title: 'Get personalised strategic advice.',
        body: 'Claude analyses your pipeline and tells you the best next topic to cover, what to improve in your scripts, and what content gaps to fill.',
        onBeforeShow: () => _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        ),
        spotlightRectBuilder: () => rectOf(_nextMoveKey),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: AbsorbPointer(
              absorbing: _showTutorial,
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 130),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _statusBar(),
                    const SizedBox(height: 4),
                    _heroCard(),
                    const SizedBox(height: 16),
                    _statsRow(context),
                    const SizedBox(height: 16),
                    _signalThemes(),
                    const SizedBox(height: 16),
                    _bestNextMove(),
                  ],
                ),
              ),
            ),
          ),
          AppTabBar(
            active: TabDest.profile,
            fabRoute: '/generator',
            fabIcon: Icons.auto_awesome,
            absorbing: _showTutorial,
          ),
          if (_showTutorial)
            TutorialOverlay(
              steps: _tutorialSteps,
              onComplete: () => setState(() => _showTutorial = false),
            ),
        ],
      ),
    );
  }

  Widget _statusBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('9:41',
              style: GoogleFonts.manrope(
                  fontSize: 13, fontWeight: FontWeight.w700, color: kText)),
          Row(children: const [
            Icon(Icons.signal_cellular_alt, size: 16, color: kText),
            SizedBox(width: 6),
            Icon(Icons.wifi, size: 16, color: kText),
            SizedBox(width: 6),
            Icon(Icons.battery_full, size: 16, color: kText),
          ]),
        ],
      ),
    );
  }

  Widget _heroCard() {
    return GlassCard(key: _heroKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CONTENT-STYLE PROFILE', style: eyebrowStyle),
                    const SizedBox(height: 8),
                    Text(
                      'Take a Peek Into What Your Content Style Looks Like',
                      style: displayTitle(26),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: _startTutorial,
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: const Color(0xB8FFFFFF),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0x200F172A)),
                  ),
                  child: const Icon(Icons.info_outline,
                      color: kMuted, size: 17),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Reel Mind continuously updates your personal content profile from the inspo references you import so idea generation stays grounded in your actual taste.',
            style: mutedBodyStyle,
          ),
        ],
      ),
    );
  }

  Widget _statsRow(BuildContext context) {
    return Column(
      key: _statsKey,
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: GlassCard(
                  padding: const EdgeInsets.all(16),
                  borderRadius: 22,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('TOTAL IDEAS',
                          style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                              color: const Color(0xFF94A3B8))),
                      const SizedBox(height: 8),
                      Text('${_ideas.length}',
                          style: GoogleFonts.manrope(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: kText)),
                      Text('across all stages',
                          style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: kMuted)),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const ArchivedIdeasScreen()),
                  ),
                  child: GlassCard(
                    padding: const EdgeInsets.all(16),
                    borderRadius: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text('ARCHIVED',
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.manrope(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.6,
                                      color: const Color(0xFF94A3B8))),
                            ),
                            const Icon(Icons.chevron_right,
                                size: 14, color: kBrand),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text('$_archivedCount',
                            style: GoogleFonts.manrope(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: kText)),
                        Text('ideas archived',
                            style: GoogleFonts.manrope(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: kMuted)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SavedAdviceScreen()),
            );
            final uid = _uid;
            if (uid != null && mounted) {
              final count = await FirestoreService.getSavedAdviceCount(uid);
              if (mounted) setState(() => _savedAdviceCount = count);
            }
          },
          child: GlassCard(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            borderRadius: 22,
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: kBrand.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.bookmark_outlined, size: 18, color: kBrand),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SAVED ADVICE',
                          style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                              color: const Color(0xFF94A3B8))),
                      const SizedBox(height: 2),
                      Text(
                        '$_savedAdviceCount ${_savedAdviceCount == 1 ? 'piece' : 'pieces'} saved',
                        style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: kText),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, size: 16, color: kBrand),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _signalThemes() {
    final topics = List<String>.from(_signals?['topics'] ?? []);

    // Count ideas tagged with each topic
    final counts = <String, int>{
      for (final t in topics)
        t: _ideas.where((i) => i.tags.contains(t)).length,
    };

    // Sort by count descending
    final sorted = [...topics]
      ..sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));

    final maxCount =
        counts.values.isEmpty ? 1 : counts.values.reduce((a, b) => a > b ? a : b);

    final barColors = [
      const Color(0xFF0F172A),
      kBrand,
      kTeal,
      const Color(0xFF7C3AED),
      const Color(0xFFD97706),
    ];

    return GlassCard(
      key: _themesKey,
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
                      Text('Content-style themes', style: sectionTitle),
                      const SizedBox(height: 2),
                      Text(
                          'Based on topics tagged across your ideas.',
                          style: sectionSubtitle),
                    ]),
              ),
              const SizedBox(width: 12),
              const RmChip(label: 'Live profile', style: ChipStyle.brand),
            ],
          ),
          const SizedBox(height: 20),
          if (topics.isEmpty)
            Text(
              'Import signals and tag ideas to build your profile.',
              style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: kMuted,
                  height: 1.5),
            )
          else
            ...sorted.asMap().entries.map((e) {
              final topic = e.value;
              final count = counts[topic] ?? 0;
              final pct = maxCount == 0 ? 0.0 : count / maxCount;
              final color = barColors[e.key % barColors.length];
              return Column(
                children: [
                  if (e.key > 0) const SizedBox(height: 16),
                  _progressBar(topic, pct, color, count),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _progressBar(String label, double value, Color color, int count) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kText)),
            ),
            const SizedBox(width: 8),
            Text(
              count == 1 ? '1 idea' : '$count ideas',
              style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kText),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Stack(
          children: [
            Container(
              height: 12,
              decoration: BoxDecoration(
                color: const Color(0xB3FFFFFF),
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _formattedAdvice(String advice) {
    final baseStyle = GoogleFonts.manrope(
        fontSize: 14, fontWeight: FontWeight.w500, color: kText, height: 1.7);
    final boldStyle = GoogleFonts.manrope(
        fontSize: 14, fontWeight: FontWeight.w800, color: kText, height: 1.7);

    final spans = <InlineSpan>[];
    for (final line in advice.trim().split('\n')) {
      if (spans.isNotEmpty) spans.add(const TextSpan(text: '\n'));
      final colon = line.indexOf(':');
      if (colon > 0) {
        spans.add(TextSpan(text: line.substring(0, colon + 1), style: boldStyle));
        spans.add(TextSpan(text: line.substring(colon + 1), style: baseStyle));
      } else {
        spans.add(TextSpan(text: line, style: baseStyle));
      }
    }

    return RichText(text: TextSpan(children: spans));
  }

  Widget _bestNextMove() {
    return GlassCard(key: _nextMoveKey,
      padding: const EdgeInsets.all(18),
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Advice by AI', style: sectionTitle),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_loadingAdvice) ...[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: kBrandDeep),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Icon(Icons.tips_and_updates_outlined, color: kBrandDeep, size: 20),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_loadingAdvice && _aiAdvice == null)
            Text('Analyzing your content...',
                style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: kMuted,
                    height: 1.6))
          else if (_aiAdvice != null)
            _formattedAdvice(_aiAdvice!)
          else if (_ideas.isEmpty)
            Text(
              'Create a few ideas in the workspace first — then come back for personalised advice.',
              style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kMuted,
                  height: 1.6),
            )
          else
            GestureDetector(
              onTap: _loadIdeasAndGetAdvice,
              child: Text('Tap to retry',
                  style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: kBrand)),
            ),
          if (_aiAdvice != null) ...[
            const SizedBox(height: 14),
            Row(
              children: [
                GestureDetector(
                  onTap: _loadIdeasAndGetAdvice,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.refresh, size: 14, color: kBrandDeep),
                      const SizedBox(width: 4),
                      Text('Refresh',
                          style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: kBrandDeep)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _currentAdviceSaved ? null : _saveCurrentAdvice,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_savingAdvice)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: kBrand),
                        )
                      else
                        Icon(
                          _currentAdviceSaved ? Icons.bookmark : Icons.bookmark_outline,
                          size: 14,
                          color: _currentAdviceSaved ? kBrand : kBrandDeep,
                        ),
                      const SizedBox(width: 4),
                      Text(
                        _currentAdviceSaved ? 'Saved' : 'Save advice',
                        style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: _currentAdviceSaved ? kBrand : kBrandDeep),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
