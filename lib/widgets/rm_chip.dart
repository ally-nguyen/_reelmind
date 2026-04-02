import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';

enum ChipStyle { soft, brand, teal }

class RmChip extends StatelessWidget {
  final String label;
  final ChipStyle style;
  final IconData? icon;

  const RmChip({
    super.key,
    required this.label,
    this.style = ChipStyle.soft,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    final Color fg;
    final Border? border;

    switch (style) {
      case ChipStyle.brand:
        bg = const Color(0x1FFF6B57);
        fg = kBrandDeep;
        border = null;
        break;
      case ChipStyle.teal:
        bg = const Color(0x240F766E);
        fg = kTeal;
        border = null;
        break;
      case ChipStyle.soft:
        bg = const Color(0xCCFFFFFF);
        fg = kText;
        border = Border.all(color: const Color(0x140F172A));
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
        border: border,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
