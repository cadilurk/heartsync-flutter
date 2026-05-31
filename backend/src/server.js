import 'dotenv/config';
import bcrypt from 'bcryptjs';
import cors from 'cors';
import express from 'express';
import jwt from 'jsonwebtoken';
import { MongoClient, ObjectId } from 'mongodb';
import createStoreRouter from './storeRouter.js';
import payOS from './payos.js';

const app = express();
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

const users = db.collection('users');
const profiles = db.collection('profiles');
const relationships = db.collection('coupleRelationships');
const pairingCodes = db.collection('pairingCodes');

// Diagnostic logger for database and collection presence
const productCount = await db.collection('products').countDocuments();
console.log(`[Database Info] Số lượng sản phẩm trong database 'heartsync': ${productCount}`);
if (productCount === 0) {
  console.log('[Database Warning] Không có sản phẩm nào trong database "heartsync".');
  try {
    const adminDb = client.db().admin();
    const dbs = await adminDb.listDatabases();
    console.log('[Database Debug] Các databases hiện có trên Cluster:', dbs.databases.map(d => d.name));
    for (const d of dbs.databases) {
      const tempDb = client.db(d.name);
      const cols = await tempDb.listCollections().toArray();
      if (cols.some(c => c.name === 'products')) {
        console.log(`[Database Debug] -> Phát hiện collection "products" đang nằm ở database: "${d.name}"`);
      }
    }
  } catch (err) {
    console.log('[Database Debug] Không thể quét danh sách database trên Atlas (có thể do thiếu quyền).');
  }
}

await users.createIndex({ email: 1 }, { unique: true });
await pairingCodes.createIndex({ code: 1 }, { unique: true });
await pairingCodes.createIndex({ expiredAt: 1 }, { expireAfterSeconds: 3600 });

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

// Cấu hình Webhook nhận thanh toán từ PayOS
app.post('/payment/payos-webhook', async (req, res) => {
  const webhookBody = req.body;
  
  try {
    // 1. Kiểm tra tính hợp lệ và giải mã dữ liệu webhook bằng SDK v2
    const decodedData = await payOS.webhooks.verify(webhookBody);
    console.log(`[PayOS Webhook] Giải mã webhook thành công:`, decodedData);
    
    // 2. Tìm đơn hàng tương ứng trong cơ sở dữ liệu MongoDB
    const orderCode = decodedData.orderCode;
    const ordersCollection = db.collection('orders');
    const cartsCollection = db.collection('carts');
    
    const order = await ordersCollection.findOne({ orderCode: orderCode });
    if (order && order.status === 'PENDING') {
      const now = new Date();
      
      // 3. Cập nhật trạng thái đơn hàng thành PAID (Đã thanh toán) hoặc Đã gửi tặng nếu isGift là true
      const newStatus = order.isGift ? 'Đã gửi tặng' : 'Đã thanh toán';
      await ordersCollection.updateOne(
        { orderCode: orderCode },
        { $set: { status: newStatus, updatedAt: now } }
      );
      
      // 4. Đồng thời xoá sạch những món đồ đã mua ra khỏi giỏ hàng của user
      const checkedOutIds = order.items.map(item => item.product.id);
      const cart = await cartsCollection.findOne({ userId: order.userId });
      if (cart) {
        const remainingItems = cart.items.filter(item => !checkedOutIds.includes(item.productId));
        await cartsCollection.updateOne(
          { userId: order.userId },
          { $set: { items: remainingItems, updatedAt: now } }
        );
      }
      
      console.log(`[PayOS Webhook] Đơn hàng ORD_${orderCode} đã cập nhật thành công trạng thái '${newStatus}'!`);
    } else {
      console.log(`[PayOS Webhook] Không tìm thấy đơn hàng PENDING khớp với mã: ${orderCode}`);
    }
    
    return res.json({ success: true });
  } catch (error) {
    console.error('[PayOS Webhook Error] Chữ ký không hợp lệ hoặc lỗi DB:', error.message);
    // Để xác nhận cho PayOS biết webhook đã nhận được (tránh họ gửi đi gửi lại nếu do lỗi ký mock),
    // ta vẫn trả về 200 nhưng ghi nhận log
    return res.status(200).json({ success: false, message: error.message });
  }
});

app.use(createStoreRouter(db, auth, ok, fail));

app.use((_req, res) => {
  const error = fail('SERVER_ERROR', 404);
  return res.status(error.status).json(error.body);
});

app.listen(port, '0.0.0.0', () => {
  console.log(`Heart Sync API listening on http://0.0.0.0:${port}`);
});
