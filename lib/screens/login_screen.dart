import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/auth_helpers.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'user-not-found' => 'No account found for that email.',
        'wrong-password' => 'Incorrect password.',
        'invalid-credential' => 'Invalid email or password.',
        'invalid-email' => 'Please enter a valid email address.',
        'user-disabled' => 'This account has been disabled.',
        'too-many-requests' => 'Too many attempts. Try again later.',
        _ => 'Sign-in failed. Please try again.',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(authSnackBar(msg, isError: true));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showForgotPassword() {
    final resetCtrl = TextEditingController();
    final resetKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F4F0),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Form(
            key: resetKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text('Reset Password',
                    style: GoogleFonts.fraunces(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: kText)),
                const SizedBox(height: 6),
                Text("Enter your email and we'll send you a reset link.",
                    style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: kMuted)),
                const SizedBox(height: 20),
                authField(
                  controller: resetCtrl,
                  label: 'Email address',
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Enter your email.';
                    if (!v.contains('@')) return 'Enter a valid email.';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: authButtonStyle(),
                    onPressed: () async {
                      if (!resetKey.currentState!.validate()) return;
                      try {
                        await FirebaseAuth.instance.sendPasswordResetEmail(
                          email: resetCtrl.text.trim(),
                        );
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          authSnackBar(
                              'Reset link sent to ${resetCtrl.text.trim()}'),
                        );
                      } on FirebaseAuthException {
                        if (!context.mounted) return;
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          authSnackBar(
                              'Could not send reset link. Check the email address.',
                              isError: true),
                        );
                      }
                    },
                    child: Text('Send Reset Link',
                        style: GoogleFonts.manrope(
                            fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 16, 18, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _heroCard(),
                    const SizedBox(height: 16),
                    _formCard(),
                    const SizedBox(height: 16),
                    _signUpCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Hero card ───────────────────────────────────────────────────────────────

  Widget _heroCard() {
    return glassCard(
      padding: const EdgeInsets.all(22),
      radius: 32,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              brandChip('🔒  Welcome back'),
              softChip('Creator login'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'REEL MIND',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.4,
              color: kBrandDeep,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Log in and pick up right where your next idea left off.',
            style: GoogleFonts.fraunces(
              fontSize: 36,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.04 * 36,
              color: kText,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Access your saved idea drafts, imported references, and AI-generated scripts in one place.',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: kMuted,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: AspectRatio(
              aspectRatio: 1.55,
              child: Image.network(
                'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?auto=format&fit=crop&w=900&q=80',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: const Color(0xFFE2D9CF),
                  child: const Icon(Icons.image_outlined,
                      size: 40, color: Color(0xFF94A3B8)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Form card ───────────────────────────────────────────────────────────────

  Widget _formCard() {
    return glassCard(
      padding: const EdgeInsets.all(18),
      radius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          protoField(
            label: 'Email',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            hint: 'you@example.com',
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter your email.';
              if (!v.contains('@')) return 'Enter a valid email.';
              return null;
            },
          ),
          const SizedBox(height: 12),
          protoField(
            label: 'Password',
            controller: _passwordCtrl,
            isPassword: true,
            obscure: _obscurePassword,
            onToggleObscure: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            validator: (v) {
              if (v == null || v.isEmpty) return 'Enter your password.';
              return null;
            },
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _showForgotPassword,
              child: Text(
                'Forgot password?',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: kBrand,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          _primaryButton(
            label: 'Log in',
            icon: Icons.arrow_forward_rounded,
            onPressed: _isLoading ? null : _submit,
            isLoading: _isLoading,
          ),
        ],
      ),
    );
  }

  // ── Sign-up promo card ───────────────────────────────────────────────────────

  Widget _signUpCard() {
    return glassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      radius: 26,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'New to Reel Mind?',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: kText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Create an account and answer a short style survey.',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: kMuted,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SignUpScreen()),
            ),
            child: Text(
              'Sign up',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: kBrandDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Button helpers ───────────────────────────────────────────────────────────

  Widget _primaryButton({
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          shadowColor: kBrand.withValues(alpha: 0.28),
        ).copyWith(
          elevation: WidgetStateProperty.all(8),
        ),
        onPressed: onPressed,
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: GoogleFonts.manrope(
                        fontSize: 15, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _secondaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          backgroundColor: Color.fromRGBO(255, 255, 255, 0.72),
          foregroundColor: kText,
          side: const BorderSide(color: Color(0x140F172A)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
        onPressed: onPressed,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.manrope(
                  fontSize: 14, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Reel Mind Logo ────────────────────────────────────────────────────────────

class ReelMindLogo extends StatelessWidget {
  final double size;
  const ReelMindLogo({super.key, this.size = 88});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
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
      child: CustomPaint(
        size: Size(size, size),
        painter: _ReelLogoPainter(),
      ),
    );
  }
}

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
