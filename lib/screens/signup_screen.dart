import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../services/rate_limiter.dart';
import '../utils/input_validator.dart';
import '../widgets/app_background.dart';
import '../widgets/auth_helpers.dart';
import '../services/firestore_service.dart';
import 'survey_topics_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // SECURITY (OWASP A07): Rate-limit account creation to 3 per hour.
    final rl = RateLimiter.instance.checkSignup();
    if (!rl.allowed) {
      final wait = rl.retryAfter != null
          ? RateLimiter.waitMessage(rl.retryAfter!)
          : 'later';
      ScaffoldMessenger.of(context).showSnackBar(
        authSnackBar('Too many sign-up attempts. $wait.', isError: true),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      final user = credential.user!;
      await user.updateDisplayName(_nameCtrl.text.trim());
      await FirestoreService.createUserDoc(
        user.uid,
        _emailCtrl.text.trim(),
      );
      // Seed an empty signals document so per-step survey saves can use update()
      await FirestoreService.saveSignals(
        user.uid,
        captions: [],
        topics: [],
        creators: [],
        videos: [],
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const SurveyTopicsScreen()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = switch (e.code) {
        'email-already-in-use' => 'An account already exists for that email.',
        'invalid-email' => 'Please enter a valid email address.',
        'weak-password' => 'Password is too weak. Use at least 8 characters.',
        'operation-not-allowed' => 'Email/password sign-up is not enabled.',
        _ => 'Sign-up failed (${e.code}). Please try again.',
      };
      ScaffoldMessenger.of(context)
          .showSnackBar(authSnackBar(msg, isError: true));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _navRow(context),
                    const SizedBox(height: 16),
                    _heroCard(),
                    const SizedBox(height: 16),
                    _formCard(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Top navigation row ───────────────────────────────────────────────────────

  Widget _navRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
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
            child: const Icon(
              Icons.chevron_left_rounded,
              color: kText,
              size: 22,
            ),
          ),
        ),
        Column(
          children: [
            Text(
              'ACCOUNT SETUP',
              style: GoogleFonts.manrope(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.8,
                color: const Color(0xFF94A3B8),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Step 1 of 5',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: kText,
              ),
            ),
          ],
        ),
        const SizedBox(width: 44),
      ],
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
              brandChip('👤  New creator'),
              softChip('2 min setup'),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'GET STARTED',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 2.4,
              color: kBrandDeep,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Create your account, then teach Reel Mind what your content feels like.',
            style: GoogleFonts.fraunces(
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.04 * 34,
              color: kText,
              height: 1.02,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'After sign up, you will answer a short onboarding survey about your topics, captions, creators you study, and example videos.',
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

  // ── Form card ───────────────────────────────────────────────────────────────

  Widget _formCard() {
    return glassCard(
      padding: const EdgeInsets.all(18),
      radius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          protoField(
            label: 'Full name',
            controller: _nameCtrl,
            hint: 'Your name',
            // SECURITY: length limits prevent oversized display names.
            validator: InputValidator.validateDisplayName,
          ),
          const SizedBox(height: 12),
          protoField(
            label: 'Email',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            hint: 'you@example.com',
            // SECURITY: RFC 5322-based regex, not just '@' check.
            validator: InputValidator.validateEmail,
          ),
          const SizedBox(height: 12),
          protoField(
            label: 'Password',
            controller: _passwordCtrl,
            isPassword: true,
            obscure: _obscurePassword,
            hint: 'Create a secure password',
            onToggleObscure: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            // SECURITY: stricter validator for new passwords — requires
            // uppercase + digit/symbol in addition to minimum length.
            validator: InputValidator.validateNewPassword,
          ),
          const SizedBox(height: 20),
          _primaryButton(
            label: 'Create Account',
            icon: Icons.arrow_forward_rounded,
            onPressed: _isLoading ? null : _submit,
            isLoading: _isLoading,
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Already have an account? ',
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kMuted,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Sign in',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: kBrand,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Button helper ────────────────────────────────────────────────────────────

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
}
