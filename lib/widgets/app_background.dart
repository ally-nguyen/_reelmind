import 'package:flutter/material.dart';

class AppBackground extends StatelessWidget {
  const AppBackground({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFFFFAF3), Color(0xFFF7F2E9), Color(0xFFF6F4EF)],
              stops: [0.0, 0.45, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 260,
            height: 260,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0xB8FFCBAD), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          top: -60,
          left: -60,
          child: Container(
            width: 220,
            height: 220,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [Color(0x60FFFFFF), Colors.transparent],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
