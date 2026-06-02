import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../models/space_album.dart';
import '../models/space_media.dart';
import '../models/space_note.dart';
import '../providers/space_provider.dart';
import 'media_viewer_screen.dart';

enum _SpaceTab { photos, notes }

class SpaceScreen extends StatefulWidget {
  const SpaceScreen({super.key});

  @override
  State<SpaceScreen> createState() => _SpaceScreenState();
}

class _SpaceScreenState extends State<SpaceScreen> {
  _SpaceTab _tab = _SpaceTab.photos;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SpaceProvider>().loadSpace();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<SpaceProvider>();

    return Scaffold(
      body: RefreshIndicator(
        color: AppColors.active,
        onRefresh: provider.loadSpace,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            const _SpaceHeader(),
            const SizedBox(height: 20),
            _StatsRow(provider: provider),
            const SizedBox(height: 22),
            _SegmentedTabs(
              selected: _tab,
              onChanged: (tab) => setState(() => _tab = tab),
            ),
            const SizedBox(height: 20),
            if (provider.isLoading && provider.media.isEmpty && provider.notes.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 60),
                child: Center(child: CircularProgressIndicator(color: AppColors.active)),
              )
            else if (_tab == _SpaceTab.photos)
              Column(
                children: [
                  _AlbumsSection(
                    title: 'Albums',
                    albums: provider.albums,
                    selectedAlbumId: provider.selectedAlbumId,
                    showAll: provider.showAllMedia,
                    countForAlbum: provider.mediaCountForAlbum,
                    outsideCount: provider.outsideMediaCount,
                    unitLabel: 'memories',
                    onSelected: provider.selectAlbum,
                    onShowAll: provider.showAllPhotos,
                    onShowOutside: provider.showOutsidePhotos,
                    onRename: _showRenameAlbumDialog,
                    onDelete: _confirmDeleteAlbum,
                  ),
                  const SizedBox(height: 22),
                  _MediaGrid(
                    media: provider.visibleMedia,
                    onAdd: _showAddMediaSheet,
                    onOpen: _openMedia,
                    onDelete: _confirmDeleteMedia,
                  ),
                ],
              )
            else
              Column(
                children: [
                  _AlbumsSection(
                    title: 'Note Albums',
                    albums: provider.albums,
                    selectedAlbumId: provider.selectedAlbumId,
                    showAll: provider.showAllNotes,
                    countForAlbum: provider.noteCountForAlbum,
                    outsideCount: provider.outsideNoteCount,
                    unitLabel: 'notes',
                    onSelected: provider.selectAlbum,
                    onShowAll: provider.showAllNoteItems,
                    onShowOutside: provider.showOutsideNotes,
                    onRename: _showRenameAlbumDialog,
                    onDelete: _confirmDeleteAlbum,
                  ),
                  const SizedBox(height: 18),
                  _NotesList(
                    notes: provider.visibleNotes,
                    mediaForNote: provider.mediaForNote,
                    onAdd: _showAddNoteSheet,
                    onOpenMedia: _openMedia,
                    onDelete: _confirmDeleteNote,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _openMedia(SpaceMedia media) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MediaViewerScreen(
          media: media,
          onUpdateNote: (note) => context.read<SpaceProvider>().updateMediaNote(
                id: media.id,
                note: note,
              ),
        ),
      ),
    );
  }

  Future<void> _waitForRouteSettle() async {
    await Future<void>.delayed(Duration.zero);
    if (!mounted) return;
    await WidgetsBinding.instance.endOfFrame;
  }

  Future<void> _showAddMediaSheet() async {
    final provider = context.read<SpaceProvider>();
    final result = await showModalBottomSheet<_SpaceSourceResult>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _MediaSourceSheet(
        provider: provider,
      ),
    );
    if (result == null || !mounted) return;
    if (result.addAlbum) {
      await _waitForRouteSettle();
      if (!mounted) return;
      await _showAddAlbumSheet();
      return;
    }
    if (result.file == null || result.type == null) return;
    await _waitForRouteSettle();
    if (!mounted) return;
    await _showMediaNoteSheet(result.file!, result.type!);
  }

  Future<void> _showMediaNoteSheet(XFile file, SpaceMediaType type) async {
    final provider = context.read<SpaceProvider>();
    final result = await showModalBottomSheet<_MemoryInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MemoryInputSheet(
        title: 'Add memory note',
        primaryLabel: 'Save Memory',
        noteHint: 'Write what made this moment special...',
        showAlbumPicker: true,
        previewFile: file,
        previewType: type,
        albums: List<SpaceAlbum>.from(provider.albums),
        initialAlbumId: provider.selectedAlbumId,
      ),
    );
    if (result == null || !mounted) return;
    await _waitForRouteSettle();
    if (!mounted) return;
    await context.read<SpaceProvider>().addMedia(
          file: file,
          type: type,
          note: result.content,
          memoryDate: result.memoryDate,
          albumId: result.albumId,
        );
    if (!mounted) return;
    _showProviderError();
  }

  Future<void> _showAddNoteSheet() async {
    final provider = context.read<SpaceProvider>();
    final result = await showModalBottomSheet<_MemoryInput>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _MemoryInputSheet(
        title: 'Add new note',
        primaryLabel: 'Save Note',
        noteHint: 'Write a memory only both of you understand...',
        showTitleField: true,
        showAlbumPicker: true,
        albums: List<SpaceAlbum>.from(provider.albums),
        initialAlbumId: provider.selectedAlbumId,
      ),
    );
    if (result == null || !mounted) return;
    await _waitForRouteSettle();
    if (!mounted) return;
    await context.read<SpaceProvider>().addNote(
          title: result.title?.trim().isNotEmpty == true ? result.title!.trim() : 'Untitled Memory',
          content: result.content,
          memoryDate: result.memoryDate,
          albumId: result.albumId,
        );
    if (!mounted) return;
    _showProviderError();
  }

  void _showProviderError() {
    final error = context.read<SpaceProvider>().errorMessage;
    if (error == null) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _confirmDeleteMedia(SpaceMedia media) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete memory?'),
        content: const Text('This will delete the media from MongoDB and Cloudinary.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.active),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _waitForRouteSettle();
    if (!mounted) return;
    await context.read<SpaceProvider>().removeMedia(media.id);
    if (!mounted) return;
    _showProviderError();
  }

  Future<void> _showAddAlbumSheet() async {
    await _waitForRouteSettle();
    if (!mounted) return;
    final title = await _showAlbumTitleDialog(title: 'Create album');
    if (title == null || title.isEmpty || !mounted) return;
    await _waitForRouteSettle();
    if (!mounted) return;
    await context.read<SpaceProvider>().addAlbum(title: title);
    if (!mounted) return;
    _showProviderError();
  }

  Future<void> _showRenameAlbumDialog(SpaceAlbum album) async {
    await _waitForRouteSettle();
    if (!mounted) return;
    final title = await _showAlbumTitleDialog(title: 'Rename album', initialValue: album.title);
    if (title == null || title.isEmpty || !mounted) return;
    await _waitForRouteSettle();
    if (!mounted) return;
    await context.read<SpaceProvider>().renameAlbum(id: album.id, title: title);
    if (!mounted) return;
    _showProviderError();
  }

  Future<void> _confirmDeleteAlbum(SpaceAlbum album) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete album?'),
        content: const Text('Media will stay in Heart Space, but will be moved out of this album.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.active),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _waitForRouteSettle();
    if (!mounted) return;
    await context.read<SpaceProvider>().removeAlbum(album.id);
    if (!mounted) return;
    _showProviderError();
  }

  Future<void> _confirmDeleteNote(SpaceNote note) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note?'),
        content: const Text('This note will be removed from MongoDB. Linked media will stay.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.active),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await _waitForRouteSettle();
    if (!mounted) return;
    await context.read<SpaceProvider>().removeNote(note.id);
    if (!mounted) return;
    _showProviderError();
  }

  Future<String?> _showAlbumTitleDialog({
    required String title,
    String initialValue = '',
  }) async {
    return showDialog<String>(
      context: context,
      builder: (_) => _AlbumTitleDialog(
        title: title,
        initialValue: initialValue,
      ),
    );
  }
}

class _AlbumTitleDialog extends StatefulWidget {
  final String title;
  final String initialValue;

  const _AlbumTitleDialog({
    required this.title,
    required this.initialValue,
  });

  @override
  State<_AlbumTitleDialog> createState() => _AlbumTitleDialogState();
}

class _AlbumTitleDialogState extends State<_AlbumTitleDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue);
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
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          labelText: 'Album name',
          prefixIcon: Icon(Icons.collections_bookmark_outlined),
        ),
        onSubmitted: (_) => _submit(),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: AppColors.active),
          onPressed: _submit,
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class _SpaceHeader extends StatelessWidget {
  const _SpaceHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: [
        Text(
          'Heart Space',
          style: TextStyle(
            color: AppColors.title,
            fontSize: 20,
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock_outline, color: AppColors.subtitle, size: 14),
            SizedBox(width: 6),
            Text(
              'Your private space together',
              style: TextStyle(color: AppColors.subtitle, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatsRow extends StatelessWidget {
  final SpaceProvider provider;

  const _StatsRow({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: Icons.photo_outlined,
            iconColor: AppColors.active,
            count: provider.photoCount + provider.videoCount,
            label: 'Media',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.chat_bubble_outline,
            iconColor: const Color(0xFFA855F7),
            count: provider.noteCount,
            label: 'Notes',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            icon: Icons.favorite_border,
            iconColor: AppColors.active,
            count: provider.momentCount,
            label: 'Moments',
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final int count;
  final String label;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: iconColor, size: 18),
          const SizedBox(height: 6),
          Text(
            '$count',
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: AppColors.subtitle, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final _SpaceTab selected;
  final ValueChanged<_SpaceTab> onChanged;

  const _SegmentedTabs({
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 42,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: _TabButton(
              icon: Icons.camera_alt_outlined,
              label: 'Photos',
              selected: selected == _SpaceTab.photos,
              onTap: () => onChanged(_SpaceTab.photos),
            ),
          ),
          Expanded(
            child: _TabButton(
              icon: Icons.chat_bubble_outline,
              label: 'Notes',
              selected: selected == _SpaceTab.notes,
              onTap: () => onChanged(_SpaceTab.notes),
            ),
          ),
        ],
      ),
    );
  }
}

class _TabButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: selected ? AppColors.active : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.active.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: selected ? Colors.white : AppColors.subtitle),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : AppColors.subtitle,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumsSection extends StatelessWidget {
  final String title;
  final List<SpaceAlbum> albums;
  final String? selectedAlbumId;
  final bool showAll;
  final int Function(String albumId) countForAlbum;
  final int outsideCount;
  final String unitLabel;
  final ValueChanged<String?> onSelected;
  final VoidCallback onShowAll;
  final VoidCallback onShowOutside;
  final ValueChanged<SpaceAlbum> onRename;
  final ValueChanged<SpaceAlbum> onDelete;

  const _AlbumsSection({
    required this.title,
    required this.albums,
    required this.selectedAlbumId,
    required this.showAll,
    required this.countForAlbum,
    required this.outsideCount,
    required this.unitLabel,
    required this.onSelected,
    required this.onShowAll,
    required this.onShowOutside,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.collections_bookmark_outlined, color: AppColors.active, size: 20),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: onShowOutside,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(0, 32),
              ),
              child: Text('Outside ($outsideCount)'),
            ),
            TextButton(
              onPressed: onShowAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                minimumSize: const Size(0, 32),
              ),
              child: Text(showAll ? 'All (on)' : 'All'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (albums.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: const Text(
              'No albums yet. Use Add Memory > Add Album to create one.',
              style: TextStyle(color: AppColors.subtitle, fontSize: 12),
            ),
          )
        else
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: albums.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.15,
            ),
            itemBuilder: (context, index) {
              final album = albums[index];
              final selected = selectedAlbumId == album.id && !showAll;
              return _AlbumCard(
                album: album,
                selected: selected,
                count: countForAlbum(album.id),
                unitLabel: unitLabel,
                onTap: () => onSelected(selected ? null : album.id),
                onRename: () => onRename(album),
                onDelete: () => onDelete(album),
              );
            },
          ),
      ],
    );
  }
}

class _AlbumCard extends StatelessWidget {
  final SpaceAlbum album;
  final bool selected;
  final int count;
  final String unitLabel;
  final VoidCallback onTap;
  final VoidCallback onRename;
  final VoidCallback onDelete;

  const _AlbumCard({
    required this.album,
    required this.selected,
    required this.count,
    required this.unitLabel,
    required this.onTap,
    required this.onRename,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.active : AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? AppColors.active : AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.folder_rounded, color: selected ? Colors.white : AppColors.active),
                const Spacer(),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: PopupMenuButton<String>(
                    icon: Icon(Icons.more_horiz, color: selected ? Colors.white : AppColors.subtitle, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 120),
                    onSelected: (value) {
                      if (value == 'rename') onRename();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(value: 'rename', child: Text('Rename')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              album.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? Colors.white : const Color(0xFF111827),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              '$count $unitLabel',
              style: TextStyle(
                color: selected ? Colors.white70 : AppColors.subtitle,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
class _MediaGrid extends StatelessWidget {
  final List<SpaceMedia> media;
  final VoidCallback onAdd;
  final ValueChanged<SpaceMedia> onOpen;
  final ValueChanged<SpaceMedia> onDelete;

  const _MediaGrid({
    required this.media,
    required this.onAdd,
    required this.onOpen,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: media.length + 1,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 1,
      ),
      itemBuilder: (context, index) {
        if (index == media.length) {
          return _AddTile(onTap: onAdd);
        }
        return _MediaTile(
          media: media[index],
          onTap: () => onOpen(media[index]),
          onDelete: () => onDelete(media[index]),
        );
      },
    );
  }
}

class _MediaTile extends StatelessWidget {
  final SpaceMedia media;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MediaTile({
    required this.media,
    required this.onTap,
    required this.onDelete,
  });

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _MediaPreview(media: media),
            if (media.isVideo)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.42),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 30),
                ),
              ),
            if (media.note.trim().isNotEmpty)
              Positioned(
                left: 8,
                right: 8,
                bottom: 28,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.36),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    media.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.36),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _formatDate(media.memoryDate),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            Positioned(
              top: 6,
              right: 6,
              child: InkWell(
                onTap: onDelete,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.42),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_outline, color: Colors.white, size: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MediaPreview extends StatelessWidget {
  final SpaceMedia media;

  const _MediaPreview({required this.media});

  @override
  Widget build(BuildContext context) {
    if (media.isVideo && media.displayUrl.isEmpty && media.localPath != null) {
      return Container(
        color: const Color(0xFF111827),
        child: const Icon(Icons.videocam, color: Colors.white, size: 42),
      );
    }

    final localPath = media.localPath;
    if (!kIsWeb && localPath != null && !media.isVideo) {
      return Image.file(File(localPath), fit: BoxFit.cover);
    }

    return Image.network(
      media.displayUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => Container(
        color: Colors.white,
        child: Icon(media.isVideo ? Icons.videocam : Icons.broken_image, color: AppColors.subtitle),
      ),
    );
  }
}

class _AddTile extends StatelessWidget {
  final VoidCallback onTap;

  const _AddTile({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.active.withValues(alpha: 0.5), style: BorderStyle.solid),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add, color: AppColors.active, size: 28),
            SizedBox(height: 8),
            Text(
              'Add Memory',
              style: TextStyle(color: AppColors.active, fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotesList extends StatelessWidget {
  final List<SpaceNote> notes;
  final List<SpaceMedia> Function(SpaceNote note) mediaForNote;
  final VoidCallback onAdd;
  final ValueChanged<SpaceMedia> onOpenMedia;
  final ValueChanged<SpaceNote> onDelete;

  const _NotesList({
    required this.notes,
    required this.mediaForNote,
    required this.onAdd,
    required this.onOpenMedia,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final note in notes) ...[
          _NoteCard(
            note: note,
            media: mediaForNote(note),
            onOpenMedia: onOpenMedia,
            onDelete: () => onDelete(note),
          ),
          const SizedBox(height: 14),
        ],
        _AddNoteButton(onTap: onAdd),
      ],
    );
  }
}

class _NoteCard extends StatelessWidget {
  final SpaceNote note;
  final List<SpaceMedia> media;
  final ValueChanged<SpaceMedia> onOpenMedia;
  final VoidCallback onDelete;

  const _NoteCard({
    required this.note,
    required this.media,
    required this.onOpenMedia,
    required this.onDelete,
  });

  String _formatDate(DateTime date) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('💕', style: TextStyle(fontSize: 24)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        note.title,
                        style: const TextStyle(
                          color: Color(0xFF374151),
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onDelete,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.delete_outline, color: AppColors.active, size: 20),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  note.content,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.subtitle,
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(
                      _formatDate(note.memoryDate),
                      style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10, fontWeight: FontWeight.w700),
                    ),
                    if (media.isNotEmpty) ...[
                      const Spacer(),
                      TextButton.icon(
                        onPressed: () => onOpenMedia(media.first),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 28),
                          foregroundColor: AppColors.active,
                        ),
                        icon: Icon(media.first.isVideo ? Icons.play_circle_outline : Icons.image_outlined, size: 16),
                        label: const Text('Open media', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800)),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AddNoteButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddNoteButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(42),
        foregroundColor: AppColors.active,
        side: BorderSide(color: AppColors.active.withValues(alpha: 0.55)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: const Icon(Icons.add, size: 18),
      label: const Text('Add New Note', style: TextStyle(fontWeight: FontWeight.w800)),
    );
  }
}

class _MediaSourceSheet extends StatelessWidget {
  final SpaceProvider provider;

  const _MediaSourceSheet({
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    return _BottomSheetFrame(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Add to Heart Space',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
          ),
          const SizedBox(height: 16),
          _SourceTile(
            icon: Icons.create_new_folder_outlined,
            title: 'Add Album',
            onTap: () => Navigator.pop(context, const _SpaceSourceResult.addAlbum()),
          ),
          const Divider(height: 10, color: AppColors.border),
          _SourceTile(
            icon: Icons.photo_camera_outlined,
            title: 'Take Photo',
            onTap: () => _pickAndClose(
              context,
              provider.capturePhoto,
              SpaceMediaType.photo,
            ),
          ),
          _SourceTile(
            icon: Icons.videocam_outlined,
            title: 'Record Video',
            onTap: () => _pickAndClose(
              context,
              provider.recordVideo,
              SpaceMediaType.video,
            ),
          ),
          _SourceTile(
            icon: Icons.photo_library_outlined,
            title: 'Choose Photo',
            onTap: () => _pickAndClose(
              context,
              provider.pickPhotoFromGallery,
              SpaceMediaType.photo,
            ),
          ),
          _SourceTile(
            icon: Icons.video_library_outlined,
            title: 'Choose Video',
            onTap: () => _pickAndClose(
              context,
              provider.pickVideoFromGallery,
              SpaceMediaType.video,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndClose(
    BuildContext context,
    Future<XFile?> Function() picker,
    SpaceMediaType type,
  ) async {
    final file = await picker();
    if (!context.mounted) return;
    _popPicked(context, file, type);
  }

  void _popPicked(BuildContext context, XFile? file, SpaceMediaType type) {
    if (file == null) {
      Navigator.pop(context);
      return;
    }
    Navigator.pop(context, _SpaceSourceResult.media(file: file, type: type));
  }
}

class _SourceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _SourceTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: AppColors.active.withValues(alpha: 0.1),
        child: Icon(icon, color: AppColors.active),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      onTap: onTap,
    );
  }
}

class _MemoryInputSheet extends StatefulWidget {
  final String title;
  final String primaryLabel;
  final String noteHint;
  final bool showTitleField;
  final bool showAlbumPicker;
  final XFile? previewFile;
  final SpaceMediaType? previewType;
  final List<SpaceAlbum> albums;
  final String? initialAlbumId;

  const _MemoryInputSheet({
    required this.title,
    required this.primaryLabel,
    required this.noteHint,
    this.showTitleField = false,
    this.showAlbumPicker = false,
    this.previewFile,
    this.previewType,
    this.albums = const [],
    this.initialAlbumId,
  });

  @override
  State<_MemoryInputSheet> createState() => _MemoryInputSheetState();
}

class _MemoryInputSheetState extends State<_MemoryInputSheet> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  DateTime _memoryDate = DateTime.now();
  String? _albumId;

  @override
  void initState() {
    super.initState();
    _albumId = widget.albums.any((album) => album.id == widget.initialAlbumId)
        ? widget.initialAlbumId
        : null;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _memoryDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _memoryDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetFrame(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.previewFile != null) ...[
              _UploadPreview(
                file: widget.previewFile!,
                type: widget.previewType ?? SpaceMediaType.photo,
              ),
              const SizedBox(height: 14),
            ],
            Text(
              widget.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF111827)),
            ),
            const SizedBox(height: 16),
            if (widget.showTitleField) ...[
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  prefixIcon: Icon(Icons.title),
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (widget.showAlbumPicker) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.collections_bookmark_outlined, color: AppColors.subtitle, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Album',
                        style: TextStyle(
                          color: AppColors.subtitle,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _AlbumChoice(
                        label: 'No album',
                        selected: _albumId == null,
                        onTap: () => setState(() => _albumId = null),
                      ),
                      for (final album in widget.albums)
                        _AlbumChoice(
                          label: album.title,
                          selected: _albumId == album.id,
                          onTap: () => setState(() => _albumId = album.id),
                        ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
            TextField(
              controller: _contentController,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: 'Memory note',
                hintText: widget.noteHint,
                prefixIcon: const Icon(Icons.favorite_border),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickDate,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.active,
                side: const BorderSide(color: AppColors.border),
              ),
              icon: const Icon(Icons.calendar_month, size: 18),
              label: Text('${_memoryDate.day}/${_memoryDate.month}/${_memoryDate.year}'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  _MemoryInput(
                    title: _titleController.text,
                    content: _contentController.text.trim(),
                    memoryDate: _memoryDate,
                    albumId: _albumId,
                  ),
                );
              },
              child: Text(widget.primaryLabel),
            ),
          ],
        ),
      ),
    );
  }
}

class _AlbumChoice extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _AlbumChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.active : AppColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: selected ? AppColors.active : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.subtitle,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _UploadPreview extends StatelessWidget {
  final XFile file;
  final SpaceMediaType type;

  const _UploadPreview({
    required this.file,
    required this.type,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (type == SpaceMediaType.photo && !kIsWeb)
              Image.file(File(file.path), fit: BoxFit.cover)
            else
              Container(
                color: const Color(0xFF111827),
                child: Icon(
                  type == SpaceMediaType.video ? Icons.videocam : Icons.image,
                  color: Colors.white,
                  size: 56,
                ),
              ),
            if (type == SpaceMediaType.video)
              Center(
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.play_arrow, color: Colors.white, size: 34),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BottomSheetFrame extends StatelessWidget {
  final Widget child;

  const _BottomSheetFrame({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: const BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.only(bottom: 18),
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(99),
              ),
            ),
            child,
          ],
        ),
      ),
    );
  }
}

class _SpaceSourceResult {
  final XFile? file;
  final SpaceMediaType? type;
  final bool addAlbum;

  const _SpaceSourceResult.media({
    required this.file,
    required this.type,
  }) : addAlbum = false;

  const _SpaceSourceResult.addAlbum()
      : file = null,
        type = null,
        addAlbum = true;
}

class _MemoryInput {
  final String? title;
  final String content;
  final DateTime memoryDate;
  final String? albumId;

  const _MemoryInput({
    this.title,
    required this.content,
    required this.memoryDate,
    this.albumId,
  });
}
