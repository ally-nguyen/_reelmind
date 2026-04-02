import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/rm_chip.dart';

class _Idea {
  final String title;
  final String description;
  final String timeLabel;
  final String typeLabel;
  const _Idea(this.title, this.description, this.timeLabel, this.typeLabel);
}

const _draftIdeas = [
  _Idea(
    'Why I stopped batch filming every Sunday',
    'Explores how rigid schedules kill creative momentum. Hook pulls from caption patterns around burnout and creator workflows.',
    'Edited 1h ago', 'Manual',
  ),
  _Idea(
    'The 3-second hook formula I borrowed from food creators',
    'Cross-niche observation on attention design. Pulling from imported references in the food and lifestyle clusters.',
    'Edited 3h ago', 'AI Assisted',
  ),
  _Idea(
    'How I organize 100+ content ideas without a spreadsheet',
    'Systems-based reel on using tags and status flows inside the app. Strong overlap with creator workflow audience.',
    'Edited yesterday', 'Manual',
  ),
  _Idea(
    'What my first 10 reels taught me about pacing',
    'Reflective storytelling reel. Pulled from early content archive and captioning notes. Good hook potential.',
    'Edited 2 days ago', 'AI Assisted',
  ),
  _Idea(
    'The caption mistake that tanks engagement before anyone watches',
    'Educational content on first-line caption structure. High resonance signal from imported creator references.',
    'Edited 3 days ago', 'Manual',
  ),
  _Idea(
    'How to find your visual identity in 30 minutes',
    'Tutorial-style reel on mood boards and reference curation. Built from taste profile signal around soft luxury and clean aesthetics.',
    'Edited 4 days ago', 'AI Assisted',
  ),
  _Idea(
    'Why more posting doesn\'t mean more growth',
    'Opinion-led reel challenging the volume-over-quality mindset. Strong hook framing from imported creator commentary.',
    'Edited 5 days ago', 'Manual',
  ),
  _Idea(
    'The B-roll shot I use to open every lifestyle reel',
    'Technique breakdown on a single signature shot type. Visual and approachable, strong save-signal potential.',
    'Edited 6 days ago', 'AI Assisted',
  ),
];

const _scriptedIdeas = [
  _Idea(
    'Three framing tweaks that instantly elevate b-roll',
    'Six bullets covering rule of thirds, camera height, and foreground depth. Ready for filming in a single session.',
    'Edited 24 min ago', 'Manual',
  ),
  _Idea(
    'How I use my taste profile to plan content that still feels like me',
    'Narrated b-roll reel with strong personal-brand hook. Six talking points generated from imported caption clusters.',
    'Edited 2h ago', 'AI Assisted',
  ),
  _Idea(
    '5 editing shortcuts that save me hours every week',
    'Tutorial reel covering Premiere Pro and CapCut workflow shortcuts. Strong retention signal from editor community.',
    'Edited yesterday', 'Manual',
  ),
  _Idea(
    'Why the first 3 seconds decide everything',
    'Hook-focused educational reel. Pulls from six top-performing imported reels to illustrate contrast in opening frames.',
    'Edited 2 days ago', 'AI Assisted',
  ),
  _Idea(
    'The gear upgrade that changed my audio quality overnight',
    'Product-led reel on lavalier mic setup. Script written and timed. Ready to record direct-to-camera.',
    'Edited 3 days ago', 'Manual',
  ),
];

const _readyToFilmIdeas = [
  _Idea(
    'How I plan a month of content in one afternoon',
    'Batching workflow walkthrough. Script finalized and b-roll shot list prepared. Location scouted.',
    'Edited 30 min ago', 'AI Assisted',
  ),
  _Idea(
    'The content batching system that actually works',
    'Systems reel on shoot-day preparation and energy management. All bullets reviewed and timed to under 60 seconds.',
    'Edited 4h ago', 'Manual',
  ),
  _Idea(
    'What I wish I knew before my first 1K followers',
    'Growth storytelling reel. Personal narrative scripted with three clear beats. Lighting setup planned.',
    'Edited yesterday', 'AI Assisted',
  ),
  _Idea(
    'Three things I changed after studying my top 5 reels',
    'Analytical reel on pattern recognition across your own content. Script locked, shot list done, backdrop ready.',
    'Edited 2 days ago', 'Manual',
  ),
];

const _postedIdeas = [
  _Idea(
    'Three Best Backpacks to Store Camera Equipment',
    'Hook built from caption patterns and creator references. Strong engagement from gear-focused audience.',
    'Posted Mar 18', 'AI Assisted',
  ),
  _Idea(
    '5 Editing Shortcuts That Save Me Hours Every Week',
    'Tutorial-style reel covering Premiere Pro workflow. High retention rate, strong save signal.',
    'Posted Mar 12', 'Manual',
  ),
  _Idea(
    'How I Plan a Month of Content in One Afternoon',
    'Batching workflow walkthrough. Resonated strongly with aspiring full-time creators.',
    'Posted Mar 5', 'AI Assisted',
  ),
  _Idea(
    '3 Tips to Build Financial Independence as a Creator',
    'Opinion-led reel on creator income strategy. High comment engagement.',
    'Posted Feb 28', 'Manual',
  ),
  _Idea(
    'The Camera Settings I Use for Every Outdoor Shot',
    'Technical deep-dive on aperture, ISO, and ND filters. Pulled from cinematic outdoor reference reels.',
    'Posted Feb 19', 'AI Assisted',
  ),
  _Idea(
    'Why I Stopped Using Presets (And What I Do Instead)',
    'Opinion-led reel on colour grading philosophy. High comment engagement with debaters.',
    'Posted Feb 10', 'Manual',
  ),
  _Idea(
    'Day in My Life: Filming 10 Reels Before Noon',
    'Vlog-format reel batched from a single shoot day. Creator reference hooks shaped pacing.',
    'Posted Jan 30', 'AI Assisted',
  ),
  _Idea(
    'The Gear That Upgraded My Audio Quality Overnight',
    'Product-review reel on lavalier mic setup. Strong click-through to gear links.',
    'Posted Jan 22', 'Manual',
  ),
  _Idea(
    'Three Framing Tweaks That Instantly Elevate B-Roll',
    'Covers rule of thirds, leading lines, and negative space in motion.',
    'Posted Jan 15', 'Manual',
  ),
  _Idea(
    'How I Grew from 0 to 10K Without Paid Ads',
    'Growth storytelling reel with a strong personal-brand hook.',
    'Posted Jan 8', 'AI Assisted',
  ),
  _Idea(
    'My Exact Morning Routine for High-Output Creative Days',
    'Lifestyle reel anchored in productivity. Audience overlap with financial independence cluster.',
    'Posted Dec 31', 'Manual',
  ),
];

List<_Idea> _ideasFor(String status) {
  switch (status) {
    case 'Draft':
      return _draftIdeas;
    case 'Scripted':
      return _scriptedIdeas;
    case 'Ready to Film':
      return _readyToFilmIdeas;
    case 'Posted':
      return _postedIdeas;
    default:
      return [];
  }
}

ChipStyle _chipStyleFor(String status) {
  switch (status) {
    case 'Draft':
      return ChipStyle.brand;
    case 'Scripted':
      return ChipStyle.teal;
    case 'Ready to Film':
      return ChipStyle.soft;
    case 'Posted':
      return ChipStyle.teal;
    default:
      return ChipStyle.soft;
  }
}

class IdeasByStatusScreen extends StatelessWidget {
  final String status;
  const IdeasByStatusScreen({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final ideas = _ideasFor(status);
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: Column(
              children: [
                _header(context, ideas.length),
                Expanded(
                  child: ideas.isEmpty
                      ? Center(
                          child: Text('No ideas here yet.',
                              style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: kMuted)),
                        )
                      : ListView.separated(
                          padding:
                              const EdgeInsets.fromLTRB(18, 8, 18, 40),
                          itemCount: ideas.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 12),
                          itemBuilder: (_, i) => _ideaCard(ideas[i]),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context, int count) {
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
                  Text(status.toUpperCase(), style: eyebrowStyle),
                  const SizedBox(height: 2),
                  Text('$count idea${count == 1 ? '' : 's'}',
                      style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: kMuted)),
                ],
              ),
            ),
            RmChip(
              label: status,
              style: _chipStyleFor(status),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ideaCard(_Idea idea) {
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
              RmChip(label: status, style: _chipStyleFor(status)),
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
              Text(idea.timeLabel.toUpperCase(),
                  style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                      color: const Color(0xFF94A3B8))),
              Text(idea.typeLabel.toUpperCase(),
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
