import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/milestone.dart';
import '../providers/milestone_provider.dart';
import '../../../app/theme.dart';

class MilestoneDialog extends StatefulWidget {
  final Milestone? milestone; // If null, we are in CREATE mode. Otherwise, EDIT mode.

  const MilestoneDialog({
    super.key,
    this.milestone,
  });

  @override
  State<MilestoneDialog> createState() => _MilestoneDialogState();
}

class _MilestoneDialogState extends State<MilestoneDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late DateTime _selectedDate;
  late String _selectedIcon;
  late String _selectedType; // 'memory' or 'challenge'
  late bool _isCompleted;

  final List<String> _emojis = [
    '👋', '💯', '💝', '🎂', '👩‍❤️‍👨', '💌', '💍', '🎁', '✈️', '🎬', '🍽️', '🏠', '🚗', '🎉', '🌟'
  ];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.milestone?.title ?? '');
    _selectedDate = widget.milestone?.date ?? DateTime.now();
    _selectedIcon = widget.milestone?.icon ?? '🎉';
    _selectedType = widget.milestone?.type ?? 'memory';
    _isCompleted = widget.milestone?.isCompleted ?? false;
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1980),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.active,
              onPrimary: Colors.white,
              onSurface: AppColors.title,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<MilestoneProvider>();
    final title = _titleController.text.trim();

    try {
      if (widget.milestone == null) {
        // Create mode
        await provider.addMilestone(
          title: title,
          date: _selectedDate,
          icon: _selectedIcon,
          type: _selectedType,
          isCompleted: _selectedType == 'challenge' ? _isCompleted : false,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã thêm cột mốc mới thành công!')),
          );
        }
      } else {
        // Edit mode
        await provider.editMilestone(
          id: widget.milestone!.id,
          title: title,
          date: _selectedDate,
          icon: _selectedIcon,
          type: _selectedType,
          isCompleted: _selectedType == 'challenge' ? _isCompleted : false,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã cập nhật cột mốc thành công!')),
          );
        }
      }
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Có lỗi xảy ra: $e')),
        );
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
        content: const Text('Bạn có chắc chắn muốn xoá cột mốc quan trọng này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huỷ', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xoá', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await provider.removeMilestone(widget.milestone!.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xoá cột mốc kỉ niệm.')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể xoá cột mốc: $e')),
          );
        }
      }
    }
  }

  String _formatDate(DateTime date) {
    final months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${months[date.month - 1]} ${date.day.toString().padLeft(2, '0')}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.milestone != null;

    return Container(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header indicator bar
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Chỉnh sửa cột mốc' : 'Thêm cột mốc mới',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.title,
                    ),
                  ),
                  if (isEdit)
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: _delete,
                    ),
                ],
              ),
              const SizedBox(height: 20),

              // Title Field
              Text(
                'Tên cột mốc kỉ niệm / Thử thách',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.subtitle),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.title),
                decoration: InputDecoration(
                  hintText: 'Ví dụ: Lần đầu gặp nhau, Gọi video 1 tiếng...',
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
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Vui lòng nhập tên cột mốc';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Milestone Type Selection
              Text(
                'Loại cột mốc',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.subtitle),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = 'memory'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedType == 'memory'
                              ? AppColors.active.withValues(alpha: 0.1)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedType == 'memory' ? AppColors.active : Colors.grey.shade200,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.favorite,
                              size: 18,
                              color: _selectedType == 'memory' ? AppColors.active : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Kỉ niệm',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: _selectedType == 'memory' ? AppColors.active : AppColors.subtitle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedType = 'challenge'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: _selectedType == 'challenge'
                              ? AppColors.active.withValues(alpha: 0.1)
                              : Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _selectedType == 'challenge' ? AppColors.active : Colors.grey.shade200,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 18,
                              color: _selectedType == 'challenge' ? AppColors.active : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Thử thách',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: _selectedType == 'challenge' ? AppColors.active : AppColors.subtitle,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Completed Tickbox (only for challenge type)
              if (_selectedType == 'challenge') ...[
                CheckboxListTile(
                  tileColor: Colors.green.shade50.withValues(alpha: 0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.green.shade100),
                  ),
                  title: const Text(
                    'Đã hoàn thành thử thách này',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: Colors.green,
                    ),
                  ),
                  value: _isCompleted,
                  activeColor: Colors.green,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                  onChanged: (val) {
                    setState(() {
                      _isCompleted = val ?? false;
                    });
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Date Selection
              Text(
                'Thời gian diễn ra',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.subtitle),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDate,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined, color: AppColors.active, size: 20),
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
                      const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Icon Selection
              Text(
                'Biểu tượng cảm xúc',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.subtitle),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 52,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _emojis.length,
                  itemBuilder: (context, index) {
                    final emoji = _emojis[index];
                    final isSelected = emoji == _selectedIcon;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedIcon = emoji;
                        });
                      },
                      child: Container(
                        width: 48,
                        height: 48,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.active.withValues(alpha: 0.1) : Colors.grey.shade50,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected ? AppColors.active : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          emoji,
                          style: const TextStyle(
                            fontSize: 22,
                            fontFamily: 'Apple Color Emoji',
                            fontFamilyFallback: ['Segoe UI Emoji', 'Noto Color Emoji', 'Android Emoji'],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 30),

              // Action Button
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF35C9B), // Pink matching the screenshot
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
      ),
    );
  }
}
