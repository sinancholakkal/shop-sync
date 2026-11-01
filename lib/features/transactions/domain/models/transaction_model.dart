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
}
