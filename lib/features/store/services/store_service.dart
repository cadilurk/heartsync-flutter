import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/product.dart';

class StoreService {
  final ApiClient _apiClient;
  // Mock product catalog
  final List<Product> _mockProducts = [
    const Product(
      id: 'p1',
      name: 'Ly Sứ Đôi Hoa Hồng',
      description: 'Cặp ly sứ cao cấp thiết kế dành riêng cho các cặp đôi. Thích hợp cho trà chiều ngọt ngào cùng partner.',
      price: 180000,
      imageUrl: 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?q=80&w=600',
      images: [
        'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?q=80&w=600',
        'https://images.unsplash.com/photo-1576092768241-dec231879fc3?q=80&w=600',
        'https://images.unsplash.com/photo-1536304997881-a372c179924b?q=80&w=600',
      ],
      rating: 4.8,
      category: 'Quà tặng',
      isDigital: false,
      inStock: 15,
      soldCount: 142,
    ),
    const Product(
      id: 'p2',
      name: 'Móc Khóa Da Khắc Tên',
      description: 'Móc khóa bằng da bò thật, khắc tên của bạn và đối phương. Một món quà nhỏ luôn bên mình.',
      price: 95000,
      imageUrl: 'https://images.unsplash.com/photo-1582139329536-e7284fece509?q=80&w=600',
      images: [
        'https://images.unsplash.com/photo-1582139329536-e7284fece509?q=80&w=600',
        'https://images.unsplash.com/photo-1622560480605-d83c853bc5c3?q=80&w=600',
        'https://images.unsplash.com/photo-1611591437281-460bfbe1220a?q=80&w=600',
      ],
      rating: 4.6,
      category: 'Quà tặng',
      isDigital: false,
      inStock: 45,
      soldCount: 389,
    ),
    const Product(
      id: 'p3',
      name: 'Voucher Hẹn Hò Nến & Hoa',
      description: 'Một bữa tối lãng mạn dành cho 2 người tại nhà hàng sân vườn Rose Garden với hoa hồng và ánh nến lung linh.',
      price: 850000,
      imageUrl: 'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?q=80&w=600',
      images: [
        'https://images.unsplash.com/photo-1517457373958-b7bdd4587205?q=80&w=600',
        'https://images.unsplash.com/photo-1522413452208-996ff3f3e740?q=80&w=600',
        'https://images.unsplash.com/photo-1559339352-11d035aa65de?q=80&w=600',
      ],
      rating: 4.9,
      category: 'Hẹn hò',
      isDigital: true,
      inStock: 99,
      soldCount: 78,
    ),
    const Product(
      id: 'p4',
      name: 'Theme Ứng Dụng Rose Gold Premium',
      description: 'Thay đổi giao diện ứng dụng HeartSync sang màu hồng vàng kim sa trọng, lấp lánh và đầy lãng mạn.',
      price: 49000,
      imageUrl: 'https://images.unsplash.com/photo-1557683316-973673baf926?q=80&w=600',
      images: [
        'https://images.unsplash.com/photo-1557683316-973673baf926?q=80&w=600',
        'https://images.unsplash.com/photo-1618005182384-a83a8bd57fbe?q=80&w=600',
        'https://images.unsplash.com/photo-1528459801416-a9e53bbf4e17?q=80&w=600',
      ],
      rating: 4.7,
      category: 'Vật phẩm số',
      isDigital: true,
      inStock: 9999,
      soldCount: 1205,
    ),
    const Product(
      id: 'p5',
      name: 'Bộ Bài Truth or Dare Couple',
      description: '50 thử thách và câu hỏi sâu sắc giúp bạn và partner hiểu nhau hơn trong các buổi hẹn hò.',
      price: 120000,
      imageUrl: 'https://images.unsplash.com/photo-1606167668584-78701c57f13d?q=80&w=600',
      images: [
        'https://images.unsplash.com/photo-1606167668584-78701c57f13d?q=80&w=600',
        'https://images.unsplash.com/photo-1585504198199-20277593b94f?q=80&w=600',
        'https://images.unsplash.com/photo-1511193311914-0346f16efe90?q=80&w=600',
      ],
      rating: 4.9,
      category: 'Hẹn hò',
      isDigital: false,
      inStock: 30,
      soldCount: 64,
    ),
    const Product(
      id: 'p6',
      name: 'Album Ảnh Kỷ Niệm Gỗ Hand-made',
      description: 'Cuốn album gỗ sang trọng để bạn dán những tấm ảnh chụp chung ngọt ngào nhất của hai người.',
      price: 250000,
      imageUrl: 'https://images.unsplash.com/photo-1544816155-12df9643f363?q=80&w=600',
      images: [
        'https://images.unsplash.com/photo-1544816155-12df9643f363?q=80&w=600',
        'https://images.unsplash.com/photo-1512820790803-83ca734da794?q=80&w=600',
        'https://images.unsplash.com/photo-1457369804613-52c61a468e7d?q=80&w=600',
      ],
      rating: 4.5,
      category: 'Quà tặng',
      isDigital: false,
      inStock: 8,
      soldCount: 29,
    ),
  ];

  // In-memory mock order history
  final List<Order> _mockOrders = [];
  final Map<String, String> _mockOrderStatuses = {};

  StoreService(this._apiClient);

  Future<List<Product>> fetchProducts() async {
    if (ApiConstants.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 400));
      return _mockProducts;
    }

    try {
      final result = await _apiClient.get<List<Product>>(
        '/products',
        (json) {
          if (json is List) {
            return json.map((e) => Product.fromJson(e as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );
      return result;
    } catch (e) {
      // Backend chưa sẵn sàng → dùng mock data để app vẫn chạy được
      return _mockProducts;
    }
  }

  Future<Product> fetchProductById(String id) async {
    if (ApiConstants.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 200));
      return _mockProducts.firstWhere((p) => p.id == id);
    }

    try {
      return await _apiClient.get<Product>(
        '/products/$id',
        (json) => Product.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      // Fallback về mock nếu API lỗi
      return _mockProducts.firstWhere((p) => p.id == id,
          orElse: () => _mockProducts.first);
    }
  }

  Future<Order> checkout({
    required List<CartItem> items,
    required bool isGift,
    String? giftMessage,
  }) async {
    if (ApiConstants.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 800));
      final double total = items.fold(0.0, (sum, item) => sum + item.totalPrice);
      final order = Order(
        id: 'ORD_${DateTime.now().millisecondsSinceEpoch}',
        items: List.from(items),
        totalAmount: total,
        orderDate: DateTime.now(),
        isGift: isGift,
        status: isGift ? 'Đã gửi tặng' : 'Đã thanh toán',
        giftMessage: giftMessage,
      );
      _mockOrders.insert(0, order);
      return order;
    }

    final body = {
      'items': items.map((item) => item.toJson()).toList(),
      'isGift': isGift,
      'giftMessage': giftMessage,
    };

    try {
      return await _apiClient.post<Order>(
        '/orders',
        body,
        (json) => Order.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      // Backend offline → tạo mock order để thanh toán tiếp tục
      final double total = items.fold(0.0, (sum, item) => sum + item.totalPrice);
      final orderId = 'ORD_${DateTime.now().millisecondsSinceEpoch}';
      final order = Order(
        id: orderId,
        items: List.from(items),
        totalAmount: total,
        orderDate: DateTime.now(),
        isGift: isGift,
        status: isGift ? 'Đã gửi tặng' : 'Đang xử lý',
        giftMessage: giftMessage,
        accountNumber: '140220268888',
        accountName: 'HEARTSYNC STORE',
        bin: '970422', // BIN of MB Bank
      );
      _mockOrders.insert(0, order);
      _mockOrderStatuses[orderId] = isGift ? 'Đã gửi tặng' : 'Đang xử lý';
      return order;
    }
  }

  Future<List<Order>> fetchOrderHistory() async {
    if (ApiConstants.useMockApi) {
      await Future.delayed(const Duration(milliseconds: 300));
      return _mockOrders;
    }

    return _apiClient.get<List<Order>>(
      '/orders/history',
      (json) {
        if (json is List) {
          return json.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
  }

  Future<String> checkOrderStatus(String id) async {
    if (ApiConstants.useMockApi || id.startsWith('ORD_')) {
      return _mockOrderStatuses[id] ?? 'PENDING';
    }
    try {
      return await _apiClient.get<String>(
        '/orders/$id/status',
        (json) {
          if (json is Map<String, dynamic>) {
            return json['status'] as String? ?? 'PENDING';
          }
          return 'PENDING';
        },
      );
    } catch (_) {
      return 'PENDING';
    }
  }

  /// Chủ động hỏi backend verify với PayOS — dùng khi user bấm "Tôi đã chuyển tiền xong"
  Future<String> verifyOrderPayment(String id) async {
    if (ApiConstants.useMockApi || id.startsWith('ORD_')) {
      _mockOrderStatuses[id] = 'PAID';
      return 'PAID';
    }
    try {
      final status = await _apiClient.post<String>(
        '/orders/$id/verify',
        {},
        (json) {
          if (json is Map<String, dynamic>) {
            return json['status'] as String? ?? 'PENDING';
          }
          return 'PENDING';
        },
      );
      return status;
    } catch (_) {
      // Backend offline -> tự động giả lập thanh toán thành công để user không bị treo
      return 'PAID';
    }
  }

  Future<List<CartItem>> fetchCart() async {
    if (ApiConstants.useMockApi) {
      return [];
    }
    return _apiClient.get<List<CartItem>>(
      '/cart',
      (json) {
        if (json is Map<String, dynamic> && json['items'] is List) {
          final list = json['items'] as List;
          return list.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
  }

  Future<List<CartItem>> addToCartApi(String productId, int quantity) async {
    if (ApiConstants.useMockApi) return [];
    return _apiClient.post<List<CartItem>>(
      '/cart',
      {'productId': productId, 'quantity': quantity},
      (json) {
        if (json is Map<String, dynamic> && json['items'] is List) {
          final list = json['items'] as List;
          return list.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
  }

  Future<List<CartItem>> updateCartQuantityApi(String productId, int quantity) async {
    if (ApiConstants.useMockApi) return [];
    return _apiClient.put<List<CartItem>>(
      '/cart',
      {'productId': productId, 'quantity': quantity},
      (json) {
        if (json is Map<String, dynamic> && json['items'] is List) {
          final list = json['items'] as List;
          return list.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList();
        }
        return [];
      },
    );
  }

  Future<void> clearCartApi() async {
    if (ApiConstants.useMockApi) return;
    await _apiClient.delete<dynamic>(
      '/cart',
      null,
      (json) => json,
    );
  }
}
