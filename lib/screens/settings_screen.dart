import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../app_theme.dart';
import '../services/app_preferences.dart';
import '../services/firestore_service.dart';
import '../widgets/app_background.dart';
import '../widgets/app_tab_bar.dart';
import '../widgets/glass_card.dart';
import '../widgets/rm_chip.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isDeletingAccount = false;

  String get _email =>
      FirebaseAuth.instance.currentUser?.email ?? 'Not signed in';

  bool get _isGoogleUser =>
      FirebaseAuth.instance.currentUser?.providerData
          .any((p) => p.providerId == GoogleAuthProvider.PROVIDER_ID) ??
      false;

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 130),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _header(),
                  const SizedBox(height: 20),
                  _personalInfoCard(),
                  const SizedBox(height: 16),
                  _preferencesCard(),
                  const SizedBox(height: 16),
                  _manageAccountCard(),
                  const SizedBox(height: 30),
                  _logoutButton(),
                ],
              ),
            ),
          ),
          const AppTabBar(
            active: TabDest.settings,
            fabRoute: '/workspace',
            fabIcon: Icons.add,
          ),
          if (_isDeletingAccount)
            Container(
              color: const Color(0xBBFFFFFF),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 32, vertical: 28),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8F4F0),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x22000000),
                          blurRadius: 32,
                          offset: Offset(0, 12)),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const CircularProgressIndicator(
                          color: Color(0xFFEF4444), strokeWidth: 2.5),
                      const SizedBox(height: 20),
                      Text('Deleting your account…',
                          style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: kText)),
                      const SizedBox(height: 6),
                      Text('This may take a moment.',
                          style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: kMuted)),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Settings',
              style: GoogleFonts.fraunces(
                  fontSize: 26, fontWeight: FontWeight.w700, color: kText)),
          Row(children: const [
            Icon(Icons.signal_cellular_alt, size: 16, color: kText),
            SizedBox(width: 6),
            Icon(Icons.wifi, size: 16, color: kText),
            SizedBox(width: 6),
            Icon(Icons.battery_full, size: 16, color: kText),
          ]),
        ],
      ),
    );
  }

  // ── Personal Info ─────────────────────────────────────────────────────────
  Widget _personalInfoCard() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Personal Info', style: sectionTitle),
              const RmChip(label: 'Secure', style: ChipStyle.teal),
            ],
          ),
          const SizedBox(height: 16),
          _infoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: _email,
            trailing: const Icon(Icons.lock_outline,
                size: 16, color: Color(0xFF94A3B8)),
          ),
          if (!_isGoogleUser) ...[
            const SizedBox(height: 12),
            _passwordRow(),
          ],
        ],
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
    Widget? trailing,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xB8FFFFFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x0F0F172A)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kNavy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: kNavy, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: kMuted)),
                const SizedBox(height: 2),
                Text(value,
                    style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: kText)),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _passwordRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xB8FFFFFF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x0F0F172A)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: kNavy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_outline, color: kNavy, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Password',
                    style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: kMuted)),
                const SizedBox(height: 2),
                Text('••••••••',
                    style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: kText,
                        letterSpacing: 3)),
              ],
            ),
          ),
          GestureDetector(
            onTap: _showChangePasswordDialog,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: kBrand,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text('Change',
                  style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Change password dialog ────────────────────────────────────────────────

  static bool _pwHasLength(String pw) => pw.length >= 8;
  static bool _pwHasUpper(String pw) => RegExp(r'[A-Z]').hasMatch(pw);
  static bool _pwHasNumber(String pw) => RegExp(r'[0-9]').hasMatch(pw);
  static bool _pwHasSpecial(String pw) =>
      RegExp(r"""[!@#$%^&*()\-_=+\[\]{};:'",.<>?/\\|`~]""").hasMatch(pw);

  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? errorMsg;
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;
    String newPwValue = '';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) {
          final hasLength = _pwHasLength(newPwValue);
          final hasUpper = _pwHasUpper(newPwValue);
          final hasNumber = _pwHasNumber(newPwValue);
          final hasSpecial = _pwHasSpecial(newPwValue);

          return AlertDialog(
            backgroundColor: const Color(0xFFF8F4F0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
            title: Text('Change Password',
                style: GoogleFonts.fraunces(
                    fontSize: 20, fontWeight: FontWeight.w700, color: kText)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (errorMsg != null) ...[
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEDED),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.error_outline,
                            color: Color(0xFFEF4444), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(errorMsg!,
                              style: GoogleFonts.manrope(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFEF4444))),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                _dialogField(
                  controller: currentCtrl,
                  label: 'Current password',
                  obscure: obscureCurrent,
                  onToggle: () =>
                      setDlgState(() => obscureCurrent = !obscureCurrent),
                ),
                const SizedBox(height: 12),
                _dialogField(
                  controller: newCtrl,
                  label: 'New password',
                  obscure: obscureNew,
                  onToggle: () => setDlgState(() => obscureNew = !obscureNew),
                  onChanged: (v) => setDlgState(() => newPwValue = v),
                ),
                const SizedBox(height: 10),
                _requirementRow('At least 8 characters', hasLength),
                const SizedBox(height: 4),
                _requirementRow('One uppercase letter (A–Z)', hasUpper),
                const SizedBox(height: 4),
                _requirementRow('One number (0–9)', hasNumber),
                const SizedBox(height: 4),
                _requirementRow('One special character (!@#\$…)', hasSpecial),
                const SizedBox(height: 12),
                _dialogField(
                  controller: confirmCtrl,
                  label: 'Confirm new password',
                  obscure: obscureConfirm,
                  onToggle: () =>
                      setDlgState(() => obscureConfirm = !obscureConfirm),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrand,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  elevation: 0,
                ),
                onPressed: () async {
                  final newPw = newCtrl.text;
                  if (currentCtrl.text.isEmpty ||
                      newPw.isEmpty ||
                      confirmCtrl.text.isEmpty) {
                    setDlgState(() => errorMsg = 'All fields are required.');
                    return;
                  }
                  if (newPw != confirmCtrl.text) {
                    setDlgState(() => errorMsg = 'New passwords do not match.');
                    return;
                  }
                  if (!_pwHasLength(newPw)) {
                    setDlgState(() =>
                        errorMsg = 'Password must be at least 8 characters.');
                    return;
                  }
                  if (!_pwHasUpper(newPw)) {
                    setDlgState(() => errorMsg =
                        'Password must include at least one uppercase letter.');
                    return;
                  }
                  if (!_pwHasNumber(newPw)) {
                    setDlgState(() => errorMsg =
                        'Password must include at least one number.');
                    return;
                  }
                  if (!_pwHasSpecial(newPw)) {
                    setDlgState(() => errorMsg =
                        'Password must include at least one special character.');
                    return;
                  }
                  final user = FirebaseAuth.instance.currentUser;
                  if (user == null) return;
                  try {
                    final credential = EmailAuthProvider.credential(
                      email: user.email!,
                      password: currentCtrl.text,
                    );
                    await user.reauthenticateWithCredential(credential);
                    await user.updatePassword(newPw);
                    if (!ctx.mounted) return;
                    Navigator.pop(ctx);
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Password updated.',
                          style: GoogleFonts.manrope(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                      backgroundColor: kNavy,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14)),
                    ));
                  } on FirebaseAuthException catch (e) {
                    setDlgState(() => errorMsg = e.code == 'wrong-password'
                        ? 'Current password is incorrect.'
                        : 'Could not update password. Try again.');
                  }
                },
                child: Text('Save',
                    style: GoogleFonts.manrope(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _requirementRow(String label, bool met) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
          size: 14,
          color: met ? kTeal : const Color(0xFFCBD5E1),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: met ? kTeal : kMuted,
          ),
        ),
      ],
    );
  }

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
    ValueChanged<String>? onChanged,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      style: GoogleFonts.manrope(fontSize: 14, color: kText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.manrope(fontSize: 13, color: kMuted),
        filled: true,
        fillColor: const Color(0xB8FFFFFF),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        suffixIcon: IconButton(
          icon: Icon(obscure ? Icons.visibility_off : Icons.visibility,
              size: 18, color: kMuted),
          onPressed: onToggle,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  // ── Preferences ───────────────────────────────────────────────────────────
  Widget _preferencesCard() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Preferences', style: sectionTitle),
              const RmChip(label: 'Personalized'),
            ],
          ),
          const SizedBox(height: 12),
          ValueListenableBuilder<bool>(
            valueListenable: AppPreferences.preloadScripts,
            builder: (_, value, __) => _prefToggle(
              'Preload AI scripts in editor',
              'Open generated bullets directly in workspace',
              value,
              (v) => AppPreferences.preloadScripts.value = v,
            ),
          ),
          const SizedBox(height: 10),
          ValueListenableBuilder<bool>(
            valueListenable: AppPreferences.autoDeleteArchived,
            builder: (_, value, __) => _prefToggle(
              'Auto-delete archived ideas',
              'Permanently remove archived ideas after 30 days',
              value,
              (v) => AppPreferences.autoDeleteArchived.value = v,
            ),
          ),
        ],
      ),
    );
  }

  Widget _prefToggle(
      String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xB8FFFFFF),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: kText)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: kMuted)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: kBrand,
            activeThumbColor: Colors.white,
            inactiveThumbColor: Colors.white,
            inactiveTrackColor: const Color(0xFFCBD5E1),
          ),
        ],
      ),
    );
  }

  // ── Manage Account ────────────────────────────────────────────────────────
  Widget _manageAccountCard() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Manage Account', style: sectionTitle),
          const SizedBox(height: 2),
          Text('Permanently remove your account.', style: sectionSubtitle),
          const SizedBox(height: 14),
          GestureDetector(
            onTap: _isDeletingAccount ? null : _showDeleteAccountDialog,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0x14EF4444),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const Icon(Icons.delete_forever_outlined,
                      color: Color(0xFFEF4444), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Delete Account',
                            style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFFEF4444))),
                        const SizedBox(height: 2),
                        Text('Permanently delete all your data.',
                            style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFFEF4444))),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: Color(0xFFEF4444), size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF8F4F0),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: Text('Delete account?',
            style: GoogleFonts.fraunces(
                fontSize: 20, fontWeight: FontWeight.w700, color: kText)),
        content: Text(
          'This will permanently delete all your ideas, imported signals, and account data. This cannot be undone.',
          style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: kMuted,
              height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _showDeleteAccountConfirmDialog();
            },
            child: Text('Delete account',
                style: GoogleFonts.manrope(
                    fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountConfirmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF8F4F0),
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFEF4444), size: 22),
            const SizedBox(width: 10),
            Text('Are you sure?',
                style: GoogleFonts.fraunces(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFEF4444))),
          ],
        ),
        content: Text(
          'All your data — ideas, captions, topics, creator references — will be deleted immediately and cannot be recovered.',
          style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: kMuted,
              height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('No, keep my account',
                style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              _executeDeleteAccount();
            },
            child: Text('Yes, delete everything',
                style: GoogleFonts.manrope(
                    fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  Future<void> _executeDeleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => _isDeletingAccount = true);
    try {
      await FirestoreService.deleteAllUserData(user.uid);
      await user.delete();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isDeletingAccount = false);
      if (e.code == 'requires-recent-login') {
        _showReauthDialog(user);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Could not delete account. Please try again.',
              style: GoogleFonts.manrope(
                  fontSize: 13, fontWeight: FontWeight.w600)),
          backgroundColor: const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14)),
        ));
      }
    } catch (_) {
      if (!mounted) return;
      setState(() => _isDeletingAccount = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Something went wrong. Please try again.',
            style: GoogleFonts.manrope(
                fontSize: 13, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14)),
      ));
    }
  }

  void _showReauthDialog(User user) {
    final isGoogleUser = user.providerData
        .any((p) => p.providerId == GoogleAuthProvider.PROVIDER_ID);
    if (isGoogleUser) {
      _reauthWithGoogle(user);
    } else {
      _showPasswordReauthDialog(user);
    }
  }

  Future<void> _reauthWithGoogle(User user) async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await user.reauthenticateWithCredential(credential);
      _executeDeleteAccount();
    } on FirebaseAuthException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Google re-authentication failed. Please try again.',
            style: GoogleFonts.manrope(
                fontSize: 13, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
    }
  }

  void _showPasswordReauthDialog(User user) {
    final passwordCtrl = TextEditingController();
    bool obscure = true;
    String? errorMsg;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFFF8F4F0),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26)),
          title: Text('Confirm your password',
              style: GoogleFonts.fraunces(
                  fontSize: 20, fontWeight: FontWeight.w700, color: kText)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'For security, please enter your password to confirm account deletion.',
                style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: kMuted,
                    height: 1.5),
              ),
              const SizedBox(height: 16),
              if (errorMsg != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Color(0xFFEF4444), size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(errorMsg!,
                            style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFEF4444))),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              _dialogField(
                controller: passwordCtrl,
                label: 'Password',
                obscure: obscure,
                onToggle: () => setDlgState(() => obscure = !obscure),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel',
                  style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: kMuted)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
              ),
              onPressed: () async {
                if (passwordCtrl.text.isEmpty) {
                  setDlgState(() => errorMsg = 'Enter your password.');
                  return;
                }
                try {
                  final credential = EmailAuthProvider.credential(
                    email: user.email!,
                    password: passwordCtrl.text,
                  );
                  await user.reauthenticateWithCredential(credential);
                  if (!ctx.mounted) return;
                  Navigator.pop(ctx);
                  _executeDeleteAccount();
                } on FirebaseAuthException {
                  setDlgState(
                      () => errorMsg = 'Incorrect password. Try again.');
                }
              },
              child: Text('Confirm delete',
                  style: GoogleFonts.manrope(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Log out ───────────────────────────────────────────────────────────────
  Widget _logoutButton() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFFF8F4F0),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(26)),
            title: Text('Log out?',
                style: GoogleFonts.fraunces(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: kText)),
            content: Text(
              'You will be returned to the login screen.',
              style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: kMuted),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text('Cancel',
                    style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: kMuted)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  Navigator.pop(ctx);
                  await FirebaseAuth.instance.signOut();
                  if (!mounted) return;
                  navigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (_) => false,
                  );
                },
                child: Text('Log out',
                    style: GoogleFonts.manrope(
                        fontSize: 14, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        );
      },
      child: Center(
        child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text('Log out',
            style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFEF4444))),
        ),
      ),
    );
  }
}
