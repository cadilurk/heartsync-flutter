import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../providers/pet_provider.dart';

class AdoptPetScreen extends StatefulWidget {
  const AdoptPetScreen({super.key});

  @override
  State<AdoptPetScreen> createState() => _AdoptPetScreenState();
}

class _AdoptPetScreenState extends State<AdoptPetScreen> {
  final _nameController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  
  String _selectedType = 'cat'; // 'cat', 'dog', 'bunny'
  bool _isSubmitting = false;

  final List<Map<String, String>> _petTypes = [
    {
      'type': 'cat',
      'emoji': '🐱',
      'label': 'Mèo Con',
      'description': 'Lém lỉnh & đáng yêu',
    },
    {
      'type': 'dog',
      'emoji': '🐶',
      'label': 'Cún Con',
      'description': 'Trung thành & ấm áp',
    },
    {
      'type': 'bunny',
      'emoji': '🐰',
      'label': 'Thỏ Bông',
      'description': 'Hiền lành & tinh nghịch',
    },
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submitAdoption() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _isSubmitting = true);
    try {
      await context.read<PetProvider>().adoptNewPet(
            _selectedType,
            _nameController.text.trim(),
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Chào mừng ${_nameController.text.trim()} đến với gia đình!'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Đã xảy ra lỗi: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                
                // Header Icon / Emoji
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.title.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Text(
                      '🐾',
                      style: TextStyle(fontSize: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Titles
                Text(
                  'Nuôi Thú Cưng Chung',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: AppColors.title,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Chọn một bé thú cưng để cùng người ấy chăm sóc và vun đắp tình yêu nhé!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.subtitle,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                
                // Pet Choices Grid
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _petTypes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final item = _petTypes[index];
                    final isSelected = _selectedType == item['type'];
                    
                    return GestureDetector(
                      onTap: () => setState(() => _selectedType = item['type']!),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.active : AppColors.border,
                            width: isSelected ? 2 : 1,
                          ),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: AppColors.active.withOpacity(0.08),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  )
                                ]
                              : [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  )
                                ],
                        ),
                        child: Row(
                          children: [
                            // Emoji circle
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppColors.active.withOpacity(0.1)
                                    : AppColors.bg,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  item['emoji']!,
                                  style: const TextStyle(fontSize: 32),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            
                            // Labels
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['label']!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['description']!,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.subtitle,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            
                            // Radio indicator
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? AppColors.active : Colors.grey.shade400,
                                  width: 2,
                                ),
                              ),
                              child: isSelected
                                  ? Center(
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: const BoxDecoration(
                                          color: AppColors.active,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                
                // Name Input field
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Đặt tên cho thú cưng',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.subtitle,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập tên cho bé cưng';
                    }
                    if (value.trim().length > 15) {
                      return 'Tên không được dài quá 15 ký tự';
                    }
                    return null;
                  },
                  decoration: const InputDecoration(
                    hintText: 'Ví dụ: Love Cat, Cục Bông...',
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
                const SizedBox(height: 32),
                
                // Submit Button
                ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitAdoption,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.active,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Nhận Nuôi Ngay 🐾',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
