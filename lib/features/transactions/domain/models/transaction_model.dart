enum PaymentMethod { cash, card, upi, qrPay }

class ShopTransaction {
  final String id;
  final String invoiceNo;
  final DateTime timestamp;
  final String staffName;
  final String customerName;
  final double totalAmount;
  final PaymentMethod paymentMethod;
  final int itemsCount;
  final String status;

  ShopTransaction({
    required this.id,
    required this.invoiceNo,
    required this.timestamp,
    required this.staffName,
    required this.customerName,
    required this.totalAmount,
    required this.paymentMethod,
    required this.itemsCount,
    this.status = 'Completed',
  });

  String get paymentMethodName {
    switch (paymentMethod) {
      case PaymentMethod.cash:
        return 'Cash';
      case PaymentMethod.card:
        return 'Credit/Debit Card';
      case PaymentMethod.upi:
        return 'UPI / Online';
      case PaymentMethod.qrPay:
        return 'Instant QR Pay';
    }
  }

  ShopTransaction copyWith({
    String? id,
    String? invoiceNo,
    DateTime? timestamp,
    String? staffName,
    String? customerName,
    double? totalAmount,
    PaymentMethod? paymentMethod,
    int? itemsCount,
    String? status,
  }) {
    return ShopTransaction(
      id: id ?? this.id,
      invoiceNo: invoiceNo ?? this.invoiceNo,
      timestamp: timestamp ?? this.timestamp,
      staffName: staffName ?? this.staffName,
      customerName: customerName ?? this.customerName,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      itemsCount: itemsCount ?? this.itemsCount,
      status: status ?? this.status,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'invoiceNo': invoiceNo,
      'timestamp': timestamp.toIso8601String(),
      'staffName': staffName,
      'customerName': customerName,
      'totalAmount': totalAmount,
      'paymentMethod': paymentMethod.name,
      'itemsCount': itemsCount,
      'status': status,
    };
  }

  factory ShopTransaction.fromMap(Map<String, dynamic> map, String docId) {
    PaymentMethod method = PaymentMethod.cash;
    if (map['paymentMethod'] != null) {
      try {
        method = PaymentMethod.values.byName(map['paymentMethod'] as String);
      } catch (_) {}
    }

    return ShopTransaction(
      id: docId,
      invoiceNo: map['invoiceNo'] as String? ?? 'INV-000',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      staffName: map['staffName'] as String? ?? 'Staff',
      customerName: map['customerName'] as String? ?? 'Walk-in Customer',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: method,
      itemsCount: (map['itemsCount'] as num?)?.toInt() ?? 1,
      status: map['status'] as String? ?? 'Completed',
    );
  }
}
