class PriceHistoryEntry {
  final DateTime timestamp;
  final double price;
  final double costPrice;
  final double? marginPercent;
  final String? note;

  PriceHistoryEntry({
    required this.timestamp,
    required this.price,
    required this.costPrice,
    this.marginPercent,
    this.note,
  });

  double get profit => price - costPrice;

  double get effectiveMargin =>
      marginPercent ?? (costPrice > 0 ? ((price - costPrice) / costPrice) * 100 : 0.0);

  Map<String, dynamic> toMap() {
    return {
      'timestamp': timestamp.toIso8601String(),
      'price': price,
      'costPrice': costPrice,
      'marginPercent': effectiveMargin,
      if (note != null) 'note': note,
    };
  }

  factory PriceHistoryEntry.fromMap(Map<String, dynamic> map) {
    final priceVal = (map['price'] as num?)?.toDouble() ?? 0.0;
    final costVal = (map['costPrice'] as num?)?.toDouble() ?? 0.0;
    return PriceHistoryEntry(
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      price: priceVal,
      costPrice: costVal,
      marginPercent: (map['marginPercent'] as num?)?.toDouble(),
      note: map['note'] as String?,
    );
  }
}

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
  final DateTime priceLastUpdated;
  final DateTime stockLastUpdated;
  final DateTime createdAt;
  final List<PriceHistoryEntry> priceHistory;

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
    DateTime? priceLastUpdated,
    DateTime? stockLastUpdated,
    DateTime? createdAt,
    List<PriceHistoryEntry>? priceHistory,
  })  : priceLastUpdated = priceLastUpdated ?? lastUpdated,
        stockLastUpdated = stockLastUpdated ?? lastUpdated,
        createdAt = createdAt ?? lastUpdated,
        priceHistory = (priceHistory != null && priceHistory.isNotEmpty)
            ? List.unmodifiable(priceHistory)
            : List.unmodifiable([
                PriceHistoryEntry(
                  timestamp: priceLastUpdated ?? lastUpdated,
                  price: price,
                  costPrice: costPrice,
                  marginPercent: marginPercent,
                  note: 'Initial Price',
                ),
              ]);

  bool get isLowStock => quantity <= minThreshold;
  bool get isOutOfStock => quantity <= 0;

  double get calculatedMarginPercent {
    if (costPrice <= 0) return 0.0;
    return ((price - costPrice) / costPrice) * 100.0;
  }

  double get effectiveMarginPercent => marginPercent ?? calculatedMarginPercent;
  double get profitPerUnit => price - costPrice;
  double get totalStockValue => price * quantity;
  double get totalStockCost => costPrice * quantity;

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
    DateTime? priceLastUpdated,
    DateTime? stockLastUpdated,
    DateTime? createdAt,
    List<PriceHistoryEntry>? priceHistory,
  }) {
    final now = DateTime.now();
    final newPrice = price ?? this.price;
    final newCost = costPrice ?? this.costPrice;
    final priceChanged = (newPrice != this.price) || (newCost != this.costPrice);
    final stockChanged = (quantity != null && quantity != this.quantity);

    List<PriceHistoryEntry> updatedHistory;
    if (priceHistory != null) {
      updatedHistory = List.from(priceHistory);
    } else {
      updatedHistory = List.from(this.priceHistory);
      if (priceChanged) {
        updatedHistory.add(
          PriceHistoryEntry(
            timestamp: now,
            price: newPrice,
            costPrice: newCost,
            marginPercent: marginPercent ?? this.marginPercent,
            note: 'Price updated',
          ),
        );
      }
    }

    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      price: newPrice,
      costPrice: newCost,
      marginPercent: marginPercent ?? this.marginPercent,
      quantity: quantity ?? this.quantity,
      minThreshold: minThreshold ?? this.minThreshold,
      lastUpdated: lastUpdated ?? now,
      priceLastUpdated: priceLastUpdated ?? (priceChanged ? now : this.priceLastUpdated),
      stockLastUpdated: stockLastUpdated ?? (stockChanged ? now : this.stockLastUpdated),
      createdAt: createdAt ?? this.createdAt,
      priceHistory: updatedHistory,
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
      'priceLastUpdated': priceLastUpdated.toIso8601String(),
      'stockLastUpdated': stockLastUpdated.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'priceHistory': priceHistory.map((e) => e.toMap()).toList(),
    };
  }

  factory InventoryItem.fromMap(Map<String, dynamic> map, String docId) {
    final priceVal = (map['price'] as num?)?.toDouble() ?? 0.0;
    final costVal = (map['costPrice'] as num?)?.toDouble() ?? 0.0;
    final marginVal = (map['marginPercent'] as num?)?.toDouble() ??
        (costVal > 0 ? ((priceVal - costVal) / costVal) * 100.0 : null);

    final lastUpdatedVal = map['lastUpdated'] != null
        ? DateTime.tryParse(map['lastUpdated'] as String) ?? DateTime.now()
        : DateTime.now();

    final priceLastUpdatedVal = map['priceLastUpdated'] != null
        ? DateTime.tryParse(map['priceLastUpdated'] as String) ?? lastUpdatedVal
        : lastUpdatedVal;

    final stockLastUpdatedVal = map['stockLastUpdated'] != null
        ? DateTime.tryParse(map['stockLastUpdated'] as String) ?? lastUpdatedVal
        : lastUpdatedVal;

    final createdAtVal = map['createdAt'] != null
        ? DateTime.tryParse(map['createdAt'] as String) ?? lastUpdatedVal
        : lastUpdatedVal;

    List<PriceHistoryEntry> history;
    if (map['priceHistory'] is List) {
      history = (map['priceHistory'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => PriceHistoryEntry.fromMap(e))
          .toList();
      if (history.isEmpty) {
        history = [
          PriceHistoryEntry(
            timestamp: priceLastUpdatedVal,
            price: priceVal,
            costPrice: costVal,
            marginPercent: marginVal,
            note: 'Initial Price',
          ),
        ];
      }
    } else {
      history = [
        PriceHistoryEntry(
          timestamp: priceLastUpdatedVal,
          price: priceVal,
          costPrice: costVal,
          marginPercent: marginVal,
          note: 'Initial Price',
        ),
      ];
    }

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
      lastUpdated: lastUpdatedVal,
      priceLastUpdated: priceLastUpdatedVal,
      stockLastUpdated: stockLastUpdatedVal,
      createdAt: createdAtVal,
      priceHistory: history,
    );
  }
}
