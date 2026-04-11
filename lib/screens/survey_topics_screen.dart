import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../app_theme.dart';
import '../services/firestore_service.dart';
import '../utils/input_validator.dart';
import '../widgets/app_background.dart';
import '../widgets/auth_helpers.dart';
import 'survey_captions_screen.dart';

const _kSuggestedTopics = [
  'Creator economy',
  'Lifestyle',
  'Fashion',
  'Behind the scenes',
  'Tutorial',
  'Day in my life',
  'Business tips',
  'Storytelling',
  'Productivity',
  'Personal finance',
  'Travel',
  'Beauty & skincare',
  'Tech & gadgets',
  'Fitness',
  'Mindset',
  'Education',
  'Home & decor',
];

class SurveyTopicsScreen extends StatefulWidget {
  const SurveyTopicsScreen({super.key});

  @override
  State<SurveyTopicsScreen> createState() => _SurveyTopicsScreenState();
}

class _SurveyTopicsScreenState extends State<SurveyTopicsScreen> {
  final Set<String> _selectedTopics = {};
  final _customTopicCtrl = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _customTopicCtrl.dispose();
    super.dispose();
  }

  void _toggleTopic(String topic) {
    setState(() {
      if (_selectedTopics.contains(topic)) {
        _selectedTopics.remove(topic);
      } else {
        _selectedTopics.add(topic);
      }
    });
  }

  void _addCustomTopic() {
    final topic = _customTopicCtrl.text.trim();
    if (topic.isEmpty) return;

    // SECURITY: validate length and sanitise before adding.
    final err = InputValidator.validateTopic(topic);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }
    if (_selectedTopics.length >= InputValidator.maxTopicCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Maximum topics reached.')),
      );
      return;
    }
    setState(() {
      _selectedTopics.add(InputValidator.sanitizeText(topic));
      _customTopicCtrl.clear();
    });
  }

  Future<void> _next() async {
    setState(() => _isSaving = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      // Sanitise preset + custom topics before saving to Firestore.
      final safeTopics = _selectedTopics
          .map((t) => InputValidator.sanitizeAndTruncate(t, InputValidator.maxTopicLength))
          .take(InputValidator.maxTopicCount)
          .toList();
      await FirestoreService.saveSurveyTopics(uid, safeTopics);
    }
    if (!mounted) return;
    setState(() => _isSaving = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SurveyCaptionsScreen()),
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
                      step: 'Step 2 of 5',
                      chipLabel: 'Topics'),
                  const SizedBox(height: 16),
                  surveyHeroCard(
                    eyebrow: 'Content Style Topics',
                    title:
                        'What topics best describe the kind of content you want to be known for?',
                    description:
                        'Pick the themes that feel most like you. These will shape your first AI-generated ideas.',
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
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kSuggestedTopics.map((topic) {
              final selected = _selectedTopics.contains(topic);
              return GestureDetector(
                onTap: () => _toggleTopic(topic),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: selected
                        ? kBrandDeep.withValues(alpha: 0.12)
                        : Color.fromRGBO(255, 255, 255, 0.80),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: selected
                          ? kBrandDeep.withValues(alpha: 0.40)
                          : const Color(0x140F172A),
                    ),
                  ),
                  child: Text(
                    topic,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? kBrandDeep : kMuted,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_selectedTopics.any((t) => !_kSuggestedTopics.contains(t))) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedTopics
                  .where((t) => !_kSuggestedTopics.contains(t))
                  .map((t) => _customChip(t))
                  .toList(),
            ),
          ],
          const SizedBox(height: 14),
          Container(
            decoration: BoxDecoration(
              color: Color.fromRGBO(255, 255, 255, 0.80),
              borderRadius: BorderRadius.circular(22),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 4, 4),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADD YOUR OWN TOPIC',
                  style: GoogleFonts.manrope(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.8,
                    color: const Color(0xFF94A3B8),
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _customTopicCtrl,
                        style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: kText),
                        // SECURITY: enforce max length in UI widget.
                        maxLength: InputValidator.maxTopicLength,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _addCustomTopic(),
                        decoration: InputDecoration(
                          counterText: '',
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          hintText: 'e.g. Soft luxury routines',
                          hintStyle: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF94A3B8),
                          ),
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 8),
                          isDense: true,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_rounded,
                          color: kBrand, size: 22),
                      onPressed: _addCustomTopic,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          surveyPrimaryButton(
            label: 'Next: captions',
            icon: Icons.arrow_forward_rounded,
            onPressed: _isSaving ? null : _next,
            isLoading: _isSaving,
          ),
        ],
      ),
    );
  }

  Widget _customChip(String topic) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: kBrand.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: kBrand.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            topic,
            style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: kBrandDeep),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => setState(() => _selectedTopics.remove(topic)),
            child: const Icon(Icons.close, size: 14, color: kBrandDeep),
          ),
        ],
      ),
    );
  }
}
