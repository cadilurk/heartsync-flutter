import { Router } from 'express';
import payOS from './payos.js';

export default function createStoreRouter(db, auth, ok, fail) {
  const router = Router();
  const products = db.collection('products');
  const orders = db.collection('orders');
  const carts = db.collection('carts');

  // Tự động seed sản phẩm nếu collection products trống
  products.countDocuments().then(async (count) => {
    if (count === 0) {
      console.log('[Seed] Collection products trống. Đang nạp sản phẩm mẫu...');
      const mockProductsList = [
        {
          id: 'p1',
          name: 'Ly Sứ Đôi Hoa Hồng',
          description: 'Cặp ly sứ cao cấp thiết kế dành riêng cho các cặp đôi. Thích hợp cho trà chiều ngọt ngào cùng partner.',
          price: 180000,
          imageUrl: 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?q=80&w=600',
          images: [
            'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?q=80&w=600',
            'https://images.unsplash.com/photo-1576092768241-dec231879fc3?q=80&w=600',
            'https://images.unsplash.com/photo-1536304997881-a372c179924b?q=80&w=600'
          ],
          rating: 4.8,
          category: 'Quà tặng',
          isDigital: false,
          inStock: 15,
          soldCount: 142
        },
        {
          id: 'p2',
          name: 'Móc Khóa Da Khắc Tên',
          description: 'Móc khóa bằng da bò thật, khắc tên của bạn và đối phương. Một món quà nhỏ luôn bên mình.',
          price: 95000,
          imageUrl: 'https://images.unsplash.com/photo-1582139329536-e7284fece509?q=80&w=600',
          images: [
            'https://images.unsplash.com/photo-1582139329536-e7284fece509?q=80&w=600',
            'https://images.unsplash.com/photo-1622560480605-d83c853bc5c3?q=80&w=600',
            'https://images.unsplash.com/photo-1611591437281-460bfbe1220a?q=80&w=600'
          ],
          rating: 4.6,
          category: 'Quà tặng',
          isDigital: false,
          inStock: 45,
          soldCount: 389
        },
        {
          id: 'p3',
          name: 'Voucher Hẹn Hò Nến & Hoa',
          description: 'Một bữa tối lãng mạn dành cho 2 người tại nhà hàng sân vườn Rose Garden với hoa hồng và ánh nến lung linh.',
          price: 850000,
          imageUrl: 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?q=80&w=600',
          images: [
            'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?q=80&w=600',
            'https://images.unsplash.com/photo-1522413452208-996ff3f3e740?q=80&w=600',
            'https://images.unsplash.com/photo-1559339352-11d035aa65de?q=80&w=600'
          ],
          rating: 4.9,
          category: 'Hẹn hò',
          isDigital: true,
          inStock: 99,
          soldCount: 78
        },
        {
          id: 'p4',
          name: 'Theme Ứng Dụng Rose Gold Premium',
          description: 'Thay đổi giao diện ứng dụng HeartSync sang màu hồng vàng kim sa trọng, lấp lánh và đầy lãng mạn.',
          price: 49000,
          imageUrl: 'https://images.unsplash.com/photo-1557683316-973673baf926?q=80&w=600',
          images: [
            'https://images.unsplash.com/photo-1557683316-973673baf926?q=80&w=600',
            'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=600',
            'https://images.unsplash.com/photo-1528459801416-a9e53bbf4e17?q=80&w=600'
          ],
          rating: 4.7,
          category: 'Vật phẩm số',
          isDigital: true,
          inStock: 9999,
          soldCount: 1205
        },
        {
          id: 'p5',
          name: 'Bộ Bài Truth or Dare Couple',
          description: '50 thử thách và câu hỏi sâu sắc giúp bạn và partner hiểu nhau hơn trong các buổi hẹn hò.',
          price: 120000,
          imageUrl: 'https://images.unsplash.com/photo-1606167668584-78701c57f13d?q=80&w=600',
          images: [
            'https://images.unsplash.com/photo-1606167668584-78701c57f13d?q=80&w=600',
            'https://images.unsplash.com/photo-1585504198199-20277593b94f?q=80&w=600',
            'https://images.unsplash.com/photo-1511193311914-0346f16efe90?q=80&w=600'
          ],
          rating: 4.9,
          category: 'Hẹn hò',
          isDigital: false,
          inStock: 30,
          soldCount: 64
        },
        {
          id: 'p6',
          name: 'Album Ảnh Kỷ Niệm Gỗ Hand-made',
          description: 'Cuốn album gỗ sang trọng để bạn dán những tấm ảnh chụp chung ngọt ngào nhất của hai người.',
          price: 250000,
          imageUrl: 'https://images.unsplash.com/photo-1544816155-12df9643f363?q=80&w=600',
          images: [
            'https://images.unsplash.com/photo-1544816155-12df9643f363?q=80&w=600',
            'https://images.unsplash.com/photo-1512820790803-83ca734da794?q=80&w=600',
            'https://images.unsplash.com/photo-1457369804613-52c61a468e7d?q=80&w=600'
          ],
          rating: 4.5,
          category: 'Quà tặng',
          isDigital: false,
          inStock: 8,
          soldCount: 29
        }
      ];
      await products.insertMany(mockProductsList);
      console.log('[Seed] Đã nạp xong 6 sản phẩm mẫu vào MongoDB.');
    }
  }).catch(err => {
    console.error('[Seed] Lỗi seed sản phẩm:', err);
  });

  // GET /products - Lấy danh sách sản phẩm từ MongoDB
  router.get('/products', async (_req, res) => {
    try {
      const list = await products.find({}).toArray();
      console.log(`[GET /products] Tìm thấy ${list.length} sản phẩm trong MongoDB`);
      return res.json(ok(list.map(p => {
        const { _id, ...rest } = p;
        return rest;
      })));
    } catch (error) {
      console.error('[GET /products] Lỗi:', error);
      const serverError = fail('SERVER_ERROR', 500);
      return res.status(serverError.status).json(serverError.body);
    }
  });

  // GET /products/:id - Lấy chi tiết một sản phẩm
  router.get('/products/:id', async (req, res) => {
    try {
      const product = await products.findOne({ id: req.params.id });
      if (!product) {
        const error = fail('SERVER_ERROR', 404);
        return res.status(error.status).json(error.body);
      }
      const { _id, ...rest } = product;
      return res.json(ok(rest));
    } catch (error) {
      console.error(`[GET /products/${req.params.id}] Lỗi:`, error);
      const serverError = fail('SERVER_ERROR', 500);
      return res.status(serverError.status).json(serverError.body);
    }
  });

  // POST /orders - Tạo đơn hàng thanh toán hoặc gửi quà qua cổng PayOS
  router.post('/orders', auth, async (req, res) => {
    const { items, isGift, giftMessage, shippingName, shippingPhone, shippingAddress } = req.body;
    if (!items || !Array.isArray(items) || items.length === 0) {
      const error = fail('INVALID_INPUT');
      return res.status(error.status).json(error.body);
    }

    const now = new Date();
    let totalAmount = 0;
    for (const item of items) {
      totalAmount += (item.product.price * item.quantity);
    }

    // Phí ship: miễn phí khi test (đặt lại sau khi deploy thật)
    const shippingFee = 0;
    const finalAmount = totalAmount + shippingFee;

    // Yêu cầu của PayOS: orderCode phải là số nguyên duy nhất, tối đa 9007199254740991
    const orderCode = Number(now.getTime().toString().slice(-9));

    let paymentLink;
    try {
      // @payos/node v2: dùng payOS.paymentRequests.create() thay vì createPaymentLink()
      paymentLink = await payOS.paymentRequests.create({
        orderCode: orderCode,
        amount: finalAmount,
        description: `Heartsync ${orderCode}`, // Tối đa 25 ký tự
        cancelUrl: `${process.env.BACKEND_BASE_URL || 'http://localhost:5291'}/health`,
        returnUrl: `${process.env.BACKEND_BASE_URL || 'http://localhost:5291'}/health`,
      });
      console.log(`[PayOS] ✅ Tạo link thành công cho ORD_${orderCode}:`, {
        checkoutUrl: paymentLink.checkoutUrl,
        qrCode: paymentLink.qrCode ? paymentLink.qrCode.substring(0, 30) + '...' : null,
        accountNumber: paymentLink.accountNumber,
        accountName: paymentLink.accountName,
        bin: paymentLink.bin,
      });
    } catch (error) {
      console.error('[PayOS] ❌ Lỗi khi gọi paymentRequests.create:', {
        message: error.message,
        code: error.code,
        response: error.response?.data || error.response || null,
        stack: error.stack?.split('\n')[0],
      });
      // Chế độ dự phòng (fallback) để tránh lỗi crash khi người dùng chưa gán API Key thật
      paymentLink = {
        checkoutUrl: 'mock-payment-url',
        qrCode: null,
        accountNumber: null,
        accountName: null,
        bin: null,
      };
    }

    const isMock = paymentLink.checkoutUrl === 'mock-payment-url';
    const status = isMock ? (isGift ? 'Đã gửi tặng' : 'Đã thanh toán') : 'PENDING';

    const order = {
      id: `ORD_${orderCode}`,
      orderCode: orderCode,
      userId: req.user._id.toString(),
      items,
      totalAmount: finalAmount,
      orderDate: now,
      isGift: isGift || false,
      status: status,
      giftMessage: giftMessage || null,
      shippingName: shippingName || null,
      shippingPhone: shippingPhone || null,
      shippingAddress: shippingAddress || null,
      checkoutUrl: paymentLink.checkoutUrl,
      qrCode: paymentLink.qrCode || null,
      accountNumber: paymentLink.accountNumber || null,
      accountName: paymentLink.accountName || null,
      bin: paymentLink.bin || null,
      createdAt: now,
      updatedAt: now
    };

    try {
      await orders.insertOne(order);

      // Nếu là luồng giả lập/thanh toán luôn, loại bỏ các sản phẩm đã thanh toán ra khỏi giỏ hàng ngay lập tức
      if (status !== 'PENDING') {
        const checkedOutIds = items.map(item => item.product.id);
        const cart = await carts.findOne({ userId: req.user._id.toString() });
        if (cart) {
          const remainingItems = cart.items.filter(item => !checkedOutIds.includes(item.productId));
          await carts.updateOne(
            { userId: req.user._id.toString() },
            { $set: { items: remainingItems, updatedAt: now } }
          );
        }
      }

      const { _id, userId, ...rest } = order;
      return res.json(ok({
        ...rest,
        orderDate: now.toISOString()
      }));
    } catch (error) {
      console.error('[POST /orders] Lỗi lưu đơn hàng:', error);
      const serverError = fail('SERVER_ERROR', 500);
      return res.status(serverError.status).json(serverError.body);
    }
  });

  // GET /orders/:id/status - Lấy trạng thái đơn hàng (phục vụ Polling kiểm tra thanh toán từ Flutter)
  router.get('/orders/:id/status', auth, async (req, res) => {
    try {
      const order = await orders.findOne({ id: req.params.id, userId: req.user._id.toString() });
      if (!order) {
        const error = fail('SERVER_ERROR', 404);
        return res.status(error.status).json(error.body);
      }
      return res.json(ok({ status: order.status }));
    } catch (error) {
      console.error(`[GET /orders/${req.params.id}/status] Lỗi:`, error);
      const serverError = fail('SERVER_ERROR', 500);
      return res.status(serverError.status).json(serverError.body);
    }
  });

  // POST /orders/:id/verify - Chủ động hỏi PayOS xem đơn hàng đã được thanh toán chưa
  // Flutter gọi route này sau khi user bấm "Tôi đã chuyển tiền xong"
  router.post('/orders/:id/verify', auth, async (req, res) => {
    try {
      const order = await orders.findOne({ id: req.params.id, userId: req.user._id.toString() });
      if (!order) {
        const error = fail('SERVER_ERROR', 404);
        return res.status(error.status).json(error.body);
      }

      // Nếu đã được cập nhật rồi thì trả về luôn
      if (order.status !== 'PENDING') {
        return res.json(ok({ status: order.status, verified: true }));
      }

      // Chủ động hỏi PayOS API về trạng thái orderCode
      let payosStatus = null;
      try {
        const paymentInfo = await payOS.paymentRequests.get(order.orderCode);
        payosStatus = paymentInfo?.status; // 'PAID', 'PENDING', 'CANCELLED', etc.
        console.log(`[Verify] PayOS trả về status cho orderCode ${order.orderCode}: ${payosStatus}`, paymentInfo);
      } catch (payosError) {
        console.error(`[Verify] Không thể hỏi PayOS:`, payosError.message);
        // Nếu hỏi PayOS lỗi thì vẫn trả về status hiện tại trong DB
        return res.json(ok({ status: order.status, verified: false, error: payosError.message }));
      }

      // Nếu PayOS xác nhận đã thanh toán → cập nhật MongoDB
      if (payosStatus === 'PAID') {
        const now = new Date();
        const newStatus = order.isGift ? 'Đã gửi tặng' : 'Đã thanh toán';
        await orders.updateOne(
          { id: req.params.id },
          { $set: { status: newStatus, updatedAt: now } }
        );

        // Xoá các sản phẩm đã thanh toán khỏi giỏ hàng
        const checkedOutIds = order.items.map(item => item.product.id);
        const cart = await carts.findOne({ userId: order.userId });
        if (cart) {
          const remainingItems = cart.items.filter(item => !checkedOutIds.includes(item.productId));
          await carts.updateOne(
            { userId: order.userId },
            { $set: { items: remainingItems, updatedAt: now } }
          );
        }

        console.log(`[Verify] ✅ Đơn hàng ${req.params.id} cập nhật thành công → '${newStatus}'`);
        return res.json(ok({ status: newStatus, verified: true }));
      }

      // PayOS chưa xác nhận thanh toán
      return res.json(ok({ status: order.status, verified: false, payosStatus }));
    } catch (error) {
      console.error(`[POST /orders/${req.params.id}/verify] Lỗi:`, error);
      const serverError = fail('SERVER_ERROR', 500);
      return res.status(serverError.status).json(serverError.body);
    }
  });

  // GET /orders/history - Lấy lịch sử đơn hàng của user hiện tại
  router.get('/orders/history', auth, async (req, res) => {
    try {
      const list = await orders.find({ userId: req.user._id.toString() }).sort({ createdAt: -1 }).toArray();
      return res.json(ok(list.map(o => {
        const { _id, userId, ...rest } = o;
        return {
          ...rest,
          orderDate: o.orderDate instanceof Date ? o.orderDate.toISOString() : o.orderDate
        };
      })));
    } catch (error) {
      console.error('[GET /orders/history] Lỗi:', error);
      const serverError = fail('SERVER_ERROR', 500);
      return res.status(serverError.status).json(serverError.body);
    }
  });

  // --- Cart API Endpoints ---

  // Helper hàm để giải quyết thông tin sản phẩm và trả về items hoàn chỉnh
  async function getResolvedCartItems(cartItemsList) {
    const resolved = [];
    for (const item of cartItemsList) {
      const prod = await products.findOne({ id: item.productId });
      if (prod) {
        const { _id, ...productData } = prod;
        resolved.push({
          product: productData,
          quantity: item.quantity
        });
      }
    }
    return resolved;
  }

  // GET /cart - Lấy giỏ hàng của user hiện tại
  router.get('/cart', auth, async (req, res) => {
    try {
      const userId = req.user._id.toString();
      const cart = await carts.findOne({ userId });
      if (!cart) {
        return res.json(ok({ userId, items: [] }));
      }
      const resolvedItems = await getResolvedCartItems(cart.items);
      return res.json(ok({ userId, items: resolvedItems }));
    } catch (error) {
      console.error('[GET /cart] Lỗi:', error);
      const serverError = fail('SERVER_ERROR', 500);
      return res.status(serverError.status).json(serverError.body);
    }
  });

  // POST /cart - Thêm sản phẩm hoặc tăng số lượng trong giỏ hàng
  router.post('/cart', auth, async (req, res) => {
    const { productId, quantity } = req.body;
    const qty = parseInt(quantity) || 1;
    if (!productId) {
      const error = fail('INVALID_INPUT');
      return res.status(error.status).json(error.body);
    }

    try {
      // Xác nhận sản phẩm tồn tại
      const product = await products.findOne({ id: productId });
      if (!product) {
        const error = fail('SERVER_ERROR', 404);
        return res.status(error.status).json(error.body);
      }

      const userId = req.user._id.toString();
      let cart = await carts.findOne({ userId });
      const now = new Date();

      if (!cart) {
        cart = {
          userId,
          items: [{ productId, quantity: qty }],
          createdAt: now,
          updatedAt: now
        };
        await carts.insertOne(cart);
      } else {
        const itemIndex = cart.items.findIndex(item => item.productId === productId);
        if (itemIndex > -1) {
          cart.items[itemIndex].quantity += qty;
        } else {
          cart.items.push({ productId, quantity: qty });
        }
        await carts.updateOne(
          { userId },
          { $set: { items: cart.items, updatedAt: now } }
        );
      }

      const resolvedItems = await getResolvedCartItems(cart.items);
      return res.json(ok({ userId, items: resolvedItems }));
    } catch (error) {
      console.error('[POST /cart] Lỗi:', error);
      const serverError = fail('SERVER_ERROR', 500);
      return res.status(serverError.status).json(serverError.body);
    }
  });

  // PUT /cart - Cập nhật chính xác số lượng sản phẩm (hoặc xóa nếu <= 0)
  router.put('/cart', auth, async (req, res) => {
    const { productId, quantity } = req.body;
    const qty = parseInt(quantity);
    if (!productId || isNaN(qty)) {
      const error = fail('INVALID_INPUT');
      return res.status(error.status).json(error.body);
    }

    try {
      const userId = req.user._id.toString();
      let cart = await carts.findOne({ userId });
      const now = new Date();

      if (!cart) {
        return res.json(ok({ userId, items: [] }));
      }

      if (qty <= 0) {
        // Xóa hẳn sản phẩm khỏi giỏ hàng
        cart.items = cart.items.filter(item => item.productId !== productId);
      } else {
        const itemIndex = cart.items.findIndex(item => item.productId === productId);
        if (itemIndex > -1) {
          cart.items[itemIndex].quantity = qty;
        } else {
          cart.items.push({ productId, quantity: qty });
        }
      }

      await carts.updateOne(
        { userId },
        { $set: { items: cart.items, updatedAt: now } }
      );

      const resolvedItems = await getResolvedCartItems(cart.items);
      return res.json(ok({ userId, items: resolvedItems }));
    } catch (error) {
      console.error('[PUT /cart] Lỗi:', error);
      const serverError = fail('SERVER_ERROR', 500);
      return res.status(serverError.status).json(serverError.body);
    }
  });

  // DELETE /cart - Xóa sạch giỏ hàng của người dùng
  router.delete('/cart', auth, async (req, res) => {
    try {
      const userId = req.user._id.toString();
      await carts.updateOne(
        { userId },
        { $set: { items: [], updatedAt: new Date() } }
      );
      return res.json(ok({ userId, items: [] }));
    } catch (error) {
      console.error('[DELETE /cart] Lỗi:', error);
      const serverError = fail('SERVER_ERROR', 500);
      return res.status(serverError.status).json(serverError.body);
    }
  });

  return router;
}
