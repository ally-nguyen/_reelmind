import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';

class TutorialStep {
  final String eyebrow;
  final String title;
  final String body;
  /// The screen-space rect to spotlight. Null = no spotlight (centered card).
  final Rect? spotlightRect;

  const TutorialStep({
    required this.eyebrow,
    required this.title,
    required this.body,
    this.spotlightRect,
  });
}

class TutorialOverlay extends StatefulWidget {
  final List<TutorialStep> steps;
  final VoidCallback onComplete;

  const TutorialOverlay({
    super.key,
    required this.steps,
    required this.onComplete,
  });

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay>
    with SingleTickerProviderStateMixin {
  int _step = 0;
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _advance() {
    if (_step < widget.steps.length - 1) {
      _ctrl.reverse().then((_) {
        if (!mounted) return;
        setState(() => _step++);
        _ctrl.forward();
      });
    } else {
      widget.onComplete();
    }
  }

  void _skip() => widget.onComplete();

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final current = widget.steps[_step];
    final isLast = _step == widget.steps.length - 1;

    return FadeTransition(
      opacity: _fade,
      child: Stack(
        children: [
          // Dimmed overlay with spotlight cutout
          CustomPaint(
            size: size,
            painter: _SpotlightPainter(
              spotlightRect: current.spotlightRect,
            ),
          ),
          // Tooltip card
          _buildCard(context, size, current, isLast),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, Size size, TutorialStep step,
      bool isLast) {
    // Position card below spotlight if there is one, above if near bottom,
    // or centered if no spotlight.
    double? top;
    double? bottom;
    final hPad = 24.0;

    if (step.spotlightRect != null) {
      final rect = step.spotlightRect!;
      const cardEstHeight = 220.0;
      const gap = 20.0;
      if (rect.bottom + gap + cardEstHeight < size.height - 120) {
        top = rect.bottom + gap;
      } else {
        bottom = size.height - rect.top + gap;
      }
    } else {
      // Centered vertically
      top = size.height * 0.28;
    }

    return Positioned(
      left: hPad,
      right: hPad,
      top: top,
      bottom: bottom,
      child: Material(
        color: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F4F0),
            borderRadius: BorderRadius.circular(28),
            boxShadow: const [
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 32,
                offset: Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Eyebrow
              Text(
                step.eyebrow.toUpperCase(),
                style: GoogleFonts.manrope(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.8,
                  color: kBrand,
                ),
              ),
              const SizedBox(height: 8),
              // Title
              Text(
                step.title,
                style: GoogleFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: kText,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              // Body
              Text(
                step.body,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kMuted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              // Progress dots + buttons
              Row(
                children: [
                  // Dots
                  Row(
                    children: List.generate(widget.steps.length, (i) {
                      final active = i == _step;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.only(right: 5),
                        width: active ? 18 : 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: active ? kBrand : const Color(0xFFCBD5E1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      );
                    }),
                  ),
                  const Spacer(),
                  // Skip (not on last step)
                  if (!isLast)
                    GestureDetector(
                      onTap: _skip,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 8),
                        child: Text(
                          'Skip',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: kMuted,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  // Next / Done button
                  GestureDetector(
                    onTap: _advance,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 22, vertical: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        gradient: const LinearGradient(
                          colors: [kBrand, Color(0xFFFF7A4C)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                      child: Text(
                        isLast ? 'Done' : 'Next',
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SpotlightPainter extends CustomPainter {
  final Rect? spotlightRect;

  const _SpotlightPainter({this.spotlightRect});

  @override
  void paint(Canvas canvas, Size size) {
    final screenRect = Rect.fromLTWH(0, 0, size.width, size.height);
    final path = Path()..addRect(screenRect);

    if (spotlightRect != null) {
      final rrect = RRect.fromRectAndRadius(
        spotlightRect!.inflate(10),
        const Radius.circular(18),
      );
      path.addRRect(rrect);
    }

    path.fillType = PathFillType.evenOdd;

    canvas.drawPath(
      path,
      Paint()..color = const Color(0xCC0F172A),
    );

    // Glowing border around spotlight
    if (spotlightRect != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          spotlightRect!.inflate(10),
          const Radius.circular(18),
        ),
        Paint()
          ..color = kBrand.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
    }
  }

  @override
  bool shouldRepaint(_SpotlightPainter old) =>
      old.spotlightRect != spotlightRect;
}
