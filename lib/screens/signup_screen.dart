import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_theme.dart';
import '../widgets/app_background.dart';
import '../widgets/auth_helpers.dart';
import 'login_screen.dart' show ReelMindLogo;

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() => _isLoading = false);
    ScaffoldMessenger.of(context).showSnackBar(
      authSnackBar('Account created! Please sign in.'),
    );
    Navigator.pop(context);
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
                    const SizedBox(height: 40),
                    const ReelMindLogo(size: 72),
                    const SizedBox(height: 16),
                    _wordmark(),
                    const SizedBox(height: 36),
                    authCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Create account',
                              style: GoogleFonts.fraunces(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w700,
                                  color: kText)),
                          const SizedBox(height: 4),
                          Text('Join Reel Mind and start creating.',
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
                            prefixIcon: Icons.lock_outline,
                            obscure: _obscurePassword,
                            onToggleObscure: () => setState(
                                () => _obscurePassword = !_obscurePassword),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Enter a password.';
                              }
                              if (v.length < 8) {
                                return 'Password must be at least 8 characters.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          authField(
                            controller: _confirmCtrl,
                            label: 'Confirm password',
                            prefixIcon: Icons.lock_outline,
                            obscure: _obscureConfirm,
                            onToggleObscure: () => setState(
                                () => _obscureConfirm = !_obscureConfirm),
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Please confirm your password.';
                              }
                              if (v != _passwordCtrl.text) {
                                return 'Passwords do not match.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 10),
                          _matchIndicator(),
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
                                  : Text('Create Account',
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
                        Text('Already have an account? ',
                            style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: kMuted)),
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Text('Sign in',
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
    return RichText(
      text: TextSpan(
        children: [
          TextSpan(
            text: 'reel ',
            style: GoogleFonts.fraunces(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: kText,
                letterSpacing: -1),
          ),
          TextSpan(
            text: 'mind',
            style: GoogleFonts.fraunces(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: kBrand,
                letterSpacing: -1),
          ),
        ],
      ),
    );
  }

  Widget _matchIndicator() {
    final password = _passwordCtrl.text;
    final confirm = _confirmCtrl.text;

    if (confirm.isEmpty) return const SizedBox.shrink();

    final matches = password == confirm;
    final color = matches ? kTeal : const Color(0xFFEF4444);
    final icon = matches ? Icons.check_circle_outline : Icons.cancel_outlined;
    final label = matches ? 'Passwords match' : 'Passwords do not match';

    return Row(
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 6),
        Text(label,
            style: GoogleFonts.manrope(
                fontSize: 12, fontWeight: FontWeight.w600, color: color)),
      ],
    );
  }
}
