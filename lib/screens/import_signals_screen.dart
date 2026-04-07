import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../services/firestore_service.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';

class _CreatorEntry {
  final String name;
  final TextEditingController styleCtrl;
  _CreatorEntry({required this.name, String style = ''})
      : styleCtrl = TextEditingController(text: style);
  void dispose() => styleCtrl.dispose();
}

class _VideoEntry {
  final TextEditingController nameCtrl;
  final TextEditingController notesCtrl;
  final String? url;
  final String? storagePath;

  _VideoEntry({
    String name = '',
    String notes = '',
    this.url,
    this.storagePath,
  })  : nameCtrl = TextEditingController(text: name),
        notesCtrl = TextEditingController(text: notes);

  bool get isUploaded => url != null && url!.isNotEmpty;

  void dispose() {
    nameCtrl.dispose();
    notesCtrl.dispose();
  }
}

const _kSuggestedTopics = [
  'Creator economy', 'Productivity', 'Lifestyle', 'Personal finance',
  'Travel', 'Food & recipes', 'Beauty & skincare', 'Fashion', 'Tech & gadgets',
  'Fitness', 'Mindset', 'Education', 'Behind the scenes', 'Day in my life',
  'Tutorial', 'Storytelling', 'Business tips', 'Home & decor',
];

class ImportSignalsScreen extends StatefulWidget {
  const ImportSignalsScreen({super.key});

  @override
  State<ImportSignalsScreen> createState() => _ImportSignalsScreenState();
}

class _ImportSignalsScreenState extends State<ImportSignalsScreen> {
  // Captions — one controller per caption
  final List<TextEditingController> _captionCtrls = [TextEditingController()];

  // Topics
  final Set<String> _selectedTopics = {};
  final _customTopicCtrl = TextEditingController();

  // Creators
  final _creatorCtrl = TextEditingController();
  final List<_CreatorEntry> _creators = [];

  // Videos
  final List<_VideoEntry> _videos = [];

  bool _isAnalyzing = false;
  bool _isLoadingExisting = true;

  @override
  void initState() {
    super.initState();
    _loadExistingSignals();
  }

  Future<void> _loadExistingSignals() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _isLoadingExisting = false);
      return;
    }
    final signals = await FirestoreService.getSignals(uid);
    if (!mounted) return;
    if (signals != null) {
      final captions = List<String>.from(signals['captions'] ?? []);
      final topics = List<String>.from(signals['topics'] ?? []);
      final rawCreators = signals['creators'] ?? [];

      final rawVideos = signals['videos'] ?? [];
      setState(() {
        if (captions.isNotEmpty) {
          for (final c in _captionCtrls) { c.dispose(); }
          _captionCtrls
            ..clear()
            ..addAll(captions.map((t) => TextEditingController(text: t)));
        }
        _selectedTopics
          ..clear()
          ..addAll(topics);
        for (final e in _creators) { e.dispose(); }
        _creators.clear();
        for (final c in rawCreators) {
          if (c is String) {
            _creators.add(_CreatorEntry(name: c));
          } else if (c is Map) {
            _creators.add(_CreatorEntry(
              name: (c['name'] ?? '').toString(),
              style: (c['style'] ?? '').toString(),
            ));
          }
        }
        for (final v in _videos) { v.dispose(); }
        _videos.clear();
        for (final v in rawVideos) {
          if (v is Map) {
            final urlVal = (v['url'] ?? '').toString();
            final pathVal = (v['storagePath'] ?? '').toString();
            _videos.add(_VideoEntry(
              name: (v['name'] ?? '').toString(),
              notes: (v['notes'] ?? '').toString(),
              url: urlVal.isEmpty ? null : urlVal,
              storagePath: pathVal.isEmpty ? null : pathVal,
            ));
          }
        }
      });
    }
    setState(() => _isLoadingExisting = false);
  }

  @override
  void dispose() {
    for (final c in _captionCtrls) { c.dispose(); }
    for (final e in _creators) { e.dispose(); }
    for (final v in _videos) { v.dispose(); }
    _customTopicCtrl.dispose();
    _creatorCtrl.dispose();
    super.dispose();
  }

  void _addCaptionField() => setState(() => _captionCtrls.add(TextEditingController()));

  void _removeCaptionField(int i) {
    if (_captionCtrls.length == 1) return;
    setState(() {
      _captionCtrls[i].dispose();
      _captionCtrls.removeAt(i);
    });
  }

  void _toggleTopic(String topic) {
    setState(() {
      if (_selectedTopics.contains(topic)) {
        _selectedTopics.remove(topic);
      } else {
        _selectedTopics.add(topic);
      }
    });
  }

  void _addCustomTopic() {
    final topic = _customTopicCtrl.text.trim();
    if (topic.isEmpty) return;
    setState(() {
      _selectedTopics.add(topic);
      _customTopicCtrl.clear();
    });
  }

  void _addCreator() {
    final name = _creatorCtrl.text.trim();
    if (name.isEmpty || _creators.any((c) => c.name == name)) return;
    setState(() {
      _creators.add(_CreatorEntry(name: name));
      _creatorCtrl.clear();
    });
  }

  void _removeCreator(int index) {
    setState(() {
      _creators[index].dispose();
      _creators.removeAt(index);
    });
  }

  Future<void> _analyze() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final captions = _captionCtrls
        .map((c) => c.text)
        .where((t) => t.trim().isNotEmpty)
        .toList();
    final topics = _selectedTopics.toList();
    final creatorMaps = _creators
        .map((e) => {'name': e.name, 'style': e.styleCtrl.text.trim()})
        .toList();
    final videoMaps = _videos
        .map((v) => {
              'name': v.nameCtrl.text.trim(),
              'notes': v.notesCtrl.text.trim(),
              'url': v.url ?? '',
              'storagePath': v.storagePath ?? '',
            })
        .toList();

    setState(() => _isAnalyzing = true);

    if (uid != null) {
      await FirestoreService.saveSignals(
        uid,
        captions: captions,
        topics: topics,
        creators: creatorMaps,
        videos: videoMaps,
      );
    }

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: Column(
              children: [
                _header(context),
                Expanded(
                  child: _isLoadingExisting
                      ? const Center(
                          child: CircularProgressIndicator(
                              color: kBrand, strokeWidth: 2))
                      : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
                    child: Column(
                      children: [
                        _captionsSection(),
                        const SizedBox(height: 16),
                        _topicsSection(),
                        const SizedBox(height: 16),
                        _creatorsSection(),
                        const SizedBox(height: 16),
                        _videosSection(),
                        const SizedBox(height: 24),
                        _analyzeButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isAnalyzing) _loadingOverlay(),
        ],
      ),
    );
  }

  Widget _loadingOverlay() {
    return Container(
      color: const Color(0xCC0F172A),
      child: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F4F0),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 40,
                offset: Offset(0, 16),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: kBrand.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(
                    color: kBrand,
                    strokeWidth: 3,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Analyzing your signals',
                style: GoogleFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: kText,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Saving your captions, topics, and creator references so Claude can generate ideas tailored to your style.',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: kMuted,
                  height: 1.55,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
      child: GlassCard(
        padding: const EdgeInsets.fromLTRB(16, 16, 20, 16),
        borderRadius: 26,
        child: Row(
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xB8FFFFFF),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0x140F172A)),
                ),
                child: const Icon(Icons.arrow_back_ios_new,
                    size: 16, color: kText),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('IMPORT SIGNALS', style: eyebrowStyle),
                  const SizedBox(height: 2),
                  Text('Add your content inputs below',
                      style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: kMuted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section 1: Captions ───────────────────────────────────────────────────
  Widget _captionsSection() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.text_fields_outlined,
            iconColor: kBrand,
            title: 'Captions',
            subtitle: 'Add one caption per field so Reel Mind learns your voice and hooks.',
          ),
          const SizedBox(height: 14),
          ...List.generate(_captionCtrls.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _entryField(
              controller: _captionCtrls[i],
              hint: 'Paste a caption from one of your posts...',
              keyboardType: TextInputType.multiline,
              index: i + 1,
              canRemove: _captionCtrls.length > 1,
              onRemove: () => _removeCaptionField(i),
              maxLines: 4,
            ),
          )),
          _addFieldButton(label: 'Add another caption', onTap: _addCaptionField),
        ],
      ),
    );
  }

  // ── Section 3: Topics ─────────────────────────────────────────────────────
  Widget _topicsSection() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.local_fire_department_outlined,
            iconColor: kTeal,
            title: 'Topics',
            subtitle: 'Select topics you create content around, or add your own.',
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kSuggestedTopics.map((topic) {
              final selected = _selectedTopics.contains(topic);
              return GestureDetector(
                onTap: () => _toggleTopic(topic),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? kNavy : const Color(0xB8FFFFFF),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? kNavy
                          : const Color(0x200F172A),
                    ),
                  ),
                  child: Text(topic,
                      style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? Colors.white
                              : kText)),
                ),
              );
            }).toList(),
          ),
          if (_selectedTopics
              .any((t) => !_kSuggestedTopics.contains(t))) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedTopics
                  .where((t) => !_kSuggestedTopics.contains(t))
                  .map((topic) => _customTopicChip(topic))
                  .toList(),
            ),
          ],
          const SizedBox(height: 14),
          Container(height: 1, color: const Color(0x140F172A)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customTopicCtrl,
                  style: GoogleFonts.manrope(
                      fontSize: 14, color: kText),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addCustomTopic(),
                  decoration: InputDecoration(
                    hintText: 'Add your own topic...',
                    hintStyle: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: kMuted.withValues(alpha: 0.6)),
                    filled: true,
                    fillColor: const Color(0xB8FFFFFF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: Color(0x140F172A)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: kBrand, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _addCustomTopic,
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: kBrand,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.add,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _customTopicChip(String topic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: kBrand.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kBrand.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(topic,
              style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kBrandDeep)),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() => _selectedTopics.remove(topic)),
            child: const Icon(Icons.close,
                size: 14, color: kBrandDeep),
          ),
        ],
      ),
    );
  }

  // ── Section 4: Favorite Creators ─────────────────────────────────────────
  Widget _creatorsSection() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.people_outline,
            iconColor: const Color(0xFF7C3AED),
            title: 'Favorite creators',
            subtitle: 'Add creators whose style, hooks, or content inspires you.',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _creatorCtrl,
                  style: GoogleFonts.manrope(
                      fontSize: 14, color: kText),
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _addCreator(),
                  decoration: InputDecoration(
                    hintText: '@username or creator name...',
                    hintStyle: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: kMuted.withValues(alpha: 0.6)),
                    prefixIcon: Icon(Icons.alternate_email,
                        size: 18,
                        color: kMuted.withValues(alpha: 0.7)),
                    filled: true,
                    fillColor: const Color(0xB8FFFFFF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: Color(0x140F172A)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide:
                          const BorderSide(color: kBrand, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _addCreator,
                child: Container(
                  height: 44,
                  width: 44,
                  decoration: BoxDecoration(
                    color: kNavy,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.add,
                      color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
          if (_creators.isNotEmpty) ...[
            const SizedBox(height: 14),
            ...List.generate(_creators.length, (i) => _creatorRow(i)),
          ],
        ],
      ),
    );
  }

  Widget _creatorRow(int index) {
    final entry = _creators[index];
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xB8FFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x140F172A)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: kNavy.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline,
                      size: 16, color: kNavy),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(entry.name,
                      style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kText)),
                ),
                GestureDetector(
                  onTap: () => _removeCreator(index),
                  child: const Icon(Icons.close,
                      size: 18, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: entry.styleCtrl,
              maxLines: 2,
              style: GoogleFonts.manrope(fontSize: 13, color: kText),
              decoration: InputDecoration(
                hintText:
                    'What do you like about their style? (optional)',
                hintStyle: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: kMuted.withValues(alpha: 0.6)),
                filled: true,
                fillColor: const Color(0x0A0F172A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide:
                      const BorderSide(color: kBrand, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                isDense: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Section 5: Video References ──────────────────────────────────────────
  Widget _videosSection() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.videocam_outlined,
            iconColor: const Color(0xFF0F766E),
            title: 'Video references',
            subtitle:
                'Reference videos that capture the pacing, framing, and style you want to replicate.',
          ),
          const SizedBox(height: 14),
          if (_videos.isNotEmpty) ...[
            ...List.generate(_videos.length, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _videoRow(i),
                )),
            const SizedBox(height: 4),
          ],
          _addFieldButton(
              label: 'Add video reference', onTap: _addVideoRow),
        ],
      ),
    );
  }

  void _addVideoRow() => setState(() => _videos.add(_VideoEntry()));

  void _removeVideoRow(int i) {
    setState(() {
      _videos[i].dispose();
      _videos.removeAt(i);
    });
  }

  Widget _videoRow(int index) {
    final entry = _videos[index];
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xB8FFFFFF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x140F172A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: entry.isUploaded
                      ? kTeal.withValues(alpha: 0.10)
                      : kTeal.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  entry.isUploaded
                      ? Icons.check_circle_outline_rounded
                      : Icons.videocam_outlined,
                  size: 16,
                  color: kTeal,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: entry.isUploaded
                    ? Text(
                        entry.nameCtrl.text,
                        style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: kText),
                        overflow: TextOverflow.ellipsis,
                      )
                    : TextField(
                        controller: entry.nameCtrl,
                        style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: kText),
                        decoration: InputDecoration(
                          hintText: 'Video name or filename...',
                          hintStyle: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: kMuted.withValues(alpha: 0.6)),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          isDense: true,
                        ),
                      ),
              ),
              if (entry.isUploaded)
                Container(
                  margin: const EdgeInsets.only(left: 6),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: kTeal.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Uploaded',
                    style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: kTeal,
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => _removeVideoRow(index),
                child: const Icon(Icons.close,
                    size: 18, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: entry.notesCtrl,
            maxLines: 2,
            style: GoogleFonts.manrope(fontSize: 13, color: kText),
            decoration: InputDecoration(
              hintText:
                  'Style notes: framing, pacing, mood, color palette... (optional)',
              hintStyle: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: kMuted.withValues(alpha: 0.6)),
              filled: true,
              fillColor: const Color(0x0A0F172A),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: kBrand, width: 1.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  // ── Shared helpers ────────────────────────────────────────────────────────
  Widget _entryField({
    required TextEditingController controller,
    required String hint,
    required int index,
    required bool canRemove,
    required VoidCallback onRemove,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 28,
          height: 28,
          margin: const EdgeInsets.only(top: 10),
          decoration: BoxDecoration(
            color: const Color(0x1FFF6B57),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Center(
            child: Text('$index',
                style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: kBrandDeep)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: GoogleFonts.manrope(fontSize: 14, color: kText),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: kMuted.withValues(alpha: 0.55)),
              filled: true,
              fillColor: const Color(0xB8FFFFFF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0x140F172A)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: kBrand, width: 1.5),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 12),
              isDense: true,
            ),
          ),
        ),
        if (canRemove) ...[
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(top: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDED),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close,
                  size: 14, color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ],
    );
  }

  Widget _addFieldButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0x1FFF6B57),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Icon(Icons.add, size: 14, color: kBrandDeep),
          ),
          const SizedBox(width: 10),
          Text(label,
              style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kBrandDeep)),
        ],
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.manrope(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: kText)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: kMuted)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _analyzeButton() {
    return GestureDetector(
      onTap: _isAnalyzing ? null : _analyze,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
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
            const Icon(Icons.insights, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text('Analyze signals',
                style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
