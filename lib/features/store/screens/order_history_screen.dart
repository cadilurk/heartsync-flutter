import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../app/theme.dart';
import '../models/order.dart';
import '../providers/store_provider.dart';
import 'checkout/widgets/real_payment_dialog.dart';

class OrderHistoryScreen extends StatefulWidget {
  const OrderHistoryScreen({super.key});

  @override
  State<OrderHistoryScreen> createState() => _OrderHistoryScreenState();
}

class _OrderHistoryScreenState extends State<OrderHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StoreProvider>().loadOrderHistory();
    });
  }

  // ── Mở lại RealPaymentDialog để hoàn tất thanh toán ──────────────────────
  void _showRetryPayment(Order order) {
    final provider = context.read<StoreProvider>();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => RealPaymentDialog(
        order: order,
        provider: provider,
        onSuccess: () {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('🎉 Thanh toán thành công! Cảm ơn bạn.'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 3),
            ),
          );
          provider.loadOrderHistory();
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  // ── Xác nhận và hủy đơn hàng PENDING ─────────────────────────────────────
  Future<void> _confirmCancelOrder(Order order) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Hủy đơn hàng?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Bạn có chắc muốn hủy đơn ${order.id}?\nHành động này không thể hoàn tác.',
          style: const TextStyle(color: AppColors.subtitle, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Giữ lại',
              style: TextStyle(color: AppColors.subtitle, fontWeight: FontWeight.bold),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Hủy đơn', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final provider = context.read<StoreProvider>();
      final success = await provider.cancelOrder(order.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
                ? '✅ Đơn hàng đã được hủy thành công.'
                : '❌ Không thể hủy đơn. Vui lòng thử lại.',
          ),
          backgroundColor: success ? Colors.green : Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ── Helper: màu sắc theo trạng thái ──────────────────────────────────────
  Color _statusBgColor(String status) {
    switch (status) {
      case 'PENDING':
        return const Color(0xFFFFF3E0);
      case 'CANCELLED':
        return const Color(0xFFFFEBEE);
      case 'Đã thanh toán':
      case 'Đã gửi tặng':
        return const Color(0xFFE8F5E9);
      default:
        return const Color(0xFFE3F2FD);
    }
  }

  Color _statusTextColor(String status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange[800]!;
      case 'CANCELLED':
        return Colors.red[700]!;
      case 'Đã thanh toán':
      case 'Đã gửi tặng':
        return Colors.green[700]!;
      default:
        return Colors.blue[700]!;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'PENDING':
        return '⏳ Chờ thanh toán';
      case 'CANCELLED':
        return '❌ Đã hủy';
      case 'Đã thanh toán':
        return '✅ Đã thanh toán';
      case 'Đã gửi tặng':
        return '🎁 Đã gửi tặng';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoreProvider>();
    final orders = provider.orders;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lịch Sử Mua Quà',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: provider.isLoading && orders.isEmpty
          ? const Center(child: CircularProgressIndicator(color: AppColors.active))
          : orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.card_giftcard, size: 80, color: AppColors.subtitle),
                      const SizedBox(height: 16),
                      const Text(
                        'Bạn chưa mua món quà nào.',
                        style: TextStyle(fontSize: 16, color: AppColors.subtitle),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final isPending = order.status == 'PENDING';
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        // Viền cam nổi bật cho đơn PENDING
                        side: isPending
                            ? const BorderSide(color: Colors.orange, width: 1.5)
                            : BorderSide.none,
                      ),
                      color: Colors.white,
                      elevation: 0,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          // ── Banner PENDING ────────────────────────────
                          if (isPending)
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              color: const Color(0xFFFFF8E1),
                              child: Row(
                                children: [
                                  const Text('⏳', style: TextStyle(fontSize: 16)),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Đơn hàng chưa được thanh toán. Bấm "Thanh toán lại" để tiếp tục.',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.orange[800],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // ── Header: Mã đơn & Trạng thái ─────────
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        order.id,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 13),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _statusBgColor(order.status),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Text(
                                        _statusLabel(order.status),
                                        style: TextStyle(
                                          color: _statusTextColor(order.status),
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),

                                // ── Danh sách sản phẩm ────────────────────
                                ...order.items.map((item) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 4),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              '${item.product.name} x${item.quantity}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(fontSize: 14),
                                            ),
                                          ),
                                          Text(
                                            '${item.totalPrice.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}đ',
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold, fontSize: 14),
                                          ),
                                        ],
                                      ),
                                    )),

                                const Divider(height: 24),

                                // ── Lời nhắn quà tặng ────────────────────
                                if (order.giftMessage != null &&
                                    order.giftMessage!.isNotEmpty) ...[
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: AppColors.bg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      '💬 Lời nhắn: "${order.giftMessage}"',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontStyle: FontStyle.italic,
                                        color: AppColors.active,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                ],

                                // ── Footer: Ngày & Tổng tiền ─────────────
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Ngày mua: ${order.orderDate.day}/${order.orderDate.month}/${order.orderDate.year}',
                                      style: const TextStyle(
                                          color: AppColors.subtitle, fontSize: 12),
                                    ),
                                    Row(
                                      children: [
                                        const Text('Tổng cộng: ',
                                            style: TextStyle(fontSize: 13)),
                                        Text(
                                          '${order.totalAmount.toStringAsFixed(0).replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}đ',
                                          style: const TextStyle(
                                            color: AppColors.active,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),

                                // ── Action Buttons cho đơn PENDING ───────
                                if (isPending) ...[
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      // Nút Hủy đơn
                                      Expanded(
                                        child: OutlinedButton.icon(
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red[700],
                                            side: BorderSide(color: Colors.red[700]!),
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                          ),
                                          icon: const Icon(Icons.cancel_outlined, size: 16),
                                          label: const Text(
                                            'Hủy đơn',
                                            style: TextStyle(
                                                fontSize: 13, fontWeight: FontWeight.bold),
                                          ),
                                          onPressed: () => _confirmCancelOrder(order),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      // Nút Thanh toán lại
                                      Expanded(
                                        flex: 2,
                                        child: ElevatedButton.icon(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: AppColors.active,
                                            foregroundColor: Colors.white,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10)),
                                            padding: const EdgeInsets.symmetric(vertical: 10),
                                          ),
                                          icon: const Icon(Icons.qr_code_scanner, size: 16),
                                          label: const Text(
                                            'Thanh toán lại',
                                            style: TextStyle(
                                                fontSize: 13, fontWeight: FontWeight.bold),
                                          ),
                                          onPressed: () => _showRetryPayment(order),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
