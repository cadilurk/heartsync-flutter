/// Các hàm tiện ích và hằng số dùng chung trong màn hình Thanh toán.
library;

/// Danh sách ngân hàng cho dropdown chọn app chuyển khoản.
const List<Map<String, String>> kVietnameseBanks = [
  {'id': 'auto', 'name': 'Tự động phát hiện (Napas landing page)'},
  {'id': 'vcb', 'name': 'Vietcombank'},
  {'id': 'mb', 'name': 'MB Bank'},
  {'id': 'tcb', 'name': 'Techcombank'},
  {'id': 'tpb', 'name': 'TPBank'},
  {'id': 'ctg', 'name': 'VietinBank'},
  {'id': 'acb', 'name': 'ACB'},
  {'id': 'bidv', 'name': 'BIDV'},
];

/// Định dạng số tiền VND: 30000 → "30.000đ".
String formatVND(double amount) {
  final str = amount.toStringAsFixed(0);
  return '${str.replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => '.')}đ';
}

/// Tra cứu tên ngân hàng từ BIN mà PayOS trả về.
String bankNameFromBin(String? bin) {
  if (bin == null) return 'Ngân hàng';
  const binMap = {
    '970422': 'MB Bank',
    '970415': 'Vietinbank',
    '970436': 'Vietcombank',
    '970432': 'VPBank',
    '970423': 'TPBank',
    '970407': 'Techcombank',
    '970443': 'SHB',
    '970418': 'BIDV',
    '970405': 'Agribank',
    '970416': 'ACB',
    '970426': 'MSB',
    '970448': 'OCB',
    '970441': 'VIB',
    '970437': 'HDBank',
    '970403': 'Sacombank',
    '970420': 'LienVietPostBank',
    '970412': 'PVcomBank',
    '970419': 'NCB',
  };
  return binMap[bin] ?? 'Ngân hàng ($bin)';
}
