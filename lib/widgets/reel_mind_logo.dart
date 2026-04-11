// ── reel_mind_logo.dart ───────────────────────────────────────────────────────
//
// HOW TO CHANGE THE LOGO
// ──────────────────────
// 1. Drop your image file into:  assets/images/logo.png
//    (PNG recommended; any format Flutter supports works)
// 2. Hot-restart the app — the image will appear automatically.
//
// If assets/images/logo.png does NOT exist the widget falls back to the
// original hand-drawn reel logo so the app always has something to show.
// ─────────────────────────────────────────────────────────────────────────────

import 'dart:math';
import 'package:flutter/material.dart';
import '../app_theme.dart';

// ── Public widget ─────────────────────────────────────────────────────────────

class ReelMindLogo extends StatelessWidget {
  final double size;

  const ReelMindLogo({super.key, this.size = 88});

  // ── Change this constant to swap the logo asset path ──────────────────────
  static const String _assetPath = 'assets/branding/reel-mind-icon-playwave-512.png';

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.22),
        boxShadow: [
          BoxShadow(
            color: kBrand.withValues(alpha: 0.28),
            blurRadius: 28,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: kNavy.withValues(alpha: 0.18),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.22),
        child: _ImageOrFallback(
          assetPath: _assetPath,
          size: size,
        ),
      ),
    );
  }
}

// ── Image with painted fallback ───────────────────────────────────────────────

class _ImageOrFallback extends StatelessWidget {
  final String assetPath;
  final double size;

  const _ImageOrFallback({
    required this.assetPath,
    required this.size,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.cover,
      // If the asset doesn't exist yet, fall back to the original painted logo.
      errorBuilder: (_, __, ___) => CustomPaint(
        size: Size(size, size),
        painter: _ReelLogoPainter(),
      ),
    );
  }
}

// ── Original painted logo (fallback) ─────────────────────────────────────────

class _ReelLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final center = Offset(cx, cy);
    final r = size.width / 2;

    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF1C3050), kNavy],
        center: Alignment.topLeft,
        radius: 1.2,
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, bgPaint);

    final ringRadius = r * 0.80;
    final ringPaint = Paint()
      ..color = kBrand
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.055;
    canvas.drawCircle(center, ringRadius, ringPaint);

    const holeCount = 8;
    final holeFill = Paint()..color = const Color(0xFFFFFFFF);
    final holeErase = Paint()..color = kNavy;
    for (int i = 0; i < holeCount; i++) {
      final angle = (i / holeCount) * 2 * pi - pi / 2;
      final hx = cx + cos(angle) * ringRadius;
      final hy = cy + sin(angle) * ringRadius;
      canvas.drawCircle(Offset(hx, hy), r * 0.075, holeFill);
      canvas.drawCircle(Offset(hx, hy), r * 0.042, holeErase);
    }

    final spokePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = r * 0.055
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 3; i++) {
      final angle = (i / 3) * 2 * pi - pi / 2;
      canvas.drawLine(
        Offset(cx + cos(angle) * r * 0.24, cy + sin(angle) * r * 0.24),
        Offset(cx + cos(angle) * r * 0.60, cy + sin(angle) * r * 0.60),
        spokePaint,
      );
    }

    final hubGrad = Paint()
      ..shader = RadialGradient(
        colors: [kBrand, kBrandDeep],
      ).createShader(Rect.fromCircle(center: center, radius: r * 0.28));
    canvas.drawCircle(center, r * 0.28, hubGrad);
    canvas.drawCircle(center, r * 0.14, Paint()..color = kNavy);

    _drawSparkle(canvas, Offset(cx + r * 0.52, cy - r * 0.52), r * 0.10);
  }

  void _drawSparkle(Canvas canvas, Offset pos, double sz) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = sz * 0.22
      ..strokeCap = StrokeCap.round;
    for (int i = 0; i < 4; i++) {
      final angle = (i / 4) * 2 * pi;
      canvas.drawLine(
        Offset(
            pos.dx + cos(angle) * sz * 0.3, pos.dy + sin(angle) * sz * 0.3),
        Offset(pos.dx + cos(angle) * sz, pos.dy + sin(angle) * sz),
        paint,
      );
    }
    canvas.drawCircle(pos, sz * 0.18, Paint()..color = kBrand);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
