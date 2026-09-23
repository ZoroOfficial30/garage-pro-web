class StockItem {
  final String id;
  final String name;
  final String brand;
  final String sku;
  final int quantity;
  final int reorderThreshold;
  final double costPrice;
  final double sellingPrice;
  final String unit;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  StockItem({
    required this.id,
    required this.name,
    required this.brand,
    required this.sku,
    required this.quantity,
    this.reorderThreshold = 5,
    required this.costPrice,
    required this.sellingPrice,
    this.unit = 'Pcs',
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  bool get isLowStock => quantity <= reorderThreshold && quantity > 0;
  bool get isOutOfStock => quantity <= 0;

  StockItem copyWith({
    String? name,
    String? brand,
    String? sku,
    int? quantity,
    int? reorderThreshold,
    double? costPrice,
    double? sellingPrice,
    String? unit,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return StockItem(
      id: id,
      name: name ?? this.name,
      brand: brand ?? this.brand,
      sku: sku ?? this.sku,
      quantity: quantity ?? this.quantity,
      reorderThreshold: reorderThreshold ?? this.reorderThreshold,
      costPrice: costPrice ?? this.costPrice,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      unit: unit ?? this.unit,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'sku': sku,
      'quantity': quantity,
      'reorderThreshold': reorderThreshold,
      'costPrice': costPrice,
      'sellingPrice': sellingPrice,
      'unit': unit,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  Map<String, dynamic> toSupabaseMap(String userId) {
    return {
      'id': id,
      'name': name,
      'brand': brand,
      'sku': sku,
      'quantity': quantity,
      'reorder_threshold': reorderThreshold,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'unit': unit,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_id': userId,
    };
  }

  factory StockItem.fromMap(Map<dynamic, dynamic> map) {
    return StockItem(
      id: (map['id'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      brand: (map['brand'] ?? '') as String,
      sku: (map['sku'] ?? '') as String,
      quantity: ((map['quantity']) as num?)?.toInt() ?? 0,
      reorderThreshold: ((map['reorderThreshold'] ?? map['reorder_threshold']) as num?)?.toInt() ?? 5,
      costPrice: ((map['costPrice'] ?? map['cost_price']) as num?)?.toDouble() ?? 0.0,
      sellingPrice: ((map['sellingPrice'] ?? map['selling_price']) as num?)?.toDouble() ?? 0.0,
      unit: (map['unit'] as String?) ?? 'Pcs',
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : (map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now()),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : (map['updated_at'] != null ? DateTime.parse(map['updated_at'] as String) : DateTime.now()),
      isSynced: (map['isSynced'] ?? map['is_synced']) as bool? ?? false,
    );
  }
}
