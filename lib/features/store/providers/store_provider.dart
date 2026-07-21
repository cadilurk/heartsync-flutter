import 'package:flutter/foundation.dart';
import '../../../core/network/api_exception.dart';
import '../models/cart_item.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/store_service.dart';

class StoreProvider extends ChangeNotifier {
  final StoreService _storeService;

  List<Product> products = [];
  List<Product> filteredProducts = [];
  List<CartItem> cartItems = [];
  List<Order> orders = [];

  bool isLoading = false;
  String? errorMessage;

  String selectedCategory = 'Tất cả';
  String searchQuery = '';

  StoreProvider({required StoreService storeService}) : _storeService = storeService;

  List<String> get categories => ['Tất cả', 'Quà tặng', 'Hẹn hò', 'Vật phẩm số'];

  double get cartTotalAmount => cartItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  int get cartTotalQuantity => cartItems.fold(0, (sum, item) => sum + item.quantity);

  // --- Catalog ---
  Future<void> loadProducts() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      products = await _storeService.fetchProducts();
      try {
        cartItems = await _storeService.fetchCart();
      } catch (_) {
        // Cart API lỗi không sao, tiếp tục với cart rỗng
      }
      _filterProducts();
    } on ApiException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = 'Không thể tải danh sách sản phẩm.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(String category) {
    selectedCategory = category;
    _filterProducts();
    notifyListeners();
  }

  void setSearchQuery(String query) {
    searchQuery = query;
    _filterProducts();
    notifyListeners();
  }

  void _filterProducts() {
    filteredProducts = products.where((product) {
      final matchesCategory = selectedCategory == 'Tất cả' || product.category == selectedCategory;
      final matchesSearch = product.name.toLowerCase().contains(searchQuery.toLowerCase()) ||
          product.description.toLowerCase().contains(searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  // --- Cart ---
  Future<void> addToCart(Product product, {int quantity = 1}) async {
    final index = cartItems.indexWhere((item) => item.product.id == product.id);
    if (index >= 0) {
      final oldItem = cartItems[index];
      cartItems[index] = oldItem.copyWith(quantity: oldItem.quantity + quantity);
    } else {
      cartItems.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();

    try {
      final updated = await _storeService.addToCartApi(product.id, quantity);
      if (updated.isNotEmpty) {
        cartItems = updated;
        notifyListeners();
      }
      // Nếu API trả rỗng list (backend chưa có /cart) → giữ local cart
    } catch (_) {
      // Backend offline → giữ local cart, không rollback
    }
  }

  Future<void> updateCartQuantity(String productId, int quantity) async {
    final index = cartItems.indexWhere((item) => item.product.id == productId);
    if (index < 0) return;

    if (quantity <= 0) {
      cartItems.removeAt(index);
      notifyListeners();

      try {
        await _storeService.updateCartQuantityApi(productId, 0);
      } catch (_) {
        // Backend offline → giữ local state
      }
      return;
    }

    cartItems[index] = cartItems[index].copyWith(quantity: quantity);
    notifyListeners();

    try {
      await _storeService.updateCartQuantityApi(productId, quantity);
    } catch (_) {
      // Backend offline → giữ local state
    }
  }

  Future<void> removeFromCart(String productId) async {
    final index = cartItems.indexWhere((item) => item.product.id == productId);
    if (index < 0) return;
    cartItems.removeAt(index);
    notifyListeners();

    try {
      await _storeService.updateCartQuantityApi(productId, 0);
    } catch (_) {
      // Backend offline → giữ local state
    }
  }

  Future<void> clearCart() async {
    cartItems.clear();
    notifyListeners();

    try {
      await _storeService.clearCartApi();
    } catch (_) {
      // Backend offline → giữ local state (cart đã xóa local rồi)
    }
  }

  // --- Checkout ---
  Future<Order?> checkout({
    required List<CartItem> items,
    required bool isGift,
    String? giftMessage,
    String? shippingName,
    String? shippingPhone,
    String? shippingAddress,
  }) async {
    if (items.isEmpty) return null;
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      final order = await _storeService.checkout(
        items: items,
        isGift: isGift,
        giftMessage: giftMessage,
        shippingName: shippingName,
        shippingPhone: shippingPhone,
        shippingAddress: shippingAddress,
      );

      // Loại bỏ các sản phẩm đã mua khỏi giỏ hàng cục bộ
      final checkedOutProductIds = items.map((e) => e.product.id).toSet();
      cartItems.removeWhere((item) => checkedOutProductIds.contains(item.product.id));

      orders.insert(0, order);
      return order;
    } on ApiException catch (e) {
      errorMessage = e.message;
      rethrow;
    } catch (e) {
      errorMessage = 'Thanh toán thất bại. Vui lòng thử lại.';
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // --- Orders ---
  Future<void> loadOrderHistory() async {
    try {
      isLoading = true;
      errorMessage = null;
      notifyListeners();

      orders = await _storeService.fetchOrderHistory();
    } on ApiException catch (e) {
      errorMessage = e.message;
    } catch (e) {
      errorMessage = 'Không thể tải lịch sử đơn hàng.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> checkOrderStatus(String orderId) async {
    try {
      return await _storeService.checkOrderStatus(orderId);
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi check đơn hàng: $e');
      }
      return null;
    }
  }

  /// Chủ động verify thanh toán với PayOS — gọi khi user bấm "Tôi đã chuyển tiền xong"
  Future<String?> verifyOrderPayment(String orderId) async {
    try {
      return await _storeService.verifyOrderPayment(orderId);
    } catch (e) {
      if (kDebugMode) {
        print('Lỗi verify đơn hàng: $e');
      }
      return null;
    }
  }

  /// Hủy đơn hàng PENDING — gọi khi user bấm "Hủy đơn"
  Future<bool> cancelOrder(String orderId) async {
    try {
      final status = await _storeService.cancelOrder(orderId);
      if (status == 'CANCELLED') {
        final index = orders.indexWhere((o) => o.id == orderId);
        if (index >= 0) {
          final old = orders[index];
          orders[index] = Order(
            id: old.id,
            items: old.items,
            totalAmount: old.totalAmount,
            orderDate: old.orderDate,
            isGift: old.isGift,
            status: 'CANCELLED',
            giftMessage: old.giftMessage,
            checkoutUrl: old.checkoutUrl,
            qrCode: old.qrCode,
            accountNumber: old.accountNumber,
            accountName: old.accountName,
            bin: old.bin,
            orderCode: old.orderCode,
            shippingName: old.shippingName,
            shippingPhone: old.shippingPhone,
            shippingAddress: old.shippingAddress,
          );
          notifyListeners();
        }
        return true;
      }
      return false;
    } catch (e) {
      if (kDebugMode) print('Lỗi hủy đơn hàng: $e');
      return false;
    }
  }
}
