import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_tab_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/rm_chip.dart';
import 'ideas_by_status_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
                  _statsRow(context),
                  const SizedBox(height: 16),
                  _recentIdeas(context),
                  const SizedBox(height: 16),
                  _tasteProfilePulse(context),
                ],
              ),
            ),
          ),
          const AppTabBar(
            active: TabDest.home,
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

  Widget _heroCard(BuildContext context) {
    return GlassCard(
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
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  'https://images.unsplash.com/photo-1524504388940-b1c1722653e1?auto=format&fit=crop&w=300&q=80',
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD6C3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '24 saved ideas, sorted by recency and production status. Your latest import pulled new hooks from captions, reel links, creator references, and saved topic clusters.',
            style: mutedBodyStyle,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _primaryBtn(context, Icons.auto_awesome, 'Generate for me', '/generator')),
              const SizedBox(width: 12),
              Expanded(child: _secondaryBtn(context, Icons.edit_outlined, 'New idea', '/workspace')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _statCard(context, 'DRAFT', 'Draft', '08', 'Fresh concepts')),
        const SizedBox(width: 12),
        Expanded(child: _statCard(context, 'SCRIPTED', 'Scripted', '05', 'Ready to film')),
        const SizedBox(width: 12),
        Expanded(child: _statCard(context, 'POSTED', 'Posted', '11', 'Recent wins')),
      ],
    );
  }

  Widget _statCard(BuildContext context, String label, String status,
      String value, String subtitle) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => IdeasByStatusScreen(status: status)),
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
                Text(label,
                    style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                        color: const Color(0xFF94A3B8))),
                const Icon(Icons.chevron_right,
                    size: 14, color: kBrand),
              ],
            ),
            const SizedBox(height: 8),
            Text(value,
                style: GoogleFonts.manrope(
                    fontSize: 30, fontWeight: FontWeight.w800, color: kText)),
            const SizedBox(height: 4),
            Text(subtitle,
                style: GoogleFonts.manrope(
                    fontSize: 11, fontWeight: FontWeight.w500, color: kMuted)),
          ],
        ),
      ),
    );
  }

  Widget _recentIdeas(BuildContext context) {
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
                    Text('Recent ideas', style: sectionTitle),
                    const SizedBox(height: 2),
                    Text('Sorted by status and most recent edits.', style: sectionSubtitle),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const RmChip(label: 'Imported 8m ago', style: ChipStyle.soft),
            ],
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/generator'),
            child: _ideaItem(
              'Three Best Backpacks to Store Camera Equipemnt',
              ChipStyle.brand,
              'Scripted',
              'Hook built from your caption patterns and creator references. Six bullets ready for a talking-head reel.',
              'Edited 24 min ago',
              'AI Assisted',
            ),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/workspace'),
            child: _ideaItem(
              'Three framing tweaks that instantly elevate b-roll',
              ChipStyle.teal,
              'Draft',
              'Manual idea started from a saved note. Structure still open with rough bullet placeholders.',
              'Edited yesterday',
              'Manual',
            ),
          ),
          const SizedBox(height: 12),
          _ideaItem(
            '3 Tips to Build Financial Independence',
            ChipStyle.soft,
            'Filmed',
            'Ready for captioning and export. Audience signal shows strong resonance with constraint-driven advice.',
            'Edited 2 days ago',
            'Manual',
          ),
        ],
      ),
    );
  }

  Widget _ideaItem(
    String title,
    ChipStyle chipStyle,
    String chipLabel,
    String description,
    String editedLabel,
    String typeLabel,
  ) {
    return ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(title,
                    style: GoogleFonts.manrope(
                        fontSize: 14, fontWeight: FontWeight.w800, color: kText)),
              ),
              const SizedBox(width: 8),
              RmChip(label: chipLabel, style: chipStyle),
            ],
          ),
          const SizedBox(height: 8),
          Text(description,
              style: GoogleFonts.manrope(
                  fontSize: 13, fontWeight: FontWeight.w500, color: kMuted, height: 1.5)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(editedLabel.toUpperCase(),
                  style: GoogleFonts.manrope(
                      fontSize: 10, fontWeight: FontWeight.w800,
                      letterSpacing: 1.6, color: const Color(0xFF94A3B8))),
              Text(typeLabel.toUpperCase(),
                  style: GoogleFonts.manrope(
                      fontSize: 10, fontWeight: FontWeight.w800,
                      letterSpacing: 1.6, color: const Color(0xFF94A3B8))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tasteProfilePulse(BuildContext context) {
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
                    Text('What your imported references are hinting this week.',
                        style: sectionSubtitle),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              GestureDetector(
                onTap: () => Navigator.pushReplacementNamed(context, '/profile'),
                child: Text('View all',
                    style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: kBrandDeep)),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              RmChip(label: 'Engineering'),
              RmChip(label: 'Home decor'),
              RmChip(label: 'Creator workflow'),
              RmChip(label: 'Financial tips'),
              RmChip(label: 'Day in my life'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _primaryBtn(BuildContext context, IconData icon, String label, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
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
            BoxShadow(color: Color(0x47FF6B57), blurRadius: 28, offset: Offset(0, 16)),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(label,
                style: GoogleFonts.manrope(
                    fontSize: 14, fontWeight: FontWeight.w800, color: Colors.white)),
          ],
        ),
      ),
    );
  }

  Widget _secondaryBtn(BuildContext context, IconData icon, String label, String route) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, route),
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
                    fontSize: 14, fontWeight: FontWeight.w800, color: kText)),
          ],
        ),
      ),
    );
  }
}
