import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../services/firestore_service.dart';
import '../widgets/app_background.dart';
import '../widgets/auth_helpers.dart';
import 'survey_videos_screen.dart';

class _CreatorEntry {
  final TextEditingController nameCtrl;
  final TextEditingController notesCtrl;
  _CreatorEntry({String name = '', String notes = ''})
      : nameCtrl = TextEditingController(text: name),
        notesCtrl = TextEditingController(text: notes);
  void dispose() {
    nameCtrl.dispose();
    notesCtrl.dispose();
  }
}

class SurveyCreatorsScreen extends StatefulWidget {
  const SurveyCreatorsScreen({super.key});

  @override
  State<SurveyCreatorsScreen> createState() => _SurveyCreatorsScreenState();
}

class _SurveyCreatorsScreenState extends State<SurveyCreatorsScreen> {
  final List<_CreatorEntry> _creators = [];
  bool _showAddForm = false;
  final _addNameCtrl = TextEditingController();
  final _addNotesCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    for (final e in _creators) {
      e.dispose();
    }
    _addNameCtrl.dispose();
    _addNotesCtrl.dispose();
    super.dispose();
  }

  void _confirmAdd() {
    final name = _addNameCtrl.text.trim();
    if (name.isEmpty) return;
    setState(() {
      _creators.add(_CreatorEntry(
        name: name,
        notes: _addNotesCtrl.text.trim(),
      ));
      _addNameCtrl.clear();
      _addNotesCtrl.clear();
      _showAddForm = false;
    });
  }

  void _removeCreator(int i) {
    setState(() {
      _creators[i].dispose();
      _creators.removeAt(i);
    });
  }

  Future<void> _next() async {
    setState(() => _isSaving = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final maps = _creators
          .map((e) => {
                'name': e.nameCtrl.text.trim(),
                'style': e.notesCtrl.text.trim(),
              })
          .toList();
      await FirestoreService.saveSurveyCreators(uid, maps);
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SurveyVideosScreen()),
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
                      step: 'Step 4 of 5',
                      chipLabel: 'Creators'),
                  const SizedBox(height: 16),
                  surveyHeroCard(
                    eyebrow: 'Creator References',
                    title:
                        'Which creators do you follow, and what exactly do you like about them?',
                    description:
                        'Be specific about what inspires you: hooks, storytelling, visuals, or how they convey themselves.',
                    titleSize: 30,
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
          if (_creators.isNotEmpty) ...[
            ...List.generate(_creators.length, (i) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _creatorItem(i),
                )),
          ],
          if (_showAddForm) ...[
            _addCreatorForm(),
            const SizedBox(height: 12),
          ],
          _addButton(
            label: '+ Add another creator reference',
            onTap: () => setState(() => _showAddForm = true),
          ),
          const SizedBox(height: 16),
          surveyPrimaryButton(
            label: 'Next: video references',
            icon: Icons.arrow_forward_rounded,
            onPressed: _isSaving ? null : _next,
            isLoading: _isSaving,
          ),
        ],
      ),
    );
  }

  Widget _creatorItem(int i) {
    final entry = _creators[i];
    return ideaItem(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  entry.nameCtrl.text,
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: kText,
                  ),
                ),
              ),
              if (entry.notesCtrl.text.isNotEmpty)
                brandChip(_tagLabel(entry.notesCtrl.text)),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _removeCreator(i),
                child: const Icon(Icons.close_rounded,
                    size: 16, color: Color(0xFF94A3B8)),
              ),
            ],
          ),
          if (entry.notesCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              entry.notesCtrl.text,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: kMuted,
                height: 1.55,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _addCreatorForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color.fromRGBO(255, 255, 255, 0.80),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0x140F172A)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _inlineField(
            label: 'CREATOR NAME',
            controller: _addNameCtrl,
            hint: '@username or creator name',
          ),
          const SizedBox(height: 10),
          _inlineField(
            label: 'WHAT DO YOU LIKE ABOUT THEM?',
            controller: _addNotesCtrl,
            hint:
                'e.g. I like the calm aesthetic, confident voice, and how each frame feels edited with taste.',
            maxLines: 3,
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() {
                    _addNameCtrl.clear();
                    _addNotesCtrl.clear();
                    _showAddForm = false;
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0x140F172A),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: kMuted),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: GestureDetector(
                  onTap: _confirmAdd,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: kBrand,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        'Add',
                        style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _inlineField({
    required String label,
    required TextEditingController controller,
    String? hint,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.8,
            color: const Color(0xFF94A3B8),
          ),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          maxLines: maxLines,
          style: GoogleFonts.manrope(
              fontSize: 14, fontWeight: FontWeight.w600, color: kText),
          decoration: InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            hintText: hint,
            hintStyle: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF94A3B8),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 4),
            isDense: true,
          ),
        ),
      ],
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

  // Derive a short display tag from the first few words of the notes
  String _tagLabel(String notes) {
    final words = notes.trim().split(' ');
    if (words.length <= 2) return notes.trim();
    return '${words[0]} ${words[1]}';
  }
}
