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
import { randomInt, createHash } from 'crypto';
import multer from 'multer';
import { v2 as cloudinary } from 'cloudinary';
import createSpaceRouter from './spaceRouter.js';
import createStoreRouter from './storeRouter.js';
import createChallengeRouter from './challengeRouter.js';
import { sendVerificationCodeEmail, sendPasswordResetCodeEmail } from './mailer.js';

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
let firebaseAuth = null;
if (fs.existsSync('./firebase-service-account.json')) {
  try {
    const serviceAccount = JSON.parse(fs.readFileSync('./firebase-service-account.json', 'utf8'));
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    firebaseMessaging = admin.messaging();
    firebaseAuth = admin.auth();
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
const heartLocations = db.collection('heartLocations');
const heartLocationHistory = db.collection('heartLocationHistory');
const verificationCodes = db.collection('verificationCodes');

try {
  await ensureUniquePartialIndex(users, 'email');
  await ensureUniquePartialIndex(users, 'phone');
  await users.updateMany(
    { emailVerified: { $exists: false }, email: { $type: 'string' } },
    { $set: { emailVerified: true } }
  );
  await pairingCodes.createIndex({ code: 1 }, { unique: true });
  await pairingCodes.createIndex({ expiredAt: 1 }, { expireAfterSeconds: 3600 });
  await signals.createIndex({ toUserId: 1, readAt: 1 });
  await signals.createIndex({ sentAt: -1 });
  await heartLocations.createIndex({ relationshipId: 1, userId: 1 }, { unique: true });
  await heartLocationHistory.createIndex({ relationshipId: 1, recordedAt: -1 });
  await verificationCodes.createIndex({ userId: 1, purpose: 1 });
  await verificationCodes.createIndex({ expiredAt: 1 }, { expireAfterSeconds: 3600 });
} catch (indexErr) {
  console.warn('MongoDB index initialization note:', indexErr.message);
}

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
    FIREBASE_TOKEN_INVALID: 'Xác thực Firebase không hợp lệ hoặc đã hết hạn. Vui lòng đăng nhập lại.',
    INVALID_OR_EXPIRED_CODE: 'Mã xác thực không đúng hoặc đã hết hạn.',
    CODE_RECENTLY_SENT: 'Bạn vừa yêu cầu mã. Vui lòng thử lại sau ít phút.',
    SERVER_ERROR: 'Máy chủ đang gặp sự cố. Vui lòng thử lại sau.'
  };
  return { status, body: { success: false, data: null, error: { code, message: messages[code] || messages.SERVER_ERROR } } };
}

function publicUser(user) {
  if (!user) return null;
  return {
    id: user._id.toString(),
    email: user.email ?? null,
    phone: user.phone ?? null,
    authProvider: user.authProvider ?? 'email',
    emailVerified: user.emailVerified ?? false,
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

async function ensureUniquePartialIndex(collection, field) {
  const wanted = { [field]: { $type: 'string' } };
  const name = `${field}_1`;
  const existing = await collection.indexes();
  const current = existing.find(idx => idx.name === name);
  const alreadyCorrect = current?.unique &&
    JSON.stringify(current.partialFilterExpression) === JSON.stringify(wanted);
  if (current && !alreadyCorrect) {
    await collection.dropIndex(name);
  }
  if (!current || !alreadyCorrect) {
    await collection.createIndex({ [field]: 1 }, { unique: true, partialFilterExpression: wanted });
  }
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

function randomNumericCode() {
  return String(randomInt(0, 1_000_000)).padStart(6, '0');
}

function hashCode(code) {
  return createHash('sha256').update(code).digest('hex');
}

async function hasRecentCode(userId, purpose, windowMs = 60_000) {
  const cutoff = new Date(Date.now() - windowMs);
  return !!(await verificationCodes.findOne({ userId, purpose, createdAt: { $gt: cutoff } }));
}

async function issueVerificationCode(user, purpose) {
  const now = new Date();
  const code = randomNumericCode();
  await verificationCodes.deleteMany({ userId: user._id, purpose });
  await verificationCodes.insertOne({
    userId: user._id, email: user.email, purpose,
    codeHash: hashCode(code), attempts: 0,
    expiredAt: new Date(now.getTime() + 10 * 60 * 1000), createdAt: now
  });
  const send = purpose === 'email_verify' ? sendVerificationCodeEmail : sendPasswordResetCodeEmail;
  send(user.email, code).catch(err => console.error(`Failed to send ${purpose} email to`, user.email, err));
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
      emailVerified: false,
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
    await issueVerificationCode(user, 'email_verify');
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

app.post('/auth/firebase', async (req, res) => {
  const idToken = String(req.body.idToken || '');
  const provider = req.body.provider;
  if (!idToken || !['google', 'phone'].includes(provider)) {
    const error = fail('INVALID_INPUT');
    return res.status(error.status).json(error.body);
  }
  if (!firebaseAuth) {
    const error = fail('SERVER_ERROR', 500);
    return res.status(error.status).json(error.body);
  }

  let decoded;
  try {
    decoded = await firebaseAuth.verifyIdToken(idToken);
  } catch {
    const error = fail('FIREBASE_TOKEN_INVALID', 401);
    return res.status(error.status).json(error.body);
  }

  const now = new Date();
  let filter, setFields, setOnInsertFields;

  if (provider === 'phone') {
    const phone = decoded.phone_number ? String(decoded.phone_number) : '';
    if (!phone) {
      const error = fail('FIREBASE_TOKEN_INVALID', 401);
      return res.status(error.status).json(error.body);
    }
    filter = { phone };
    setFields = { updatedAt: now };
    setOnInsertFields = {
      // No email on a phone-only account, so there's nothing to verify —
      // default true so the emailVerified gate never blocks these users.
      authProvider: 'phone', email: null, passwordHash: null,
      emailVerified: true, status: 'active', fcmTokens: [], createdAt: now
    };
  } else {
    const email = decoded.email ? String(decoded.email).trim().toLowerCase() : '';
    if (!email) {
      const error = fail('FIREBASE_TOKEN_INVALID', 401);
      return res.status(error.status).json(error.body);
    }
    filter = { email };
    setFields = { updatedAt: now };
    setOnInsertFields = {
      authProvider: 'google', phone: null, passwordHash: null,
      status: 'active', fcmTokens: [], createdAt: now
    };
    // emailVerified must live in EXACTLY ONE of these two operators — never both, never neither.
    // If both $set and $setOnInsert touch the same field path, MongoDB throws a conflict error.
    if (decoded.email_verified) {
      setFields.emailVerified = true;
    } else {
      setOnInsertFields.emailVerified = false;
    }
  }

  const update = { $set: setFields, $setOnInsert: setOnInsertFields };

  try {
    const user = await users.findOneAndUpdate(filter, update, { upsert: true, returnDocument: 'after' });
    if (user.status !== 'active') {
      const error = fail('ACCOUNT_DISABLED', 403);
      return res.status(error.status).json(error.body);
    }
    return res.json(ok({ ...signTokens(user._id.toString()), user: publicUser(user) }));
  } catch (error) {
    if (error.code === 11000) {
      // Lost a concurrent upsert race — the doc now exists from the other request; just log in.
      const user = await users.findOne(filter);
      if (user) return res.json(ok({ ...signTokens(user._id.toString()), user: publicUser(user) }));
    }
    console.error('Error in POST /auth/firebase:', error);
    const serverError = fail('SERVER_ERROR', 500);
    return res.status(500).json(serverError.body);
  }
});

app.post('/auth/email/send-code', async (req, res) => {
  const email = String(req.body.email || '').trim().toLowerCase();
  if (!email.includes('@')) {
    const error = fail('INVALID_INPUT');
    return res.status(error.status).json(error.body);
  }
  try {
    const user = await users.findOne({ email });
    if (user && !user.emailVerified) {
      if (await hasRecentCode(user._id, 'email_verify')) {
        const error = fail('CODE_RECENTLY_SENT', 429);
        return res.status(error.status).json(error.body);
      }
      await issueVerificationCode(user, 'email_verify');
    }
    return res.json(ok(true));
  } catch (error) {
    console.error('Error in POST /auth/email/send-code:', error);
    const serverError = fail('SERVER_ERROR', 500);
    return res.status(500).json(serverError.body);
  }
});

app.post('/auth/email/verify', async (req, res) => {
  const email = String(req.body.email || '').trim().toLowerCase();
  const code = String(req.body.code || '').trim();
  if (!email.includes('@') || !/^\d{6}$/.test(code)) {
    const error = fail('INVALID_INPUT');
    return res.status(error.status).json(error.body);
  }
  try {
    const user = await users.findOne({ email });
    const record = user && await verificationCodes.findOne({ userId: user._id, purpose: 'email_verify' });

    if (!user || !record || record.expiredAt <= new Date() || record.attempts >= 5) {
      const error = fail('INVALID_OR_EXPIRED_CODE');
      return res.status(error.status).json(error.body);
    }
    if (record.codeHash !== hashCode(code)) {
      await verificationCodes.updateOne({ _id: record._id }, { $inc: { attempts: 1 } });
      const error = fail('INVALID_OR_EXPIRED_CODE');
      return res.status(error.status).json(error.body);
    }
    if (user.status !== 'active') {
      const error = fail('ACCOUNT_DISABLED', 403);
      return res.status(error.status).json(error.body);
    }

    await users.updateOne({ _id: user._id }, { $set: { emailVerified: true, updatedAt: new Date() } });
    await verificationCodes.deleteOne({ _id: record._id });
    const updatedUser = await users.findOne({ _id: user._id });
    return res.json(ok({ ...signTokens(user._id.toString()), user: publicUser(updatedUser) }));
  } catch (error) {
    console.error('Error in POST /auth/email/verify:', error);
    const serverError = fail('SERVER_ERROR', 500);
    return res.status(500).json(serverError.body);
  }
});

app.post('/auth/password/forgot', async (req, res) => {
  const email = String(req.body.email || '').trim().toLowerCase();
  if (!email.includes('@')) {
    const error = fail('INVALID_INPUT');
    return res.status(error.status).json(error.body);
  }
  try {
    const user = await users.findOne({ email });
    if (user && user.passwordHash && !(await hasRecentCode(user._id, 'password_reset'))) {
      await issueVerificationCode(user, 'password_reset');
    }
    return res.json(ok(true)); // ALWAYS this — found, not-found, no-password, cooldown all look identical
  } catch (error) {
    console.error('Error in POST /auth/password/forgot:', error);
    const serverError = fail('SERVER_ERROR', 500);
    return res.status(500).json(serverError.body);
  }
});

app.post('/auth/password/reset', async (req, res) => {
  const email = String(req.body.email || '').trim().toLowerCase();
  const code = String(req.body.code || '').trim();
  const newPassword = String(req.body.newPassword || '');
  if (!email.includes('@') || !/^\d{6}$/.test(code) || newPassword.length < 6) {
    const error = fail('INVALID_INPUT');
    return res.status(error.status).json(error.body);
  }
  try {
    const user = await users.findOne({ email });
    const record = user && await verificationCodes.findOne({ userId: user._id, purpose: 'password_reset' });

    if (!user || !record || record.expiredAt <= new Date() || record.attempts >= 5) {
      const error = fail('INVALID_OR_EXPIRED_CODE');
      return res.status(error.status).json(error.body);
    }
    if (record.codeHash !== hashCode(code)) {
      await verificationCodes.updateOne({ _id: record._id }, { $inc: { attempts: 1 } });
      const error = fail('INVALID_OR_EXPIRED_CODE');
      return res.status(error.status).json(error.body);
    }
    if (user.status !== 'active') {
      const error = fail('ACCOUNT_DISABLED', 403);
      return res.status(error.status).json(error.body);
    }

    const passwordHash = await bcrypt.hash(newPassword, 10);
    await users.updateOne(
      { _id: user._id },
      { $set: { passwordHash, emailVerified: true, updatedAt: new Date() } }
    );
    await verificationCodes.deleteOne({ _id: record._id });
    const updatedUser = await users.findOne({ _id: user._id });
    return res.json(ok({ ...signTokens(user._id.toString()), user: publicUser(updatedUser) }));
  } catch (error) {
    console.error('Error in POST /auth/password/reset:', error);
    const serverError = fail('SERVER_ERROR', 500);
    return res.status(500).json(serverError.body);
  }
});

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

function relationshipMemberIds(relationship, currentUserId) {
  if (!relationship) return [String(currentUserId)];
  return [String(relationship.userAId), String(relationship.userBId)];
}

function sanitizeChecklist(
  rawChecklist = [],
  allowedAssigneeIds = [],
  fallbackAssigneeId = '',
  existingChecklist = null,
  preserveSubmittedDone = true
) {
  if (!Array.isArray(rawChecklist)) return [];
  const allowed = allowedAssigneeIds.map(String);
  const fallback = String(fallbackAssigneeId || allowed[0] || '');
  const existingDoneById = new Map(
    Array.isArray(existingChecklist)
      ? existingChecklist.map((item) => [String(item?.id || ''), Boolean(item?.isDone)])
      : []
  );
  return rawChecklist
    .map((item) => {
      const title = String(item?.title || '').trim();
      if (!title) return null;
      const assignee = String(item?.assignee || '').trim();
      const id = item?.id ? String(item.id) : new ObjectId().toString();
      return {
        id,
        title,
        assignee: allowed.length === 0 || allowed.includes(assignee) ? assignee : fallback,
        isDone: existingDoneById.has(id)
          ? existingDoneById.get(id)
          : preserveSubmittedDone && Boolean(item?.isDone),
      };
    })
    .filter(Boolean);
}

// Helper: serialize a milestone document to API response shape
function serializeMilestone(item) {
  // Derive isCompleted from status for backward compatibility
  const status = item.status || 'completed';
  const isCompleted = status === 'completed';
  return {
    id: item._id.toString(),
    userId: item.userId.toString(),
    relationshipId: item.relationshipId ? item.relationshipId.toString() : null,
    title: item.title,
    date: item.date,
    icon: item.icon,
    type: item.type || 'memory',
    isCompleted,
    status,
    creatorConfirmed: item.creatorConfirmed ?? true,
    partnerConfirmed: item.partnerConfirmed ?? false,
    partnerProposedDate: item.partnerProposedDate ?? null,
    partnerResponse: item.partnerResponse ?? null,
    // Media & mood
    coverImageUrl: item.coverImageUrl ?? null,
    coverImageUrls: item.coverImageUrls || (item.coverImageUrl ? [item.coverImageUrl] : []),
    mood: item.mood ?? null,
    songTitle: item.songTitle ?? null,
    songArtist: item.songArtist ?? null,
    songPreviewUrl: item.songPreviewUrl ?? null,
    songArtworkUrl: item.songArtworkUrl ?? null,
    checklist: sanitizeChecklist(item.checklist, [], ''),
    createdAt: item.createdAt.toISOString(),
    updatedAt: item.updatedAt.toISOString()
  };
}

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
    return res.json(ok(list.map(serializeMilestone)));
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
      date: String(date),
      icon: String(icon || '🎉'),
      type: String(req.body.type || 'memory'),
      // Dual-confirmation fields
      status: 'pending',
      creatorConfirmed: true,
      partnerConfirmed: false,
      partnerProposedDate: null,
      partnerResponse: null,
      // Media & mood fields
      coverImageUrl: null,
      coverImageUrls: [],
      mood: req.body.mood ? String(req.body.mood) : null,
      songTitle: req.body.songTitle ? String(req.body.songTitle) : null,
      songArtist: req.body.songArtist ? String(req.body.songArtist) : null,
      songPreviewUrl: req.body.songPreviewUrl ? String(req.body.songPreviewUrl) : null,
      songArtworkUrl: req.body.songArtworkUrl ? String(req.body.songArtworkUrl) : null,
      checklist: sanitizeChecklist(
        req.body.checklist,
        relationshipMemberIds(relationship, req.user._id),
        req.user._id,
        null,
        false
      ),
      createdAt: now,
      updatedAt: now
    };
    const result = await milestones.insertOne(milestone);
    milestone._id = result.insertedId;
    return res.json(ok(serializeMilestone(milestone)));
  } catch (error) {
    console.error('Error creating milestone:', error);
    const serverError = fail('SERVER_ERROR', 500);
    return res.status(serverError.status).json(serverError.body);
  }
});

// PUT /milestones/:id  (creator-only: edit title/date/icon)
app.put('/milestones/:id', auth, async (req, res) => {
  const { id } = req.params;
  const { title, date, icon } = req.body;
  if (!title || !date) {
    const error = fail('INVALID_INPUT');
    return res.status(error.status).json(error.body);
  }
  try {
    const query = { _id: new ObjectId(id) };
    const milestone = await milestones.findOne(query);
    if (!milestone) {
      return res.status(404).json({ success: false, error: 'Not found' });
    }
    const isCreator = String(milestone.userId) === String(req.user._id);
    if (!isCreator) {
      return res.status(403).json({ success: false, error: 'Only the creator can edit a milestone.' });
    }
    const relationship = await activeRelationshipFor(req.user._id);
    const now = new Date();
    await milestones.updateOne(query, {
      $set: {
        title: String(title).trim(),
        date: String(date),
        icon: String(icon || '🎉'),
        type: String(req.body.type || milestone.type || 'memory'),
        // Reset confirmation when creator edits
        status: 'pending',
        partnerConfirmed: false,
        partnerResponse: null,
        partnerProposedDate: null,
        // Media & mood
        ...(req.body.mood !== undefined && { mood: req.body.mood ? String(req.body.mood) : null }),
        ...(req.body.songTitle !== undefined && { songTitle: req.body.songTitle ? String(req.body.songTitle) : null }),
        ...(req.body.songArtist !== undefined && { songArtist: req.body.songArtist ? String(req.body.songArtist) : null }),
        ...(req.body.songPreviewUrl !== undefined && { songPreviewUrl: req.body.songPreviewUrl ? String(req.body.songPreviewUrl) : null }),
        ...(req.body.songArtworkUrl !== undefined && { songArtworkUrl: req.body.songArtworkUrl ? String(req.body.songArtworkUrl) : null }),
        ...(req.body.checklist !== undefined && {
          checklist: sanitizeChecklist(
            req.body.checklist,
            relationshipMemberIds(relationship, req.user._id),
            req.user._id,
            milestone.checklist,
            false
          )
        }),
        updatedAt: now
      }
    });
    const updated = await milestones.findOne(query);
    return res.json(ok(serializeMilestone(updated)));
  } catch (error) {
    console.error('Error updating milestone:', error);
    const serverError = fail('SERVER_ERROR', 500);
    return res.status(serverError.status).json(serverError.body);
  }
});

// POST /milestones/:id/respond  (partner: accept | decline | propose_date)
app.post('/milestones/:id/respond', auth, async (req, res) => {
  const { id } = req.params;
  const { action, proposedDate } = req.body;
  if (!['accept', 'decline', 'propose_date'].includes(action)) {
    const error = fail('INVALID_INPUT');
    return res.status(error.status).json(error.body);
  }
  if (action === 'propose_date' && !proposedDate) {
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
    // Must be partner (not creator)
    const isCreator = String(milestone.userId) === String(req.user._id);
    if (isCreator) {
      return res.status(403).json({ success: false, error: 'Creator cannot respond to their own milestone. Use /confirm instead.' });
    }
    if (!relationship) {
      const error = fail('UNAUTHENTICATED', 401);
      return res.status(error.status).json(error.body);
    }
    const now = new Date();
    let statusUpdate = {};
    if (action === 'accept') {
      statusUpdate = { status: 'completed', partnerConfirmed: true, partnerResponse: 'accepted' };
    } else if (action === 'decline') {
      statusUpdate = { status: 'declined', partnerConfirmed: false, partnerResponse: 'declined' };
    } else {
      // propose_date
      statusUpdate = {
        status: 'negotiating',
        partnerConfirmed: false,
        partnerResponse: 'proposed_date',
        partnerProposedDate: String(proposedDate)
      };
    }
    await milestones.updateOne(query, { $set: { ...statusUpdate, updatedAt: now } });
    const updated = await milestones.findOne(query);
    return res.json(ok(serializeMilestone(updated)));
  } catch (error) {
    console.error('Error responding to milestone:', error);
    const serverError = fail('SERVER_ERROR', 500);
    return res.status(serverError.status).json(serverError.body);
  }
});

// POST /milestones/:id/confirm  (creator: accept | decline partner's proposed date)
app.post('/milestones/:id/confirm', auth, async (req, res) => {
  const { id } = req.params;
  const { action } = req.body;
  if (!['accept', 'decline'].includes(action)) {
    const error = fail('INVALID_INPUT');
    return res.status(error.status).json(error.body);
  }
  try {
    const query = { _id: new ObjectId(id) };
    const milestone = await milestones.findOne(query);
    if (!milestone) {
      return res.status(404).json({ success: false, error: 'Not found' });
    }
    const isCreator = String(milestone.userId) === String(req.user._id);
    if (!isCreator) {
      return res.status(403).json({ success: false, error: 'Only the creator can confirm a date proposal.' });
    }
    if (milestone.status !== 'negotiating') {
      return res.status(400).json({ success: false, error: 'Milestone is not in negotiating state.' });
    }
    const now = new Date();
    let statusUpdate = {};
    if (action === 'accept') {
      statusUpdate = {
        status: 'completed',
        partnerConfirmed: true,
        date: milestone.partnerProposedDate,  // adopt partner's suggested date
        updatedAt: now
      };
    } else {
      statusUpdate = { status: 'declined', updatedAt: now };
    }
    await milestones.updateOne(query, { $set: statusUpdate });
    const updated = await milestones.findOne(query);
    return res.json(ok(serializeMilestone(updated)));
  } catch (error) {
    console.error('Error confirming milestone:', error);
    const serverError = fail('SERVER_ERROR', 500);
    return res.status(serverError.status).json(serverError.body);
  }
});

// PATCH /milestones/:id/tasks/:taskId  (relationship members: toggle task)
app.patch('/milestones/:id/tasks/:taskId', auth, async (req, res) => {
  const { id, taskId } = req.params;
  const { isDone } = req.body;
  if (typeof isDone !== 'boolean') {
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

    const checklist = sanitizeChecklist(
      milestone.checklist,
      relationshipMemberIds(relationship, req.user._id),
      req.user._id
    );
    const taskIndex = checklist.findIndex((task) => task.id === String(taskId));
    if (taskIndex === -1) {
      return res.status(404).json({ success: false, error: 'Task not found' });
    }
    if (String(checklist[taskIndex].assignee) !== String(req.user._id)) {
      return res.status(403).json({ success: false, error: 'Only the assigned person can complete this task.' });
    }

    checklist[taskIndex] = { ...checklist[taskIndex], isDone };
    await milestones.updateOne(query, {
      $set: {
        checklist,
        updatedAt: new Date()
      }
    });
    const updated = await milestones.findOne(query);
    return res.json(ok(serializeMilestone(updated)));
  } catch (error) {
    console.error('Error updating milestone task:', error);
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

// POST /milestones/:id/cover  – upload cover image to Cloudinary
const _coverUpload = multer({ storage: multer.memoryStorage(), limits: { fileSize: 10 * 1024 * 1024 } });

app.post('/milestones/:id/cover', auth, _coverUpload.any(), async (req, res) => {
  const { id } = req.params;
  try {
    if (!req.files || req.files.length === 0) {
      const error = fail('INVALID_INPUT');
      return res.status(error.status).json(error.body);
    }

    const query = { _id: new ObjectId(id) };
    const milestone = await milestones.findOne(query);
    if (!milestone) {
      return res.status(404).json({ success: false, error: 'Not found' });
    }
    const isCreator = String(milestone.userId) === String(req.user._id);
    if (!isCreator) {
      return res.status(403).json({ success: false, error: 'Only the creator can upload a cover image.' });
    }

    // Configure cloudinary
    cloudinary.config({
      cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
      api_key: process.env.CLOUDINARY_API_KEY,
      api_secret: process.env.CLOUDINARY_API_SECRET,
    });

    if (!process.env.CLOUDINARY_CLOUD_NAME) {
      return res.status(500).json({ success: false, error: 'Cloudinary not configured' });
    }

    // Upload to Cloudinary under milestones/ folder
    const folder = `milestones/${String(req.user._id)}`;
    
    const coverImageUrls = [];
    for (let i = 0; i < req.files.length; i++) {
      const file = req.files[i];
      const publicId = `cover_${id}_${i}_${Date.now()}`;

      const uploadResult = await new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
          { folder, public_id: publicId, overwrite: true, resource_type: 'image' },
          (err, result) => {
            if (err) reject(err);
            else resolve(result);
          }
        );
        stream.end(file.buffer);
      });

      const url = cloudinary.url(uploadResult.public_id, {
        secure: true,
        transformation: [{ width: 800, crop: 'limit', quality: 'auto', fetch_format: 'auto' }],
      });
      coverImageUrls.push(url);
    }

    const coverImageUrl = coverImageUrls.length > 0 ? coverImageUrls[0] : null;

    const now = new Date();
    await milestones.updateOne(query, { $set: { coverImageUrl, coverImageUrls, updatedAt: now } });
    const updated = await milestones.findOne(query);
    return res.json(ok(serializeMilestone(updated)));
  } catch (error) {
    console.error('Error uploading milestone cover:', error);
    const serverError = fail('SERVER_ERROR', 500);
    return res.status(serverError.status).json(serverError.body);
  }
});

app.get('/heart-map', auth, async (req, res) => {
  try {
    const relationship = await activeRelationshipFor(req.user._id);
    if (!relationship) {
      const error = fail('RELATIONSHIP_NOT_FOUND', 404);
      return res.status(error.status).json(error.body);
    }

    const partnerId = String(relationship.userAId) === String(req.user._id)
      ? relationship.userBId
      : relationship.userAId;
    const [selfLocation, partnerLocation, history] = await Promise.all([
      heartLocations.findOne({ relationshipId: relationship._id, userId: req.user._id }),
      heartLocations.findOne({ relationshipId: relationship._id, userId: partnerId }),
      heartLocationHistory
        .find({ relationshipId: relationship._id })
        .sort({ recordedAt: -1 })
        .limit(40)
        .toArray()
    ]);

    const distanceMeters = selfLocation && partnerLocation
      ? distanceBetweenMeters(selfLocation, partnerLocation)
      : null;

    return res.json(ok({
      relationshipId: relationship._id.toString(),
      self: serializeHeartLocation(selfLocation),
      partner: serializeHeartLocation(partnerLocation),
      distanceMeters,
      status: heartDistanceStatus(distanceMeters),
      history: history.map(serializeHeartLocation)
    }));
  } catch (error) {
    console.error('Error fetching heart map:', error);
    const serverError = fail('SERVER_ERROR', 500);
    return res.status(serverError.status).json(serverError.body);
  }
});

app.post('/heart-map/location', auth, async (req, res) => {
  try {
    const latitude = Number(req.body.latitude);
    const longitude = Number(req.body.longitude);
    const accuracy = req.body.accuracy == null ? null : Number(req.body.accuracy);

    if (!Number.isFinite(latitude) || !Number.isFinite(longitude) ||
        latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
      const error = fail('INVALID_INPUT');
      return res.status(error.status).json(error.body);
    }

    const relationship = await activeRelationshipFor(req.user._id);
    if (!relationship) {
      const error = fail('RELATIONSHIP_NOT_FOUND', 404);
      return res.status(error.status).json(error.body);
    }

    const partnerId = String(relationship.userAId) === String(req.user._id)
      ? relationship.userBId
      : relationship.userAId;
    const now = new Date();
    const location = {
      relationshipId: relationship._id,
      userId: req.user._id,
      latitude,
      longitude,
      accuracy,
      recordedAt: now,
      updatedAt: now
    };

    await heartLocations.updateOne(
      { relationshipId: relationship._id, userId: req.user._id },
      { $set: location, $setOnInsert: { createdAt: now } },
      { upsert: true }
    );
    await heartLocationHistory.insertOne(location);

    const [selfLocation, partnerLocation, history] = await Promise.all([
      heartLocations.findOne({ relationshipId: relationship._id, userId: req.user._id }),
      heartLocations.findOne({ relationshipId: relationship._id, userId: partnerId }),
      heartLocationHistory
        .find({ relationshipId: relationship._id })
        .sort({ recordedAt: -1 })
        .limit(40)
        .toArray()
    ]);

    const distanceMeters = selfLocation && partnerLocation
      ? distanceBetweenMeters(selfLocation, partnerLocation)
      : null;

    return res.json(ok({
      relationshipId: relationship._id.toString(),
      self: serializeHeartLocation(selfLocation),
      partner: serializeHeartLocation(partnerLocation),
      distanceMeters,
      status: heartDistanceStatus(distanceMeters),
      history: history.map(serializeHeartLocation)
    }));
  } catch (error) {
    console.error('Error updating heart map location:', error);
    const serverError = fail('SERVER_ERROR', 500);
    return res.status(serverError.status).json(serverError.body);
  }
});

function serializeHeartLocation(location) {
  if (!location) return null;
  return {
    id: location._id?.toString?.() ?? null,
    relationshipId: location.relationshipId?.toString?.() ?? null,
    userId: location.userId?.toString?.() ?? null,
    latitude: location.latitude,
    longitude: location.longitude,
    accuracy: location.accuracy ?? null,
    recordedAt: location.recordedAt?.toISOString?.() ?? location.recordedAt,
    updatedAt: location.updatedAt?.toISOString?.() ?? location.updatedAt
  };
}

function distanceBetweenMeters(a, b) {
  const earthRadiusMeters = 6371000;
  const lat1 = toRadians(a.latitude);
  const lat2 = toRadians(b.latitude);
  const deltaLat = toRadians(b.latitude - a.latitude);
  const deltaLng = toRadians(b.longitude - a.longitude);
  const h = Math.sin(deltaLat / 2) ** 2 +
    Math.cos(lat1) * Math.cos(lat2) * Math.sin(deltaLng / 2) ** 2;
  return Math.round(earthRadiusMeters * 2 * Math.atan2(Math.sqrt(h), Math.sqrt(1 - h)));
}

function toRadians(value) {
  return value * Math.PI / 180;
}

function heartDistanceStatus(distanceMeters) {
  if (distanceMeters == null) return 'unknown';
  return distanceMeters <= 1000 ? 'near' : 'far';
}

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
