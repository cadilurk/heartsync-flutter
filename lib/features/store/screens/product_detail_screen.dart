import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import '../providers/store_provider.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;

  const ProductDetailScreen({
    super.key,
    required this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  int _currentImageIndex = 0;

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoreProvider>();
    // Recommend other products (excluding current product)
    final recommended = provider.products.where((p) => p.id != widget.product.id).toList();

    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            // Scrollable Body
            SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 96), // Space for bottom floating bar
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image PageView with Indicator
                  Stack(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height * 0.38,
                        width: double.infinity,
                        child: PageView.builder(
                          itemCount: widget.product.images.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return Image.network(
                              widget.product.images[index],
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>  Container(
                                color: AppColors.bg,
                                child: Icon(Icons.broken_image, size: 64, color: AppColors.subtitle),
                              ),
                            );
                          },
                        ),
                      ),
                      // Slide Dot Indicators
                      if (widget.product.images.length > 1)
                        Positioned(
                          bottom: 32, // positioned slightly above the bottom sheet overlap
                          left: 0,
                          right: 0,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: List.generate(
                              widget.product.images.length,
                              (index) => Container(
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _currentImageIndex == index
                                      ? AppColors.active
                                      : Colors.white.withOpacity(0.6),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),

                  // Info & Description Container
                  Transform.translate(
                    offset: const Offset(0, -20),
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Category & Rating
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.bg,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        widget.product.category,
                                        style: const TextStyle(
                                          color: AppColors.title,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.star, color: Colors.amber, size: 20),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${widget.product.rating}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                // Title
                                Text(
                                  widget.product.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                const SizedBox(height: 8),

                                // Price & Stock
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${widget.product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}đ',
                                      style: const TextStyle(
                                        color: AppColors.active,
                                        fontSize: 22,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      widget.product.isDigital
                                          ? 'Vật phẩm số • Đã bán ${widget.product.soldCount}'
                                          : 'Còn lại: ${widget.product.inStock} • Đã bán ${widget.product.soldCount}',
                                      style: const TextStyle(
                                        color: AppColors.subtitle,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // Description
                                const Text(
                                  'Mô tả sản phẩm',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  widget.product.description,
                                  style: const TextStyle(
                                    color: AppColors.subtitle,
                                    fontSize: 14,
                                    height: 1.5,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const Divider(height: 32, thickness: 8, color: AppColors.bg),

                          // --- Reviews Section ---
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Khách hàng đánh giá',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      'Xem tất cả',
                                      style: TextStyle(color: AppColors.active, fontSize: 13, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                _buildReviewItem(
                                  coupleNames: 'Hùng & Lan',
                                  rating: 5.0,
                                  comment: 'Sản phẩm đóng gói rất cẩn thận, giao hàng siêu nhanh. Ly đôi sứ dày dặn và cực kỳ đáng yêu, partner của mình thích lắm!',
                                  timeAgo: '2 ngày trước',
                                ),
                                const Divider(height: 24),
                                _buildReviewItem(
                                  coupleNames: 'Phương & Khánh',
                                  rating: 4.8,
                                  comment: 'Voucher rất dễ sử dụng, tụi mình đã có một tối hẹn hò lãng mạn vô cùng ấm áp tại nhà hàng. Đánh giá 5 sao cho chất lượng dịch vụ.',
                                  timeAgo: '1 tuần trước',
                                ),
                              ],
                            ),
                          ),

                          const Divider(height: 40, thickness: 8, color: AppColors.bg),

                          // --- Recommendations Section ---
                          Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: Text(
                                    'Gợi ý sản phẩm khác',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                const SizedBox(height: 16),
                                SizedBox(
                                  height: 190,
                                  child: ListView.builder(
                                    scrollDirection: Axis.horizontal,
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                    itemCount: recommended.length,
                                    itemBuilder: (context, index) {
                                      final item = recommended[index];
                                      return GestureDetector(
                                        onTap: () {
                                          // Navigate to the selected product detail page
                                          context.push('/product-detail', extra: item);
                                        },
                                        child: Container(
                                          width: 140,
                                          margin: const EdgeInsets.only(right: 12),
                                          decoration: BoxDecoration(
                                            color: AppColors.card,
                                            borderRadius: BorderRadius.circular(16),
                                            border: Border.all(color: AppColors.border, width: 0.8),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              // Recommended Item Image
                                              Expanded(
                                                child: ClipRRect(
                                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                                  child: Image.network(
                                                    item.imageUrl,
                                                    width: double.infinity,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (_, __, ___) =>  Container(
                                                      color: AppColors.bg,
                                                      child: Icon(Icons.broken_image, size: 24),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                padding: const EdgeInsets.all(8),
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      item.name,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                                    ),
                                                    const SizedBox(height: 2),
                                                    Text(
                                                      '${item.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}đ',
                                                      style: const TextStyle(
                                                        color: AppColors.active,
                                                        fontSize: 12,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Floating Header (Back & Cart)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.4),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  CircleAvatar(
                    backgroundColor: Colors.black.withOpacity(0.4),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                          onPressed: () => context.push('/cart'),
                        ),
                        if (provider.cartTotalQuantity > 0)
                          Positioned(
                            right: 2,
                            top: 2,
                            child: Container(
                              padding: const EdgeInsets.all(3),
                              decoration: const BoxDecoration(
                                color: AppColors.active,
                                shape: BoxShape.circle,
                              ),
                              constraints: const BoxConstraints(
                                minWidth: 14,
                                minHeight: 14,
                              ),
                              child: Text(
                                '${provider.cartTotalQuantity}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom Fixed Action Bar
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    // Add to Cart Button
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.active, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        padding: const EdgeInsets.all(12),
                        minimumSize: const Size(60, 52),
                      ),
                      onPressed: () {
                        provider.addToCart(widget.product);
                        ScaffoldMessenger.of(context).hideCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Đã thêm "${widget.product.name}" vào giỏ hàng!'),
                            duration: const Duration(seconds: 3),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: const Icon(
                        Icons.add_shopping_cart,
                        color: AppColors.active,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Gift to Partner Button
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.active,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          minimumSize: const Size.fromHeight(52),
                          elevation: 0,
                        ),
                        onPressed: () {
                          context.push(
                            '/checkout',
                            extra: [CartItem(product: widget.product, quantity: 1)],
                          );
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.card_giftcard, size: 20, color: Colors.white),
                            SizedBox(width: 8),
                            Text(
                              'Mua Ngay',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem({
    required String coupleNames,
    required double rating,
    required String comment,
    required String timeAgo,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 16,
                  backgroundColor: Color(0xFFFFF0F5),
                  child: Icon(Icons.favorite, color: AppColors.active, size: 16),
                ),
                const SizedBox(width: 8),
                Text(
                  coupleNames,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            Text(
              timeAgo,
              style: const TextStyle(color: AppColors.subtitle, fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: List.generate(5, (index) {
            final starVal = index + 1;
            return Icon(
              Icons.star,
              color: starVal <= rating ? Colors.amber : Colors.grey[350],
              size: 16,
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          comment,
          style: const TextStyle(color: AppColors.subtitle, fontSize: 13, height: 1.4),
        ),
      ],
    );
  }
}
