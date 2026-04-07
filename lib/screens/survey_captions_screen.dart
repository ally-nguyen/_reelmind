import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../services/firestore_service.dart';
import '../widgets/app_background.dart';
import '../widgets/auth_helpers.dart';
import 'survey_creators_screen.dart';

class SurveyCaptionsScreen extends StatefulWidget {
  const SurveyCaptionsScreen({super.key});

  @override
  State<SurveyCaptionsScreen> createState() => _SurveyCaptionsScreenState();
}

class _SurveyCaptionsScreenState extends State<SurveyCaptionsScreen> {
  final List<TextEditingController> _captionCtrls = [
    TextEditingController(),
  ];
  bool _isSaving = false;

  @override
  void dispose() {
    for (final c in _captionCtrls) {
      c.dispose();
    }
    super.dispose();
  }

  void _addCaption() =>
      setState(() => _captionCtrls.add(TextEditingController()));

  void _removeCaption(int i) {
    if (_captionCtrls.length == 1) return;
    setState(() {
      _captionCtrls[i].dispose();
      _captionCtrls.removeAt(i);
    });
  }

  Future<void> _next() async {
    setState(() => _isSaving = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final captions = _captionCtrls
          .map((c) => c.text.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      await FirestoreService.saveSurveyCaptions(uid, captions);
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SurveyCreatorsScreen()),
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
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  surveyNavRow(
                      context: context,
                      step: 'Step 3 of 5',
                      chipLabel: 'Captions'),
                  const SizedBox(height: 16),
                  surveyHeroCard(
                    eyebrow: 'Voice Samples',
                    title:
                        'Share a few caption examples so Reel Mind can learn how you sound.',
                    description:
                        'Add 2 to 4 caption examples. Your wording, pacing, and point of view to help AI stay on-brand.',
                    titleSize: 32,
                  ),
                  const SizedBox(height: 16),
                  _formCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _formCard() {
    return glassCard(
      padding: const EdgeInsets.all(18),
      radius: 26,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...List.generate(_captionCtrls.length, (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _captionField(i),
              )),
          _addButton(
            label: '+ Add another caption',
            onTap: _addCaption,
          ),
          const SizedBox(height: 16),
          surveyPrimaryButton(
            label: 'Next: creators',
            icon: Icons.arrow_forward_rounded,
            onPressed: _isSaving ? null : _next,
            isLoading: _isSaving,
          ),
        ],
      ),
    );
  }

  Widget _captionField(int i) {
    return Container(
      decoration: BoxDecoration(
        color: Color.fromRGBO(255, 255, 255, 0.80),
        borderRadius: BorderRadius.circular(22),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 4, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'CAPTION EXAMPLE ${i + 1}',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
              ),
              if (_captionCtrls.length > 1)
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      size: 16, color: Color(0xFF94A3B8)),
                  onPressed: () => _removeCaption(i),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              const SizedBox(width: 12),
            ],
          ),
          TextField(
            controller: _captionCtrls[i],
            maxLines: 4,
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: kText,
              height: 1.5,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText:
                  'Paste or type a caption from one of your posts...',
              hintStyle: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF94A3B8),
                height: 1.5,
              ),
              contentPadding: const EdgeInsets.only(bottom: 8),
              isDense: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _addButton({required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Color.fromRGBO(255, 255, 255, 0.80),
          borderRadius: BorderRadius.circular(22),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: kBrandDeep,
          ),
        ),
      ),
    );
  }
}
