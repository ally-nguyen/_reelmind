import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

class _SettingsScreenState extends State<SettingsScreen>
    with SingleTickerProviderStateMixin {
  // ── Personal Info state ──────────────────────────────────────────────────
  File? _profileImage;
  bool _isDeletingAccount = false;
  String get _email =>
      FirebaseAuth.instance.currentUser?.email ?? 'Not signed in';

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Image picker ─────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: source,
      imageQuality: 80,
      maxWidth: 512,
    );
    if (picked != null) {
      setState(() => _profileImage = File(picked.path));
    }
  }

  void _showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        decoration: BoxDecoration(
          color: const Color(0xFFF8F4F0),
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _sheetOption(
              icon: Icons.camera_alt_outlined,
              label: 'Take a photo',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            _sheetOption(
              icon: Icons.photo_library_outlined,
              label: 'Choose from library',
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_profileImage != null)
              _sheetOption(
                icon: Icons.delete_outline,
                label: 'Remove photo',
                color: const Color(0xFFEF4444),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _profileImage = null);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _sheetOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    final c = color ?? kText;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(icon, color: c, size: 22),
            const SizedBox(width: 14),
            Text(label,
                style: GoogleFonts.manrope(
                    fontSize: 15, fontWeight: FontWeight.w600, color: c)),
          ],
        ),
      ),
    );
  }

  // ── Change password dialog ────────────────────────────────────────────────
  void _showChangePasswordDialog() {
    final currentCtrl = TextEditingController();
    final newCtrl = TextEditingController();
    final confirmCtrl = TextEditingController();
    String? errorMsg;
    bool obscureCurrent = true;
    bool obscureNew = true;
    bool obscureConfirm = true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
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
              ),
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
              onPressed: () {
                if (currentCtrl.text.isEmpty ||
                    newCtrl.text.isEmpty ||
                    confirmCtrl.text.isEmpty) {
                  setDlgState(() => errorMsg = 'All fields are required.');
                  return;
                }
                if (newCtrl.text != confirmCtrl.text) {
                  setDlgState(
                      () => errorMsg = 'New passwords do not match.');
                  return;
                }
                if (newCtrl.text.length < 8) {
                  setDlgState(() =>
                      errorMsg = 'Password must be at least 8 characters.');
                  return;
                }
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Password updated.',
                        style: GoogleFonts.manrope(
                            fontSize: 13, fontWeight: FontWeight.w600)),
                    backgroundColor: kNavy,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                );
              },
              child: Text('Save',
                  style: GoogleFonts.manrope(
                      fontSize: 14, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dialogField({
    required TextEditingController controller,
    required String label,
    required bool obscure,
    required VoidCallback onToggle,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: GoogleFonts.manrope(fontSize: 14, color: kText),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            GoogleFonts.manrope(fontSize: 13, color: kMuted),
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

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          const AppBackground(),
          SafeArea(
            child: Column(
              children: [
                _statusBar(),
                _tabBarHeader(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _personalInfoTab(),
                      _appSettingsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const AppTabBar(
            active: TabDest.settings,
            fabRoute: '/workspace',
            fabIcon: Icons.add,
          ),
          // Blocking overlay shown while deletion is in progress.
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

  Widget _statusBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('9:41',
              style: GoogleFonts.manrope(
                  fontSize: 13, fontWeight: FontWeight.w700, color: kText)),
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

  Widget _tabBarHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xB8FFFFFF),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: const Color(0x1A0F172A)),
        ),
        child: TabBar(
          controller: _tabController,
          indicator: BoxDecoration(
            color: kNavy,
            borderRadius: BorderRadius.circular(18),
          ),
          indicatorSize: TabBarIndicatorSize.tab,
          dividerColor: Colors.transparent,
          labelStyle: GoogleFonts.manrope(
              fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.manrope(
              fontSize: 13, fontWeight: FontWeight.w600),
          labelColor: Colors.white,
          unselectedLabelColor: kMuted,
          tabs: const [
            Tab(text: 'Personal Info'),
            Tab(text: 'App Settings'),
          ],
        ),
      ),
    );
  }

  // ── Personal Info tab ─────────────────────────────────────────────────────
  Widget _personalInfoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 130),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _profilePictureCard(),
          const SizedBox(height: 16),
          _accountInfoCard(),
          const SizedBox(height: 30),
          _logoutButton(),
        ],
      ),
    );
  }

  Widget _profilePictureCard() {
    return GlassCard(
      padding: const EdgeInsets.all(24),
      borderRadius: 26,
      child: Column(
        children: [
          Text('Profile Picture', style: sectionTitle),
          const SizedBox(height: 6),
          Text('Tap the photo to update your avatar.',
              style: sectionSubtitle, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          GestureDetector(
            onTap: _showImageSourceSheet,
            child: Stack(
              alignment: Alignment.bottomRight,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFFFD6C3),
                    border: Border.all(color: Colors.white, width: 3),
                    boxShadow: [
                      BoxShadow(
                        color: kNavy.withValues(alpha: 0.12),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: _profileImage != null
                        ? Image.file(_profileImage!,
                            fit: BoxFit.cover,
                            width: 100,
                            height: 100)
                        : const Icon(Icons.person,
                            size: 48, color: Color(0xFFFF6B57)),
                  ),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: kBrand,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: const Icon(Icons.camera_alt,
                      color: Colors.white, size: 15),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            _profileImage != null ? 'Photo saved' : 'No photo yet',
            style: GoogleFonts.manrope(
                fontSize: 12, fontWeight: FontWeight.w600, color: kMuted),
          ),
        ],
      ),
    );
  }

  Widget _accountInfoCard() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Account Info', style: sectionTitle),
              const RmChip(label: 'Secure', style: ChipStyle.teal),
            ],
          ),
          const SizedBox(height: 16),
          // Email row
          _infoRow(
            icon: Icons.email_outlined,
            label: 'Email',
            value: _email,
            trailing: const Icon(Icons.lock_outline,
                size: 16, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 12),
          // Password row
          _passwordRow(),
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

  // ── Delete account ────────────────────────────────────────────────────────

  /// Step 1 — first confirmation dialog.
  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF8F4F0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: Text('Delete account?',
            style: GoogleFonts.fraunces(
                fontSize: 20, fontWeight: FontWeight.w700, color: kText)),
        content: Text(
          'This will permanently delete all your ideas, imported signals, and account data. This cannot be undone.',
          style: GoogleFonts.manrope(
              fontSize: 14, fontWeight: FontWeight.w500, color: kMuted,
              height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel',
                style: GoogleFonts.manrope(
                    fontSize: 14, fontWeight: FontWeight.w600, color: kMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              // Step 2 — second confirmation before executing deletion.
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

  /// Step 2 — final "are you absolutely sure?" dialog before deleting.
  void _showDeleteAccountConfirmDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF8F4F0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Color(0xFFEF4444), size: 22),
            const SizedBox(width: 10),
            Text('Are you sure?',
                style: GoogleFonts.fraunces(
                    fontSize: 20, fontWeight: FontWeight.w700,
                    color: const Color(0xFFEF4444))),
          ],
        ),
        content: Text(
          'All your data — ideas, captions, topics, creator references — will be deleted immediately and cannot be recovered.',
          style: GoogleFonts.manrope(
              fontSize: 14, fontWeight: FontWeight.w500, color: kMuted,
              height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('No, keep my account',
                style: GoogleFonts.manrope(
                    fontSize: 14, fontWeight: FontWeight.w600, color: kMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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

  /// Executes deletion.  Handles the re-authentication case where Firebase
  /// requires a fresh sign-in before deleting the account.
  Future<void> _executeDeleteAccount() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isDeletingAccount = true);

    try {
      // Delete all Firestore data and Storage files first.
      await FirestoreService.deleteAllUserData(user.uid);

      // Then delete the Firebase Auth account.
      await user.delete();

      if (!mounted) return;
      // Navigate to login — auth stream will handle it, but be explicit.
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (_) => false,
      );
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isDeletingAccount = false);

      if (e.code == 'requires-recent-login') {
        // Firebase requires re-authentication within 5 minutes of sensitive
        // operations.  Prompt for password, then retry.
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

  /// Shows a password prompt to re-authenticate, then retries deletion.
  void _showReauthDialog(User user) {
    final passwordCtrl = TextEditingController();
    bool obscure = true;
    String? errorMsg;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          backgroundColor: const Color(0xFFF8F4F0),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
          title: Text('Confirm your password',
              style: GoogleFonts.fraunces(
                  fontSize: 20, fontWeight: FontWeight.w700, color: kText)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'For security, please enter your password to confirm account deletion.',
                style: GoogleFonts.manrope(
                    fontSize: 13, fontWeight: FontWeight.w500, color: kMuted,
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
                      fontSize: 14, fontWeight: FontWeight.w600,
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
                  // Retry deletion now that we're re-authenticated.
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

  Widget _manageAccountCard() {
    return GlassCard(
      padding: const EdgeInsets.all(18),
      borderRadius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Manage Account', style: sectionTitle),
                    const SizedBox(height: 2),
                    Text('Deactivate or permanently remove your account.',
                        style: sectionSubtitle),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Deactivate button
          GestureDetector(
            onTap: _isDeletingAccount ? null : _showDeactivateDialog,
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xB8FFFFFF),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  const Icon(Icons.pause_circle_outline,
                      color: Color(0xFF64748B), size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Deactivate Account',
                            style: GoogleFonts.manrope(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: kText)),
                        const SizedBox(height: 2),
                        Text('Sign out and pause your account activity.',
                            style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: kMuted)),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      color: Color(0xFF94A3B8), size: 18),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Delete button
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

  Widget _logoutButton() {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: const Color(0xFFF8F4F0),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
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
                    color: kMuted)),
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
                    MaterialPageRoute(
                        builder: (_) => const LoginScreen()),
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
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Text('Log out',
            style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: const Color(0xFFEF4444))),
      ),
    );
  }

  // ── App Settings tab (existing content) ───────────────────────────────────
  Widget _appSettingsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 130),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heroCard(),
          const SizedBox(height: 16),
          _preferences(),
          const SizedBox(height: 16),
          _manageAccountCard(),
        ],
      ),
    );
  }

  Widget _heroCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('SETTINGS', style: eyebrowStyle),
                    const SizedBox(height: 10),
                    Text(
                      'Control your imports, generation, and privacy settings.',
                      style: displayTitle(32),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: kNavy,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Icon(Icons.settings,
                    color: Colors.white, size: 24),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            'Designed for a clean creator workflow: fast imports, transparent data handling, and one-tap access to your idea system.',
            style: mutedBodyStyle,
          ),
        ],
      ),
    );
  }
  Widget _preferences() {
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

  void _showDeactivateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFF8F4F0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(26)),
        title: Text('Deactivate account?',
            style: GoogleFonts.fraunces(
                fontSize: 20, fontWeight: FontWeight.w700, color: kText)),
        content: Text(
            'You will be signed out. Your data will be preserved and you can log back in at any time.',
            style: GoogleFonts.manrope(
                fontSize: 14, fontWeight: FontWeight.w500, color: kMuted)),
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
              backgroundColor: kNavy,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
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
            child: Text('Deactivate',
                style: GoogleFonts.manrope(
                    fontSize: 14, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
