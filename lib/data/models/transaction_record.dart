class TransactionRecord {
  final String id;
  final String? customerId;
  final String customerName;
  final String type; // 'payment', 'due', 'invoice', 'stock_out'
  final double amount;
  final double runningBalance;
  final String description;
  final String paymentMethod; // 'cash', 'card', 'bank', 'credit'
  final String? referenceJobId;
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  TransactionRecord({
    required this.id,
    this.customerId,
    required this.customerName,
    required this.type,
    required this.amount,
    this.runningBalance = 0.0,
    required this.description,
    this.paymentMethod = 'cash',
    this.referenceJobId,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  bool get isPayment => type == 'payment';
  bool get isDue => type == 'due';
  bool get isStockOut => type == 'stock_out';
  bool get isStockSale => type == 'stock_sale';
  bool get isInvoice => type == 'invoice';
  bool get isCarWash => type == 'car_wash';
  bool get isIncome =>
      type == 'payment' ||
      type == 'car_wash' ||
      type == 'income' ||
      type == 'service' ||
      type == 'stock_sale';

  TransactionRecord copyWith({
    String? customerId,
    String? customerName,
    String? type,
    double? amount,
    double? runningBalance,
    String? description,
    String? paymentMethod,
    String? referenceJobId,
    DateTime? date,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return TransactionRecord(
      id: id,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      runningBalance: runningBalance ?? this.runningBalance,
      description: description ?? this.description,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      referenceJobId: referenceJobId ?? this.referenceJobId,
      date: date ?? this.date,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'type': type,
      'amount': amount,
      'runningBalance': runningBalance,
      'description': description,
      'paymentMethod': paymentMethod,
      'referenceJobId': referenceJobId,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  Map<String, dynamic> toSupabaseMap(String userId) {
    return {
      'id': id,
      'type': type,
      'amount': amount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_id': userId,
    };
  }

  factory TransactionRecord.fromMap(Map<dynamic, dynamic> map) {
    return TransactionRecord(
      id: (map['id'] ?? '') as String,
      customerId: (map['customerId'] ?? map['customer_id']) as String?,
      customerName: (map['customerName'] ?? map['customer_name'] ?? 'General') as String,
      type: (map['type'] ?? 'payment') as String,
      amount: ((map['amount']) as num?)?.toDouble() ?? 0.0,
      runningBalance: ((map['runningBalance'] ?? map['running_balance']) as num?)?.toDouble() ?? 0.0,
      description: (map['description'] ?? map['desc'] ?? '') as String,
      paymentMethod: (map['paymentMethod'] ?? map['payment_method'] ?? 'cash') as String,
      referenceJobId: (map['referenceJobId'] ?? map['reference_job_id']) as String?,
      date: map['date'] != null
          ? DateTime.parse(map['date'] as String)
          : (map['created_at'] != null ? DateTime.parse(map['created_at'] as String) : DateTime.now()),
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
