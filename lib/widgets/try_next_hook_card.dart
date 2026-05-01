import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../models/try_next_insight.dart';
import 'rm_chip.dart';

class TryNextHookCard extends StatelessWidget {
  final TryNextHook hook;
  final VoidCallback onTap;
  final VoidCallback? onSave;
  final bool isSaved;
  final bool isSaving;

  const TryNextHookCard({
    super.key,
    required this.hook,
    required this.onTap,
    this.onSave,
    this.isSaved = false,
    this.isSaving = false,
  });

  @override
  Widget build(BuildContext context) {
    final isBridge = hook.bridgeTopic != null && hook.bridgeTopic!.isNotEmpty;
    return Material(
      color: const Color(0x8CFFFFFF),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      hook.label,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: kText,
                        height: 1.25,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  RmChip(
                    label: isBridge ? 'Bridge' : hook.targetTopic,
                    style: isBridge ? ChipStyle.teal : ChipStyle.brand,
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                '"${hook.hook}"',
                style: GoogleFonts.fraunces(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: kText,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                hook.reason,
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: kMuted,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 14, color: kBrandDeep),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Generate this direction',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: kBrandDeep,
                      ),
                    ),
                  ),
                  if (onSave != null) ...[
                    const SizedBox(width: 12),
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: isSaved || isSaving ? null : onSave,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSaving)
                            const SizedBox(
                              width: 13,
                              height: 13,
                              child: CircularProgressIndicator(
                                strokeWidth: 1.6,
                                color: kBrand,
                              ),
                            )
                          else
                            Icon(
                              isSaved ? Icons.bookmark : Icons.bookmark_outline,
                              size: 15,
                              color: isSaved ? kBrand : kMuted,
                            ),
                          const SizedBox(width: 4),
                          Text(
                            isSaved ? 'Saved' : 'Save',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isSaved ? kBrand : kMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
