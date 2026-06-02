import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../../../../app/theme.dart';
import '../../../models/order.dart';
import '../../../providers/store_provider.dart';
import '../checkout_utils.dart';

/// Dialog hiển thị mã QR thật từ PayOS và polling trạng thái đơn hàng.
/// Khi PayOS webhook cập nhật trạng thái → dialog tự động đóng và gọi [onSuccess].
class RealPaymentDialog extends StatefulWidget {
  final Order order;
  final StoreProvider provider;
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const RealPaymentDialog({
    super.key,
    required this.order,
    required this.provider,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  State<RealPaymentDialog> createState() => _RealPaymentDialogState();
}

class _RealPaymentDialogState extends State<RealPaymentDialog> {
  Timer? _timer;
  bool _isVerifying = false;
  String _message = 'Đang kiểm tra biến động số dư tài khoản nhận...';

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      if (!mounted) return;
      final status = await widget.provider.checkOrderStatus(widget.order.id);
      if (status == 'PAID' ||
          status == 'Đã thanh toán' ||
          status == 'Đã gửi tặng') {
        _timer?.cancel();
        if (mounted) widget.onSuccess();
      }
    });
  }

  Future<void> _onConfirmTransferred() async {
    if (_isVerifying) return;
    setState(() {
      _isVerifying = true;
      _message = 'Đang xác nhận giao dịch với PayOS...';
    });

    try {
      final status = await widget.provider.verifyOrderPayment(widget.order.id);
      if (!mounted) return;

      if (status == 'PAID' ||
          status == 'Đã thanh toán' ||
          status == 'Đã gửi tặng') {
        _timer?.cancel();
        widget.onSuccess();
      } else {
        // PayOS chưa nhận được tiền
        setState(() {
          _isVerifying = false;
          _message = 'Đang kiểm tra biến động số dư tài khoản nhận...';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'PayOS chưa ghi nhận giao dịch. Vui lòng chờ thêm hoặc kiểm tra lại nội dung chuyển khoản.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _message = 'Đang kiểm tra biến động số dư tài khoản nhận...';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi kết nối: $e'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã sao chép $label!'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderCodeStr =
        'Heartsync ${widget.order.orderCode ?? widget.order.id.replaceAll('ORD_', '')}';
    final amountStr = widget.order.totalAmount.toStringAsFixed(0);
    final qrFallbackUrl = 'https://img.vietqr.io/image/MB-140220268888-compact2.png'
        '?amount=$amountStr'
        '&addInfo=${Uri.encodeComponent(orderCodeStr)}'
        '&accountName=${Uri.encodeComponent('HEARTSYNC STORE')}';

    return PopScope(
      canPop: false,
      child: Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Header ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Quét Mã Chuyển Khoản',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: widget.onCancel,
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),

                // ── QR Code (thật từ PayOS hoặc fallback VietQR) ────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: widget.order.qrCode != null
                      ? Column(
                          children: [
                            QrImageView(
                              data: widget.order.qrCode!,
                              version: QrVersions.auto,
                              size: 230,
                              eyeStyle: const QrEyeStyle(
                                eyeShape: QrEyeShape.square,
                                color: Color(0xFF1A1A2E),
                              ),
                              dataModuleStyle: const QrDataModuleStyle(
                                dataModuleShape: QrDataModuleShape.square,
                                color: Color(0xFF1A1A2E),
                              ),
                              errorStateBuilder: (ctx, err) => const SizedBox(
                                width: 230,
                                height: 230,
                                child: Center(
                                  child: Text(
                                    'Không thể tải mã QR',
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.verified_rounded,
                                    size: 14, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  'Mã QR thật từ PayOS',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                      // Fallback: ảnh VietQR tĩnh nếu không có qrCode
                      : Image.network(
                          qrFallbackUrl,
                          width: 230,
                          height: 230,
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const SizedBox(
                              width: 230,
                              height: 230,
                              child: Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.active),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 230,
                            height: 230,
                            color: AppColors.bg,
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined,
                                  size: 48, color: Colors.grey),
                            ),
                          ),
                        ),
                ),
                const SizedBox(height: 16),

                // ── Thông tin chuyển khoản thật từ PayOS ────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF5F7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFFCE7F3)),
                  ),
                  child: Column(
                    children: [
                      _buildInfoRow(
                        'Ngân hàng:',
                        bankNameFromBin(widget.order.bin),
                      ),
                      const SizedBox(height: 8),
                      _buildCopyableRow(
                        'Số tài khoản:',
                        widget.order.accountNumber ?? '—',
                        'số tài khoản',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Chủ tài khoản:',
                        widget.order.accountName ?? '—',
                      ),
                      const SizedBox(height: 8),
                      _buildInfoRow(
                        'Số tiền:',
                        formatVND(widget.order.totalAmount),
                        isBoldValue: true,
                      ),
                      const SizedBox(height: 8),
                      _buildCopyableRow(
                        'Nội dung chuyển:',
                        orderCodeStr,
                        'nội dung chuyển',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // ── Trạng thái polling ───────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: AppColors.active,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _message,
                        style: const TextStyle(
                          color: AppColors.subtitle,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // ── Nút xác nhận đã chuyển tiền ─────────────────────────
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.active,
                    elevation: 0,
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: _isVerifying ? null : _onConfirmTransferred,
                  child: _isVerifying
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          'Tôi đã chuyển tiền xong ✓',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                ),
                const SizedBox(height: 8),

                // ── Nút hủy ─────────────────────────────────────────────
                TextButton(
                  style: TextButton.styleFrom(
                    minimumSize: const Size.fromHeight(40),
                  ),
                  onPressed: _isVerifying ? null : widget.onCancel,
                  child: const Text(
                    'Hủy bỏ & Quay lại',
                    style: TextStyle(
                        color: Colors.black45, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helper rows ──────────────────────────────────────────────────────────

  Widget _buildInfoRow(String label, String value,
      {bool isBoldValue = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: const TextStyle(color: AppColors.subtitle, fontSize: 12)),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isBoldValue ? FontWeight.w900 : FontWeight.bold,
              color: isBoldValue ? AppColors.active : AppColors.title,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCopyableRow(String label, String value, String copyLabel) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: 110,
          child: Text(label,
              style: const TextStyle(color: AppColors.subtitle, fontSize: 12)),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.title),
          ),
        ),
        GestureDetector(
          onTap: () => _copyToClipboard(value, copyLabel),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.copy_rounded, size: 10, color: AppColors.active),
                SizedBox(width: 4),
                Text(
                  'Sao chép',
                  style: TextStyle(
                      fontSize: 9,
                      color: AppColors.active,
                      fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
