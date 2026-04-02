import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_tab_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/rm_chip.dart';

class WorkspaceScreen extends StatefulWidget {
  const WorkspaceScreen({super.key});

  @override
  State<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends State<WorkspaceScreen> {
  final _titleCtrl = TextEditingController(
    text: 'Three framing tweaks that instantly elevate b-roll',
  );
  final _scriptCtrl = TextEditingController(
    text: '• Open by showing the same clip twice: one flat frame and one upgraded frame.\n'
        '• Explain how camera height changes the feeling of a shot in seconds.\n'
        '• Demonstrate one foreground element that adds depth without clutter.',
  );
  String _activeStatus = 'Draft';

  @override
  void initState() {
    super.initState();
    _scriptCtrl.addListener(_handleBulletAutoInsert);
  }

  String _lastText = '';

  void _handleBulletAutoInsert() {
    final text = _scriptCtrl.text;
    final cursor = _scriptCtrl.selection.baseOffset;

    // Only react to insertions (text grew) and cursor is valid
    if (text.length <= _lastText.length || cursor < 1) {
      _lastText = text;
      return;
    }

    // Check if the character just typed was a newline
    if (cursor <= text.length && text[cursor - 1] == '\n') {
      final newText = '${text.substring(0, cursor)}• ${text.substring(cursor)}';
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
    _titleCtrl.dispose();
    _scriptCtrl.dispose();
    super.dispose();
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF8F4F0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: Text('Delete idea?',
            style: GoogleFonts.fraunces(
                fontSize: 20, fontWeight: FontWeight.w700, color: kText)),
        content: Text(
            'This draft will be permanently deleted and cannot be recovered.',
            style: GoogleFonts.manrope(
                fontSize: 14, fontWeight: FontWeight.w500, color: kMuted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.manrope(
                    fontSize: 14, fontWeight: FontWeight.w600, color: kMuted)),
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
            onPressed: () {
              Navigator.pop(ctx);
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              } else {
                Navigator.pushReplacementNamed(context, '/');
              }
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
            child: SingleChildScrollView(
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
          const AppTabBar(
            active: TabDest.none,
            fabRoute: '/workspace',
            fabIcon: Icons.edit_outlined,
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
                Navigator.pushReplacementNamed(context, '/');
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
              Text('MANUAL WORKSPACE',
                  style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.8,
                      color: const Color(0xFF94A3B8))),
              const SizedBox(height: 2),
              Text('New Idea',
                  style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: kText)),
            ],
          ),
          const Spacer(),
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
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const RmChip(label: 'Draft', style: ChipStyle.brand),
              Row(children: const [
                RmChip(label: 'Autosaved'),
                SizedBox(width: 8),
                RmChip(label: 'Archive'),
              ]),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            maxLines: null,
            style: displayTitle(30),
            decoration: InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
              hintText: 'Idea title...',
              hintStyle: displayTitle(30).copyWith(
                  color: kMuted.withValues(alpha: 0.4)),
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: const Color(0x140F172A)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              RmChip(label: 'Creator tips'),
              RmChip(label: 'B-roll'),
              RmChip(label: 'Editing'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _bulletScript(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bullet-point script', style: sectionTitle),
          const SizedBox(height: 16),
          TextField(
            controller: _scriptCtrl,
            maxLines: null,
            keyboardType: TextInputType.multiline,
            style: GoogleFonts.manrope(
                fontSize: 14, fontWeight: FontWeight.w500, color: kText, height: 1.75),
            decoration: InputDecoration(
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
              _statusStep('Scripted'),
              const SizedBox(width: 8),
              _statusStep('Ready to Film'),
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
        onTap: () => setState(() => _activeStatus = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
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

  Widget _mediaAndActions(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 26,
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.network(
              'https://images.unsplash.com/photo-1516321318423-f06f85e504b3?auto=format&fit=crop&w=900&q=80',
              width: double.infinity,
              height: 180,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 180,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () =>
                      Navigator.pushReplacementNamed(context, '/'),
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
                        const Icon(Icons.save_outlined,
                            color: Colors.white, size: 16),
                        const SizedBox(width: 8),
                        Text('Save draft',
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
                  onTap: () =>
                      Navigator.pushNamed(context, '/generator'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: const Color(0xB8FFFFFF),
                      borderRadius: BorderRadius.circular(18),
                      border:
                          Border.all(color: const Color(0x140F172A)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome,
                            color: kText, size: 16),
                        const SizedBox(width: 8),
                        Text('AI assist',
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
