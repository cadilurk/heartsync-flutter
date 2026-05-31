import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/theme.dart';
import '../../models/cart_item.dart';
import '../../models/order.dart';
import '../../providers/store_provider.dart';
import 'checkout_utils.dart';
import 'widgets/real_payment_dialog.dart';
import 'widgets/simulated_payment_dialog.dart';

/// Màn hình thanh toán — hiển thị danh sách sản phẩm, form giao hàng,
/// chọn phương thức thanh toán và kích hoạt dialog QR / App-to-App.
class CheckoutScreen extends StatefulWidget {
  final List<CartItem> items;

  const CheckoutScreen({
    super.key,
    required this.items,
  });

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _messageController = TextEditingController();

  bool _isGift = false;
  bool _isCheckingOut = false;
  bool _saveInfoForNextTime = true;

  /// 'app_to_app' hoặc 'manual'
  String _paymentMethod = 'app_to_app';

  /// 'auto', 'vcb', 'mb', 'tcb', ...
  String _selectedBankAppId = 'auto';

  final _storage = const FlutterSecureStorage();

  @override
  void initState() {
    super.initState();
    _loadShippingInfo();
  }

  Future<void> _loadShippingInfo() async {
    try {
      final saveFlagStr = await _storage.read(key: 'save_shipping_info_flag');
      final name = await _storage.read(key: 'shipping_name');
      final phone = await _storage.read(key: 'shipping_phone');
      final address = await _storage.read(key: 'shipping_address');

      if (mounted) {
        setState(() {
          if (saveFlagStr != null) {
            _saveInfoForNextTime = saveFlagStr == 'true';
          }
          if (_saveInfoForNextTime) {
            if (name != null) _nameController.text = name;
            if (phone != null) _phoneController.text = phone;
            if (address != null) _addressController.text = address;
          }
        });
      }
    } catch (e) {
      debugPrint('Lỗi tải thông tin giao hàng: $e');
    }
  }

  Future<void> _saveShippingInfo() async {
    try {
      await _storage.write(
        key: 'save_shipping_info_flag',
        value: _saveInfoForNextTime.toString(),
      );
      if (_saveInfoForNextTime) {
        await _storage.write(key: 'shipping_name', value: _nameController.text.trim());
        await _storage.write(key: 'shipping_phone', value: _phoneController.text.trim());
        await _storage.write(key: 'shipping_address', value: _addressController.text.trim());
      } else {
        await _storage.delete(key: 'shipping_name');
        await _storage.delete(key: 'shipping_phone');
        await _storage.delete(key: 'shipping_address');
      }
    } catch (e) {
      debugPrint('Lỗi lưu thông tin giao hàng: $e');
    }
  }

  // ── Getters tính giá ────────────────────────────────────────────────────

  double get _subtotal =>
      widget.items.fold(0.0, (sum, item) => sum + item.totalPrice);
  double get _shippingFee => 0.0; // Miễn phí vận chuyển khi test
  double get _totalAmount => _subtotal + _shippingFee;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  // ── Luồng thanh toán ────────────────────────────────────────────────────

  Future<void> _confirmCheckout(StoreProvider provider) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCheckingOut = true);
    await _saveShippingInfo();

    try {
      final order = await provider.checkout(
        items: widget.items,
        isGift: _isGift,
        giftMessage: _isGift ? _messageController.text.trim() : null,
      );

      if (order != null && mounted) {
        final checkoutUrl = order.checkoutUrl;
        final isMock =
            checkoutUrl == null || checkoutUrl == 'mock-payment-url';

        if (_paymentMethod == 'app_to_app') {
          if (!isMock) {
            final uri = Uri.parse(checkoutUrl);
            try {
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                await launchUrl(uri, mode: LaunchMode.platformDefault);
              }
              if (mounted) _showRealPaymentDialog(provider, order);
            } catch (e) {
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                    'Không thể mở cổng thanh toán: $e. Vui lòng thanh toán thủ công.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ));
              }
            }
          } else {
            if (mounted) _showSimulatedPaymentDialog(provider, order);
          }
        } else {
          // manual → luôn hiện QR dialog (thật hoặc mock)
          if (mounted) _showRealPaymentDialog(provider, order);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(
            'Đặt hàng thất bại: ${provider.errorMessage ?? e.toString()}',
          ),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isCheckingOut = false);
    }
  }

  void _showRealPaymentDialog(StoreProvider provider, Order order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => RealPaymentDialog(
        order: order,
        provider: provider,
        onSuccess: () {
          Navigator.pop(dialogContext);
          _showSuccessDialog(order);
        },
        onCancel: () => Navigator.pop(dialogContext),
      ),
    );
  }

  void _showSimulatedPaymentDialog(StoreProvider provider, Order order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => SimulatedPaymentDialog(
        onSuccess: () {
          Navigator.pop(dialogContext);
          _showSuccessDialog(order);
        },
        onCancel: () => Navigator.pop(dialogContext),
      ),
    );
  }

  void _showSuccessDialog(Order order) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.favorite, color: AppColors.active, size: 64),
              const SizedBox(height: 16),
              const Text(
                'Thanh Toán Thành Công!',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _isGift
                    ? 'Lời nhắn ngọt ngào của bạn đã được ghi nhận. Cửa hàng sẽ chuyển quà tới partner của bạn ngay sau khi xác minh chuyển khoản.'
                    : 'Yêu cầu đặt mua đã gửi thành công. Hệ thống đang tiến hành duyệt thanh toán của bạn.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    color: AppColors.subtitle, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.active,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  Navigator.pop(dialogContext);
                  context.pop();
                  if (context.canPop()) context.pop();
                },
                child: const Text(
                  'Tuyệt vời',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<StoreProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Thanh Toán',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildItemsSection(),
                const Divider(thickness: 8, color: AppColors.bg),
                _buildShippingSection(),
                const Divider(thickness: 8, color: AppColors.bg),
                _buildGiftSection(),
                const Divider(thickness: 8, color: AppColors.bg),
                _buildPaymentMethodSection(),
                const Divider(thickness: 8, color: AppColors.bg),
                _buildBillingSection(),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomBar(provider),
    );
  }

  // ── Section builders ────────────────────────────────────────────────────

  /// 1. Danh sách sản phẩm thanh toán
  Widget _buildItemsSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sản phẩm thanh toán:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.items.length,
            itemBuilder: (context, index) {
              final item = widget.items[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        item.product.imageUrl,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(
                          width: 50,
                          height: 50,
                          child: Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Số lượng: ${item.quantity}',
                            style: const TextStyle(
                                color: AppColors.subtitle, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      formatVND(item.totalPrice),
                      style: const TextStyle(
                          fontWeight: FontWeight.w900, color: AppColors.active),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// 2. Form thông tin giao hàng
  Widget _buildShippingSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Thông tin giao hàng:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: 'Họ và tên người nhận',
              prefixIcon:
                  const Icon(Icons.person_outline, color: AppColors.active),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Vui lòng nhập họ tên người nhận'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'Số điện thoại liên lạc',
              prefixIcon:
                  const Icon(Icons.phone_outlined, color: AppColors.active),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Vui lòng nhập số điện thoại'
                : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _addressController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Địa chỉ nhận hàng chi tiết',
              prefixIcon: const Icon(Icons.location_on_outlined,
                  color: AppColors.active),
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
            validator: (value) => (value == null || value.trim().isEmpty)
                ? 'Vui lòng nhập địa chỉ nhận hàng'
                : null,
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () {
              setState(() => _saveInfoForNextTime = !_saveInfoForNextTime);
            },
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: _saveInfoForNextTime,
                    activeColor: AppColors.active,
                    onChanged: (val) {
                      if (val != null) {
                        setState(() => _saveInfoForNextTime = val);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Lưu thông tin giao hàng cho lần sau',
                  style: TextStyle(fontSize: 13, color: AppColors.subtitle),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Chọn hình thức nhận & lời nhắn tặng quà
  Widget _buildGiftSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hình thức nhận:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Mua dùng chung')),
                  selected: !_isGift,
                  selectedColor: AppColors.active,
                  labelStyle: TextStyle(
                    color: !_isGift ? Colors.white : AppColors.subtitle,
                    fontWeight: FontWeight.bold,
                  ),
                  showCheckmark: false,
                  onSelected: (val) {
                    if (val) setState(() => _isGift = false);
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Tặng Partner')),
                  selected: _isGift,
                  selectedColor: AppColors.active,
                  labelStyle: TextStyle(
                    color: _isGift ? Colors.white : AppColors.subtitle,
                    fontWeight: FontWeight.bold,
                  ),
                  showCheckmark: false,
                  onSelected: (val) {
                    if (val) setState(() => _isGift = true);
                  },
                ),
              ),
            ],
          ),
          if (_isGift) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _messageController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Lời chúc ngọt ngào gửi partner của bạn...',
                contentPadding: const EdgeInsets.all(12),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  /// 4. Chọn phương thức thanh toán
  Widget _buildPaymentMethodSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Phương thức thanh toán:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Mở App chuyển khoản')),
                  selected: _paymentMethod == 'app_to_app',
                  selectedColor: AppColors.active,
                  labelStyle: TextStyle(
                    color: _paymentMethod == 'app_to_app'
                        ? Colors.white
                        : AppColors.subtitle,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  showCheckmark: false,
                  onSelected: (val) {
                    if (val) setState(() => _paymentMethod = 'app_to_app');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ChoiceChip(
                  label: const Center(child: Text('Quét mã QR thủ công')),
                  selected: _paymentMethod == 'manual',
                  selectedColor: AppColors.active,
                  labelStyle: TextStyle(
                    color: _paymentMethod == 'manual'
                        ? Colors.white
                        : AppColors.subtitle,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  showCheckmark: false,
                  onSelected: (val) {
                    if (val) setState(() => _paymentMethod = 'manual');
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _paymentMethod == 'app_to_app'
              ? _buildAppToAppCard()
              : _buildManualQrCard(),
        ],
      ),
    );
  }

  Widget _buildAppToAppCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCE7F3), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chọn ứng dụng ngân hàng trong máy:',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: AppColors.title),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedBankAppId,
                isExpanded: true,
                items: kVietnameseBanks.map((bank) {
                  return DropdownMenuItem<String>(
                    value: bank['id'],
                    child: Text(bank['name']!,
                        style: const TextStyle(fontSize: 14)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedBankAppId = val);
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Lưu ý: Hệ thống sẽ tự động mở ứng dụng ngân hàng đã chọn và điền sẵn số tài khoản nhận, số tiền & nội dung chuyển khoản.',
            style: TextStyle(
              color: AppColors.subtitle,
              fontSize: 11,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualQrCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F7),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFCE7F3), width: 1.5),
      ),
      child: Column(
        children: [
          const Icon(Icons.qr_code_scanner_rounded,
              size: 48, color: AppColors.active),
          const SizedBox(height: 12),
          const Text(
            'Mã QR Thanh Toán Động',
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.title),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hệ thống sẽ tự động tạo mã QR VietQR chứa chính xác số tiền cần chuyển khoản và nội dung thanh toán ngay sau khi bạn nhấn nút "Xác nhận chuyển khoản" dưới chân trang.',
            textAlign: TextAlign.center,
            style: TextStyle(
                color: AppColors.subtitle, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.info_outline, size: 14, color: AppColors.active),
                SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Chụp màn hình mã QR đó để quét thanh toán rất tiện lợi!',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.active,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 5. Chi tiết thanh toán (Billing Breakdown)
  Widget _buildBillingSection() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Chi tiết thanh toán:',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Tạm tính:',
                  style: TextStyle(color: AppColors.subtitle)),
              Text(formatVND(_subtotal),
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Phí giao hàng:',
                  style: TextStyle(color: AppColors.subtitle)),
              Text(
                _shippingFee == 0 ? 'Miễn phí' : formatVND(_shippingFee),
                style: TextStyle(
                  color: _shippingFee == 0 ? Colors.green : AppColors.title,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tổng cộng:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                formatVND(_totalAmount),
                style: const TextStyle(
                  color: AppColors.active,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Bottom bar: tổng tiền + nút thanh toán
  Widget _buildBottomBar(StoreProvider provider) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tổng thanh toán',
                      style:
                          TextStyle(color: AppColors.subtitle, fontSize: 11),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatVND(_totalAmount),
                      style: const TextStyle(
                        color: AppColors.active,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 6,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.active,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    elevation: 0,
                  ),
                  onPressed: _isCheckingOut
                      ? null
                      : () => _confirmCheckout(provider),
                  child: _isCheckingOut
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : Text(
                          _paymentMethod == 'app_to_app'
                              ? 'Mở App Ngân Hàng'
                              : 'Xác nhận chuyển khoản',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
