import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../services/rate_limiter.dart';
import '../utils/input_validator.dart';
import '../widgets/app_background.dart';
import '../widgets/auth_helpers.dart';
import '../widgets/reel_mind_logo.dart';
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

    // SECURITY (OWASP A07): Check client-side rate limit before attempting
    // sign-in.  Fires before any network call so brute-force attempts are
    // blocked locally even when Firebase's own lockout hasn't triggered yet.
    final rl = RateLimiter.instance.checkLogin();
    if (!rl.allowed) {
      final wait = rl.retryAfter != null
          ? RateLimiter.waitMessage(rl.retryAfter!)
          : 'later';
      ScaffoldMessenger.of(context).showSnackBar(
        authSnackBar('Too many attempts. $wait.', isError: true),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      if (!mounted) return;
      // Reset the login bucket so a user who mis-typed a few times isn't
      // locked out after a successful login.
      RateLimiter.instance.onLoginSuccess();
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
                  // SECURITY: use centralised regex validator, not just '@' check.
                  validator: InputValidator.validateEmail,
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: authButtonStyle(),
                    onPressed: () async {
                      if (!resetKey.currentState!.validate()) return;
                      final navigator = Navigator.of(context);
                      final messenger = ScaffoldMessenger.of(context);
                      // SECURITY: rate-limit password reset emails to prevent
                      // using this endpoint to flood a victim's inbox.
                      final rl = RateLimiter.instance.checkPasswordReset();
                      if (!rl.allowed) {
                        final wait = rl.retryAfter != null
                            ? RateLimiter.waitMessage(rl.retryAfter!)
                            : 'later';
                        if (!context.mounted) return;
                        navigator.pop();
                        messenger.showSnackBar(
                          authSnackBar('Too many requests. $wait.', isError: true),
                        );
                        return;
                      }
                      try {
                        await FirebaseAuth.instance.sendPasswordResetEmail(
                          email: resetCtrl.text.trim(),
                        );
                        if (!context.mounted) return;
                        navigator.pop();
                        messenger.showSnackBar(
                          authSnackBar(
                              'Reset link sent to ${resetCtrl.text.trim()}'),
                        );
                      } on FirebaseAuthException {
                        if (!context.mounted) return;
                        navigator.pop();
                        messenger.showSnackBar(
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
          const SizedBox(height: 20),
          const Center(child: ReelMindLogo(size: 140)),
          const SizedBox(height: 20),
          Text(
            'Log in and pick up right where your next idea left off.',
            style: GoogleFonts.fraunces(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.04 * 20,
              color: kText,
              height: 1.3,
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
            // SECURITY: centralised RFC 5322 regex, not a bare '@' check.
            validator: InputValidator.validateEmail,
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

}


