import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_tab_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/rm_chip.dart';

class GeneratorScreen extends StatefulWidget {
  const GeneratorScreen({super.key});

  @override
  State<GeneratorScreen> createState() => _GeneratorScreenState();
}

class _GeneratorScreenState extends State<GeneratorScreen> {
  void _showRegenerateSheet() {
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
              Text('Regenerate idea',
                  style: GoogleFonts.fraunces(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: kText)),
              const SizedBox(height: 6),
              Text(
                  'AI will generate a new idea based on your taste profile. Add a direction below to guide it.',
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
                      'Optional — add a topic, direction, or constraint...',
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
                    backgroundColor: kNavy,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushReplacementNamed(context, '/generator');
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome,
                          size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Text('Generate',
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
                  _statusBar(),
                  const SizedBox(height: 4),
                  _heroCard(),
                  const SizedBox(height: 16),
                  _generatedScript(),
                  const SizedBox(height: 16),
                  _generationInputs(),
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
            Icon(Icons.battery_3_bar, size: 16, color: kText),
          ]),
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
            children: const [
              RmChip(
                label: 'Cloud Function',
                style: ChipStyle.brand,
                icon: Icons.auto_awesome,
              ),
              RmChip(label: 'Claude Ready'),
            ],
          ),
          const SizedBox(height: 16),
          Text('GENERATED FOR YOU', style: eyebrowStyle),
          const SizedBox(height: 10),
          Text(
            'How I use my taste profile to plan content that still feels like me',
            style: displayTitle(32),
          ),
          const SizedBox(height: 14),
          Text(
            'Based on your imported captions, creator references, topic tags, and your own tutorial reels. This draft is already pre-loaded into the editor for quick tweaking.',
            style: mutedBodyStyle,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              RmChip(label: '#creatorbusiness'),
              RmChip(label: '#reelsstrategy'),
              RmChip(label: 'Audience hook'),
              RmChip(label: 'Narrated b-roll'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _generatedScript() {
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
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Generated script', style: sectionTitle),
                  const SizedBox(height: 2),
                  Text('Six talking points, ready to refine.', style: sectionSubtitle),
                ]),
              ),
              const SizedBox(width: 12),
              const RmChip(label: 'Scripted', style: ChipStyle.teal),
            ],
          ),
          const SizedBox(height: 16),
          _bulletRow('1',
              'Start with the frustration: "I stopped forcing trends that never matched my taste."'),
          _divider(),
          _bulletRow('2',
              'Explain that your saved references already reveal the visual language you naturally come back to.'),
          _divider(),
          _bulletRow('3',
              'Call out the repeated patterns: clean styling, calm pacing, behind-the-scenes honesty.'),
          _divider(),
          _bulletRow('4',
              'Show how you turn those patterns into a content angle instead of copying someone else.'),
          _divider(),
          _bulletRow('5',
              'Offer one fast takeaway viewers can use to mine their own captions and saved references for ideas.'),
          _divider(),
          _bulletRow('6',
              'Close with a grounded CTA: "Make content that sounds like you, not just what is trending."'),
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
                    fontSize: 12, fontWeight: FontWeight.w800, color: kBrandDeep),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: GoogleFonts.manrope(
                    fontSize: 14, fontWeight: FontWeight.w600, color: kText)),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(height: 1, color: const Color(0x140F172A));
  }

  Widget _generationInputs() {
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
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Generation inputs', style: sectionTitle),
                  const SizedBox(height: 2),
                  Text('User-provided signals bundled into the prompt.',
                      style: sectionSubtitle),
                ]),
              ),
              const SizedBox(width: 12),
              const RmChip(label: 'Last 30 days'),
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
                      Text('REFERENCE IMPORTS',
                          style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                              color: const Color(0xFF94A3B8))),
                      const SizedBox(height: 8),
                      Text('Soft luxury, routine edits, polished tutorials',
                          style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: kText)),
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
                      Text('YOUR CONTENT',
                          style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.6,
                              color: const Color(0xFF94A3B8))),
                      const SizedBox(height: 8),
                      Text(
                          'Direct-to-camera teaching with aspirational b-roll and caption notes',
                          style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: kText)),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
              onTap: () => Navigator.pushNamed(context, '/workspace'),
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
                    const Icon(Icons.edit_outlined, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text('Tweak in editor',
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
                    Text('Generate another',
                        style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: kText)),
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
