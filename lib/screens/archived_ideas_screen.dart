import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/rm_chip.dart';

class _ArchivedIdea {
  final String title;
  final String description;
  final String postedDate;
  final String type;

  const _ArchivedIdea({
    required this.title,
    required this.description,
    required this.postedDate,
    required this.type,
  });
}

const _kArchivedIdeas = [
  _ArchivedIdea(
    title: 'Three Best Backpacks to Store Camera Equipment',
    description:
        'Hook built from caption patterns and creator references. Six bullets filmed as a talking-head reel. Performed well with gear-focused audience.',
    postedDate: 'Posted Mar 18',
    type: 'AI Assisted',
  ),
  _ArchivedIdea(
    title: '5 Editing Shortcuts That Save Me Hours Every Week',
    description:
        'Tutorial-style reel covering Premiere Pro workflow. Strong retention rate, high save signal from editor community.',
    postedDate: 'Posted Mar 12',
    type: 'Manual',
  ),
  _ArchivedIdea(
    title: 'How I Plan a Month of Content in One Afternoon',
    description:
        'Batching workflow walkthrough. Generated from imported creator reference cluster. Resonated strongly with aspiring full-time creators.',
    postedDate: 'Posted Mar 5',
    type: 'AI Assisted',
  ),
  _ArchivedIdea(
    title: '3 Tips to Build Financial Independence as a Creator',
    description:
        'Captioning complete, audience signal shows strong resonance with constraint-driven financial advice.',
    postedDate: 'Posted Feb 28',
    type: 'Manual',
  ),
  _ArchivedIdea(
    title: 'The Camera Settings I Use for Every Outdoor Shot',
    description:
        'Technical deep-dive on aperture, ISO, and ND filters. Pulled from saved reference reels on cinematic outdoor content.',
    postedDate: 'Posted Feb 19',
    type: 'AI Assisted',
  ),
  _ArchivedIdea(
    title: 'Why I Stopped Using Presets (And What I Do Instead)',
    description:
        'Opinion-led reel on colour grading philosophy. Written manually, high comment engagement with debaters.',
    postedDate: 'Posted Feb 10',
    type: 'Manual',
  ),
  _ArchivedIdea(
    title: 'Day in My Life: Filming 10 Reels Before Noon',
    description:
        'Vlog-format reel batched from a single shoot day. Creator reference hooks shaped the pacing and hook structure.',
    postedDate: 'Posted Jan 30',
    type: 'AI Assisted',
  ),
  _ArchivedIdea(
    title: 'The Gear That Upgraded My Audio Quality Overnight',
    description:
        'Product-review reel on lavalier mic setup. Strong click-through to gear links, saved by audio-focused creators.',
    postedDate: 'Posted Jan 22',
    type: 'Manual',
  ),
  _ArchivedIdea(
    title: 'Three Framing Tweaks That Instantly Elevate B-Roll',
    description:
        'Manual idea started from a saved note. Covers rule of thirds, leading lines, and negative space in motion.',
    postedDate: 'Posted Jan 15',
    type: 'Manual',
  ),
  _ArchivedIdea(
    title: 'How I Grew from 0 to 10K Without Paid Ads',
    description:
        'Growth storytelling reel with a strong personal-brand hook. Referenced three top-performing creator caption structures.',
    postedDate: 'Posted Jan 8',
    type: 'AI Assisted',
  ),
  _ArchivedIdea(
    title: 'My Exact Morning Routine for High-Output Creative Days',
    description:
        'Lifestyle reel anchored in productivity. Audience overlap with financial independence and creator workflow clusters.',
    postedDate: 'Posted Dec 31',
    type: 'Manual',
  ),
];

class ArchivedIdeasScreen extends StatelessWidget {
  const ArchivedIdeasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(context),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
                    itemCount: _kArchivedIdeas.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _ideaCard(_kArchivedIdeas[i]),
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
                  Text('ARCHIVED IDEAS', style: eyebrowStyle),
                  const SizedBox(height: 2),
                  Text('Posted ideas — all time',
                      style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: kMuted)),
                ],
              ),
            ),
            RmChip(
              label: '${_kArchivedIdeas.length} total',
              style: ChipStyle.soft,
            ),
          ],
        ),
      ),
    );
  }

  Widget _ideaCard(_ArchivedIdea idea) {
    return ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(idea.title,
                    style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: kText)),
              ),
              const SizedBox(width: 8),
              const RmChip(label: 'Posted', style: ChipStyle.teal),
            ],
          ),
          const SizedBox(height: 8),
          Text(idea.description,
              style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: kMuted,
                  height: 1.5)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(idea.postedDate.toUpperCase(),
                  style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                      color: const Color(0xFF94A3B8))),
              Text(idea.type.toUpperCase(),
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
}
