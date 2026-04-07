import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_tab_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/rm_chip.dart';
import 'import_signals_screen.dart';

class ConnectScreen extends StatelessWidget {
  const ConnectScreen({super.key});

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
                  _heroCard(context),
                  const SizedBox(height: 16),
                  _whatGetsAnalyzed(),
                  const SizedBox(height: 16),
                  _afterImport(),
                ],
              ),
            ),
          ),
          const AppTabBar(
            active: TabDest.connect,
            fabRoute: '/workspace',
            fabIcon: Icons.add,
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

  Widget _heroCard(BuildContext context) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const RmChip(label: 'Signal Import', style: ChipStyle.brand, icon: Icons.camera_alt_outlined),
            ],
          ),
          const SizedBox(height: 16),
          Text('REEL MIND', style: eyebrowStyle),
          const SizedBox(height: 10),
          Text(
            'Turn your Instagram-inspired signals into your next winning video.',
            style: displayTitle(38),
          ),
          const SizedBox(height: 14),
          Text(
            'Import your own captions, videos, saved topics, and creator references. Reel Mind turns those inputs into a personalized collection of your next best video ideas.',
            style: mutedBodyStyle,
          ),
           const SizedBox(height: 18),
          _importBtn(context),
        ],
      ),
    );
  }

  Widget _whatGetsAnalyzed() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('What gets analyzed',
                        style: GoogleFonts.manrope(
                            fontSize: 14, fontWeight: FontWeight.w800, color: kText)),
                    const SizedBox(height: 4),
                    Text('Share your inspo to shape better video ideas for you.',
                        style: sectionSubtitle),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const RmChip(label: 'Private by design', style: ChipStyle.teal),
            ],
          ),
          const SizedBox(height: 16),
          _analysisItem(
            Icons.favorite_border,
            const Color(0xFF0F1115),
            Colors.white,
            'Upload videos + references',
            'Bring in your own reels and creators you want to study.',
          ),
          const SizedBox(height: 12),
          _analysisItem(
            Icons.movie_creation_outlined,
            kBrand,
            Colors.white,
            'Captions + transcripts',
            'Paste your own words so the app learns your voice, themes, and recurring hooks.',
          ),
          const SizedBox(height: 12),
          _analysisItem(
            Icons.local_fire_department_outlined,
            kTeal,
            Colors.white,
            'Topics',
            'Add niches and recurring themesto guide idea generation.',
          ),
        ],
      ),
    );
  }

  Widget _analysisItem(IconData icon, Color iconBg, Color iconFg, String title, String desc) {
    return ContentCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconFg, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.manrope(
                        fontSize: 14, fontWeight: FontWeight.w800, color: kText)),
                const SizedBox(height: 4),
                Text(desc,
                    style: GoogleFonts.manrope(
                        fontSize: 12, fontWeight: FontWeight.w500, color: kMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _afterImport() {
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
                child: Text('After import',
                    style: GoogleFonts.manrope(
                        fontSize: 14, fontWeight: FontWeight.w800, color: kText)),
              ),
              const SizedBox(width: 12),
              Text('READY INSTANTLY',
                  style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                      color: const Color(0xFF94A3B8))),
            ],
          ),
          const SizedBox(height: 12),
          _afterItem(Icons.storage_outlined,
              'A profile is made for you for fast idea generation and draft memory.'),
          const SizedBox(height: 10),
          _afterItem(Icons.auto_awesome,
              'Tap "Generate for me" to formulate 5–7 bullet points of a brand new scripted idea based on your inspiration.'),
          const SizedBox(height: 10),
          _afterItem(Icons.auto_awesome,
              'Tap "New Idea" to start jotting down your own script for your next video, but if you need assistance, tap "AI Assist" to help build on your existing idea!'),
        ],
      ),
    );
  }

  Widget _afterItem(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xB3FFFFFF),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: const Color(0x1FFF6B57),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Icon(icon, size: 14, color: kBrandDeep),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text,
                style: GoogleFonts.manrope(
                    fontSize: 13, fontWeight: FontWeight.w600, color: kText)),
          ),
        ],
      ),
    );
  }

  Widget _importBtn(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ImportSignalsScreen()),
      ),
      child: Container(
        width: double.infinity,
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
            const Icon(Icons.file_download_outlined,
                color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text('Import my signals',
                style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _secondaryBtn(BuildContext context, IconData icon, String label, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushReplacementNamed(context, route),
      child: Container(
        width: double.infinity,
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
                    fontSize: 14, fontWeight: FontWeight.w800, color: kText)),
          ],
        ),
      ),
    );
  }
}
