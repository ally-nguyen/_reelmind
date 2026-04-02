import 'package:flutter/material.dart';

class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(22),
    this.borderRadius = 32,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xDBFFFFFF),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0x140F172A)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1E122033),
            blurRadius: 45,
            offset: Offset(0, 18),
          ),
        ],
      ),
      child: child,
    );
  }
}

class ContentCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  const ContentCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: const Color(0xB8FFFFFF),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: const Color(0x0F0F172A)),
      ),
      child: child,
    );
  }
}
