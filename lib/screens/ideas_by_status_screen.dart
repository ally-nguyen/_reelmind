import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../models/idea_model.dart';
import '../services/firestore_service.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';
import '../widgets/rm_chip.dart';
import 'workspace_screen.dart';

ChipStyle _chipStyleFor(String status) {
  switch (status) {
    case 'Script Ready':
      return ChipStyle.teal;
    case 'Posted':
      return ChipStyle.teal;
    default:
      return ChipStyle.brand;
  }
}

class IdeasByStatusScreen extends StatelessWidget {
  final String status;
  const IdeasByStatusScreen({super.key, required this.status});

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

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
                  ? FirestoreService.ideasStream(_uid!)
                  : const Stream.empty(),
              builder: (context, snapshot) {
                final ideas = (snapshot.data ?? [])
                    .where((i) => i.status == status)
                    .toList();
                return Column(
                  children: [
                    _header(context, ideas.length),
                    Expanded(
                      child: ideas.isEmpty
                          ? Center(
                              child: Text(
                                snapshot.connectionState ==
                                        ConnectionState.waiting
                                    ? 'Loading...'
                                    : 'No ideas here yet.',
                                style: GoogleFonts.manrope(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: kMuted),
                              ),
                            )
                          : ListView.separated(
                              padding:
                                  const EdgeInsets.fromLTRB(18, 8, 18, 40),
                              itemCount: ideas.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (_, i) => GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          WorkspaceScreen(idea: ideas[i])),
                                ),
                                child: _ideaCard(ideas[i]),
                              ),
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
            RmChip(label: status, style: _chipStyleFor(status)),
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
              RmChip(label: status, style: _chipStyleFor(status)),
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
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(idea.timeAgoLabel.toUpperCase(),
                  style: GoogleFonts.manrope(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                      color: const Color(0xFF94A3B8))),
              Text(idea.isAIGenerated ? 'AI ASSISTED' : 'MANUAL',
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
