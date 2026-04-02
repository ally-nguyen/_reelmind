import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';

enum TabDest { connect, home, profile, settings, none }

class AppTabBar extends StatelessWidget {
  final TabDest active;
  final String fabRoute;
  final IconData fabIcon;

  const AppTabBar({
    super.key,
    required this.active,
    this.fabRoute = '/workspace',
    this.fabIcon = Icons.add,
  });

  void _navigate(BuildContext context, String route) {
    Navigator.pushReplacementNamed(context, route);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 18,
      right: 18,
      bottom: 18,
      child: SizedBox(
        height: 94,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            // Glass tab bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 68,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xE0FFFFFF),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0x140F172A)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x240F172A),
                      blurRadius: 40,
                      offset: Offset(0, 16),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _tabItem(context, Icons.link, 'Import', '/connect', active == TabDest.connect),
                    _tabItem(context, Icons.home_outlined, 'Home', '/', active == TabDest.home),
                    const SizedBox(width: 52),
                    _tabItem(context, Icons.bar_chart_outlined, 'Profile', '/profile', active == TabDest.profile),
                    _tabItem(context, Icons.settings_outlined, 'Settings', '/settings', active == TabDest.settings),
                  ],
                ),
              ),
            ),
            // Floating FAB
            Positioned(
              top: 0,
              child: GestureDetector(
                onTap: () => _navigate(context, fabRoute),
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFF6B57), Color(0xFFFF8A5C)],
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x47FF6B57),
                        blurRadius: 30,
                        offset: Offset(0, 16),
                      ),
                    ],
                  ),
                  child: Icon(fabIcon, color: Colors.white, size: 22),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabItem(
    BuildContext context,
    IconData icon,
    String label,
    String route,
    bool isActive,
  ) {
    final color = isActive ? kBrandDeep : const Color(0xFF687588);
    return GestureDetector(
      onTap: () => _navigate(context, route),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 56,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
