import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../models/idea_model.dart';
import '../services/firestore_service.dart';
import '../widgets/app_background.dart';
import '../widgets/app_tab_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/rm_chip.dart';
import '../widgets/tutorial_overlay.dart';
import 'generator_screen.dart';
import 'ideas_by_status_screen.dart';
import 'workspace_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  // GlobalKeys for spotlight targeting
  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _statsKey = GlobalKey();
  final GlobalKey _recentKey = GlobalKey();

  bool _showTutorial = false;
  List<TutorialStep> _tutorialSteps = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkTutorial());
  }

  Future<void> _checkTutorial() async {
    final uid = _uid;
    if (uid == null) return;
    final seen = await FirestoreService.hasTutorialBeenSeen(uid);
    if (seen || !mounted) return;
    _buildTutorialSteps();
    setState(() => _showTutorial = true);
  }

  void _buildTutorialSteps() {
    final size = MediaQuery.of(context).size;

    Rect? rectOf(GlobalKey key) {
      final box = key.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) return null;
      final offset = box.localToGlobal(Offset.zero);
      return offset & box.size;
    }

    _tutorialSteps = [
      const TutorialStep(
        eyebrow: 'Welcome',
        title: 'Your AI content studio is ready.',
        body: 'Reel Mind helps you go from inspiration to script in seconds — powered by your own content style. Let\'s take a quick tour.',
      ),
      TutorialStep(
        eyebrow: 'Idea Dashboard',
        title: 'Generate ideas instantly.',
        body: 'Tap "Generate for me" to let AI create a fresh video idea shaped by your saved signals, or start a blank idea with "New idea".',
        spotlightRect: rectOf(_heroKey),
      ),
      TutorialStep(
        eyebrow: 'Production Stats',
        title: 'Track your pipeline.',
        body: 'These cards show how many ideas are in Draft, Script Ready, or Posted. Tap any card to see the full list.',
        spotlightRect: rectOf(_statsKey),
      ),
      TutorialStep(
        eyebrow: 'Recent Ideas',
        title: 'Jump back in.',
        body: 'Your most recently edited ideas live here. Tap any card to open it in the workspace and keep writing.',
        spotlightRect: rectOf(_recentKey),
      ),
      TutorialStep(
        eyebrow: 'Quick Create',
        title: 'Create from anywhere.',
        body: 'The + button at the bottom opens a blank workspace so you can capture ideas the moment inspiration hits.',
        spotlightRect: Rect.fromCenter(
          center: Offset(size.width / 2, size.height - 86),
          width: 64,
          height: 64,
        ),
      ),
      TutorialStep(
        eyebrow: 'Import Signals',
        title: 'Keep your style fresh.',
        body: 'Tap Import to update your captions, topics, and creator inspirations. The more you add, the more on-brand your AI ideas become.',
        spotlightRect: Rect.fromCenter(
          center: Offset(size.width * 0.34, size.height - 52),
          width: 72,
          height: 60,
        ),
      ),
      TutorialStep(
        eyebrow: 'Your Profile',
        title: 'See your content style at a glance.',
        body: 'The Profile tab shows your content-style breakdown, production stats, and a full view of your imported signals — all in one place.',
        spotlightRect: Rect.fromCenter(
          center: Offset(size.width * 0.66, size.height - 52),
          width: 72,
          height: 60,
        ),
      ),
    ];
  }

  Future<void> _completeTutorial() async {
    setState(() => _showTutorial = false);
    final uid = _uid;
    if (uid != null) {
      await FirestoreService.markTutorialSeen(uid);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: StreamBuilder<List<IdeaModel>>(
              stream: _uid != null
                  ? FirestoreService.ideasStream(_uid!)
                  : const Stream.empty(),
              builder: (context, snapshot) {
                final ideas = snapshot.data ?? [];
                return AbsorbPointer(
                  absorbing: _showTutorial,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 130),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _statusBar(),
                        const SizedBox(height: 4),
                        _heroCard(context),
                        const SizedBox(height: 16),
                        _statsRow(context, ideas),
                        const SizedBox(height: 16),
                        _recentIdeas(context, ideas),
                        const SizedBox(height: 16),
                        _tasteProfilePulse(context),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          AppTabBar(
            active: TabDest.home,
            fabRoute: '/workspace',
            fabIcon: Icons.add,
            absorbing: _showTutorial,
          ),
          if (_showTutorial)
            TutorialOverlay(
              steps: _tutorialSteps,
              onComplete: _completeTutorial,
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
          Row(
            children: const [
              Icon(Icons.signal_cellular_alt, size: 16, color: kText),
              SizedBox(width: 6),
              Icon(Icons.wifi, size: 16, color: kText),
              SizedBox(width: 6),
              Icon(Icons.battery_full, size: 16, color: kText),
            ],
          ),
        ],
      ),
    );
  }

  void _showGenerateSheet(BuildContext context) {
    final promptCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
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
              Text('Generate an idea',
                  style: GoogleFonts.fraunces(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: kText)),
              const SizedBox(height: 6),
              Text(
                  'Claude will use your saved signals to generate a fresh idea. Add an optional direction to guide it.',
                  style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kMuted)),
              const SizedBox(height: 20),
              TextField(
                controller: promptCtrl,
                maxLines: 3,
                style: GoogleFonts.manrope(fontSize: 14, color: kText),
                decoration: InputDecoration(
                  hintText:
                      'Optional — add a topic, angle, or constraint...',
                  hintStyle: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: kMuted.withValues(alpha: 0.6)),
                  filled: true,
                  fillColor: const Color(0xB8FFFFFF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: Color(0x140F172A)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide:
                        const BorderSide(color: kBrand, width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kBrand,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    final direction = promptCtrl.text.trim();
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => GeneratorScreen(
                          extraDirection:
                              direction.isEmpty ? null : direction,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('Generate for me',
                          style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w700)),
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

  Widget _heroCard(BuildContext context) {
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
                    Text('IDEA DASHBOARD', style: eyebrowStyle),
                    const SizedBox(height: 10),
                    Text(
                      'Create your next video with AI, shaped by your own content style.',
                      style: displayTitle(34),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
             
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Your ideas, sorted by recency and production status.',
            style: mutedBodyStyle,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                  child: _primaryBtn(
                      context, Icons.auto_awesome, 'Generate for me',
                      onTap: () => _showGenerateSheet(context))),
              const SizedBox(width: 12),
              Expanded(
                  child: _secondaryBtn(
                      context, Icons.edit_outlined, 'New idea', null,
                      onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const WorkspaceScreen()),
                          ))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statsRow(BuildContext context, List<IdeaModel> ideas) {
    int count(String status) =>
        ideas.where((i) => i.status == status).length;

    return Row(
      key: _statsKey,
      children: [
        Expanded(
            child: _statCard(context, 'DRAFT', 'Draft',
                count('Draft').toString(), 'Fresh concepts')),
        const SizedBox(width: 12),
        Expanded(
            child: _statCard(context, 'SCRIPT READY', 'Script Ready',
                count('Script Ready').toString(), 'Ready to film')),
        const SizedBox(width: 12),
        Expanded(
            child: _statCard(context, 'POSTED', 'Posted',
                count('Posted').toString(), 'Recent wins')),
      ],
    );
  }

  Widget _statCard(BuildContext context, String label, String status,
      String value, String subtitle) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => IdeasByStatusScreen(status: status)),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xCCFFFFFF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x140F172A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                          color: const Color(0xFF94A3B8))),
                ),
                const Icon(Icons.chevron_right, size: 14, color: kBrand),
              ],
            ),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.manrope(
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                    color: kText)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: kMuted)),
          ],
        ),
      ),
    );
  }

  Widget _recentIdeas(BuildContext context, List<IdeaModel> ideas) {
    final recent = ideas.take(3).toList();
    return GlassCard(
      key: _recentKey,
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
                    Text('Recent ideas', style: sectionTitle),
                    const SizedBox(height: 2),
                    Text('Sorted by most recent edits.',
                        style: sectionSubtitle),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              RmChip(
                label: '${ideas.length} total',
                style: ChipStyle.soft,
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (recent.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text('No ideas yet. Tap + to create one.',
                    style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: kMuted)),
              ),
            )
          else
            ...recent.asMap().entries.map((entry) {
              final i = entry.key;
              final idea = entry.value;
              return Column(
                children: [
                  if (i > 0) const SizedBox(height: 12),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => WorkspaceScreen(idea: idea)),
                    ),
                    child: _ideaItem(idea),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _ideaItem(IdeaModel idea) {
    final chipStyle = switch (idea.status) {
      'Script Ready' => ChipStyle.teal,
      'Posted' => ChipStyle.teal,
      _ => ChipStyle.brand,
    };
    return ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                    idea.title.isEmpty ? 'Untitled idea' : idea.title,
                    style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: kText)),
              ),
              const SizedBox(width: 8),
              RmChip(label: idea.status, style: chipStyle),
            ],
          ),
          if (idea.script.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              idea.script.length > 120
                  ? '${idea.script.substring(0, 120)}...'
                  : idea.script,
              style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: kMuted,
                  height: 1.5),
            ),
          ],
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(idea.timeAgoLabel.toUpperCase(),
                  style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                      color: const Color(0xFF94A3B8))),
              Text(
                  idea.isAIGenerated
                      ? 'AI ASSISTED'
                      : 'MANUAL',
                  style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                      color: const Color(0xFF94A3B8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tasteProfilePulse(BuildContext context) {
    final uid = _uid;
    return FutureBuilder<Map<String, dynamic>?>(
      future: uid != null ? FirestoreService.getSignals(uid) : Future.value(null),
      builder: (context, snapshot) {
        final topics = snapshot.hasData && snapshot.data != null
            ? List<String>.from(snapshot.data!['topics'] ?? [])
            : <String>[];
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
                        Text('Content-Style Profile', style: sectionTitle),
                        const SizedBox(height: 2),
                        Text(
                            'What your imported references are hinting this week.',
                            style: sectionSubtitle),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: () =>
                        Navigator.pushReplacementNamed(context, '/profile'),
                    child: Text('View all',
                        style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: kBrandDeep)),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (snapshot.connectionState == ConnectionState.waiting)
                const SizedBox(
                  height: 32,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                )
              else if (topics.isEmpty)
                GestureDetector(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/import'),
                  child: Row(
                    children: [
                      const Icon(Icons.add_circle_outline,
                          size: 16, color: kBrand),
                      const SizedBox(width: 8),
                      Text('Import signals to see your profile',
                          style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: kBrand)),
                    ],
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: topics.map((t) => RmChip(label: t)).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _primaryBtn(BuildContext context, IconData icon, String label,
      {VoidCallback? onTap, String? route}) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.pushNamed(context, route!),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [kBrand, Color(0xFFFF7A4C)],
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x47FF6B57),
                blurRadius: 28,
                offset: Offset(0, 16)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _secondaryBtn(BuildContext context, IconData icon, String label,
      String? route,
      {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap ?? () => Navigator.pushNamed(context, route!),
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
            Icon(icon, color: kText, size: 16),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: kText)),
          ],
        ),
      ),
    );
  }
}
