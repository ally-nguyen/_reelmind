import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/app_tab_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/rm_chip.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

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
                  _statsRow(),
                  const SizedBox(height: 16),
                  _signalThemes(),
                  const SizedBox(height: 16),
                  _recentInspiration(),
                  const SizedBox(height: 16),
                  _bestNextMove(),
                ],
              ),
            ),
          ),
          const AppTabBar(
            active: TabDest.profile,
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
            Icon(Icons.battery_full, size: 16, color: kText),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Image.network(
                  'https://images.unsplash.com/photo-1488426862026-3ee34a7d66df?auto=format&fit=crop&w=500&q=80',
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFD6C3),
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
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
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Reel Mind continuously updates your personal content profile from the inspo references you import so idea generation stays grounded in your actual taste instead of generic prompts.',
            style: mutedBodyStyle,
          ),
        ],
      ),
    );
  }

  Widget _statsRow() {
    return Row(
      children: [
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('TOP AUDIENCE PULL',
                    style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                        color: const Color(0xFF94A3B8))),
                const SizedBox(height: 8),
                Text('Narrated process videos',
                    style: GoogleFonts.manrope(
                        fontSize: 16, fontWeight: FontWeight.w800, color: kText)),
              ],
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GlassCard(
            padding: const EdgeInsets.all(16),
            borderRadius: 22,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('CONTENT GAP',
                    style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                        color: const Color(0xFF94A3B8))),
                const SizedBox(height: 8),
                Text('Personal story hooks',
                    style: GoogleFonts.manrope(
                        fontSize: 16, fontWeight: FontWeight.w800, color: kText)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _signalThemes() {
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
                  Text('Content-style themes', style: sectionTitle),
                  const SizedBox(height: 2),
                  Text('Weighted from creator references and your own reels.',
                      style: sectionSubtitle),
                ]),
              ),
              const SizedBox(width: 12),
              const RmChip(label: 'Live profile', style: ChipStyle.brand),
            ],
          ),
          const SizedBox(height: 20),
          _progressBar('Engineering', 0.92, const Color(0xFF0F172A)),
          const SizedBox(height: 16),
          _progressBar('Home decor', 0.84, kBrand),
          const SizedBox(height: 16),
          _progressBar('Day in the life', 0.71, kTeal),
        ],
      ),
    );
  }

  Widget _progressBar(String label, double value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: GoogleFonts.manrope(
                    fontSize: 13, fontWeight: FontWeight.w700, color: kText)),
            Text('${(value * 100).round()}%',
                style: GoogleFonts.manrope(
                    fontSize: 13, fontWeight: FontWeight.w700, color: kText)),
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
              widthFactor: value,
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

  Widget _recentInspiration() {
    final images = [
      'https://images.unsplash.com/photo-1512436991641-6745cdb1723f?auto=format&fit=crop&w=500&q=80',
      'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?auto=format&fit=crop&w=500&q=80',
      'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=500&q=80',
    ];

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
                  Text('Recent inspiration', style: sectionTitle),
                  const SizedBox(height: 2),
                  Text('Pulled from references and selected content.',
                      style: sectionSubtitle),
                ]),
              ),
              const SizedBox(width: 12),
              const RmChip(label: '18 posts'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: images
                .map((url) => Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                            right: url == images.last ? 0 : 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: AspectRatio(
                            aspectRatio: 0.76,
                            child: Image.network(
                              url,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                  color: const Color(0xFFE2E8F0)),
                            ),
                          ),
                        ),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _bestNextMove() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Best next move', style: sectionTitle),
              const Icon(Icons.trending_up, color: kBrandDeep, size: 20),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Generate more first-person videos that connect your polished visuals to a personal decision, routine, or lesson. That is the clearest opening for growth in your current profile.',
            style: GoogleFonts.manrope(
                fontSize: 14, fontWeight: FontWeight.w600, color: kText, height: 1.6),
          ),
        ],
      ),
    );
  }
}
