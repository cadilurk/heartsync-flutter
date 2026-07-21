import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/milestone.dart';
import '../models/song_result.dart';
import '../providers/milestone_provider.dart';
import 'auto_slider_background.dart';

// ── Mood definitions ─────────────────────────────────────────────────────────

class _Mood {
  final String id;
  final String emoji;
  final String label;
  final Color color;
  const _Mood(this.id, this.emoji, this.label, this.color);
}

const _moods = [
  _Mood('happy', '😄', 'Vui vẻ', Color(0xFFFBBF24)),
  _Mood('emotional', '🥹', 'Xúc động', Color(0xFF818CF8)),
  _Mood('romantic', '🥰', 'Lãng mạn', Color(0xFFF472B6)),
  _Mood('excited', '🤩', 'Hào hứng', Color(0xFFFB923C)),
  _Mood('happy_cry', '😭', 'Hạnh phúc', Color(0xFF34D399)),
  _Mood('nostalgic', '💭', 'Hoài niệm', Color(0xFF60A5FA)),
];

class _ChecklistDraft {
  final String id;
  final TextEditingController titleController;
  String assigneeId;
  bool isDone;

  _ChecklistDraft({
    required this.id,
    required String title,
    required this.assigneeId,
    required this.isDone,
  }) : titleController = TextEditingController(text: title);

  void dispose() {
    titleController.dispose();
  }
}

// ── Dialog ────────────────────────────────────────────────────────────────────

class MilestoneDialog extends StatefulWidget {
  final Milestone? milestone;
  final String currentUserId;

  const MilestoneDialog({
    super.key,
    this.milestone,
    required this.currentUserId,
  });

  @override
  State<MilestoneDialog> createState() => _MilestoneDialogState();
}

class _MilestoneDialogState extends State<MilestoneDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  final TextEditingController _songSearchController = TextEditingController();
  late DateTime _selectedDate;
  late String _selectedIcon;
  late String _selectedType;

  // Media
  List<XFile> _pendingCoverImages = [];
  String? _selectedMood;
  SongResult? _selectedSong;
  final List<_ChecklistDraft> _checklistDrafts = [];

  // Song search state
  List<SongResult> _songResults = [];
  bool _searchingSongs = false;
  Timer? _debounce;

  // Audio player
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _playingPreviewUrl;

  // For propose_date flow
  DateTime? _proposedDate;

  final List<String> _emojis = [
    '👋',
    '💯',
    '💝',
    '🎂',
    '👩‍❤️‍👨',
    '💌',
    '💍',
    '🎁',
    '✈️',
    '🎬',
    '🍽️',
    '🏠',
    '🚗',
    '🎉',
    '🌟',
  ];

  @override
  void initState() {
    super.initState();
    final m = widget.milestone;
    _titleController = TextEditingController(text: m?.title ?? '');
    _selectedDate = m?.date ?? DateTime.now();
    _selectedIcon = m?.icon ?? '🎉';
    _selectedType = m?.type ?? 'memory';
    _selectedMood = m?.mood;
    if (m?.songTitle != null) {
      _selectedSong = SongResult(
        trackId: 0,
        trackName: m!.songTitle!,
        artistName: m.songArtist ?? '',
        artworkUrl: m.songArtworkUrl,
        previewUrl: m.songPreviewUrl,
      );
    }
    if (m?.songPreviewUrl != null) {
      _songSearchController.text = m!.songTitle ?? '';
    }
    for (final task in m?.checklist ?? <MilestoneTask>[]) {
      _checklistDrafts.add(
        _ChecklistDraft(
          id: task.id,
          title: task.title,
          assigneeId: task.assignee.isNotEmpty
              ? task.assignee
              : widget.currentUserId,
          isDone: task.isDone,
        ),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _songSearchController.dispose();
    for (final task in _checklistDrafts) {
      task.dispose();
    }
    _debounce?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  bool _isCreator() => widget.milestone?.userId == widget.currentUserId;

  String _formatDate(DateTime date) {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  String _dateFmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _newTaskId() =>
      'task_${DateTime.now().microsecondsSinceEpoch}_${_checklistDrafts.length}';

  List<({String id, String label})> _assigneeOptions() {
    final session = context.read<AuthProvider>().session;
    final currentId = session.user?.id ?? widget.currentUserId;
    final currentLabel = session.profile?.displayName.trim().isNotEmpty == true
        ? '${session.profile!.displayName} (Bạn)'
        : 'Bạn';
    final partner = session.partner;
    final partnerLabel =
        session.partnerDisplayName ??
        (partner?.email.isNotEmpty == true ? partner!.email : 'Người ấy');

    return [
      (id: currentId, label: currentLabel),
      if (partner != null) (id: partner.id, label: partnerLabel),
    ];
  }

  String _assigneeLabel(String assigneeId) {
    final options = _assigneeOptions();
    return options
            .where((option) => option.id == assigneeId)
            .map((option) => option.label)
            .firstOrNull ??
        (assigneeId.isEmpty ? 'Chưa phân công' : 'Người được phân công');
  }

  bool _isTaskAssignedToCurrentUser(MilestoneTask task) {
    final currentId =
        context.read<AuthProvider>().session.user?.id ?? widget.currentUserId;
    return task.assignee == currentId;
  }

  List<MilestoneTask> _buildChecklistPayload() {
    return _checklistDrafts
        .map((task) {
          final title = task.titleController.text.trim();
          if (title.isEmpty) return null;
          return MilestoneTask(
            id: task.id,
            title: title,
            assignee: task.assigneeId,
            isDone: task.isDone,
          );
        })
        .whereType<MilestoneTask>()
        .toList();
  }

  void _addChecklistTask() {
    setState(() {
      _checklistDrafts.add(
        _ChecklistDraft(
          id: _newTaskId(),
          title: '',
          assigneeId: widget.currentUserId,
          isDone: false,
        ),
      );
    });
  }

  void _removeChecklistTask(int index) {
    final removed = _checklistDrafts.removeAt(index);
    removed.dispose();
    setState(() {});
  }

  Future<void> _pickDate({bool isProposal = false}) async {
    final initial = isProposal
        ? (_proposedDate ?? _selectedDate)
        : _selectedDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1980),
      lastDate: DateTime(2100),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.active,
            onPrimary: Colors.white,
            onSurface: AppColors.title,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isProposal)
          _proposedDate = picked;
        else
          _selectedDate = picked;
      });
    }
  }

  // ── Song search ───────────────────────────────────────────────────────────

  void _onSongSearchChanged(String query) {
    _debounce?.cancel();
    if (query.trim().isEmpty) {
      setState(() {
        _songResults = [];
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () async {
      setState(() => _searchingSongs = true);
      try {
        final results = await context.read<MilestoneProvider>().searchSongs(
          query,
        );
        if (mounted)
          setState(() {
            _songResults = results;
            _searchingSongs = false;
          });
      } catch (_) {
        if (mounted) setState(() => _searchingSongs = false);
      }
    });
  }

  Future<void> _togglePreview(SongResult song) async {
    if (_playingPreviewUrl == song.previewUrl) {
      await _audioPlayer.stop();
      setState(() => _playingPreviewUrl = null);
    } else {
      await _audioPlayer.stop();
      if (song.previewUrl != null) {
        setState(() => _playingPreviewUrl = song.previewUrl);
        await _audioPlayer.play(UrlSource(song.previewUrl!));
        _audioPlayer.onPlayerComplete.listen((_) {
          if (mounted) setState(() => _playingPreviewUrl = null);
        });
      }
    }
  }

  void _selectSong(SongResult song) {
    setState(() {
      _selectedSong = song;
      _songResults = [];
      _songSearchController.text = '${song.trackName} – ${song.artistName}';
    });
    _audioPlayer.stop();
    _playingPreviewUrl = null;
  }

  // ── Cover image ───────────────────────────────────────────────────────────

  Future<void> _pickCoverImages() async {
    final files = await context.read<MilestoneProvider>().pickCoverImages();
    if (files.isNotEmpty) {
      setState(() {
        _pendingCoverImages = files;
      });
    }
  }

  // ── Submit (create / edit) ────────────────────────────────────────────────

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<MilestoneProvider>();
    final title = _titleController.text.trim();
    final checklist = _buildChecklistPayload();

    try {
      Milestone saved;
      if (widget.milestone == null) {
        saved = await provider.addMilestone(
          title: title,
          date: _selectedDate,
          icon: _selectedIcon,
          type: _selectedType,
          mood: _selectedMood,
          songTitle: _selectedSong?.trackName,
          songArtist: _selectedSong?.artistName,
          songPreviewUrl: _selectedSong?.previewUrl,
          songArtworkUrl: _selectedSong?.artworkUrl,
          checklist: checklist,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Đã thêm cột mốc! Chờ người kia xác nhận 🕐'),
            ),
          );
        }
      } else {
        await provider.editMilestone(
          id: widget.milestone!.id,
          title: title,
          date: _selectedDate,
          icon: _selectedIcon,
          type: _selectedType,
          mood: _selectedMood,
          songTitle: _selectedSong?.trackName,
          songArtist: _selectedSong?.artistName,
          songPreviewUrl: _selectedSong?.previewUrl,
          songArtworkUrl: _selectedSong?.artworkUrl,
          checklist: checklist,
        );
        saved = provider.milestones.firstWhere(
          (m) => m.id == widget.milestone!.id,
          orElse: () => widget.milestone!,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã cập nhật cột mốc 🕐')),
          );
        }
      }

      // Upload cover image if chosen
      if (_pendingCoverImages.isNotEmpty && mounted) {
        try {
          await provider.uploadCoverImage(
            milestoneId: saved.id,
            files: _pendingCoverImages,
          );
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lưu milestone nhưng ảnh bìa chưa upload: $e'),
              ),
            );
          }
        }
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Có lỗi xảy ra: $e')));
      }
    }
  }

  void _delete() async {
    if (widget.milestone == null) return;
    final provider = context.read<MilestoneProvider>();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá cột mốc?'),
        content: const Text(
          'Bạn có chắc chắn muốn xoá cột mốc quan trọng này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huỷ', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Xoá',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await provider.removeMilestone(widget.milestone!.id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Đã xoá cột mốc.')));
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Không thể xoá: $e')));
      }
    }
  }

  // ── Partner respond ───────────────────────────────────────────────────────

  Future<void> _respond(String action) async {
    final m = widget.milestone!;
    final provider = context.read<MilestoneProvider>();
    if (action == 'propose_date') {
      await _pickDate(isProposal: true);
      if (_proposedDate == null) return;
      try {
        await provider.respondToMilestone(
          id: m.id,
          action: 'propose_date',
          proposedDate: _dateFmt(_proposedDate!),
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Đã đề xuất ngày ${_formatDate(_proposedDate!)} 💬',
              ),
            ),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
      return;
    }
    try {
      await provider.respondToMilestone(id: m.id, action: action);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'accept' ? 'Đã xác nhận ✅' : 'Đã từ chối ❌',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  Future<void> _confirm(String action) async {
    final m = widget.milestone!;
    final provider = context.read<MilestoneProvider>();
    try {
      await provider.confirmMilestone(id: m.id, action: action);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              action == 'accept' ? 'Đã chấp nhận ngày mới ✅' : 'Đã từ chối ❌',
            ),
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.milestone != null;
    final providerMilestones = context.watch<MilestoneProvider>().milestones;
    final m = isEdit
        ? providerMilestones
                  .where((item) => item.id == widget.milestone!.id)
                  .firstOrNull ??
              widget.milestone
        : null;
    final amCreator = isEdit ? _isCreator() : true;
    final status = m?.status ?? 'pending';

    final showPartnerActions = isEdit && !amCreator && status == 'pending';
    final showCreatorConfirm = isEdit && amCreator && status == 'negotiating';
    final showEditForm =
        !isEdit || (amCreator && status != 'completed' && status != 'declined');

    return Container(
      padding: EdgeInsets.only(
        left: 0,
        right: 0,
        top: 0,
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isEdit ? 'Chi tiết cột mốc' : 'Thêm cột mốc mới',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.title,
                        ),
                      ),
                      if (isEdit && amCreator)
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: _delete,
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Status Banner
                  if (isEdit) _buildStatusBanner(status, m!),

                  // Partner actions
                  if (showPartnerActions) ...[
                    const SizedBox(height: 12),
                    _buildPartnerActionPanel(m!),
                  ],

                  // Creator confirm
                  if (showCreatorConfirm) ...[
                    const SizedBox(height: 12),
                    _buildCreatorConfirmPanel(m!),
                  ],

                  // Edit / Create form
                  if (showEditForm) ...[
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // ── Cover Image ─────────────────────────────────
                          _buildCoverImageSection(m),
                          const SizedBox(height: 20),

                          // ── Title ────────────────────────────────────────
                          _sectionLabel('Tên cột mốc'),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _titleController,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppColors.title,
                            ),
                            decoration: _inputDecoration(
                              'Ví dụ: Lần đầu gặp nhau...',
                            ),
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Vui lòng nhập tên cột mốc'
                                : null,
                          ),
                          const SizedBox(height: 20),

                          // ── Type ─────────────────────────────────────────
                          _sectionLabel('Loại cột mốc'),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _typeChip('memory', Icons.favorite, 'Kỉ niệm'),
                              const SizedBox(width: 12),
                              _typeChip(
                                'challenge',
                                Icons.auto_awesome,
                                'Thử thách',
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // ── Date ─────────────────────────────────────────
                          _sectionLabel('Thời gian'),
                          const SizedBox(height: 8),
                          InkWell(
                            onTap: () => _pickDate(),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 14,
                              ),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.calendar_today_outlined,
                                    color: AppColors.active,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    _formatDate(_selectedDate),
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.title,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                    Icons.arrow_drop_down,
                                    color: Colors.grey,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Checklist ────────────────────────────────────
                          _sectionLabel('Checklist chuẩn bị'),
                          const SizedBox(height: 8),
                          _buildChecklistEditor(),
                          const SizedBox(height: 20),

                          // ── Icon picker ───────────────────────────────────
                          _sectionLabel('Biểu tượng'),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 52,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: _emojis.length,
                              itemBuilder: (_, i) {
                                final emoji = _emojis[i];
                                final sel = emoji == _selectedIcon;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedIcon = emoji),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      color: sel
                                          ? AppColors.active.withValues(
                                              alpha: 0.1,
                                            )
                                          : Colors.grey.shade50,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: sel
                                            ? AppColors.active
                                            : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    alignment: Alignment.center,
                                    child: Text(
                                      emoji,
                                      style: const TextStyle(fontSize: 22),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // ── Mood picker ───────────────────────────────────
                          _sectionLabel('Cảm xúc lúc đó'),
                          const SizedBox(height: 10),
                          _buildMoodPicker(),
                          const SizedBox(height: 20),

                          // ── Song search ───────────────────────────────────
                          _sectionLabel('Nhạc nền – Bài hát của tụi mình'),
                          const SizedBox(height: 8),
                          _buildSongSection(),
                          const SizedBox(height: 28),

                          // ── Submit button ─────────────────────────────────
                          ElevatedButton(
                            onPressed: _submit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFF35C9B),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              isEdit ? 'Lưu Thay Đổi' : 'Thêm Cột Mốc Mới',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else if (isEdit)
                    _buildReadOnlyView(m!),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Section helpers ───────────────────────────────────────────────────────

  Widget _sectionLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w700,
      color: AppColors.subtitle,
    ),
  );

  InputDecoration _inputDecoration(String hint) => InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade300),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(color: Colors.grey.shade200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: AppColors.active, width: 1.5),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Colors.red),
    ),
  );

  Widget _typeChip(String type, IconData icon, String label) {
    final selected = _selectedType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.active.withValues(alpha: 0.1)
                : Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? AppColors.active : Colors.grey.shade200,
              width: 1.5,
            ),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: selected ? AppColors.active : Colors.grey,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: selected ? AppColors.active : AppColors.subtitle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistEditor() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (_checklistDrafts.isEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Text(
                'Thêm các việc cần chuẩn bị như mua vé, đặt phòng, chuẩn bị đồ...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  height: 1.4,
                ),
              ),
            )
          else ...[
            for (var i = 0; i < _checklistDrafts.length; i++) ...[
              _buildChecklistEditorRow(i),
              if (i != _checklistDrafts.length - 1) const SizedBox(height: 10),
            ],
            const SizedBox(height: 10),
          ],
          OutlinedButton.icon(
            onPressed: _addChecklistTask,
            icon: const Icon(Icons.add_task, size: 18),
            label: const Text(
              'Thêm hoạt động',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.active,
              side: const BorderSide(color: AppColors.active),
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistEditorRow(int index) {
    final task = _checklistDrafts[index];
    final assignees = _assigneeOptions();
    if (!assignees.any((option) => option.id == task.assigneeId) &&
        assignees.isNotEmpty) {
      task.assigneeId = assignees.first.id;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: AppColors.active.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.checklist,
              size: 18,
              color: AppColors.active,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              children: [
                TextFormField(
                  controller: task.titleController,
                  decoration: _inputDecoration('Hoạt động cần làm').copyWith(
                    isDense: true,
                    prefixIcon: const Icon(
                      Icons.checklist,
                      size: 18,
                      color: AppColors.active,
                    ),
                  ),
                  validator: (_) {
                    if (task.titleController.text.trim().isEmpty) {
                      return 'Nhập tên hoạt động';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: task.assigneeId,
                  isExpanded: true,
                  decoration: _inputDecoration('Phân công cho ai?').copyWith(
                    isDense: true,
                    prefixIcon: const Icon(
                      Icons.person_outline,
                      size: 18,
                      color: AppColors.active,
                    ),
                  ),
                  items: assignees
                      .map(
                        (assignee) => DropdownMenuItem<String>(
                          value: assignee.id,
                          child: Text(
                            assignee.label,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: assignees.length <= 1
                      ? null
                      : (value) {
                          if (value == null) return;
                          setState(() => task.assigneeId = value);
                        },
                  validator: (value) => value == null || value.isEmpty
                      ? 'Chọn người phụ trách'
                      : null,
                  selectedItemBuilder: (context) {
                    return assignees
                        .map(
                          (assignee) => Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              assignee.label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        )
                        .toList();
                  },
                  icon: const Icon(Icons.expand_more, color: AppColors.active),
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.title,
                    fontWeight: FontWeight.w700,
                  ),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                if (task.isDone) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        size: 14,
                        color: Colors.green.shade600,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Hoạt động này đã được đánh dấu xong',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.green.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            onPressed: () => _removeChecklistTask(index),
            icon: const Icon(Icons.close, size: 18, color: Colors.grey),
            tooltip: 'Xoá hoạt động',
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistProgress(Milestone m) {
    final percent = (m.progress * 100).round();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFDF2F8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFBCFE8)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.task_alt, size: 18, color: AppColors.active),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Tiến độ chuẩn bị',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.title,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColors.active,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: m.progress,
              minHeight: 8,
              backgroundColor: Colors.white,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.active),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${m.completedTaskCount}/${m.totalTaskCount} hoạt động đã xong',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistReadOnly(Milestone m) {
    if (m.checklist.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChecklistProgress(m),
        const SizedBox(height: 12),
        ...m.checklist.map((task) {
          final canToggle = _isTaskAssignedToCurrentUser(task);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: task.isDone ? Colors.green.shade50 : Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: task.isDone
                      ? Colors.green.shade200
                      : Colors.grey.shade200,
                ),
              ),
              child: Row(
                children: [
                  Checkbox(
                    value: task.isDone,
                    activeColor: Colors.green,
                    visualDensity: VisualDensity.compact,
                    onChanged: canToggle
                        ? (value) async {
                            try {
                              await context
                                  .read<MilestoneProvider>()
                                  .updateChecklistTask(
                                    milestoneId: m.id,
                                    taskId: task.id,
                                    isDone: value ?? false,
                                  );
                            } catch (e) {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Không thể cập nhật checklist: $e',
                                    ),
                                  ),
                                );
                              }
                            }
                          }
                        : null,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          task.title,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: task.isDone
                                ? Colors.green.shade700
                                : AppColors.title,
                            decoration: task.isDone
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              canToggle ? Icons.person : Icons.lock_outline,
                              size: 12,
                              color: canToggle
                                  ? AppColors.active
                                  : Colors.grey.shade500,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                canToggle
                                    ? 'Bạn phụ trách'
                                    : '${_assigneeLabel(task.assignee)} phụ trách',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: canToggle
                                      ? AppColors.active
                                      : Colors.grey.shade600,
                                  fontWeight: FontWeight.w600,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  // ── Cover Image Section ───────────────────────────────────────────────────

  Widget _buildCoverImageSection(Milestone? m) {
    final hasLocal = _pendingCoverImages.isNotEmpty;
    final hasRemote = m != null && m.coverImageUrls.isNotEmpty;

    if (!hasLocal && !hasRemote) {
      return GestureDetector(
        onTap: _pickCoverImages,
        child: Container(
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade200, width: 1.5),
            color: Colors.grey.shade50,
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 32,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 8),
                Text(
                  'Chọn ảnh bìa (tối đa 5)',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final itemCount = hasLocal
        ? _pendingCoverImages.length
        : m!.coverImageUrls.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: itemCount,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              return Container(
                width: 120,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: hasLocal
                    ? Image.network(
                        _pendingCoverImages[i].path,
                        fit: BoxFit.cover,
                      )
                    : FramedContainImage(
                        imageUrl: m!.coverImageUrls[i],
                        borderRadius: 15,
                        padding: const EdgeInsets.all(6),
                      ),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickCoverImages,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.edit, size: 14, color: AppColors.active),
              SizedBox(width: 4),
              Text(
                'Đổi ảnh',
                style: TextStyle(
                  color: AppColors.active,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Mood Picker ───────────────────────────────────────────────────────────

  Widget _buildMoodPicker() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _moods.map((mood) {
        final selected = _selectedMood == mood.id;
        return GestureDetector(
          onTap: () =>
              setState(() => _selectedMood = selected ? null : mood.id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected
                  ? mood.color.withValues(alpha: 0.15)
                  : Colors.grey.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: selected ? mood.color : Colors.grey.shade200,
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(mood.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  mood.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: selected ? mood.color : AppColors.subtitle,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Song Section ──────────────────────────────────────────────────────────

  Widget _buildSongSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Selected song mini player
        if (_selectedSong != null) _buildMiniPlayer(_selectedSong!),
        if (_selectedSong != null) const SizedBox(height: 10),

        // Search field
        TextField(
          controller: _songSearchController,
          onChanged: _onSongSearchChanged,
          decoration: _inputDecoration('Tìm tên bài hát hoặc nghệ sĩ...')
              .copyWith(
                prefixIcon: const Icon(
                  Icons.music_note_outlined,
                  color: AppColors.active,
                  size: 20,
                ),
                suffixIcon: _searchingSongs
                    ? const Padding(
                        padding: EdgeInsets.all(12),
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.active,
                          ),
                        ),
                      )
                    : null,
              ),
        ),

        // Song results
        if (_songResults.isNotEmpty) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: ListView.separated(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(vertical: 4),
                itemCount: _songResults.length,
                separatorBuilder: (_, __) =>
                    Divider(height: 1, color: Colors.grey.shade100),
                itemBuilder: (_, i) => _buildSongTile(_songResults[i]),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMiniPlayer(SongResult song) {
    final playing = _playingPreviewUrl == song.previewUrl;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF9F0FA), Color(0xFFEEF2FF)],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFDDD6FE)),
      ),
      child: Row(
        children: [
          // Artwork
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: song.artworkUrl != null
                ? Image.network(
                    song.artworkUrl!,
                    width: 44,
                    height: 44,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 44,
                    height: 44,
                    color: Colors.purple.shade100,
                    child: const Icon(Icons.music_note, color: Colors.purple),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.trackName,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppColors.title,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  song.artistName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Play/stop
          if (song.previewUrl != null)
            GestureDetector(
              onTap: () => _togglePreview(song),
              child: Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: Color(0xFFA855F7),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          const SizedBox(width: 8),
          // Remove
          GestureDetector(
            onTap: () {
              setState(() {
                _selectedSong = null;
                _songSearchController.clear();
                _songResults = [];
              });
              _audioPlayer.stop();
              _playingPreviewUrl = null;
            },
            child: const Icon(Icons.close, size: 18, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildSongTile(SongResult song) {
    final playing = _playingPreviewUrl == song.previewUrl;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: song.artworkUrl != null
            ? Image.network(
                song.artworkUrl!,
                width: 42,
                height: 42,
                fit: BoxFit.cover,
              )
            : Container(
                width: 42,
                height: 42,
                color: Colors.purple.shade50,
                child: const Icon(
                  Icons.music_note,
                  color: Colors.purple,
                  size: 20,
                ),
              ),
      ),
      title: Text(
        song.trackName,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        song.artistName,
        style: const TextStyle(fontSize: 11, color: Colors.grey),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (song.previewUrl != null)
            GestureDetector(
              onTap: () => _togglePreview(song),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: playing
                      ? Colors.purple.shade100
                      : Colors.grey.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                  size: 18,
                  color: playing ? Colors.purple : Colors.grey.shade600,
                ),
              ),
            ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _selectSong(song),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.active,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                'Chọn',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
      onTap: () => _selectSong(song),
    );
  }

  // ── Status Banner ─────────────────────────────────────────────────────────

  Widget _buildStatusBanner(String status, Milestone m) {
    Color bgColor;
    Color textColor;
    IconData icon;
    String label;
    switch (status) {
      case 'completed':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade700;
        icon = Icons.check_circle_outline;
        label = 'Hoàn thành – cả hai đã xác nhận ✅';
        break;
      case 'declined':
        bgColor = Colors.red.shade50;
        textColor = Colors.red.shade700;
        icon = Icons.cancel_outlined;
        label = 'Đã từ chối ❌';
        break;
      case 'negotiating':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade700;
        icon = Icons.chat_bubble_outline;
        final d = m.partnerProposedDate != null
            ? _formatDate(
                DateTime.tryParse(m.partnerProposedDate!) ?? DateTime.now(),
              )
            : '...';
        label = 'Đang thương lượng 💬 – Đề xuất: $d';
        break;
      default:
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade700;
        icon = Icons.hourglass_empty_outlined;
        label = 'Đang chờ người kia xác nhận 🕐';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPartnerActionPanel(Milestone m) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Xác nhận cột mốc này',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: AppColors.subtitle,
          ),
        ),
        const SizedBox(height: 10),
        ElevatedButton.icon(
          onPressed: () => _respond('accept'),
          icon: const Icon(Icons.check_circle_outline, size: 18),
          label: const Text(
            'Đồng ý xác nhận',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _respond('propose_date'),
          icon: const Icon(Icons.edit_calendar_outlined, size: 18),
          label: const Text(
            'Đề xuất ngày khác',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.active,
            side: const BorderSide(color: AppColors.active),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _respond('decline'),
          icon: const Icon(Icons.cancel_outlined, size: 18),
          label: const Text(
            'Từ chối',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.red,
            side: const BorderSide(color: Colors.red),
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreatorConfirmPanel(Milestone m) {
    final proposedDateStr = m.partnerProposedDate != null
        ? _formatDate(
            DateTime.tryParse(m.partnerProposedDate!) ?? DateTime.now(),
          )
        : '...';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bạn ấy đề xuất ngày mới:',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.black54,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                proposedDateStr,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.title,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => _confirm('accept'),
                icon: const Icon(Icons.check, size: 16),
                label: const Text(
                  'Chấp nhận',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _confirm('decline'),
                icon: const Icon(Icons.close, size: 16),
                label: const Text(
                  'Từ chối',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReadOnlyView(Milestone m) {
    final mood = _moods.where((mo) => mo.id == m.mood).firstOrNull;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        // Cover image
        if (m.coverImageUrl != null) ...[
          SizedBox(
            height: 190,
            width: double.infinity,
            child: FramedContainImage(
              imageUrl: m.coverImageUrl!,
              borderRadius: 16,
              padding: const EdgeInsets.all(10),
            ),
          ),
          const SizedBox(height: 16),
        ],
        Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.pink.shade50.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Text(m.icon, style: const TextStyle(fontSize: 28)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.title,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(m.date),
                    style: const TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (mood != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: mood.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: mood.color.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(mood.emoji, style: const TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  mood.label,
                  style: TextStyle(
                    color: mood.color,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
        if (m.songTitle != null) ...[
          const SizedBox(height: 12),
          _buildMiniPlayer(
            SongResult(
              trackId: 0,
              trackName: m.songTitle!,
              artistName: m.songArtist ?? '',
              artworkUrl: m.songArtworkUrl,
              previewUrl: m.songPreviewUrl,
            ),
          ),
        ],
        if (m.checklist.isNotEmpty) ...[
          const SizedBox(height: 16),
          _buildChecklistReadOnly(m),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            _confirmChip('Người tạo', m.creatorConfirmed),
            const SizedBox(width: 10),
            _confirmChip('Người kia', m.partnerConfirmed),
          ],
        ),
      ],
    );
  }

  Widget _confirmChip(String label, bool confirmed) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: confirmed ? Colors.green.shade50 : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: confirmed ? Colors.green.shade200 : Colors.grey.shade200,
          ),
        ),
        child: Column(
          children: [
            Icon(
              confirmed ? Icons.check_circle : Icons.radio_button_unchecked,
              color: confirmed ? Colors.green : Colors.grey,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: confirmed ? Colors.green.shade700 : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
