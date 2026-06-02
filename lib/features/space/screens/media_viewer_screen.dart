import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../app/theme.dart';
import '../models/space_media.dart';

class MediaViewerScreen extends StatefulWidget {
  final SpaceMedia media;
  final Future<SpaceMedia?> Function(String note)? onUpdateNote;

  const MediaViewerScreen({
    super.key,
    required this.media,
    this.onUpdateNote,
  });

  @override
  State<MediaViewerScreen> createState() => _MediaViewerScreenState();
}

class _MediaViewerScreenState extends State<MediaViewerScreen> {
  VideoPlayerController? _videoController;
  bool _videoReady = false;
  late SpaceMedia _media;

  @override
  void initState() {
    super.initState();
    _media = widget.media;
    if (_media.isVideo) {
      _initVideo();
    }
  }

  Future<void> _initVideo() async {
    final localPath = _media.localPath;
    final url = _media.url;
    if (!kIsWeb && localPath != null) {
      _videoController = VideoPlayerController.file(File(localPath));
    } else if (url != null) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    }

    final controller = _videoController;
    if (controller == null) return;

    await controller.initialize();
    await controller.setLooping(true);
    if (mounted) {
      setState(() => _videoReady = true);
      controller.play();
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: Center(
                child: widget.media.isVideo ? _buildVideo() : _buildPhoto(),
              ),
            ),
            Positioned(
              top: 8,
              left: 8,
              child: IconButton.filled(
                style: IconButton.styleFrom(backgroundColor: Colors.black.withValues(alpha: 0.45)),
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close, color: Colors.white),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatDate(_media.memoryDate),
                      style: const TextStyle(
                        color: AppColors.active,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _media.note.trim().isEmpty ? 'No note yet.' : _media.note,
                            style: const TextStyle(
                              color: Color(0xFF374151),
                              fontSize: 14,
                              height: 1.4,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: widget.onUpdateNote == null ? null : _editNote,
                          icon: const Icon(Icons.edit_note, color: AppColors.active),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    final localPath = _media.localPath;
    if (!kIsWeb && localPath != null) {
      return InteractiveViewer(child: Image.file(File(localPath), fit: BoxFit.contain));
    }
    return InteractiveViewer(
      child: Image.network(
        _media.displayUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => const Icon(Icons.broken_image, color: Colors.white, size: 72),
      ),
    );
  }

  Widget _buildVideo() {
    final controller = _videoController;
    if (!_videoReady || controller == null) {
      return const CircularProgressIndicator(color: AppColors.active);
    }
    return GestureDetector(
      onTap: () {
        setState(() {
          controller.value.isPlaying ? controller.pause() : controller.play();
        });
      },
      child: AspectRatio(
        aspectRatio: controller.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            VideoPlayer(controller),
            if (!controller.value.isPlaying)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _editNote() async {
    final updatedNote = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditNoteSheet(initialNote: _media.note),
    );
    if (updatedNote == null) return;
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    final updated = await widget.onUpdateNote?.call(updatedNote);
    if (updated != null && mounted) {
      setState(() => _media = updated);
    }
  }
}

class _EditNoteSheet extends StatefulWidget {
  final String initialNote;

  const _EditNoteSheet({required this.initialNote});

  @override
  State<_EditNoteSheet> createState() => _EditNoteSheetState();
}

class _EditNoteSheetState extends State<_EditNoteSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNote);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final value = _controller.text.trim();
    FocusManager.instance.primaryFocus?.unfocus();
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;
    Navigator.pop(context, value);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit memory note',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _controller,
              autofocus: true,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'Note',
                prefixIcon: Icon(Icons.favorite_border),
              ),
              onSubmitted: (_) => _submit(),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Save Note'),
            ),
          ],
        ),
      ),
    );
  }
}
