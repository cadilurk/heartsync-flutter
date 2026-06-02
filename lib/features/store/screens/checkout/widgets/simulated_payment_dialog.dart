import 'package:flutter/material.dart';
import '../../../../../app/theme.dart';

/// Dialog giả lập quét chuyển khoản (dùng khi PayOS chưa cấu hình thật
/// hoặc khi chọn phương thức App-to-App ở chế độ mock).
class SimulatedPaymentDialog extends StatefulWidget {
  final VoidCallback onSuccess;
  final VoidCallback onCancel;

  const SimulatedPaymentDialog({
    super.key,
    required this.onSuccess,
    required this.onCancel,
  });

  @override
  State<SimulatedPaymentDialog> createState() => _SimulatedPaymentDialogState();
}

class _SimulatedPaymentDialogState extends State<SimulatedPaymentDialog> {
  int _currentStep = 0;

  final List<String> _steps = [
    'Đang mở cổng liên thông VietQR & Napas...',
    'Đang chờ bạn thực hiện chuyển khoản trên ứng dụng ngân hàng...',
    'Đang kiểm tra biến động số dư tài khoản nhận (MB Bank)...',
    'Đã phát hiện biến động số dư khớp với giá trị đơn hàng!',
    'Đang khởi tạo hóa đơn giao dịch điện tử...',
  ];

  @override
  void initState() {
    super.initState();
    _startScanning();
  }

  void _startScanning() async {
    for (int i = 0; i < _steps.length; i++) {
      await Future.delayed(const Duration(milliseconds: 1800));
      if (mounted) {
        setState(() => _currentStep = i + 1);
      }
    }
    await Future.delayed(const Duration(milliseconds: 600));
    widget.onSuccess();
  }

  @override
  Widget build(BuildContext context) {
    final progress = _currentStep / _steps.length;
    final isDone = _currentStep >= _steps.length;

    return PopScope(
      canPop: false,
      child: AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              isDone
                  ? const CircleAvatar(
                      radius: 36,
                      backgroundColor: Colors.green,
                      child: Icon(Icons.check, color: Colors.white, size: 40),
                    )
                  : Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80,
                          height: 80,
                          child: CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 6,
                            color: AppColors.active,
                            backgroundColor: AppColors.bg,
                          ),
                        ),
                        const Icon(
                          Icons.swap_horizontal_circle_outlined,
                          size: 40,
                          color: AppColors.active,
                        ),
                      ],
                    ),
              const SizedBox(height: 24),
              const Text(
                'Xác Minh Chuyển Khoản',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 48,
                child: Text(
                  _currentStep < _steps.length
                      ? _steps[_currentStep]
                      : 'Hoàn tất giao dịch...',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isDone ? Colors.green : AppColors.subtitle,
                    fontSize: 13,
                    fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
                    height: 1.4,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              if (!isDone)
                TextButton(
                  onPressed: widget.onCancel,
                  child: const Text(
                    'Hủy bỏ giao dịch',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
