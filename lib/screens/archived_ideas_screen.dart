import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../models/idea_model.dart';
import '../services/app_preferences.dart';
import '../services/firestore_service.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/rm_chip.dart';

class ArchivedIdeasScreen extends StatefulWidget {
  const ArchivedIdeasScreen({super.key});

  @override
  State<ArchivedIdeasScreen> createState() => _ArchivedIdeasScreenState();
}

class _ArchivedIdeasScreenState extends State<ArchivedIdeasScreen> {
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    // Run auto-delete if the preference is enabled
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final uid = _uid;
      if (uid != null && AppPreferences.autoDeleteArchived.value) {
        await FirestoreService.deleteOldArchivedIdeas(uid);
      }
    });
  }

  Future<void> _unarchive(IdeaModel idea) async {
    final uid = _uid;
    final ideaId = idea.id;
    if (uid == null || ideaId == null) return;
    await FirestoreService.unarchiveIdea(uid, ideaId);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${idea.title.isEmpty ? 'Idea' : idea.title}" moved back to active.',
            style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600)),
        backgroundColor: kNavy,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
            child: StreamBuilder<List<IdeaModel>>(
              stream: _uid != null
                  ? FirestoreService.archivedIdeasStream(_uid!)
                  : const Stream.empty(),
              builder: (context, snapshot) {
                final ideas = snapshot.data ?? [];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(context, ideas.length),
                    Expanded(
                      child: snapshot.connectionState ==
                              ConnectionState.waiting
                          ? const Center(child: CircularProgressIndicator())
                          : ideas.isEmpty
                              ? _emptyState()
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(
                                      18, 8, 18, 40),
                                  itemCount: ideas.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (_, i) =>
                                      _ideaCard(ideas[i]),
                                ),
                    ),
                  ],
                );
              },
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
                  Text('ARCHIVED IDEAS', style: eyebrowStyle),
                  const SizedBox(height: 2),
                  Text('Tap the restore button to unarchive',
                      style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: kMuted)),
                ],
              ),
            ),
            RmChip(
              label: '$count total',
              style: ChipStyle.soft,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.archive_outlined,
                size: 48, color: Color(0xFF94A3B8)),
            const SizedBox(height: 16),
            Text(
              'No archived ideas yet',
              style: GoogleFonts.fraunces(
                  fontSize: 20, fontWeight: FontWeight.w700, color: kText),
            ),
            const SizedBox(height: 8),
            Text(
              'When you archive an idea from the workspace, it will appear here.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kMuted,
                  height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ideaCard(IdeaModel idea) {
    return ContentCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                    idea.title.isEmpty ? 'Untitled idea' : idea.title,
                    style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: kText)),
              ),
              const SizedBox(width: 8),
              const RmChip(label: 'Archived', style: ChipStyle.soft),
            ],
          ),
          if (idea.script.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              idea.script.length > 120
                  ? '${idea.script.substring(0, 120)}...'
                  : idea.script,
              style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: kMuted,
                  height: 1.5),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(idea.timeAgoLabel.toUpperCase(),
                  style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                      color: const Color(0xFF94A3B8))),
              // Unarchive button
              GestureDetector(
                onTap: () => _unarchive(idea),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 7),
                  decoration: BoxDecoration(
                    color: kNavy.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: kNavy.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.unarchive_outlined,
                          size: 13, color: kNavy),
                      const SizedBox(width: 5),
                      Text('Restore',
                          style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: kNavy)),
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
}
