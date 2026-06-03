import { Router } from 'express';
import { ObjectId } from 'mongodb';

export default function createChallengeRouter(db, auth, ok, fail) {
  const router = Router();
  const lovePets = db.collection('lovePets');
  const challenges = db.collection('challenges');
  const completedChallenges = db.collection('completedChallenges');
  const coupleRelationships = db.collection('coupleRelationships');
  const signals = db.collection('signals');
  const milestones = db.collection('milestones');
  const orders = db.collection('orders');
  const users = db.collection('users');

  // Auto-seed challenges list
  challenges.countDocuments().then(async (count) => {
    if (count === 0) {
      console.log('[Seed] Collection challenges trống. Đang nạp danh sách nhiệm vụ mẫu...');
      const defaultChallenges = [
        {
          key: 'send_signals',
          title: 'Gửi chuông tình yêu',
          description: 'Gửi ít nhất 3 tín hiệu yêu thương (Miss, Care, Love) cho đối phương.',
          xpReward: 10,
          happinessReward: 15,
          type: 'daily',
          isAutoVerifiable: true,
          icon: 'favorite'
        },
        {
          key: 'add_milestone',
          title: 'Tạo mốc kỷ niệm mới',
          description: 'Thêm ít nhất 1 kỷ niệm tình yêu mới ngày hôm nay.',
          xpReward: 15,
          happinessReward: 20,
          type: 'daily',
          isAutoVerifiable: true,
          icon: 'calendar_month'
        },
        {
          key: 'video_call',
          title: 'Gọi video 15 phút',
          description: 'Cùng nhau gọi video kết nối tối thiểu 15 phút.',
          xpReward: 20,
          happinessReward: 25,
          type: 'daily',
          isAutoVerifiable: false,
          icon: 'video_call'
        },
        {
          key: 'good_morning',
          title: 'Lời chào buổi sáng',
          description: 'Nói lời yêu thương hoặc gửi chúc buổi sáng tốt lành đến đối phương.',
          xpReward: 5,
          happinessReward: 10,
          type: 'daily',
          isAutoVerifiable: false,
          icon: 'wb_sunny'
        },
        {
          key: 'share_photo',
          title: 'Chia sẻ ảnh hôm nay',
          description: 'Cùng nhau đăng tải 1 tấm ảnh chung của ngày hôm nay vào Space.',
          xpReward: 12,
          happinessReward: 18,
          type: 'daily',
          isAutoVerifiable: false,
          icon: 'image'
        }
      ];
      await challenges.insertMany(defaultChallenges);
      console.log('[Seed] Đã nạp xong 5 nhiệm vụ mẫu.');
    }
  }).catch(err => console.error('[Seed] Lỗi seed challenges:', err));

  // Helper: Tìm relationship hoạt động của user
  async function getActiveRelationship(userId) {
    return coupleRelationships.findOne({
      status: 'active',
      $or: [{ userAId: userId }, { userBId: userId }]
    });
  }

  // Helper: Kiểm tra Premium của cả 2 user trong relationship
  async function checkRelationshipPremium(relationship, userId) {
    const partnerId = String(relationship.userAId) === String(userId)
      ? relationship.userBId
      : relationship.userAId;

    const [userMe, userPartner] = await Promise.all([
      users.findOne({ _id: userId }),
      users.findOne({ _id: partnerId })
    ]);

    return (userMe?.isPremium === true) || (userPartner?.isPremium === true);
  }

  // GET /pet - Lấy thông tin thú cưng của cặp đôi
  router.get('/pet', auth, async (req, res) => {
    try {
      const relationship = await getActiveRelationship(req.user._id);
      if (!relationship) {
        return res.status(400).json(fail('RELATIONSHIP_NOT_FOUND'));
      }

      let pet = await lovePets.findOne({ relationshipId: relationship._id });
      if (!pet) {
        return res.json(ok({ hasPet: false }));
      }

      // Kiểm tra 7 ngày đóng băng
      const now = new Date();
      const lastActivity = new Date(pet.lastActivityAt || pet.createdAt);
      const diffTime = Math.abs(now - lastActivity);
      const diffDays = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

      let updated = false;
      if (diffDays > 7 && pet.status !== 'frozen') {
        pet.status = 'frozen';
        pet.happiness = 0;
        await lovePets.updateOne(
          { _id: pet._id },
          { $set: { status: 'frozen', happiness: 0, updatedAt: now } }
        );
        updated = true;
      }

      // Tính số ngày còn lại trước khi đóng băng
      const daysLeft = Math.max(0, 7 - Math.floor(diffTime / (1000 * 60 * 60 * 24)));

      return res.json(ok({
        hasPet: true,
        id: pet._id.toString(),
        name: pet.name,
        petType: pet.petType,
        level: pet.level,
        xp: pet.xp,
        xpNeeded: pet.xpNeeded,
        happiness: pet.happiness,
        status: pet.status,
        streak: pet.streak,
        daysLeft: daysLeft,
        lastActivityAt: pet.lastActivityAt.toISOString(),
        isPremium: await checkRelationshipPremium(relationship, req.user._id)
      }));
    } catch (error) {
      console.error('[GET /pet] Error:', error);
      return res.status(500).json(fail('SERVER_ERROR'));
    }
  });

  // POST /pet/adopt - Nhận nuôi hoặc thay đổi loại thú cưng
  router.post('/pet/adopt', auth, async (req, res) => {
    try {
      const { petType, name } = req.body;
      if (!petType || !name) {
        return res.status(400).json(fail('INVALID_INPUT'));
      }

      const relationship = await getActiveRelationship(req.user._id);
      if (!relationship) {
        return res.status(400).json(fail('RELATIONSHIP_NOT_FOUND'));
      }

      const now = new Date();
      let pet = await lovePets.findOne({ relationshipId: relationship._id });

      if (pet) {
        // Cập nhật đổi loài/đổi tên
        await lovePets.updateOne(
          { _id: pet._id },
          { $set: { petType, name: name.trim(), updatedAt: now } }
        );
        pet = await lovePets.findOne({ _id: pet._id });
      } else {
        // Nhận nuôi mới
        const newPet = {
          relationshipId: relationship._id,
          petType,
          name: name.trim(),
          level: 1,
          xp: 0,
          xpNeeded: 100, // Cấp 1 cần 100 XP
          happiness: 100,
          status: 'active',
          streak: 0,
          lastActivityAt: now,
          createdAt: now,
          updatedAt: now
        };
        const result = await lovePets.insertOne(newPet);
        pet = { ...newPet, _id: result.insertedId };
      }

      return res.json(ok({
        hasPet: true,
        id: pet._id.toString(),
        name: pet.name,
        petType: pet.petType,
        level: pet.level,
        xp: pet.xp,
        xpNeeded: pet.xpNeeded,
        happiness: pet.happiness,
        status: pet.status,
        streak: pet.streak,
        lastActivityAt: pet.lastActivityAt.toISOString()
      }));
    } catch (error) {
      console.error('[POST /pet/adopt] Error:', error);
      return res.status(500).json(fail('SERVER_ERROR'));
    }
  });

  // POST /pet/rename - Đổi tên thú cưng
  router.post('/pet/rename', auth, async (req, res) => {
    try {
      const { name } = req.body;
      if (!name || !name.trim()) {
        return res.status(400).json(fail('INVALID_INPUT'));
      }

      const relationship = await getActiveRelationship(req.user._id);
      if (!relationship) {
        return res.status(400).json(fail('RELATIONSHIP_NOT_FOUND'));
      }

      const result = await lovePets.updateOne(
        { relationshipId: relationship._id },
        { $set: { name: name.trim(), updatedAt: new Date() } }
      );

      if (result.matchedCount === 0) {
        return res.status(404).json(fail('INVALID_INPUT')); // Chưa nuôi pet
      }

      return res.json(ok(true));
    } catch (error) {
      console.error('[POST /pet/rename] Error:', error);
      return res.status(500).json(fail('SERVER_ERROR'));
    }
  });

  // GET /challenges/today - Lấy danh sách nhiệm vụ hôm nay và trạng thái hoàn thành
  router.get('/challenges/today', auth, async (req, res) => {
    try {
      const relationship = await getActiveRelationship(req.user._id);
      if (!relationship) {
        return res.status(400).json(fail('RELATIONSHIP_NOT_FOUND'));
      }

      const list = await challenges.find({}).toArray();
      
      // Tìm các nhiệm vụ đã hoàn thành hôm nay bởi cặp đôi
      const startOfDay = new Date();
      startOfDay.setHours(0, 0, 0, 0);
      const endOfDay = new Date();
      endOfDay.setHours(23, 59, 59, 999);

      const completedToday = await completedChallenges.find({
        relationshipId: relationship._id,
        completedAt: { $gte: startOfDay, $lte: endOfDay }
      }).toArray();

      const completedIds = completedToday.map(c => c.challengeId.toString());

      const data = list.map(item => ({
        id: item._id.toString(),
        key: item.key,
        title: item.title,
        description: item.description,
        xpReward: item.xpReward,
        happinessReward: item.happinessReward,
        type: item.type,
        isAutoVerifiable: item.isAutoVerifiable,
        icon: item.icon,
        isCompleted: completedIds.includes(item._id.toString())
      }));

      // Lấy tổng quan stats
      const pet = await lovePets.findOne({ relationshipId: relationship._id });
      const completedTodayCount = completedToday.length;
      
      // Thống kê tuần này
      const startOfWeek = new Date();
      startOfWeek.setDate(startOfWeek.getDate() - startOfWeek.getDay() + 1); // Monday
      startOfWeek.setHours(0,0,0,0);
      const completedThisWeekCount = await completedChallenges.countDocuments({
        relationshipId: relationship._id,
        completedAt: { $gte: startOfWeek }
      });

      return res.json(ok({
        challenges: data,
        stats: {
          todayCount: completedTodayCount,
          thisWeekCount: completedThisWeekCount,
          streak: pet?.streak ?? 0
        }
      }));
    } catch (error) {
      console.error('[GET /challenges/today] Error:', error);
      return res.status(500).json(fail('SERVER_ERROR'));
    }
  });

  // POST /challenges/:key/complete - Báo hoàn thành thử thách
  router.post('/challenges/:key/complete', auth, async (req, res) => {
    try {
      const challengeKey = req.params.key;
      const relationship = await getActiveRelationship(req.user._id);
      if (!relationship) {
        return res.status(400).json(fail('RELATIONSHIP_NOT_FOUND'));
      }

      const pet = await lovePets.findOne({ relationshipId: relationship._id });
      if (!pet) {
        return res.status(400).json(fail('INVALID_INPUT')); // Chưa nuôi pet
      }

      if (pet.status === 'frozen') {
        return res.status(400).json({
          success: false,
          error: { code: 'PET_FROZEN', message: 'Thú cưng đang bị đóng băng. Vui lòng giải băng trước.' }
        });
      }

      const challenge = await challenges.findOne({ key: challengeKey });
      if (!challenge) {
        return res.status(404).json(fail('INVALID_INPUT'));
      }

      // Check xem hôm nay đã hoàn thành chưa
      const startOfDay = new Date();
      startOfDay.setHours(0, 0, 0, 0);
      const endOfDay = new Date();
      endOfDay.setHours(23, 59, 59, 999);

      const alreadyDone = await completedChallenges.findOne({
        relationshipId: relationship._id,
        challengeId: challenge._id,
        completedAt: { $gte: startOfDay, $lte: endOfDay }
      });

      if (alreadyDone) {
        return res.status(400).json({
          success: false,
          error: { code: 'ALREADY_COMPLETED', message: 'Thử thách này đã được hoàn thành hôm nay.' }
        });
      }

      // Nếu là auto-verify, kiểm tra nghiệp vụ thực tế
      const now = new Date();
      if (challenge.isAutoVerifiable) {
        if (challengeKey === 'send_signals') {
          // Kiểm tra xem hôm nay cặp đôi đã gửi ít nhất 3 signals chưa
          const signalCount = await signals.countDocuments({
            $or: [
              { fromUserId: relationship.userAId, toUserId: relationship.userBId },
              { fromUserId: relationship.userBId, toUserId: relationship.userAId }
            ],
            sentAt: { $gte: startOfDay, $lte: endOfDay }
          });
          if (signalCount < 3) {
            return res.status(400).json({
              success: false,
              error: { code: 'VERIFICATION_FAILED', message: `Bạn chỉ mới gửi ${signalCount}/3 tín hiệu yêu thương.` }
            });
          }
        } else if (challengeKey === 'add_milestone') {
          // Kiểm tra xem hôm nay có milestone nào được tạo không
          const milestoneCount = await milestones.countDocuments({
            relationshipId: relationship._id,
            createdAt: { $gte: startOfDay, $lte: endOfDay }
          });
          if (milestoneCount < 1) {
            return res.status(400).json({
              success: false,
              error: { code: 'VERIFICATION_FAILED', message: 'Bạn chưa tạo mốc kỷ niệm mới nào trong ngày hôm nay.' }
            });
          }
        }
      }

      // Premium check & Boost rewards
      const isPremium = await checkRelationshipPremium(relationship, req.user._id);
      const multiplier = isPremium ? 1.5 : 1.0;
      const finalXpReward = Math.round(challenge.xpReward * multiplier);
      const finalHappinessReward = challenge.happinessReward; // giữ nguyên happiness reward

      // Ghi nhận hoàn thành
      await completedChallenges.insertOne({
        relationshipId: relationship._id,
        userId: req.user._id,
        challengeId: challenge._id,
        completedAt: now,
        xpEarned: finalXpReward,
        happinessEarned: finalHappinessReward
      });

      // Cập nhật trạng thái Thú Cưng
      let newXp = pet.xp + finalXpReward;
      let newLevel = pet.level;
      let xpNeeded = pet.level * 100;

      while (newXp >= xpNeeded) {
        newXp -= xpNeeded;
        newLevel += 1;
        xpNeeded = newLevel * 100;
      }

      const newHappiness = Math.min(100, pet.happiness + finalHappinessReward);

      // Cập nhật streak (nếu lần hoạt động cuối là hôm qua thì tăng streak, nếu là cùng ngày thì giữ nguyên, nếu xa hơn thì reset về 1)
      let newStreak = pet.streak || 0;
      const lastActivity = new Date(pet.lastActivityAt);
      const diffTime = Math.abs(now - lastActivity);
      const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));

      if (diffDays === 1 || pet.streak === 0) {
        newStreak += 1;
      } else if (diffDays > 1) {
        newStreak = 1;
      }

      await lovePets.updateOne(
        { _id: pet._id },
        {
          $set: {
            level: newLevel,
            xp: newXp,
            xpNeeded: xpNeeded,
            happiness: newHappiness,
            streak: newStreak,
            lastActivityAt: now,
            updatedAt: now
          }
        }
      );

      const updatedPet = await lovePets.findOne({ _id: pet._id });

      return res.json(ok({
        completed: true,
        xpEarned: finalXpReward,
        happinessEarned: finalHappinessReward,
        isPremium,
        pet: {
          level: updatedPet.level,
          xp: updatedPet.xp,
          xpNeeded: updatedPet.xpNeeded,
          happiness: updatedPet.happiness,
          streak: updatedPet.streak
        }
      }));
    } catch (error) {
      console.error('[POST /challenges/:key/complete] Error:', error);
      return res.status(500).json(fail('SERVER_ERROR'));
    }
  });

  // POST /pet/unfreeze - Giải băng cho thú cưng
  router.post('/pet/unfreeze', auth, async (req, res) => {
    try {
      const { method } = req.body; // 'free' (nhiệm vụ gửi 10 tin nhắn) hoặc 'store' (mua bình nước hồi sinh)
      const relationship = await getActiveRelationship(req.user._id);
      if (!relationship) {
        return res.status(400).json(fail('RELATIONSHIP_NOT_FOUND'));
      }

      const pet = await lovePets.findOne({ relationshipId: relationship._id });
      if (!pet) {
        return res.status(400).json(fail('INVALID_INPUT')); // Chưa nuôi pet
      }

      if (pet.status !== 'frozen') {
        return res.status(400).json({
          success: false,
          error: { code: 'NOT_FROZEN', message: 'Thú cưng hiện không bị đóng băng.' }
        });
      }

      const now = new Date();
      if (method === 'free') {
        // Kiểm tra xem cặp đôi đã gửi tổng cộng ít nhất 10 signals chưa
        const totalSignals = await signals.countDocuments({
          $or: [
            { fromUserId: relationship.userAId, toUserId: relationship.userBId },
            { fromUserId: relationship.userBId, toUserId: relationship.userAId }
          ]
        });

        if (totalSignals < 10) {
          return res.status(400).json({
            success: false,
            error: { code: 'UNFREEZE_FAILED', message: `Cần tối thiểu 10 tín hiệu tình yêu gửi đi (Hiện tại có: ${totalSignals}/10).` }
          });
        }
      } else if (method === 'store') {
        // Tìm đơn hàng thành công của "Bình nước hồi sinh" (product id p_revival) từ 1 trong 2 người
        const partnerId = String(relationship.userAId) === String(req.user._id)
          ? relationship.userBId
          : relationship.userAId;

        const order = await orders.findOne({
          status: 'PAID',
          userId: { $in: [req.user._id.toString(), partnerId.toString()] },
          'items.product.id': 'p_revival'
        });

        if (!order) {
          return res.status(400).json({
            success: false,
            error: { code: 'UNFREEZE_FAILED', message: 'Không tìm thấy đơn mua "Bình nước hồi sinh" đã thanh toán trong Cửa hàng.' }
          });
        }

        // Xóa hoặc tiêu thụ item: Trong trường hợp test, chỉ cần tìm thấy đơn hàng PAID hợp lệ.
      } else {
        return res.status(400).json(fail('INVALID_INPUT'));
      }

      // Kích hoạt lại pet
      await lovePets.updateOne(
        { _id: pet._id },
        {
          $set: {
            status: 'active',
            happiness: 100, // Đầy cây hạnh phúc sau khi hồi sinh
            lastActivityAt: now,
            updatedAt: now
          }
        }
      );

      const updatedPet = await lovePets.findOne({ _id: pet._id });

      return res.json(ok({
        unfrozen: true,
        pet: {
          status: updatedPet.status,
          happiness: updatedPet.happiness,
          lastActivityAt: updatedPet.lastActivityAt.toISOString()
        }
      }));
    } catch (error) {
      console.error('[POST /pet/unfreeze] Error:', error);
      return res.status(500).json(fail('SERVER_ERROR'));
    }
  });

  return router;
}
