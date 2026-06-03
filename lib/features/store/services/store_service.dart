import '../../../core/network/api_client.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/product.dart';

class StoreService {
  final ApiClient _apiClient;
  StoreService(this._apiClient);

  Future<List<Product>> fetchProducts() async {
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
      rethrow;
    }
  }

  Future<Product> fetchProductById(String id) async {
    try {
      return await _apiClient.get<Product>(
        '/products/$id',
        (json) => Product.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<Order> checkout({
    required List<CartItem> items,
    required bool isGift,
    String? giftMessage,
    String? shippingName,
    String? shippingPhone,
    String? shippingAddress,
  }) async {
    final body = {
      'items': items.map((item) => item.toJson()).toList(),
      'isGift': isGift,
      'giftMessage': giftMessage,
      'shippingName': shippingName,
      'shippingPhone': shippingPhone,
      'shippingAddress': shippingAddress,
    };

    try {
      return await _apiClient.post<Order>(
        '/orders',
        body,
        (json) => Order.fromJson(json as Map<String, dynamic>),
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Order>> fetchOrderHistory() async {
    try {
      return await _apiClient.get<List<Order>>(
        '/orders/history',
        (json) {
          if (json is List) {
            return json.map((e) => Order.fromJson(e as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<String> checkOrderStatus(String id) async {
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
    } catch (e) {
      rethrow;
    }
  }

  /// Chủ động hỏi backend verify với PayOS — dùng khi user bấm "Tôi đã chuyển tiền xong"
  Future<String> verifyOrderPayment(String id) async {
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
    } catch (e) {
      rethrow;
    }
  }

  /// Hủy đơn hàng đang PENDING — dùng khi user bấm "Hủy đơn"
  Future<String> cancelOrder(String id) async {
    try {
      return await _apiClient.post<String>(
        '/orders/$id/cancel',
        {},
        (json) {
          if (json is Map<String, dynamic>) {
            return json['status'] as String? ?? 'CANCELLED';
          }
          return 'CANCELLED';
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<CartItem>> fetchCart() async {
    try {
      return await _apiClient.get<List<CartItem>>(
        '/cart',
        (json) {
          if (json is Map<String, dynamic> && json['items'] is List) {
            final list = json['items'] as List;
            return list.map((e) => CartItem.fromJson(e as Map<String, dynamic>)).toList();
          }
          return [];
        },
      );
    } catch (e) {
      rethrow;
    }
  }

  Future<List<CartItem>> addToCartApi(String productId, int quantity) async {
    try {
      return await _apiClient.post<List<CartItem>>(
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
    } catch (e) {
      rethrow;
    }
  }

  Future<List<CartItem>> updateCartQuantityApi(String productId, int quantity) async {
    try {
      return await _apiClient.put<List<CartItem>>(
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
    } catch (e) {
      rethrow;
    }
  }

  Future<void> clearCartApi() async {
    try {
      await _apiClient.delete<dynamic>(
        '/cart',
        null,
        (json) => json,
      );
    } catch (e) {
      rethrow;
    }
  }
}
