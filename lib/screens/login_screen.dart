import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pushReplacementNamed(context, '/');
  }

  void _showForgotPassword() {
    final resetCtrl = TextEditingController();
    final resetKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
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
                    if (v == null || v.isEmpty) {
                      return 'Enter your email.';
                    }
                    if (!v.contains('@')) {
                      return 'Enter a valid email.';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: authButtonStyle(),
                    onPressed: () {
                      if (resetKey.currentState!.validate()) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          authSnackBar(
                              'Reset link sent to ${resetCtrl.text}'),
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
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 56),
                    const ReelMindLogo(size: 88),
                    const SizedBox(height: 20),
                    _wordmark(),
                    const SizedBox(height: 48),
                    authCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Welcome back',
                              style: GoogleFonts.fraunces(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: kText)),
                          const SizedBox(height: 4),
                          Text('Sign in to your account',
                              style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: kMuted)),
                          const SizedBox(height: 24),
                          authField(
                            controller: _emailCtrl,
                            label: 'Email address',
                            keyboardType: TextInputType.emailAddress,
                            prefixIcon: Icons.email_outlined,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Enter your email.';
                              }
                              if (!v.contains('@')) {
                                return 'Enter a valid email.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          authField(
                            controller: _passwordCtrl,
                            label: 'Password',
                            obscure: _obscurePassword,
                            prefixIcon: Icons.lock_outline,
                            onToggleObscure: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Enter your password.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: _showForgotPassword,
                              child: Text('Forgot password?',
                                  style: GoogleFonts.manrope(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: kBrand)),
                            ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: authButtonStyle(),
                              onPressed: _isLoading ? null : _submit,
                              child: _isLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : Text('Sign In',
                                      style: GoogleFonts.manrope(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700)),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text("Don't have an account? ",
                            style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: kMuted)),
                        GestureDetector(
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SignUpScreen()),
                          ),
                          child: Text('Sign up',
                              style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: kBrand)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _wordmark() {
    return Column(
      children: [
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'reel ',
                style: GoogleFonts.fraunces(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: kText,
                    letterSpacing: -1),
              ),
              TextSpan(
                text: 'mind',
                style: GoogleFonts.fraunces(
                    fontSize: 34,
                    fontWeight: FontWeight.w700,
                    color: kBrand,
                    letterSpacing: -1),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text('AI-powered creator studio',
            style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: kMuted,
                letterSpacing: 0.2)),
      ],
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

    // Background circle with gradient
    final bgPaint = Paint()
      ..shader = RadialGradient(
        colors: [const Color(0xFF1C3050), kNavy],
        center: Alignment.topLeft,
        radius: 1.2,
      ).createShader(Rect.fromCircle(center: center, radius: r));
    canvas.drawCircle(center, r, bgPaint);

    // Outer reel ring
    final ringRadius = r * 0.80;
    final ringPaint = Paint()
      ..color = kBrand
      ..style = PaintingStyle.stroke
      ..strokeWidth = r * 0.055;
    canvas.drawCircle(center, ringRadius, ringPaint);

    // Sprocket holes on the ring
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

    // Three spokes
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

    // Center hub
    final hubGrad = Paint()
      ..shader = RadialGradient(
        colors: [kBrand, kBrandDeep],
      ).createShader(Rect.fromCircle(center: center, radius: r * 0.28));
    canvas.drawCircle(center, r * 0.28, hubGrad);
    canvas.drawCircle(center, r * 0.14, Paint()..color = kNavy);

    // Sparkle accent (top-right)
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
