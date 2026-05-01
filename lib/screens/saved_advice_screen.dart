import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../models/saved_advice_model.dart';
import '../services/firestore_service.dart';
import '../widgets/app_background.dart';
import '../widgets/glass_card.dart';

class SavedAdviceScreen extends StatefulWidget {
  const SavedAdviceScreen({super.key});

  @override
  State<SavedAdviceScreen> createState() => _SavedAdviceScreenState();
}

class _SavedAdviceScreenState extends State<SavedAdviceScreen> {
  final Set<String> _deleting = {};

  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  String _formatDate(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final date = DateTime(dt.year, dt.month, dt.day);
    final diff = today.difference(date).inDays;

    final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final time = '$hour:$minute $period';

    if (diff == 0) return 'Today at $time';
    if (diff == 1) return 'Yesterday at $time';
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final label = '${months[dt.month - 1]} ${dt.day}';
    return dt.year == now.year ? '$label at $time' : '$label, ${dt.year}';
  }

  Future<void> _unsave(String docId) async {
    final uid = _uid;
    if (uid == null || _deleting.contains(docId)) return;
    setState(() => _deleting.add(docId));
    try {
      await FirestoreService.deleteSavedAdvice(uid, docId);
    } finally {
      if (mounted) setState(() => _deleting.remove(docId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _uid;
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 0),
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
                          child: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 16,
                            color: kText,
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SAVED HOOKS',
                            style: GoogleFonts.manrope(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.8,
                              color: kBrandDeep,
                            ),
                          ),
                          Text(
                            'Your bookmarked hook directions',
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: kText,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: uid == null
                      ? const SizedBox.shrink()
                      : StreamBuilder<List<SavedAdviceModel>>(
                          stream: FirestoreService.savedAdviceStream(uid),
                          builder: (context, snap) {
                            if (snap.connectionState ==
                                ConnectionState.waiting) {
                              return const Center(
                                child: CircularProgressIndicator(color: kBrand),
                              );
                            }
                            final items = snap.data ?? [];
                            if (items.isEmpty) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 18,
                                ),
                                child: GlassCard(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        Icons.bookmark_outline,
                                        size: 36,
                                        color: kMuted,
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No saved hooks yet',
                                        style: GoogleFonts.manrope(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: kText,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Tap "Save" on a What to Try Next hook to keep a direction for later.',
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.manrope(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: kMuted,
                                          height: 1.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }
                            return ListView.separated(
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                0,
                                18,
                                120,
                              ),
                              itemCount: items.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, i) =>
                                  _adviceCard(items[i]),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _adviceCard(SavedAdviceModel item) {
    final baseStyle = GoogleFonts.manrope(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: kText,
      height: 1.7,
    );
    final boldStyle = GoogleFonts.manrope(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      color: kText,
      height: 1.7,
    );

    final spans = <InlineSpan>[];
    for (final line in item.text.trim().split('\n')) {
      if (spans.isNotEmpty) spans.add(const TextSpan(text: '\n'));
      final colon = line.indexOf(':');
      if (colon > 0) {
        spans.add(
          TextSpan(text: line.substring(0, colon + 1), style: boldStyle),
        );
        spans.add(TextSpan(text: line.substring(colon + 1), style: baseStyle));
      } else {
        spans.add(TextSpan(text: line, style: baseStyle));
      }
    }

    final isDeleting = _deleting.contains(item.id);

    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.bookmark, size: 13, color: kBrand),
                  const SizedBox(width: 5),
                  Text(
                    _formatDate(item.savedAt),
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: kMuted,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: isDeleting ? null : () => _unsave(item.id),
                child: isDeleting
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          color: kMuted,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.bookmark_remove_outlined,
                            size: 14,
                            color: kMuted,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'Unsave',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: kMuted,
                            ),
                          ),
                        ],
                      ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          RichText(text: TextSpan(children: spans)),
        ],
      ),
    );
  }
}
