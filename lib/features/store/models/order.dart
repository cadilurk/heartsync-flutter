import 'cart_item.dart';

class Order {
  final String id;
  final List<CartItem> items;
  final double totalAmount;
  final DateTime orderDate;
  final bool isGift;
  final String status;
  final String? giftMessage;
  final String? checkoutUrl;
  final String? qrCode;       // Raw EMV QR string từ PayOS
  final String? accountNumber; // Số tài khoản ngân hàng từ PayOS
  final String? accountName;   // Tên chủ tài khoản từ PayOS
  final String? bin;           // BIN ngân hàng từ PayOS
  final int? orderCode;

  const Order({
    required this.id,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    required this.isGift,
    required this.status,
    this.giftMessage,
    this.checkoutUrl,
    this.qrCode,
    this.accountNumber,
    this.accountName,
    this.bin,
    this.orderCode,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      orderDate: DateTime.parse(json['orderDate'] as String),
      isGift: json['isGift'] as bool? ?? false,
      status: json['status'] as String? ?? 'completed',
      giftMessage: json['giftMessage'] as String?,
      checkoutUrl: json['checkoutUrl'] as String?,
      qrCode: json['qrCode'] as String?,
      accountNumber: json['accountNumber'] as String?,
      accountName: json['accountName'] as String?,
      bin: json['bin'] as String?,
      orderCode: json['orderCode'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'orderDate': orderDate.toIso8601String(),
      'isGift': isGift,
      'status': status,
      'giftMessage': giftMessage,
      'checkoutUrl': checkoutUrl,
      'qrCode': qrCode,
      'accountNumber': accountNumber,
      'accountName': accountName,
      'bin': bin,
      'orderCode': orderCode,
    };
  }
}
