import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../models/idea_model.dart';
import '../services/claude_service.dart';
import '../services/firestore_service.dart';
import '../utils/input_validator.dart';
import '../widgets/app_background.dart';
import '../widgets/app_tab_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/rm_chip.dart';
import '../widgets/tutorial_overlay.dart';

enum _SaveState { idle, saving, saved }

class WorkspaceScreen extends StatefulWidget {
  final IdeaModel? idea;
  const WorkspaceScreen({super.key, this.idea});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _scriptCtrl;
  late String _activeStatus;
  String? _ideaId;
  _SaveState _saveState = _SaveState.idle;
  bool _isAssisting = false;
  Timer? _debounce;
  String _lastText = '';
  List<String> _selectedTags = [];
  List<String> _availableTopics = [];

  // Tutorial
  bool _showTutorial = false;
  List<TutorialStep> _tutorialSteps = [];
  final GlobalKey _heroKey = GlobalKey();
  final GlobalKey _scriptKey = GlobalKey();
  final GlobalKey _statusKey = GlobalKey();
  final GlobalKey _actionsKey = GlobalKey();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    final idea = widget.idea;
    _titleCtrl = TextEditingController(text: idea?.title ?? '');
    _scriptCtrl = TextEditingController(text: idea?.script ?? '');
    _activeStatus = idea?.status ?? 'Draft';
    _ideaId = idea?.id;
    _selectedTags = List<String>.from(idea?.tags ?? []);
    _scriptCtrl.addListener(_handleBulletAutoInsert);
    _titleCtrl.addListener(_onTextChanged);
    _scriptCtrl.addListener(_onTextChanged);
    _loadAvailableTopics();

    // Auto-save immediately when opening with a generated idea that hasn't
    // been persisted yet (no id means it came from the generator, not Firestore).
    if (_ideaId == null && _titleCtrl.text.trim().isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _autoSave());
    }
  }

  Future<void> _loadAvailableTopics() async {
    final uid = _uid;
    if (uid == null) return;
    final signals = await FirestoreService.getSignals(uid);
    if (!mounted) return;
    setState(() {
      _availableTopics = List<String>.from(signals?['topics'] ?? []);
    });
  }

  void _handleBulletAutoInsert() {
    final text = _scriptCtrl.text;
    final cursor = _scriptCtrl.selection.baseOffset;
    if (text.length <= _lastText.length || cursor < 1) {
      _lastText = text;
      return;
    }
    // First character typed into empty field — prepend bullet
    if (_lastText.isEmpty && text.isNotEmpty && !text.startsWith('• ')) {
      final newText = '• $text';
      _scriptCtrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursor + 2),
      );
      _lastText = _scriptCtrl.text;
      return;
    }
    // Enter pressed — add bullet on new line
    if (cursor <= text.length && text[cursor - 1] == '\n') {
      final newText =
          '${text.substring(0, cursor)}• ${text.substring(cursor)}';
      _scriptCtrl.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: cursor + 2),
      );
      _lastText = _scriptCtrl.text;
      return;
    }
    _lastText = text;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _titleCtrl.dispose();
    _scriptCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  void _startTutorial() {
    _buildTutorialSteps();
    setState(() => _showTutorial = true);
  }

  Future<void> _scrollToKey(GlobalKey key) async {
    final ctx = key.currentContext;
    if (ctx == null) return;
    await Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.2, // show the widget near the top of the viewport
    );
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
        eyebrow: 'Workspace',
        title: 'Your idea editing canvas.',
        body: 'This is where you write, refine, and manage your video ideas. Every change saves automatically — just start typing.',
      ),
      TutorialStep(
        eyebrow: 'Idea Title & Tags',
        title: 'Name your idea and tag it.',
        body: 'Type a title to give your idea a name. Tap any topic chip to tag this idea — tags help you filter and organise your pipeline later.',
        onBeforeShow: () => _scrollToKey(_heroKey),
        spotlightRectBuilder: () => rectOf(_heroKey),
      ),
      TutorialStep(
        eyebrow: 'Bullet-point Script',
        title: 'Build your talking points.',
        body: 'Each line is a bullet point for your video. Press Enter to add a new point. Use "AI assist" to generate additional bullets based on your signals.',
        onBeforeShow: () => _scrollToKey(_scriptKey),
        spotlightRectBuilder: () => rectOf(_scriptKey),
      ),
      TutorialStep(
        eyebrow: 'Production Status',
        title: 'Move ideas through your pipeline.',
        body: 'Tap Draft, Script Ready, or Posted to track where this idea is in production. Your home dashboard counts ideas by status.',
        onBeforeShow: () => _scrollToKey(_statusKey),
        spotlightRectBuilder: () => rectOf(_statusKey),
      ),
      TutorialStep(
        eyebrow: 'Actions',
        title: 'Finish up or get more help.',
        body: 'Tap "Done" to save and return home. Tap "AI assist" anytime to let Claude expand your script with more talking points.',
        onBeforeShow: () => _scrollToKey(_actionsKey),
        spotlightRectBuilder: () => rectOf(_actionsKey),
      ),
    ];
  }

  void _onTextChanged() {
    if (_titleCtrl.text.trim().isEmpty) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 1500), _autoSave);
  }

  Future<void> _autoSave() async {
    final uid = _uid;
    if (uid == null || _titleCtrl.text.trim().isEmpty) return;
    setState(() => _saveState = _SaveState.saving);

    // SECURITY (OWASP A03): sanitise before persisting to Firestore.
    final safeTitle = InputValidator.sanitizeAndTruncate(_titleCtrl.text.trim(), 200);
    final safeScript = InputValidator.sanitizeAndTruncate(_scriptCtrl.text, 10000);

    try {
      if (_ideaId == null) {
        final idea = IdeaModel(
          title: safeTitle,
          script: safeScript,
          status: _activeStatus,
          tags: _selectedTags,
          isAIGenerated: widget.idea?.isAIGenerated ?? false,
        );
        _ideaId = await FirestoreService.addIdea(uid, idea);
      } else {
        await FirestoreService.updateIdea(uid, _ideaId!, {
          'title': safeTitle,
          'script': safeScript,
          'status': _activeStatus,
          'tags': _selectedTags,
        });
      }
      if (mounted) setState(() => _saveState = _SaveState.saved);
    } catch (_) {
      if (mounted) setState(() => _saveState = _SaveState.idle);
    }
  }

  Future<void> _aiAssist() async {
    final uid = _uid;
    if (uid == null) return;
    setState(() => _isAssisting = true);
    final signals = await FirestoreService.getSignals(uid);
    final newBullets = await ClaudeService.assistWithScript(
      title: _titleCtrl.text.trim(),
      currentScript: _scriptCtrl.text,
      signals: signals,
    );
    if (!mounted) return;
    setState(() => _isAssisting = false);
    if (newBullets == null || newBullets.trim().isEmpty) return;

    final current = _scriptCtrl.text;
    final separator = current.trim().isEmpty ? '' : '\n';
    _scriptCtrl.text = '$current$separator$newBullets';
    _scriptCtrl.selection = TextSelection.collapsed(
        offset: _scriptCtrl.text.length);
  }

  Widget _saveIndicator() {
    return switch (_saveState) {
      _SaveState.saving => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(strokeWidth: 1.5, color: kMuted),
            ),
            const SizedBox(width: 6),
            Text('Saving...',
                style: GoogleFonts.manrope(
                    fontSize: 11, fontWeight: FontWeight.w600, color: kMuted)),
          ],
        ),
      _SaveState.saved => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_outline, size: 13, color: kTeal),
            const SizedBox(width: 4),
            Text('Saved',
                style: GoogleFonts.manrope(
                    fontSize: 11, fontWeight: FontWeight.w600, color: kTeal)),
          ],
        ),
      _SaveState.idle => Text('Unsaved',
          style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: kMuted.withValues(alpha: 0.6))),
    };
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF8F4F0),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: Text('Remove this idea?',
            style: GoogleFonts.fraunces(
                fontSize: 20, fontWeight: FontWeight.w700, color: kText)),
        content: Text(
            'Archive it to keep a record, or delete it permanently.',
            style: GoogleFonts.manrope(
                fontSize: 14, fontWeight: FontWeight.w500, color: kMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE2E8F0),
              foregroundColor: kText,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final uid = _uid;
              if (uid != null && _ideaId != null) {
                await FirestoreService.archiveIdea(uid, _ideaId!);
              }
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                  context, '/home', (_) => false);
            },
            child: Text('Archive',
                style: GoogleFonts.manrope(
                    fontSize: 14, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () async {
              Navigator.pop(ctx);
              final uid = _uid;
              if (uid != null && _ideaId != null) {
                await FirestoreService.deleteIdea(uid, _ideaId!);
              }
              if (!context.mounted) return;
              Navigator.pushNamedAndRemoveUntil(
                  context, '/home', (_) => false);
            },
            child: Text('Delete',
                style: GoogleFonts.manrope(
                    fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ],
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
            child: AbsorbPointer(
              absorbing: _showTutorial,
              child: SingleChildScrollView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 130),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _topBar(context),
                    const SizedBox(height: 16),
                    _heroCard(),
                    const SizedBox(height: 16),
                    _bulletScript(context),
                    const SizedBox(height: 16),
                    _productionStatus(),
                    const SizedBox(height: 16),
                    _mediaAndActions(context),
                  ],
                ),
              ),
            ),
          ),
          AppTabBar(
            active: TabDest.none,
            fabRoute: '/workspace',
            fabIcon: Icons.edit_outlined,
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

  Widget _topBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/home');
              }
            },
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xCCFFFFFF),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Color(0x140F172A), blurRadius: 8)
                ],
              ),
              child: const Icon(Icons.chevron_left, color: kText),
            ),
          ),
          const Spacer(),
          Column(
            children: [
              Text('WORKSPACE',
                  style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                      color: const Color(0xFF94A3B8))),
              const SizedBox(height: 2),
              Text(_ideaId == null ? 'New Idea' : 'Edit Idea',
                  style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: kText)),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: _startTutorial,
            child: Container(
              width: 44,
              height: 44,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: const Color(0xCCFFFFFF),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Color(0x140F172A), blurRadius: 8)
                ],
              ),
              child: const Icon(Icons.info_outline, color: kMuted, size: 20),
            ),
          ),
          GestureDetector(
            onTap: () => _confirmDelete(context),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDED),
                borderRadius: BorderRadius.circular(18),
                boxShadow: const [
                  BoxShadow(color: Color(0x140F172A), blurRadius: 8)
                ],
              ),
              child: const Icon(Icons.delete_outline,
                  color: Color(0xFFEF4444), size: 20),
            ),
          ),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              RmChip(label: _activeStatus, style: ChipStyle.brand),
              _saveIndicator(),
            ],
          ),
          const SizedBox(height: 16),
          // SECURITY: cap title length before it reaches Firestore.
          TextField(
            controller: _titleCtrl,
            maxLines: null,
            maxLength: 200,
            style: displayTitle(30),
            decoration: InputDecoration(
              counterText: '',
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: 'Idea title...',
              hintStyle: displayTitle(30)
                  .copyWith(color: kMuted.withValues(alpha: 0.4)),
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0x140F172A)),
          const SizedBox(height: 16),
          if (_availableTopics.isEmpty)
            Text(
              _uid == null
                  ? ''
                  : 'No topics yet — import signals to tag ideas.',
              style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: kMuted.withValues(alpha: 0.6)),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _availableTopics.map((topic) {
                final selected = _selectedTags.contains(topic);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (selected) {
                        _selectedTags.remove(topic);
                      } else {
                        _selectedTags.add(topic);
                      }
                    });
                    _onTextChanged();
                  },
                  child: RmChip(
                    label: topic,
                    style: selected ? ChipStyle.brand : ChipStyle.soft,
                  ),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  Widget _bulletScript(BuildContext context) {
    return GlassCard(key: _scriptKey,
      padding: const EdgeInsets.all(18),
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bullet-point script', style: sectionTitle),
          const SizedBox(height: 16),
          // SECURITY: cap script length; 10 000 chars ~ 20 bullets with room to spare.
          TextField(
            controller: _scriptCtrl,
            maxLines: null,
            maxLength: 10000,
            keyboardType: TextInputType.multiline,
            style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: kText,
                height: 1.75),
            decoration: InputDecoration(
              counterText: '',
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: '• Start typing your first point...',
              hintStyle: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kMuted.withValues(alpha: 0.6)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _productionStatus() {
    return GlassCard(key: _statusKey,
      padding: const EdgeInsets.all(18),
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                  child: Text('Production status', style: sectionTitle)),
              const SizedBox(width: 12),
              const RmChip(label: 'Move forward', style: ChipStyle.teal),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _statusStep('Draft'),
              const SizedBox(width: 8),
              _statusStep('Script Ready'),
              const SizedBox(width: 8),
              _statusStep('Posted'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusStep(String label) {
    final isActive = _activeStatus == label;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() => _activeStatus = label);
          _onTextChanged();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isActive ? kBrand : const Color(0xCCFFFFFF),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isActive ? Colors.white : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  Widget _editingLogo() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1C3050), kNavy],
        ),
      ),
      child: Stack(
        children: [
          // Film-strip hole row — top
          Positioned(
            top: 14,
            left: 0,
            right: 0,
            child: _filmStripRow(),
          ),
          // Film-strip hole row — bottom
          Positioned(
            bottom: 14,
            left: 0,
            right: 0,
            child: _filmStripRow(),
          ),
          // Center content
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Glowing edit icon
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: kBrand.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: kBrand.withValues(alpha: 0.30),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.edit_rounded,
                    color: kBrand,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Edit Studio',
                  style: GoogleFonts.fraunces(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your script editing canvas',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.45),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _filmStripRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        9,
        (i) => Container(
          width: 18,
          height: 12,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _mediaAndActions(BuildContext context) {
    return GlassCard(key: _actionsKey,
      padding: const EdgeInsets.all(18),
      borderRadius: 26,
      child: Column(
        children: [
          _editingLogo(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.pushNamedAndRemoveUntil(
                      context, '/home', (_) => false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: const LinearGradient(
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
                        const Icon(Icons.check, color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text('Done',
                            style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: Colors.white)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _isAssisting ? null : _aiAssist,
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
                        if (_isAssisting)
                          const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: kBrandDeep),
                          )
                        else
                          const Icon(Icons.auto_awesome,
                              color: kText, size: 16),
                        const SizedBox(width: 8),
                        Text(_isAssisting ? 'Thinking...' : 'AI assist',
                            style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: kText)),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
