import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../app_theme.dart';
import '../services/firestore_service.dart';
import '../widgets/app_background.dart';
import '../widgets/auth_helpers.dart';

class _VideoEntry {
  final TextEditingController nameCtrl;
  final TextEditingController notesCtrl;
  final String? url;
  final String? storagePath;

  _VideoEntry({
    String name = '',
    String notes = '',
    this.url,
    this.storagePath,
  })  : nameCtrl = TextEditingController(text: name),
        notesCtrl = TextEditingController(text: notes);

  bool get isUploaded => url != null && url!.isNotEmpty;

  void dispose() {
    nameCtrl.dispose();
    notesCtrl.dispose();
  }
}

class SurveyVideosScreen extends StatefulWidget {
  const SurveyVideosScreen({super.key});

  @override
  State<SurveyVideosScreen> createState() => _SurveyVideosScreenState();
}

class _SurveyVideosScreenState extends State<SurveyVideosScreen> {
  final List<_VideoEntry> _videos = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadingName;
  bool _isSaving = false;

  @override
  void dispose() {
    for (final v in _videos) {
      v.dispose();
    }
    super.dispose();
  }

  Future<void> _pickAndUploadVideo() async {
    final xFile = await ImagePicker().pickVideo(
      source: ImageSource.gallery,
      maxDuration: const Duration(seconds: 90),
    );
    if (xFile == null || !mounted) return;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _uploadingName = xFile.name;
    });

    try {
      final ts = DateTime.now().millisecondsSinceEpoch;
      final ext = xFile.name.split('.').last.toLowerCase();
      final storagePath = 'users/$uid/videos/${ts}_${xFile.name}';
      final ref = FirebaseStorage.instance.ref().child(storagePath);

      final uploadTask = ref.putFile(
        File(xFile.path),
        SettableMetadata(contentType: 'video/$ext'),
      );

      uploadTask.snapshotEvents.listen((snap) {
        if (mounted && snap.totalBytes > 0) {
          setState(() =>
              _uploadProgress = snap.bytesTransferred / snap.totalBytes);
        }
      });

      await uploadTask;
      final downloadUrl = await ref.getDownloadURL();

      if (!mounted) return;
      setState(() {
        _videos.add(_VideoEntry(
          name: xFile.name,
          url: downloadUrl,
          storagePath: storagePath,
        ));
        _isUploading = false;
        _uploadProgress = 0.0;
        _uploadingName = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _uploadingName = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Upload failed. Please try again.',
            style: GoogleFonts.manrope(
                fontSize: 13, fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFFEF4444),
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ));
    }
  }

  void _removeVideo(int i) {
    setState(() {
      _videos[i].dispose();
      _videos.removeAt(i);
    });
  }

  Future<void> _finish() async {
    setState(() => _isSaving = true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final maps = _videos
          .map((v) => {
                'name': v.nameCtrl.text.trim(),
                'notes': v.notesCtrl.text.trim(),
                'url': v.url ?? '',
                'storagePath': v.storagePath ?? '',
              })
          .toList();
      await FirestoreService.saveSurveyVideos(uid, maps);
    }
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
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
                    step: 'Step 5 of 5',
                    chipLabel: 'Videos',
                  ),
                  const SizedBox(height: 16),
                  surveyHeroCard(
                    eyebrow: 'Video Imports',
                    title:
                        'Add example videos you have saved as content-style references.',
                    description:
                        'Add a few short clips you want Reel Mind to reference for pacing, framing, mood, and editing style.',
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
          _uploadZone(),
          if (_videos.isNotEmpty) ...[
            const SizedBox(height: 16),
            ...List.generate(
              _videos.length,
              (i) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _videoItem(i),
              ),
            ),
          ],
          const SizedBox(height: 16),
          surveyPrimaryButton(
            label: 'Finish and build my profile',
            icon: Icons.auto_awesome_rounded,
            onPressed: (_isSaving || _isUploading) ? null : _finish,
            isLoading: _isSaving,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: (_isSaving || _isUploading) ? null : _finish,
            child: Center(
              child: Text(
                'Skip for now',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: kMuted,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Upload zone ──────────────────────────────────────────────────────────

  Widget _uploadZone() {
    if (_isUploading) {
      return Container(
        padding:
            const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
        decoration: BoxDecoration(
          color: Color.fromRGBO(255, 255, 255, 0.80),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: kBrand, width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: kBrand.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Icon(Icons.upload_rounded,
                  color: kBrand, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              'Uploading...',
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: kText,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _uploadingName ?? '',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: kMuted,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
            const SizedBox(height: 14),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: _uploadProgress,
                backgroundColor: const Color(0x1FFF6B57),
                color: kBrand,
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(_uploadProgress * 100).toInt()}%',
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: kBrand,
              ),
            ),
          ],
        ),
      );
    }

    return GestureDetector(
      onTap: _pickAndUploadVideo,
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
        decoration: BoxDecoration(
          color: Color.fromRGBO(255, 255, 255, 0.80),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: const Color(0xFF94A3B8), width: 1.5),
        ),
        child: Column(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: kBrand,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(Icons.videocam_rounded,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              'Tap to upload a video',
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: kText,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'MP4 or MOV files up to 90 seconds each.\nUsed as style reference only.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: kMuted,
                height: 1.55,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Uploaded video card ──────────────────────────────────────────────────

  Widget _videoItem(int i) {
    final entry = _videos[i];
    return ideaItem(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: entry.isUploaded
                  ? kTeal.withValues(alpha: 0.10)
                  : kNavy.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              entry.isUploaded
                  ? Icons.check_circle_outline_rounded
                  : Icons.videocam_outlined,
              color: entry.isUploaded ? kTeal : kNavy,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.nameCtrl.text,
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: kText,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                    if (entry.isUploaded)
                      Container(
                        margin: const EdgeInsets.only(left: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: kTeal.withValues(alpha: 0.10),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          'Uploaded',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: kTeal,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: entry.notesCtrl,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: kText,
                  ),
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    hintText: 'Style notes: pacing, mood, color palette...',
                    hintStyle: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF94A3B8),
                    ),
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _removeVideo(i),
            child: const Icon(Icons.close_rounded,
                size: 18, color: Color(0xFF94A3B8)),
          ),
        ],
      ),
    );
  }
}
