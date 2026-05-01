import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../models/idea_model.dart';
import '../models/try_next_insight.dart';
import '../services/claude_service.dart';
import '../services/firestore_service.dart';
import '../services/rate_limiter.dart';
import '../services/try_next_analyzer.dart';
import '../widgets/app_background.dart';
import '../widgets/app_tab_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/rm_chip.dart';
import '../widgets/tutorial_overlay.dart';
import '../widgets/try_next_hook_card.dart';
import 'archived_ideas_screen.dart';
import 'generator_screen.dart';
import 'saved_advice_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  TryNextInsight? _tryNextInsight;
  bool _loadingTryNext = false;
  String? _tryNextError;
  String? _lastRequestedSignature;
  List<IdeaModel> _ideas = [];
  Map<String, dynamic>? _signals;
  int _archivedCount = 0;
  int _savedAdviceCount = 0;
  final Set<String> _savedHookKeys = {};
  final Set<String> _savingHookKeys = {};

  StreamSubscription<List<IdeaModel>>? _ideasSub;
  StreamSubscription<List<IdeaModel>>? _archivedSub;

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
    _subscribeToIdeas();
    _loadStaticData();
  }

  @override
  void dispose() {
    _ideasSub?.cancel();
    _archivedSub?.cancel();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _subscribeToIdeas() {
    final uid = _uid;
    if (uid == null) return;
    _ideasSub = FirestoreService.ideasStream(uid).listen((ideas) {
      if (!mounted) return;
      setState(() => _ideas = ideas);
      _queueTryNextLoad();
    });
    _archivedSub = FirestoreService.archivedIdeasStream(uid).listen((archived) {
      if (mounted) setState(() => _archivedCount = archived.length);
    });
  }

  Future<void> _loadStaticData() async {
    final uid = _uid;
    if (uid == null) return;

    final signalsFuture = FirestoreService.getSignals(uid);
    final countFuture = FirestoreService.getSavedAdviceCount(uid);

    final signals = await signalsFuture;
    if (!mounted) return;
    setState(() => _signals = signals);
    _queueTryNextLoad();

    try {
      final savedCount = await countFuture;
      if (mounted) setState(() => _savedAdviceCount = savedCount);
    } catch (_) {}
  }

  List<String> _savedTopics() {
    return TryNextAnalyzer.normalizeTopics(
      List<String>.from(_signals?['topics'] ?? []),
    );
  }

  void _queueTryNextLoad() {
    if (!mounted || _signals == null || _loadingTryNext) return;
    final topics = _savedTopics();
    final posted = TryNextAnalyzer.postedIdeas(_ideas);
    if (topics.isEmpty || posted.isEmpty) {
      setState(() {
        _tryNextInsight = null;
        _tryNextError = null;
      });
      return;
    }
    final signature = TryNextAnalyzer.sourceSignature(posted, topics);
    if (_tryNextInsight?.sourceSignature == signature ||
        _lastRequestedSignature == signature) {
      return;
    }
    unawaited(_loadTryNextInsight());
  }

  Future<void> _refreshTryNext() async {
    await _loadTryNextInsight(forceRefresh: true);
  }

  Future<void> _loadTryNextInsight({bool forceRefresh = false}) async {
    final uid = _uid;
    final signals = _signals;
    if (uid == null || signals == null || _loadingTryNext) return;

    final topics = _savedTopics();
    final posted = TryNextAnalyzer.postedIdeas(_ideas);
    if (topics.isEmpty || posted.isEmpty) {
      setState(() {
        _tryNextInsight = null;
        _tryNextError = null;
      });
      return;
    }

    final sourceSignature = TryNextAnalyzer.sourceSignature(posted, topics);
    if (!forceRefresh && _tryNextInsight?.sourceSignature == sourceSignature) {
      return;
    }

    setState(() {
      _loadingTryNext = true;
      _tryNextError = null;
      _lastRequestedSignature = sourceSignature;
    });

    try {
      if (!forceRefresh) {
        final cached = await FirestoreService.getTryNextInsight(uid);
        if (!mounted) return;
        if (cached != null && cached.sourceSignature == sourceSignature) {
          setState(() {
            _tryNextInsight = cached;
            _loadingTryNext = false;
          });
          return;
        }
      }

      final result = await ClaudeService.getTryNextInsightResult(
        postedIdeas: posted,
        topics: topics,
        sourceSignature: sourceSignature,
        signals: signals,
      );
      if (!mounted) return;

      if (!result.isOk || result.value == null) {
        _handleTryNextError(result.error, result.retryAfter);
        return;
      }

      final insight = result.value!;
      await _applyInferredTags(uid, posted, topics, insight.inferredTags);

      final appliedPosted = TryNextAnalyzer.applyInferredTags(
        posted,
        topics,
        insight.inferredTags,
      );
      final counts = TryNextAnalyzer.topicCounts(appliedPosted, topics);
      final anchor = TryNextAnalyzer.anchorTopic(appliedPosted, topics);
      final hooks = TryNextAnalyzer.normalizeHooks(
        hooks: insight.hooks,
        topics: topics,
        anchorTopic: anchor,
        counts: counts,
      );
      final finalSignature = TryNextAnalyzer.sourceSignature(
        appliedPosted,
        topics,
      );
      final normalizedInsight = insight.copyWith(
        pattern: insight.pattern.isNotEmpty
            ? insight.pattern
            : 'Your posted scripts currently lean most into $anchor.',
        anchorTopic: anchor,
        topicCounts: counts,
        hooks: hooks,
        sourceSignature: finalSignature,
      );

      await FirestoreService.saveTryNextInsight(uid, normalizedInsight);
      if (!mounted) return;
      setState(() => _tryNextInsight = normalizedInsight);
    } finally {
      if (mounted) setState(() => _loadingTryNext = false);
    }
  }

  Future<void> _applyInferredTags(
    String uid,
    List<IdeaModel> posted,
    List<String> topics,
    List<TryNextInferredTag> inferredTags,
  ) async {
    final topicSet = topics.toSet();
    final byId = {
      for (final idea in posted)
        if (idea.id != null) idea.id!: idea,
    };
    final updates = <Future<void>>[];
    for (final inferred in inferredTags) {
      final idea = byId[inferred.ideaId];
      if (idea == null || !topicSet.contains(inferred.topic)) continue;
      if (!TryNextAnalyzer.lacksSavedTopic(idea, topics)) continue;
      final tags = [...idea.tags];
      if (!tags.contains(inferred.topic)) tags.add(inferred.topic);
      updates.add(FirestoreService.updateIdea(uid, idea.id!, {'tags': tags}));
    }
    await Future.wait(updates);
  }

  void _handleTryNextError(ClaudeErrorKind? error, Duration? retryAfter) {
    final String msg;
    if (error == ClaudeErrorKind.rateLimitedLocally) {
      final wait = retryAfter != null
          ? RateLimiter.waitMessage(retryAfter)
          : 'Try again in a moment';
      msg = 'Insight refresh limit reached. $wait.';
    } else if (error == ClaudeErrorKind.rateLimitedByApi) {
      msg = 'Insight refresh limit reached. Try again later.';
    } else {
      msg = 'Could not load suggestions. Check your connection.';
    }
    setState(() => _tryNextError = msg);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          msg,
          style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _openHook(TryNextHook hook) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GeneratorScreen(
          extraDirection: hook.generationDirection,
          initialTags: [hook.targetTopic],
        ),
      ),
    );
  }

  String _hookSaveText(TryNextHook hook) {
    final bridge = hook.bridgeTopic == null
        ? ''
        : '\nConnected topic: ${hook.bridgeTopic}';
    return 'Hook: "${hook.hook}"\n'
        'Topic: ${hook.targetTopic}$bridge\n'
        'Why: ${hook.reason}\n'
        'Direction: ${hook.generationDirection}';
  }

  Future<void> _saveHook(TryNextHook hook) async {
    final uid = _uid;
    if (uid == null) return;
    final text = _hookSaveText(hook);
    if (_savedHookKeys.contains(text) || _savingHookKeys.contains(text)) return;

    setState(() => _savingHookKeys.add(text));
    try {
      await FirestoreService.addSavedAdvice(uid, text);
      if (!mounted) return;
      setState(() {
        _savedHookKeys.add(text);
        _savedAdviceCount = _savedAdviceCount + 1;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Hook saved!',
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          backgroundColor: kNavy,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _savingHookKeys.remove(text));
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
        body:
            'This screen shows everything about your content style — stats, themes, and AI-powered suggestions — all in one place.',
      ),
      TutorialStep(
        eyebrow: 'Production Stats',
        title: 'Track your idea pipeline.',
        body:
            'See how many ideas you have in total, how many are archived, and your saved insights. Tap Archived to browse or restore old ideas.',
        spotlightRectBuilder: () => rectOf(_statsKey),
      ),
      TutorialStep(
        eyebrow: 'Content-Style Themes',
        title: 'Discover your strongest topics.',
        body:
            'Each bar shows a topic from your signals and how many ideas you\'ve tagged with it. The longer the bar, the more you\'ve explored that theme.',
        spotlightRectBuilder: () => rectOf(_themesKey),
      ),
      TutorialStep(
        eyebrow: 'What to Try Next',
        title: 'Turn posted patterns into new hooks.',
        body:
            'Claude reads your posted scripts, fills missing topic tags, and suggests clickable directions for your next AI-generated idea.',
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

  Widget _heroCard() {
    return GlassCard(
      key: _heroKey,
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
                  child: const Icon(
                    Icons.info_outline,
                    color: kMuted,
                    size: 17,
                  ),
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
                      Text(
                        'TOTAL IDEAS',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${_ideas.length}',
                        style: GoogleFonts.manrope(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: kText,
                        ),
                      ),
                      Text(
                        'across all stages',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: kMuted,
                        ),
                      ),
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
                      builder: (_) => const ArchivedIdeasScreen(),
                    ),
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
                              child: Text(
                                'ARCHIVED',
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.manrope(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.6,
                                  color: const Color(0xFF94A3B8),
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.chevron_right,
                              size: 14,
                              color: kBrand,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$_archivedCount',
                          style: GoogleFonts.manrope(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: kText,
                          ),
                        ),
                        Text(
                          'ideas archived',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: kMuted,
                          ),
                        ),
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
          onTap: () => _openSavedAdviceScreen(),
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
                  child: const Icon(
                    Icons.bookmark_outlined,
                    size: 18,
                    color: kBrand,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SAVED HOOKS',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                          color: const Color(0xFF94A3B8),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$_savedAdviceCount ${_savedAdviceCount == 1 ? 'hook' : 'hooks'} saved',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: kText,
                        ),
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
      for (final t in topics) t: _ideas.where((i) => i.tags.contains(t)).length,
    };

    // Sort by count descending
    final sorted = [...topics]
      ..sort((a, b) => (counts[b] ?? 0).compareTo(counts[a] ?? 0));

    final maxCount = counts.values.isEmpty
        ? 1
        : counts.values.reduce((a, b) => a > b ? a : b);

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
                      style: sectionSubtitle,
                    ),
                  ],
                ),
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
                height: 1.5,
              ),
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
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kText,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              count == 1 ? '1 idea' : '$count ideas',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: kText,
              ),
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

  Future<void> _openSavedAdviceScreen() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SavedAdviceScreen()),
    );
    final uid = _uid;
    if (uid != null && mounted) {
      final savedCount = await FirestoreService.getSavedAdviceCount(uid);
      if (mounted) {
        setState(() => _savedAdviceCount = savedCount);
      }
    }
  }

  Widget _bestNextMove() {
    final topics = _savedTopics();
    final posted = TryNextAnalyzer.postedIdeas(_ideas);
    final insight = _tryNextInsight;

    return GlassCard(
      key: _nextMoveKey,
      padding: const EdgeInsets.all(18),
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(child: Text('What to Try Next', style: sectionTitle)),
              const SizedBox(width: 12),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_loadingTryNext) ...[
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: kBrandDeep,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  const Icon(Icons.auto_awesome, color: kBrandDeep, size: 20),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (topics.isEmpty)
            _tryNextMessage(
              'Import or select topics first so Reel Mind has categories to compare.',
            )
          else if (posted.isEmpty)
            _tryNextMessage(
              'Mark finished scripts as Posted to unlock hook suggestions from your real publishing patterns.',
            )
          else if (_loadingTryNext && insight == null)
            _tryNextMessage(
              'Analyzing posted scripts and finding your next angles...',
            )
          else if (insight != null)
            _tryNextContent(insight)
          else if (_tryNextError != null)
            _tryNextRetry(_tryNextError!)
          else
            _tryNextRetry('Tap to load suggestions.'),
          if (topics.isNotEmpty && posted.isNotEmpty) ...[
            const SizedBox(height: 14),
            GestureDetector(
              onTap: _loadingTryNext ? null : _refreshTryNext,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh, size: 14, color: kBrandDeep),
                  const SizedBox(width: 4),
                  Text(
                    _loadingTryNext ? 'Refreshing...' : 'Refresh',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: kBrandDeep,
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

  Widget _tryNextContent(TryNextInsight insight) {
    final anchorCount = insight.topicCounts[insight.anchorTopic] ?? 0;
    final inferredCount = insight.inferredTags.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          insight.pattern,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: kText,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            RmChip(
              label: '$anchorCount posted in ${insight.anchorTopic}',
              style: ChipStyle.brand,
            ),
            if (inferredCount > 0)
              RmChip(
                label: '$inferredCount auto-tagged',
                style: ChipStyle.teal,
              ),
          ],
        ),
        const SizedBox(height: 16),
        ...insight.hooks.asMap().entries.map((entry) {
          return Column(
            children: [
              if (entry.key > 0) const SizedBox(height: 10),
              TryNextHookCard(
                hook: entry.value,
                onTap: () => _openHook(entry.value),
                onSave: () => _saveHook(entry.value),
                isSaved: _savedHookKeys.contains(_hookSaveText(entry.value)),
                isSaving: _savingHookKeys.contains(_hookSaveText(entry.value)),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _tryNextMessage(String message) {
    return Text(
      message,
      style: GoogleFonts.manrope(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: kMuted,
        height: 1.6,
      ),
    );
  }

  Widget _tryNextRetry(String message) {
    return GestureDetector(
      onTap: _loadingTryNext ? null : _refreshTryNext,
      child: Text(
        message,
        style: GoogleFonts.manrope(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: kBrand,
          height: 1.5,
        ),
      ),
    );
  }
}
