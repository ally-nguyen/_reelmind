import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';

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
          fontSize: 13, fontWeight: FontWeight.w500, color: kMuted),
      prefixIcon: Icon(prefixIcon, size: 18, color: kMuted),
      suffixIcon: obscure != null
          ? IconButton(
              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
                  size: 18, color: kMuted),
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
      contentPadding:
          const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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

SnackBar authSnackBar(String message) {
  return SnackBar(
    content: Text(message,
        style: GoogleFonts.manrope(fontSize: 13, fontWeight: FontWeight.w600)),
    backgroundColor: kNavy,
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
}
