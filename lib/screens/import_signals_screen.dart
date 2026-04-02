import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';

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
  // Reel links — one controller per link
  final List<TextEditingController> _reelCtrls = [TextEditingController()];

  // Captions — one controller per caption
  final List<TextEditingController> _captionCtrls = [TextEditingController()];

  // Topics
  final Set<String> _selectedTopics = {};
  final _customTopicCtrl = TextEditingController();

  // Creators
  final _creatorCtrl = TextEditingController();
  final List<String> _creators = [];

  @override
  void dispose() {
    for (final c in _reelCtrls) { c.dispose(); }
    for (final c in _captionCtrls) { c.dispose(); }
    _customTopicCtrl.dispose();
    _creatorCtrl.dispose();
    super.dispose();
  }

  void _addReelField() => setState(() => _reelCtrls.add(TextEditingController()));

  void _removeReelField(int i) {
    if (_reelCtrls.length == 1) return;
    setState(() {
      _reelCtrls[i].dispose();
      _reelCtrls.removeAt(i);
    });
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
    final creator = _creatorCtrl.text.trim();
    if (creator.isEmpty || _creators.contains(creator)) return;
    setState(() {
      _creators.add(creator);
      _creatorCtrl.clear();
    });
  }

  void _removeCreator(String creator) {
    setState(() => _creators.remove(creator));
  }

  void _submit() {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Signals saved — generating your profile.',
            style: GoogleFonts.manrope(
                fontSize: 13, fontWeight: FontWeight.w600)),
        backgroundColor: kNavy,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            child: Column(
              children: [
                _header(context),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 32),
                    child: Column(
                      children: [
                        _reelLinksSection(),
                        const SizedBox(height: 16),
                        _captionsSection(),
                        const SizedBox(height: 16),
                        _topicsSection(),
                        const SizedBox(height: 16),
                        _creatorsSection(),
                        const SizedBox(height: 24),
                        _submitButton(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
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

  // ── Section 1: Reel Links ─────────────────────────────────────────────────
  Widget _reelLinksSection() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.link,
            iconColor: kNavy,
            title: 'Reel links',
            subtitle: 'Add one link per field — your own reels or public references.',
          ),
          const SizedBox(height: 14),
          ...List.generate(_reelCtrls.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _entryField(
              controller: _reelCtrls[i],
              hint: 'https://instagram.com/reel/...',
              keyboardType: TextInputType.url,
              index: i + 1,
              canRemove: _reelCtrls.length > 1,
              onRemove: () => _removeReelField(i),
            ),
          )),
          _addFieldButton(label: 'Add another link', onTap: _addReelField),
        ],
      ),
    );
  }

  // ── Section 2: Captions ───────────────────────────────────────────────────
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
            ..._creators.map((c) => _creatorRow(c)),
          ],
        ],
      ),
    );
  }

  Widget _creatorRow(String creator) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xB8FFFFFF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x140F172A)),
        ),
        child: Row(
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
              child: Text(creator,
                  style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kText)),
            ),
            GestureDetector(
              onTap: () => _removeCreator(creator),
              child: const Icon(Icons.close,
                  size: 18, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
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

  Widget _submitButton() {
    return GestureDetector(
      onTap: _submit,
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
            const Icon(Icons.file_download_outlined,
                color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Text('Save & analyze signals',
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
