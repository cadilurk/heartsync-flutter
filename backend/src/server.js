import 'dotenv/config';
import dns from 'dns';
dns.setServers(['8.8.8.8', '1.1.1.1']);
import admin from 'firebase-admin';
import fs from 'fs';
import bcrypt from 'bcryptjs';
import cors from 'cors';
import express from 'express';
import { createServer } from 'http';
import jwt from 'jsonwebtoken';
import { MongoClient, ObjectId } from 'mongodb';
import { Server } from 'socket.io';
import createSpaceRouter from './spaceRouter.js';
import createStoreRouter from './storeRouter.js';
import createChallengeRouter from './challengeRouter.js';

const app = express();
const httpServer = createServer(app);
const io = new Server(httpServer, {
  cors: { origin: true, methods: ['GET', 'POST'] },
});
const port = Number(process.env.PORT || 5291);
const mongoUri = process.env.MONGO_URI;
const jwtSecret = process.env.JWT_SECRET || 'dev-only-change-me';

if (!mongoUri) {
  console.error('MONGO_URI is required.');
  process.exit(1);
}

app.use(cors({ origin: true, credentials: true }));
app.use(express.json());

const client = new MongoClient(mongoUri);
await client.connect();
const db = client.db('heartsync');
app.use('/', createStoreRouter(db, auth, ok, fail));
app.use('/', createSpaceRouter(db, auth, ok, fail));
app.use('/', createChallengeRouter(db, auth, ok, fail));

let firebaseMessaging = null;
if (fs.existsSync('./firebase-service-account.json')) {
  try {
    const serviceAccount = JSON.parse(fs.readFileSync('./firebase-service-account.json', 'utf8'));
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    firebaseMessaging = admin.messaging();
    console.log('Firebase Admin SDK initialized successfully.');
  } catch (error) {
    console.error('Failed to initialize Firebase Admin SDK:', error);
  }
} else {
  console.warn('Warning: firebase-service-account.json not found. FCM push notifications will be disabled.');
}

const users = db.collection('users');
const profiles = db.collection('profiles');
const relationships = db.collection('coupleRelationships');
const pairingCodes = db.collection('pairingCodes');
const signals = db.collection('signals');
const milestones = db.collection('milestones');

await users.createIndex({ email: 1 }, { unique: true });
await pairingCodes.createIndex({ code: 1 }, { unique: true });
await pairingCodes.createIndex({ expiredAt: 1 }, { expireAfterSeconds: 3600 });
await signals.createIndex({ toUserId: 1, readAt: 1 });
await signals.createIndex({ sentAt: -1 });

function ok(data) {
  return { success: true, data, error: null };
}

function fail(code, status = 400) {
  const messages = {
    INVALID_INPUT: 'Thông tin nhập chưa hợp lệ.',
    EMAIL_ALREADY_EXISTS: 'Email này đã được đăng ký.',
    INVALID_EMAIL_OR_PASSWORD: 'Email hoặc mật khẩu không đúng.',
    UNAUTHENTICATED: 'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
    ACCOUNT_DISABLED: 'Tài khoản đã bị vô hiệu hóa.',
    PAIRING_CODE_INVALID: 'Mã ghép đôi không đúng.',
    PAIRING_CODE_EXPIRED: 'Mã ghép đôi đã hết hạn. Vui lòng tạo mã mới.',
    PAIRING_CODE_USED: 'Mã này đã được sử dụng.',
    PAIRING_SELF_NOT_ALLOWED: 'Bạn không thể tự ghép đôi với chính mình.',
    USER_ALREADY_PAIRED: 'Tài khoản của bạn đã được ghép đôi.',
    PARTNER_ALREADY_PAIRED: 'Người dùng này đã được ghép đôi.',
    RELATIONSHIP_NOT_FOUND: 'Không tìm thấy kết nối partner.',
    SERVER_ERROR: 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.'
  };
  return { status, body: { success: false, data: null, error: { code, message: messages[code] || messages.SERVER_ERROR } } };
}

function publicUser(user) {
  if (!user) return null;
  return {
    id: user._id.toString(),
    email: user.email,
    phone: user.phone ?? null,
    authProvider: user.authProvider ?? 'email',
    status: user.status ?? 'active',
    createdAt: user.createdAt?.toISOString?.() ?? user.createdAt,
    updatedAt: user.updatedAt?.toISOString?.() ?? user.updatedAt
  };
}

function serializeProfile(profile) {
  if (!profile) return null;
  return {
    id: profile._id.toString(),
    userId: profile.userId.toString(),
    displayName: profile.displayName ?? '',
    avatarUrl: profile.avatarUrl ?? null,
    dateOfBirth: profile.dateOfBirth ?? null,
    gender: profile.gender ?? null,
    bio: profile.bio ?? null,
    relationshipStartDate: profile.relationshipStartDate ?? null,
    createdAt: profile.createdAt?.toISOString?.() ?? profile.createdAt,
    updatedAt: profile.updatedAt?.toISOString?.() ?? profile.updatedAt
  };
}

function serializeRelationship(relationship) {
  if (!relationship) return null;
  return {
    id: relationship._id.toString(),
    userAId: relationship.userAId.toString(),
    userBId: relationship.userBId.toString(),
    relationshipStartDate: relationship.relationshipStartDate ?? null,
    status: relationship.status,
    disconnectedAt: relationship.disconnectedAt ?? null,
    createdAt: relationship.createdAt?.toISOString?.() ?? relationship.createdAt,
    updatedAt: relationship.updatedAt?.toISOString?.() ?? relationship.updatedAt
  };
}

function serializePairingCode(pairingCode) {
  return {
    id: pairingCode._id.toString(),
    code: pairingCode.code,
    createdByUserId: pairingCode.createdByUserId.toString(),
    status: pairingCode.status,
    expiredAt: pairingCode.expiredAt.toISOString(),
    usedByUserId: pairingCode.usedByUserId?.toString?.() ?? null,
    usedAt: pairingCode.usedAt?.toISOString?.() ?? null,
    createdAt: pairingCode.createdAt.toISOString()
  };
}

function signTokens(userId) {
  return {
    accessToken: jwt.sign({ sub: userId }, jwtSecret, { expiresIn: '2h' }),
    refreshToken: jwt.sign({ sub: userId, type: 'refresh' }, jwtSecret, { expiresIn: '30d' })
  };
}

async function auth(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;
  if (!token) {
    const error = fail('UNAUTHENTICATED', 401);
    return res.status(error.status).json(error.body);
  }
  try {
    const payload = jwt.verify(token, jwtSecret);
    const user = await users.findOne({ _id: new ObjectId(payload.sub) });
    if (!user) {
      const error = fail('UNAUTHENTICATED', 401);
      return res.status(error.status).json(error.body);
    }
    req.user = user;
    next();
  } catch {
    const error = fail('UNAUTHENTICATED', 401);
    return res.status(error.status).json(error.body);
  }
}

async function activeRelationshipFor(userId) {
  return relationships.findOne({
    status: 'active',
    $or: [{ userAId: userId }, { userBId: userId }]
  });
}

function randomCode() {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  return Array.from({ length: 6 }, () => chars[Math.floor(Math.random() * chars.length)]).join('');
}

app.get('/health', (_req, res) => res.json(ok({ status: 'ok' })));

app.post('/auth/register', async (req, res) => {
  const email = String(req.body.email || '').trim().toLowerCase();
  const password = String(req.body.password || '');
  if (!email.includes('@') || password.length < 6) {
    const error = fail('INVALID_INPUT');
    return res.status(error.status).json(error.body);
  }

  const now = new Date();
  const passwordHash = await bcrypt.hash(password, 10);
  try {
    const result = await users.insertOne({
      email,
      passwordHash,
      authProvider: 'email',
      status: 'active',
      fcmTokens: [],
      createdAt: now,
      updatedAt: now
    });
    const userId = result.insertedId;
    const displayName = String(req.body.displayName || '').trim();
    if (displayName) {
      await profiles.insertOne({ userId, displayName, createdAt: now, updatedAt: now });
    }
    const user = await users.findOne({ _id: userId });
    return res.json(ok({ ...signTokens(userId.toString()), user: publicUser(user) }));
  } catch (error) {
    if (error.code === 11000) {
      const duplicate = fail('EMAIL_ALREADY_EXISTS');
      return res.status(duplicate.status).json(duplicate.body);
    }
    const serverError = fail('SERVER_ERROR', 500);
    return res.status(serverError.status).json(serverError.body);
  }
});

app.post('/auth/login', async (req, res) => {
  const email = String(req.body.email || '').trim().toLowerCase();
  const password = String(req.body.password || '');
  const user = await users.findOne({ email });
  if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
    const error = fail('INVALID_EMAIL_OR_PASSWORD', 401);
    return res.status(error.status).json(error.body);
  }
  if (user.status !== 'active') {
    const error = fail('ACCOUNT_DISABLED', 403);
    return res.status(error.status).json(error.body);
  }
  return res.json(ok({ ...signTokens(user._id.toString()), user: publicUser(user) }));
});

app.post('/auth/logout', auth, (_req, res) => res.json(ok(true)));

app.get('/account/me', auth, async (req, res) => {
  const relationship = await activeRelationshipFor(req.user._id);
  const partnerId = relationship
    ? String(relationship.userAId) === String(req.user._id)
      ? relationship.userBId
      : relationship.userAId
    : null;
  const [profile, partner] = await Promise.all([
    profiles.findOne({ userId: req.user._id }),
    partnerId ? users.findOne({ _id: partnerId }) : null
  ]);
  return res.json(ok({
    user: publicUser(req.user),
    profile: serializeProfile(profile),
    relationship: serializeRelationship(relationship),
    partner: publicUser(partner)
  }));
});

app.put('/account/profile', auth, async (req, res) => {
  const displayName = String(req.body.displayName || '').trim();
  if (!displayName) {
    const error = fail('INVALID_INPUT');
    return res.status(error.status).json(error.body);
  }
  const now = new Date();
  await profiles.updateOne(
    { userId: req.user._id },
    {
      $set: {
        displayName,
        avatarUrl: req.body.avatarUrl || null,
        dateOfBirth: req.body.dateOfBirth || null,
        relationshipStartDate: req.body.relationshipStartDate || null,
        gender: req.body.gender || null,
        bio: req.body.bio || null,
        updatedAt: now
      },
      $setOnInsert: { userId: req.user._id, createdAt: now }
    },
    { upsert: true }
  );
  const profile = await profiles.findOne({ userId: req.user._id });
  return res.json(ok(serializeProfile(profile)));
});

app.put('/users/me/fcm-token', auth, async (req, res) => {
  try {
    const { token } = req.body;
    if (!token) {
      return res.status(400).json({ success: false, error: 'Token is required' });
    }
    await users.updateOne(
      { _id: req.user._id },
      { $addToSet: { fcmTokens: token } }
    );
    return res.json(ok(true));
  } catch (error) {
    console.error('Error in PUT /users/me/fcm-token:', error);
    const serverError = fail('SERVER_ERROR', 500);
    return res.status(500).json(serverError.body);
  }
});

app.delete('/users/me/fcm-token', auth, async (req, res) => {
  try {
    const { token } = req.body;
    if (!token) {
      return res.status(400).json({ success: false, error: 'Token is required' });
    }
    await users.updateOne(
      { _id: req.user._id },
      { $pull: { fcmTokens: token } }
    );
    return res.json(ok(true));
  } catch (error) {
    console.error('Error in DELETE /users/me/fcm-token:', error);
    const serverError = fail('SERVER_ERROR', 500);
    return res.status(500).json(serverError.body);
  }
});

// POST /account/relationship/shift-date
app.post('/account/relationship/shift-date', auth, async (req, res) => {
  try {
    const relationship = await activeRelationshipFor(req.user._id);
    const profile = await profiles.findOne({ userId: req.user._id });
    
    let currentDateString = relationship 
      ? relationship.relationshipStartDate 
      : (profile ? profile.relationshipStartDate : null);
      
    if (!currentDateString) {
      currentDateString = new Date().toISOString();
    }
    
    const currentDate = new Date(currentDateString);
    currentDate.setDate(currentDate.getDate() - 1); // Lùi ngày kỉ niệm về quá khứ 1 ngày
    const newDateString = currentDate.toISOString();
    
    if (relationship) {
      await relationships.updateOne(
        { _id: relationship._id },
        { $set: { relationshipStartDate: newDateString, updatedAt: new Date() } }
      );
    }
    
    await profiles.updateOne(
      { userId: req.user._id },
      { $set: { relationshipStartDate: newDateString, updatedAt: new Date() } },
      { upsert: true }
    );
    
    return res.json(ok({ newStartDate: newDateString }));
  } catch (error) {
    console.error('Error shifting start date:', error);
    const serverError = fail('SERVER_ERROR', 500);
    return res.status(serverError.status).json(serverError.body);
  }
});

app.post('/pairing/generate', auth, async (req, res) => {
  if (await activeRelationshipFor(req.user._id)) {
    const error = fail('USER_ALREADY_PAIRED');
    return res.status(error.status).json(error.body);
  }
  const now = new Date();
  let code = randomCode();
  while (await pairingCodes.findOne({ code, status: 'active' })) code = randomCode();
  const pairingCode = {
    code,
    createdByUserId: req.user._id,
    status: 'active',
    expiredAt: new Date(now.getTime() + 15 * 60 * 1000),
    usedByUserId: null,
    usedAt: null,
    createdAt: now
  };
  const result = await pairingCodes.insertOne(pairingCode);
  return res.json(ok(serializePairingCode({ ...pairingCode, _id: result.insertedId })));
});

app.post('/pairing/connect', auth, async (req, res) => {
  if (await activeRelationshipFor(req.user._id)) {
    const error = fail('USER_ALREADY_PAIRED');
    return res.status(error.status).json(error.body);
  }
  const code = String(req.body.code || '').trim().toUpperCase();
  const pairingCode = await pairingCodes.findOne({ code });
  if (!pairingCode) {
    const error = fail('PAIRING_CODE_INVALID');
    return res.status(error.status).json(error.body);
  }
  if (pairingCode.status === 'used') {
    const error = fail('PAIRING_CODE_USED');
    return res.status(error.status).json(error.body);
  }
  if (pairingCode.expiredAt < new Date()) {
    const error = fail('PAIRING_CODE_EXPIRED');
    return res.status(error.status).json(error.body);
  }
  if (String(pairingCode.createdByUserId) === String(req.user._id)) {
    const error = fail('PAIRING_SELF_NOT_ALLOWED');
    return res.status(error.status).json(error.body);
  }
  if (await activeRelationshipFor(pairingCode.createdByUserId)) {
    const error = fail('PARTNER_ALREADY_PAIRED');
    return res.status(error.status).json(error.body);
  }

  const now = new Date();
  const creatorProfile = await profiles.findOne({ userId: pairingCode.createdByUserId });
  const relationship = {
    userAId: pairingCode.createdByUserId,
    userBId: req.user._id,
    relationshipStartDate: creatorProfile?.relationshipStartDate || now.toISOString(),
    status: 'active',
    disconnectedAt: null,
    createdAt: now,
    updatedAt: now
  };
  const result = await relationships.insertOne(relationship);
  await pairingCodes.updateOne(
    { _id: pairingCode._id, status: 'active' },
    { $set: { status: 'used', usedByUserId: req.user._id, usedAt: now } }
  );
  const partner = await users.findOne({ _id: pairingCode.createdByUserId });
  return res.json(ok({
    relationship: serializeRelationship({ ...relationship, _id: result.insertedId }),
    partner: publicUser(partner)
  }));
});

app.get('/pairing/status', auth, async (req, res) => {
  const relationship = await activeRelationshipFor(req.user._id);
  if (!relationship) return res.json(ok({ status: 'unpaired', relationshipId: null, partner: null }));
  const partnerId = String(relationship.userAId) === String(req.user._id)
    ? relationship.userBId
    : relationship.userAId;
  const partner = await users.findOne({ _id: partnerId });
  return res.json(ok({
    status: 'paired',
    relationshipId: relationship._id.toString(),
    partner: publicUser(partner)
  }));
});

app.delete('/pairing/disconnect', auth, async (req, res) => {
  const relationship = await activeRelationshipFor(req.user._id);
  if (!relationship) {
    const error = fail('RELATIONSHIP_NOT_FOUND');
    return res.status(error.status).json(error.body);
  }
  await relationships.updateOne(
    { _id: relationship._id },
    { $set: { status: 'disconnected', disconnectedAt: new Date(), updatedAt: new Date() } }
  );
  return res.json(ok(true));
});

// ── Signals API Endpoints ──────────────────────────────────────────────────

app.post('/signals', auth, async (req, res) => {
  try {
    const { signalType } = req.body;
    if (!['miss', 'care', 'love'].includes(signalType)) {
      const error = fail('INVALID_INPUT');
      return res.status(error.status).json(error.body);
    }

    const relationship = await activeRelationshipFor(req.user._id);
    if (!relationship) {
      const error = fail('RELATIONSHIP_NOT_FOUND');
      error.body.error.message = 'Chưa ghép đôi';
      return res.status(error.status).json(error.body);
    }

    const partnerId = String(relationship.userAId) === String(req.user._id)
      ? relationship.userBId
      : relationship.userAId;

    const signal = {
      fromUserId: req.user._id,
      toUserId: partnerId,
      signalType,
      sentAt: new Date(),
      deliveredViaSocket: false,
      fcmSent: false,
      readAt: null
    };

    const result = await signals.insertOne(signal);

    const partnerSocketId = onlineUsers.get(String(partnerId));
    if (partnerSocketId) {
      io.to(partnerSocketId).emit('alarm:receive', {
        signalId: result.insertedId.toString(),
        fromUserId: String(req.user._id),
        timestamp: signal.sentAt.toISOString(),
        signalType: signal.signalType
      });
      await signals.updateOne(
        { _id: result.insertedId },
        { $set: { deliveredViaSocket: true } }
      );
      signal.deliveredViaSocket = true;
    } else {
      if (firebaseMessaging) {
        const partner = await users.findOne({ _id: partnerId });
        if (partner && partner.fcmTokens && partner.fcmTokens.length > 0) {
          const labels = { miss: 'Nhớ em lắm...', care: 'Đang nghĩ đến em', love: 'Yêu em lắm...' };
          const emojis = { miss: '🥺', care: '🤗', love: '💕' };
          const senderProfile = await profiles.findOne({ userId: req.user._id });
          const senderName = senderProfile?.displayName || req.user.email.split('@')[0];

          try {
            await firebaseMessaging.sendEachForMulticast({
              tokens: partner.fcmTokens,
              notification: {
                title: `${senderName} gửi ${emojis[signalType]}`,
                body: labels[signalType]
              },
              data: {
                type: 'heart_alarm',
                signalId: result.insertedId.toString(),
                fromUserId: String(req.user._id),
                signalType: signalType
              },
              android: {
                priority: 'high',
                notification: {
                  channelId: 'heart_alarm',
                  color: '#EC4899',
                  vibrateTimingsMillis: [0, 500, 200, 500]
                }
              }
            });
            await signals.updateOne(
              { _id: result.insertedId },
              { $set: { fcmSent: true } }
            );
            signal.fcmSent = true;
          } catch (fcmError) {
            console.error('Failed to send FCM notifications:', fcmError);
          }
        }
      }
    }
    
    return res.json(ok({
      id: result.insertedId.toString(),
      fromUserId: String(signal.fromUserId),
      toUserId: String(signal.toUserId),
      signalType: signal.signalType,
      sentAt: signal.sentAt.toISOString(),
      deliveredViaSocket: signal.deliveredViaSocket,
      fcmSent: signal.fcmSent,
      readAt: null
    }));
  } catch (error) {
    console.error('Error in POST /signals:', error);
    const serverError = fail('SERVER_ERROR', 500);
    return res.status(500).json(serverError.body);
  }
});

app.get('/signals/unread', auth, async (req, res) => {
  try {
    const unreadList = await signals.aggregate([
      { $match: { toUserId: req.user._id, readAt: null } },
      { $sort: { sentAt: 1 } },
      { $limit: 50 },
      {
        $lookup: {
          from: 'profiles',
          localField: 'fromUserId',
          foreignField: 'userId',
          as: 'senderProfile'
        }
      },
      {
        $project: {
          _id: 1,
          fromUserId: 1,
          toUserId: 1,
          signalType: 1,
          sentAt: 1,
          deliveredViaSocket: 1,
          fcmSent: 1,
          readAt: 1,
          senderProfile: { $arrayElemAt: ['$senderProfile', 0] }
        }
      }
    ]).toArray();

    const responseData = unreadList.map(s => ({
      id: s._id.toString(),
      fromUserId: s.fromUserId.toString(),
      toUserId: s.toUserId.toString(),
      signalType: s.signalType,
      sentAt: s.sentAt.toISOString(),
      deliveredViaSocket: s.deliveredViaSocket,
      fcmSent: s.fcmSent,
      readAt: s.readAt ? s.readAt.toISOString() : null,
      fromDisplayName: s.senderProfile?.displayName || null,
      fromAvatarUrl: s.senderProfile?.avatarUrl || null
    }));

    return res.json(ok(responseData));
  } catch (error) {
    console.error('Error in GET /signals/unread:', error);
    const serverError = fail('SERVER_ERROR', 500);
    return res.status(500).json(serverError.body);
  }
});

app.get('/signals/history', auth, async (req, res) => {
  try {
    const limit = Math.min(Number(req.query.limit || 20), 100);
    const before = req.query.before;

    const matchQuery = {
      $or: [
        { fromUserId: req.user._id },
        { toUserId: req.user._id }
      ]
    };

    if (before) {
      const beforeDate = new Date(before);
      if (!isNaN(beforeDate.getTime())) {
        matchQuery.sentAt = { $lt: beforeDate };
      }
    }

    const historyList = await signals.aggregate([
      { $match: matchQuery },
      { $sort: { sentAt: -1 } },
      { $limit: limit },
      {
        $lookup: {
          from: 'profiles',
          localField: 'fromUserId',
          foreignField: 'userId',
          as: 'senderProfile'
        }
      },
      {
        $project: {
          _id: 1,
          fromUserId: 1,
          toUserId: 1,
          signalType: 1,
          sentAt: 1,
          deliveredViaSocket: 1,
          fcmSent: 1,
          readAt: 1,
          senderProfile: { $arrayElemAt: ['$senderProfile', 0] }
        }
      }
    ]).toArray();

    const responseData = historyList.map(s => ({
      id: s._id.toString(),
      fromUserId: s.fromUserId.toString(),
      toUserId: s.toUserId.toString(),
      signalType: s.signalType,
      sentAt: s.sentAt.toISOString(),
      deliveredViaSocket: s.deliveredViaSocket,
      fcmSent: s.fcmSent,
      readAt: s.readAt ? s.readAt.toISOString() : null,
      fromDisplayName: s.senderProfile?.displayName || null,
      fromAvatarUrl: s.senderProfile?.avatarUrl || null
    }));

    return res.json(ok(responseData));
  } catch (error) {
    console.error('Error in GET /signals/history:', error);
    const serverError = fail('SERVER_ERROR', 500);
    return res.status(500).json(serverError.body);
  }
});

app.patch('/signals/:id/read', auth, async (req, res) => {
  try {
    const signalId = req.params.id;
    if (!ObjectId.isValid(signalId)) {
      return res.status(400).json({ success: false, error: 'Invalid ID format' });
    }
    const signal = await signals.findOne({ _id: new ObjectId(signalId) });
    if (!signal) {
      return res.status(404).json({ success: false, error: 'Signal not found' });
    }
    if (String(signal.toUserId) !== String(req.user._id)) {
      return res.status(403).json({ success: false, error: 'Unauthorized' });
    }
    if (!signal.readAt) {
      await signals.updateOne(
        { _id: new ObjectId(signalId) },
        { $set: { readAt: new Date() } }
      );
    }
    return res.json(ok(true));
  } catch (error) {
    console.error('Error in PATCH /signals/:id/read:', error);
    const serverError = fail('SERVER_ERROR', 500);
    return res.status(500).json(serverError.body);
  }
});

app.patch('/signals/read-all', auth, async (req, res) => {
  try {
    await signals.updateMany(
      { toUserId: req.user._id, readAt: null },
      { $set: { readAt: new Date() } }
    );
    return res.json(ok(true));
  } catch (error) {
    console.error('Error in PATCH /signals/read-all:', error);
    const serverError = fail('SERVER_ERROR', 500);
    return res.status(500).json(serverError.body);
  }
});

// ── Milestones API Endpoints ───────────────────────────────────────────────

// GET /milestones
app.get('/milestones', auth, async (req, res) => {
  const relationship = await activeRelationshipFor(req.user._id);
  let query = {};
  if (relationship) {
    query = {
      $or: [
        { relationshipId: relationship._id },
        { userId: req.user._id },
        { userId: String(relationship.userAId) === String(req.user._id) ? relationship.userBId : relationship.userAId }
      ]
    };
  } else {
    query = { userId: req.user._id };
  }
  try {
    const list = await milestones.find(query).sort({ date: 1 }).toArray();
    const serialized = list.map(item => ({
      id: item._id.toString(),
      userId: item.userId.toString(),
      relationshipId: item.relationshipId ? item.relationshipId.toString() : null,
      title: item.title,
      date: item.date,
      icon: item.icon,
      type: item.type || 'memory',
      isCompleted: item.isCompleted ?? false,
      createdAt: item.createdAt.toISOString(),
      updatedAt: item.updatedAt.toISOString()
    }));
    return res.json(ok(serialized));
  } catch (error) {
    console.error('Error fetching milestones:', error);
    const serverError = fail('SERVER_ERROR', 500);
    return res.status(serverError.status).json(serverError.body);
  }
});

// POST /milestones
app.post('/milestones', auth, async (req, res) => {
  const { title, date, icon } = req.body;
  if (!title || !date) {
    const error = fail('INVALID_INPUT');
    return res.status(error.status).json(error.body);
  }
  try {
    const relationship = await activeRelationshipFor(req.user._id);
    const now = new Date();
    const milestone = {
      userId: req.user._id,
      relationshipId: relationship ? relationship._id : null,
      title: String(title).trim(),
      date: String(date), // YYYY-MM-DD
      icon: String(icon || '🎉'),
      type: String(req.body.type || 'memory'), // 'memory' or 'challenge'
      isCompleted: Boolean(req.body.isCompleted ?? false),
      createdAt: now,
      updatedAt: now
    };
    const result = await milestones.insertOne(milestone);
    return res.json(ok({
      id: result.insertedId.toString(),
      userId: milestone.userId.toString(),
      relationshipId: milestone.relationshipId ? milestone.relationshipId.toString() : null,
      title: milestone.title,
      date: milestone.date,
      icon: milestone.icon,
      type: milestone.type,
      isCompleted: milestone.isCompleted,
      createdAt: now.toISOString(),
      updatedAt: now.toISOString()
    }));
  } catch (error) {
    console.error('Error creating milestone:', error);
    const serverError = fail('SERVER_ERROR', 500);
    return res.status(serverError.status).json(serverError.body);
  }
});

// PUT /milestones/:id
app.put('/milestones/:id', auth, async (req, res) => {
  const { id } = req.params;
  const { title, date, icon } = req.body;
  if (!title || !date) {
    const error = fail('INVALID_INPUT');
    return res.status(error.status).json(error.body);
  }
  try {
    const relationship = await activeRelationshipFor(req.user._id);
    const query = { _id: new ObjectId(id) };
    const milestone = await milestones.findOne(query);
    if (!milestone) {
      return res.status(404).json({ success: false, error: 'Not found' });
    }
    const isCreator = String(milestone.userId) === String(req.user._id);
    const isPartner = relationship && (
      String(milestone.relationshipId) === String(relationship._id) ||
      String(milestone.userId) === String(String(relationship.userAId) === String(req.user._id) ? relationship.userBId : relationship.userAId)
    );
    if (!isCreator && !isPartner) {
      const error = fail('UNAUTHENTICATED', 401);
      return res.status(error.status).json(error.body);
    }
    const now = new Date();
    const { type, isCompleted } = req.body;
    await milestones.updateOne(
      query,
      {
        $set: {
          title: String(title).trim(),
          date: String(date),
          icon: String(icon || '🎉'),
          type: String(type || 'memory'),
          isCompleted: Boolean(isCompleted ?? false),
          updatedAt: now
        }
      }
    );
    const updated = await milestones.findOne(query);
    return res.json(ok({
      id: updated._id.toString(),
      userId: updated.userId.toString(),
      relationshipId: updated.relationshipId ? updated.relationshipId.toString() : null,
      title: updated.title,
      date: updated.date,
      icon: updated.icon,
      type: updated.type || 'memory',
      isCompleted: updated.isCompleted ?? false,
      createdAt: updated.createdAt.toISOString(),
      updatedAt: updated.updatedAt.toISOString()
    }));
  } catch (error) {
    console.error('Error updating milestone:', error);
    const serverError = fail('SERVER_ERROR', 500);
    return res.status(serverError.status).json(serverError.body);
  }
});

// DELETE /milestones/:id
app.delete('/milestones/:id', auth, async (req, res) => {
  const { id } = req.params;
  try {
    const relationship = await activeRelationshipFor(req.user._id);
    const query = { _id: new ObjectId(id) };
    const milestone = await milestones.findOne(query);
    if (!milestone) {
      return res.status(404).json({ success: false, error: 'Not found' });
    }
    const isCreator = String(milestone.userId) === String(req.user._id);
    const isPartner = relationship && (
      String(milestone.relationshipId) === String(relationship._id) ||
      String(milestone.userId) === String(String(relationship.userAId) === String(req.user._id) ? relationship.userBId : relationship.userAId)
    );
    if (!isCreator && !isPartner) {
      const error = fail('UNAUTHENTICATED', 401);
      return res.status(error.status).json(error.body);
    }
    await milestones.deleteOne(query);
    return res.json(ok(true));
  } catch (error) {
    console.error('Error deleting milestone:', error);
    const serverError = fail('SERVER_ERROR', 500);
    return res.status(serverError.status).json(serverError.body);
  }
});

app.use((_req, res) => {
  const error = fail('SERVER_ERROR', 404);
  return res.status(error.status).json(error.body);
});

// ── Socket.io ──────────────────────────────────────────────────────────────

const onlineUsers = new Map(); // userId → socketId

io.use((socket, next) => {
  const token = socket.handshake.auth?.token;
  if (!token) return next(new Error('Unauthorized'));
  try {
    const payload = jwt.verify(token, jwtSecret);
    socket.userId = payload.sub;
    next();
  } catch {
    next(new Error('Unauthorized'));
  }
});

io.on('connection', (socket) => {
  onlineUsers.set(socket.userId, socket.id);

  socket.on('alarm:send', ({ partnerId, signalType } = {}) => {
    if (!partnerId) return;
    const partnerSocketId = onlineUsers.get(String(partnerId));
    if (partnerSocketId) {
      io.to(partnerSocketId).emit('alarm:receive', {
        fromUserId: socket.userId,
        timestamp: new Date().toISOString(),
        signalType: signalType || 'love',
      });
    } else {
      socket.emit('alarm:partner_offline');
    }
  });

  socket.on('disconnect', () => {
    onlineUsers.delete(socket.userId);
  });
});

// ──────────────────────────────────────────────────────────────────────────

httpServer.listen(port, '0.0.0.0', () => {
  console.log(`Server listening on 0.0.0.0:${port} — LAN IP: 10.12.65.104:${port}`);
});
