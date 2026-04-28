import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../app_theme.dart';

// ── Google Sign-In ────────────────────────────────────────────────────────────

/// Signs in with Google and returns the [UserCredential], or null if the user
/// cancelled. Throws on error so callers can show an appropriate snack bar.
Future<UserCredential?> signInWithGoogle() async {
  final gsi = GoogleSignIn(scopes: const ['email']);
  await gsi.signOut(); // clear cached account so picker always shows
  final googleUser = await gsi.signIn();
  if (googleUser == null) return null; // user cancelled

  final googleAuth = await googleUser.authentication;
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );
  return FirebaseAuth.instance.signInWithCredential(credential);
}

/// A styled "Continue with Google" button that calls [onPressed].
Widget googleSignInButton({required VoidCallback? onPressed}) {
  return SizedBox(
    width: double.infinity,
    child: OutlinedButton(
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: const BorderSide(color: Color(0x330F172A)),
        backgroundColor: Colors.white,
      ),
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Google "G" drawn with coloured quadrants
          SizedBox(
            width: 20,
            height: 20,
            child: CustomPaint(painter: _GoogleGPainter()),
          ),
          const SizedBox(width: 10),
          Text(
            'Continue with Google',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: kText,
            ),
          ),
        ],
      ),
    ),
  );
}

/// A thin "— or —" row divider used between the email form and social buttons.
Widget orDivider() {
  return Row(
    children: [
      const Expanded(child: Divider(color: Color(0x330F172A))),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Text(
          'or',
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: kMuted,
          ),
        ),
      ),
      const Expanded(child: Divider(color: Color(0x330F172A))),
    ],
  );
}

/// Paints a simple 4-colour Google "G" logo.
class _GoogleGPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final rect = Rect.fromCircle(center: Offset(r, r), radius: r);

    void arc(double start, double sweep, Color color) {
      canvas.drawArc(rect, start, sweep, true, Paint()..color = color);
    }

    // Approximate Google colours per quadrant
    arc(-0.5, 1.6, const Color(0xFF4285F4)); // blue – top-right
    arc(1.1, 1.6, const Color(0xFF34A853)); // green – bottom-right
    arc(2.7, 1.6, const Color(0xFFFBBC05)); // yellow – bottom-left
    arc(4.3, 1.6, const Color(0xFFEA4335)); // red – top-left

    // White centre circle to make it a ring
    canvas.drawCircle(Offset(r, r), r * 0.55, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ── Prototype-style glass card ────────────────────────────────────────────────

Widget glassCard({
  required Widget child,
  EdgeInsets padding = const EdgeInsets.all(22),
  double radius = 32,
}) {
  return Container(
    width: double.infinity,
    padding: padding,
    decoration: BoxDecoration(
      color: const Color(0xDBFFFFFF),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: const Color(0x140F172A)),
      boxShadow: const [
        BoxShadow(
          color: Color(0x1F122033),
          blurRadius: 45,
          offset: Offset(0, 18),
        ),
      ],
    ),
    child: child,
  );
}

// ── Chips ─────────────────────────────────────────────────────────────────────

Widget brandChip(String label) =>
    _chip(label, bgColor: const Color(0x1FFF6B57), textColor: kBrandDeep);

Widget softChip(String label) => _chip(
  label,
  bgColor: Color.fromRGBO(255, 255, 255, 0.80),
  textColor: kMuted,
  hasBorder: true,
);

Widget _chip(
  String label, {
  required Color bgColor,
  required Color textColor,
  bool hasBorder = false,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    decoration: BoxDecoration(
      color: bgColor,
      borderRadius: BorderRadius.circular(999),
      border: hasBorder ? Border.all(color: const Color(0x140F172A)) : null,
    ),
    child: Text(
      label,
      style: GoogleFonts.manrope(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: textColor,
      ),
    ),
  );
}

// ── Prototype-style form field ────────────────────────────────────────────────

Widget protoField({
  required String label,
  required TextEditingController controller,
  TextInputType keyboardType = TextInputType.text,
  bool isPassword = false,
  bool obscure = false,
  VoidCallback? onToggleObscure,
  String? hint,
  String? Function(String?)? validator,
}) {
  return Container(
    decoration: BoxDecoration(
      color: Color.fromRGBO(255, 255, 255, 0.80),
      borderRadius: BorderRadius.circular(22),
    ),
    padding: const EdgeInsets.fromLTRB(16, 12, 4, 0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
            color: const Color(0xFF94A3B8),
          ),
        ),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: controller,
                keyboardType: keyboardType,
                obscureText: obscure,
                validator: validator,
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: kText,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  hintText: hint,
                  hintStyle: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF94A3B8),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  isDense: true,
                ),
              ),
            ),
            if (isPassword && onToggleObscure != null)
              IconButton(
                icon: Icon(
                  obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: kMuted,
                ),
                onPressed: onToggleObscure,
              ),
          ],
        ),
      ],
    ),
  );
}

// ── Shared survey helpers ─────────────────────────────────────────────────────

Widget surveyNavRow({
  required BuildContext context,
  required String step,
  required String chipLabel,
  VoidCallback? onBack,
}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      GestureDetector(
        onTap: onBack ?? () => Navigator.pop(context),
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Color.fromRGBO(255, 255, 255, 0.80),
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x14122033),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: const Icon(Icons.chevron_left_rounded, color: kText, size: 22),
        ),
      ),
      Column(
        children: [
          Text(
            'STYLE SURVEY',
            style: GoogleFonts.manrope(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
              color: const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            step,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: kText,
            ),
          ),
        ],
      ),
      softChip(chipLabel),
    ],
  );
}

Widget surveyHeroCard({
  required String eyebrow,
  required String title,
  required String description,
  double titleSize = 32,
}) {
  return glassCard(
    padding: const EdgeInsets.all(22),
    radius: 32,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 2.4,
            color: kBrandDeep,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          title,
          style: GoogleFonts.fraunces(
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.04 * titleSize,
            color: kText,
            height: 1.02,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description,
          style: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: kMuted,
            height: 1.6,
          ),
        ),
      ],
    ),
  );
}

Widget surveyPrimaryButton({
  required String label,
  required IconData icon,
  required VoidCallback? onPressed,
  bool isLoading = false,
}) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: kBrand,
        foregroundColor: Colors.white,
        disabledBackgroundColor: kBrand.withValues(alpha: 0.6),
        elevation: 0,
        padding: const EdgeInsets.symmetric(vertical: 15),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        shadowColor: kBrand.withValues(alpha: 0.28),
      ).copyWith(elevation: WidgetStateProperty.all(8)),
      onPressed: onPressed,
      child: isLoading
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
    ),
  );
}

// ── "idea item" card (used in survey creator/video lists) ─────────────────────

Widget ideaItem({required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Color.fromRGBO(255, 255, 255, 0.72),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0x0F122033)),
    ),
    child: child,
  );
}

Widget authCard({required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(
      color: const Color(0xDBFFFFFF),
      borderRadius: BorderRadius.circular(28),
      border: Border.all(color: const Color(0x140F172A)),
      boxShadow: [
        BoxShadow(
          color: kNavy.withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    ),
    child: child,
  );
}

Widget authField({
  required TextEditingController controller,
  required String label,
  TextInputType keyboardType = TextInputType.text,
  required IconData prefixIcon,
  bool? obscure,
  VoidCallback? onToggleObscure,
  String? Function(String?)? validator,
}) {
  return TextFormField(
    controller: controller,
    keyboardType: keyboardType,
    obscureText: obscure ?? false,
    style: GoogleFonts.manrope(fontSize: 14, color: kText),
    validator: validator,
    decoration: InputDecoration(
      labelText: label,
      labelStyle: GoogleFonts.manrope(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: kMuted,
      ),
      prefixIcon: Icon(prefixIcon, size: 18, color: kMuted),
      suffixIcon: obscure != null
          ? IconButton(
              icon: Icon(
                obscure ? Icons.visibility_off : Icons.visibility,
                size: 18,
                color: kMuted,
              ),
              onPressed: onToggleObscure,
            )
          : null,
      filled: true,
      fillColor: const Color(0xB8FFFFFF),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0x140F172A)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: kBrand, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
  );
}

ButtonStyle authButtonStyle() {
  return ElevatedButton.styleFrom(
    backgroundColor: kBrand,
    foregroundColor: Colors.white,
    disabledBackgroundColor: kBrand.withValues(alpha: 0.6),
    elevation: 0,
    padding: const EdgeInsets.symmetric(vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  );
}

SnackBar authSnackBar(String message, {bool isError = false}) {
  return SnackBar(
    content: Text(
      message,
      style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600),
    ),
    backgroundColor: isError ? const Color(0xFFEF4444) : kNavy,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
}
