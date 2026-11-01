class InventoryItem {
  final String id;
  final String name;
  final String sku;
  final String category;
  final double price;
  final double costPrice;
  final double? marginPercent;
  final int quantity;
  final int minThreshold;
  final DateTime lastUpdated;

  InventoryItem({
    required this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.price,
    required this.costPrice,
    this.marginPercent,
    required this.quantity,
    required this.minThreshold,
    required this.lastUpdated,
  });

  bool get isLowStock => quantity <= minThreshold;
  bool get isOutOfStock => quantity <= 0;

  double get calculatedMarginPercent {
    if (costPrice <= 0) return 0.0;
    return ((price - costPrice) / costPrice) * 100.0;
  }

  double get effectiveMarginPercent => marginPercent ?? calculatedMarginPercent;
  double get profitPerUnit => price - costPrice;

  InventoryItem copyWith({
    String? id,
    String? name,
    String? sku,
    String? category,
    double? price,
    double? costPrice,
    double? marginPercent,
    int? quantity,
    int? minThreshold,
    DateTime? lastUpdated,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      marginPercent: marginPercent ?? this.marginPercent,
      quantity: quantity ?? this.quantity,
      minThreshold: minThreshold ?? this.minThreshold,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sku': sku,
      'category': category,
      'price': price,
      'costPrice': costPrice,
      'marginPercent': marginPercent ?? calculatedMarginPercent,
      'quantity': quantity,
      'minThreshold': minThreshold,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map, String docId) {
    final priceVal = (map['price'] as num?)?.toDouble() ?? 0.0;
    final costVal = (map['costPrice'] as num?)?.toDouble() ?? 0.0;
    final marginVal = (map['marginPercent'] as num?)?.toDouble() ??
        (costVal > 0 ? ((priceVal - costVal) / costVal) * 100.0 : null);

    return InventoryItem(
      id: docId,
      name: map['name'] as String? ?? 'Unnamed Product',
      sku: map['sku'] as String? ?? 'SKU-000',
      category: map['category'] as String? ?? 'General',
      price: priceVal,
      costPrice: costVal,
      marginPercent: marginVal,
      quantity: (map['quantity'] as num?)?.toInt() ?? 0,
      minThreshold: (map['minThreshold'] as num?)?.toInt() ?? 5,
      lastUpdated: map['lastUpdated'] != null
          ? DateTime.tryParse(map['lastUpdated'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
