import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../app/theme.dart';
import '../providers/pet_provider.dart';
import '../models/challenge.dart';
import '../models/love_pet.dart';
import 'adopt_pet_screen.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> with SingleTickerProviderStateMixin {
  late AnimationController _swayController;
  late Animation<double> _swayAnimation;

  @override
  void initState() {
    super.initState();
    _swayController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _swayAnimation = Tween<double>(begin: -0.06, end: 0.06).animate(
      CurvedAnimation(parent: _swayController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PetProvider>().loadPetAndChallenges();
    });
  }

  @override
  void dispose() {
    _swayController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    await context.read<PetProvider>().loadPetAndChallenges();
  }

  void _showChangePetDialog(LovePet pet) {
    final nameController = TextEditingController(text: pet.name);
    String selectedType = pet.petType;
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: const Text('Cài đặt Thú Cưng', style: TextStyle(fontWeight: FontWeight.bold)),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Chọn loài thú cưng:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildSpeciesOption('cat', '🐱', 'Mèo', selectedType, (type) {
                            setModalState(() => selectedType = type);
                          }),
                          _buildSpeciesOption('dog', '🐶', 'Cún', selectedType, (type) {
                            setModalState(() => selectedType = type);
                          }),
                          _buildSpeciesOption('bunny', '🐰', 'Thỏ', selectedType, (type) {
                            setModalState(() => selectedType = type);
                          }),
                        ],
                      ),
                      const SizedBox(height: 16),
                      const Text('Tên thú cưng:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nameController,
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Tên không được trống' : null,
                        decoration: const InputDecoration(
                          hintText: 'Đặt tên mới...',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!formKey.currentState!.validate()) return;
                    Navigator.pop(context);
                    
                    try {
                      await context.read<PetProvider>().adoptNewPet(selectedType, nameController.text.trim());
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🎉 Đã cập nhật thú cưng của hai bạn!')),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('❌ Lỗi: ${e.toString()}'), backgroundColor: Colors.red),
                        );
                      }
                    }
                  },
                  child: const Text('Xác nhận'),
                )
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildSpeciesOption(String type, String emoji, String label, String currentType, Function(String) onSelect) {
    final isSelected = currentType == type;
    return GestureDetector(
      onTap: () => onSelect(type),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.active.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? AppColors.active : Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 28)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: isSelected ? AppColors.active : Colors.black87)),
          ],
        ),
      ),
    );
  }

  void _showUnfreezeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('❤️ Hồi Sinh Thú Cưng', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Thú cưng đã bị đóng băng vì quá 7 ngày không làm nhiệm vụ. Hãy chọn một cách giải băng dưới đây:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              
              // Option 1: Free
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await context.read<PetProvider>().unfreeze('free');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🎉 Giải băng thành công! Thú cưng đã tỉnh giấc.')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Chưa Đủ Điều Kiện'),
                          content: Text(e.toString().replaceAll('Exception: ', '')),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))
                          ],
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('💬', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Cách 1: Gửi 10 chuông yêu thương', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text('Cả hai cùng gửi tổng cộng 10 tín hiệu yêu thương.', style: TextStyle(fontSize: 11, color: AppColors.subtitle)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 18),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              
              // Option 2: Store
              InkWell(
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    await context.read<PetProvider>().unfreeze('store');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('🎉 Đã dùng Bình Nước Hồi Sinh để mở băng thú cưng thành công!')),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Chưa Mua Vật Phẩm'),
                          content: Text(e.toString().replaceAll('Exception: ', '')),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng'))
                          ],
                        ),
                      );
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Text('🧪', style: TextStyle(fontSize: 24)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Cách 2: Bình Nước Hồi Sinh', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            const SizedBox(height: 2),
                            Text('Mua "Bình Nước Hồi Sinh" tại Cửa Hàng để mở khóa tức thì.', style: TextStyle(fontSize: 11, color: AppColors.subtitle)),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            )
          ],
        );
      },
    );
  }

  void _triggerVerifyChallenge(Challenge challenge) async {
    try {
      final res = await context.read<PetProvider>().completeTask(challenge.key);
      if (mounted) {
        final xp = res['xpEarned'] as int? ?? 0;
        final hap = res['happinessEarned'] as int? ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Nhiệm vụ hoàn thành! Thú cưng nhận +$xp XP và +$hap% hạnh phúc.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Nhiệm Vụ Chưa Đạt'),
            content: Text(e.toString().replaceAll('Exception: ', '')),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final petProvider = context.watch<PetProvider>();

    if (petProvider.isLoading && petProvider.activePet == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!petProvider.hasPet) {
      return const AdoptPetScreen();
    }

    final pet = petProvider.activePet!;
    final challenges = petProvider.challenges;
    final stats = petProvider.stats;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF6F9), // Soft elegant pink background
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Heart Challenges',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF8C1D40),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Raise your love pet together 🐾',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Color(0xFF8C1D40)),
                      onPressed: () => _showChangePetDialog(pet),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Main Pet Card with Gradients
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: pet.status == 'frozen'
                          ? [Colors.grey.shade400, Colors.blueGrey.shade600]
                          : [const Color(0xFFDCAFFB), const Color(0xFFFFA6C9)], // Purple to soft pink
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: (pet.status == 'frozen' ? Colors.black26 : const Color(0xFFFFA6C9).withOpacity(0.4)),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Pet Avatar container with Animated Swaying
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white.withOpacity(0.2),
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                          RotationTransition(
                            turns: _swayAnimation,
                            child: Text(
                              pet.petEmoji,
                              style: const TextStyle(fontSize: 70),
                            ),
                          ),
                          
                          // Level Badge
                          Positioned(
                            top: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFD54F),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.white, width: 1.5),
                              ),
                              child: Text(
                                'Lv.${pet.level}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Pet Name
                      Text(
                        pet.name,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              offset: Offset(0, 2),
                              blurRadius: 4,
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Happiness Level Bar
                      _buildProgressBar(
                        label: 'Happiness',
                        value: pet.happiness / 100.0,
                        valueText: '${pet.happiness}%',
                        fillColor: const Color(0xFFFFD54F), // Gold yellow
                      ),
                      const SizedBox(height: 12),

                      // Experience Bar
                      _buildProgressBar(
                        label: 'Experience',
                        value: pet.xp / pet.xpNeeded.toDouble(),
                        valueText: '${pet.xp}/${pet.xpNeeded}',
                        fillColor: const Color(0xFF00E676), // Bright neon green
                      ),
                      
                      // Premium account indicator
                      if (pet.isPremium) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: const [
                              Icon(Icons.stars, color: Color(0xFFFFD54F), size: 16),
                              SizedBox(width: 6),
                              Text(
                                'Premium Boost x1.5 XP Active 👑',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Warning alerts (frozen or days remaining)
                if (pet.status == 'frozen') ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFEBEE),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.ac_unit, color: Colors.blueAccent, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Thú cưng đã bị đóng băng!',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Không thể tích lũy điểm XP. Hãy giải băng ngay.',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: _showUnfreezeDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blueAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            minimumSize: const Size(60, 36),
                          ),
                          child: const Text('Giải băng', style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFDE7),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.amber, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            pet.daysLeft == 0
                                ? '⚠️ Hôm nay là hạn cuối! Hãy làm thử thách ngay.'
                                : '⏰ Còn ${pet.daysLeft} ngày để làm nhiệm vụ. Nếu không thú cưng sẽ bị đóng băng.',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Stats row
                Row(
                  children: [
                    _buildStatCard(
                      icon: Icons.emoji_events,
                      iconColor: const Color(0xFFFFB300),
                      value: '${stats['todayCount'] ?? 0}',
                      label: 'Nhiệm vụ hôm nay',
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      icon: Icons.check_circle_outline,
                      iconColor: const Color(0xFF4CAF50),
                      value: '${stats['thisWeekCount'] ?? 0}',
                      label: 'Tuần này',
                    ),
                    const SizedBox(width: 12),
                    _buildStatCard(
                      icon: Icons.local_fire_department,
                      iconColor: Colors.deepOrangeAccent,
                      value: '${stats['streak'] ?? 0}',
                      label: 'Chuỗi ngày',
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Challenges Title
                const Text(
                  "Today's Challenges",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8C1D40),
                  ),
                ),
                const SizedBox(height: 12),

                // List of Challenges
                if (challenges.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text('Không có nhiệm vụ nào hôm nay.'),
                    ),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: challenges.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = challenges[index];
                      return _buildChallengeCard(item, pet.isPremium);
                    },
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar({
    required String label,
    required double value,
    required String valueText,
    required Color fillColor,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              valueText,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 10,
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: Colors.white.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(fillColor),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 9,
                color: AppColors.subtitle,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallengeCard(Challenge challenge, bool isPremium) {
    // Map string icon key to IconData
    IconData getIcon(String key) {
      switch (key) {
        case 'favorite':
          return Icons.favorite;
        case 'calendar_month':
          return Icons.calendar_month;
        case 'video_call':
          return Icons.video_call;
        case 'wb_sunny':
          return Icons.wb_sunny;
        case 'image':
          return Icons.image;
        default:
          return Icons.star;
      }
    }

    final displayXp = isPremium ? (challenge.xpReward * 1.5).round() : challenge.xpReward;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: challenge.isCompleted ? Colors.green.shade200 : AppColors.border,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Challenge type icon
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: challenge.isCompleted
                  ? Colors.green.shade50
                  : AppColors.active.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              getIcon(challenge.icon),
              color: challenge.isCompleted ? Colors.green : AppColors.active,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),

          // Text content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  challenge.title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: challenge.isCompleted ? Colors.grey : Colors.black87,
                    decoration: challenge.isCompleted ? TextDecoration.lineThrough : null,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  challenge.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 6),
                
                // Reward badges
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+$displayXp XP ${isPremium ? '👑' : ''}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF8E1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '+${challenge.happinessReward}% Happiness',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF57F17),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Completion Button
          if (challenge.isCompleted)
            const Icon(Icons.check_circle, color: Colors.green, size: 28)
          else
            ElevatedButton(
              onPressed: () => _triggerVerifyChallenge(challenge),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.active,
                minimumSize: const Size(60, 36),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                challenge.isAutoVerifiable ? 'Xác minh' : 'Bắt đầu',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
