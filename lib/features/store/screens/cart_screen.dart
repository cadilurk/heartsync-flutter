import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../providers/store_provider.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Set<String> _selectedProductIds = {};

  @override
  void initState() {
    super.initState();
    // Khởi tạo tự động tích chọn tất cả sản phẩm hiện có trong giỏ hàng
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<StoreProvider>();
      setState(() {
        _selectedProductIds.addAll(provider.cartItems.map((item) => item.product.id));
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoreProvider>();
    final cartItems = provider.cartItems;

    // Lọc danh sách các sản phẩm đang được tích chọn
    final selectedItems = cartItems.where((item) => _selectedProductIds.contains(item.product.id)).toList();
    final selectedTotalAmount = selectedItems.fold(0.0, (sum, item) => sum + item.totalPrice);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Giỏ Hàng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.active))
          : cartItems.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.shopping_basket_outlined, size: 80, color: AppColors.subtitle),
                      const SizedBox(height: 16),
                      const Text(
                        'Giỏ hàng của bạn đang trống',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.subtitle),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: 200,
                        child: ElevatedButton(
                          onPressed: () => context.pop(),
                          child: const Text('Tiếp tục mua sắm'),
                        ),
                      ),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Cart Items List
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: cartItems.length,
                        itemBuilder: (context, index) {
                          final item = cartItems[index];
                          final isChecked = _selectedProductIds.contains(item.product.id);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 0,
                            color: AppColors.card,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                              child: Row(
                                children: [
                                  // Circular Checkbox to select item
                                  Checkbox(
                                    activeColor: AppColors.active,
                                    shape: const CircleBorder(),
                                    value: isChecked,
                                    onChanged: (val) {
                                      setState(() {
                                        if (val == true) {
                                          _selectedProductIds.add(item.product.id);
                                        } else {
                                          _selectedProductIds.remove(item.product.id);
                                        }
                                      });
                                    },
                                  ),
                                  // Product Image
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      item.product.imageUrl,
                                      width: 64,
                                      height: 64,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => const SizedBox(
                                        width: 64,
                                        height: 64,
                                        child: Icon(Icons.broken_image),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  // Title, Price
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.product.name,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${item.product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{3})(?=\d)'), (Match m) => '${m[1]}.')}đ',
                                          style: const TextStyle(
                                            color: AppColors.active,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Quantity controllers
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: AppColors.subtitle, size: 22),
                                        onPressed: () => provider.updateCartQuantity(
                                          item.product.id,
                                          item.quantity - 1,
                                        ),
                                      ),
                                      Text(
                                        '${item.quantity}',
                                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.add_circle_outline, color: AppColors.active, size: 22),
                                        onPressed: () => provider.updateCartQuantity(
                                          item.product.id,
                                          item.quantity + 1,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                    // Billing Panel and Checkout Button
                    Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 10,
                            offset: Offset(0, -4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Total bill
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Đã chọn (${selectedItems.length} món):',
                                style: const TextStyle(fontSize: 14, color: AppColors.subtitle),
                              ),
                              Text(
                                '${selectedTotalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{3})(?=\d)'), (Match m) => '${m[1]}.')}đ',
                                style: const TextStyle(
                                  color: AppColors.active,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // Checkout Button
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.active,
                              minimumSize: const Size.fromHeight(52),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            onPressed: selectedItems.isEmpty
                                ? null
                                : () {
                                    context.push('/checkout', extra: selectedItems);
                                  },
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.shopping_cart_checkout_outlined, color: Colors.white),
                                SizedBox(width: 8),
                                Text(
                                  'Mua Ngay',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }
}
