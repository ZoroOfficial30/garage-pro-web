class SupplierPayment {
  final String id;
  final double amount;
  final DateTime date;
  final String paymentMethod;
  final String notes;
  final String? expenseId; // Linked ExpenseRecord.id for cashbook sync & undo

  const SupplierPayment({
    required this.id,
    required this.amount,
    required this.date,
    this.paymentMethod = 'Cash',
    this.notes = '',
    this.expenseId,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'amount': amount,
    'date': date.toIso8601String(),
    'paymentMethod': paymentMethod,
    'notes': notes,
    'expenseId': expenseId,
  };

  factory SupplierPayment.fromMap(Map<dynamic, dynamic> map) => SupplierPayment(
    id: map['id']?.toString() ?? '',
    amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
    date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
    paymentMethod: map['paymentMethod']?.toString() ?? 'Cash',
    notes: map['notes']?.toString() ?? '',
    expenseId: map['expenseId']?.toString(),
  );

  SupplierPayment copyWith({
    String? id,
    double? amount,
    DateTime? date,
    String? paymentMethod,
    String? notes,
    String? expenseId,
  }) => SupplierPayment(
    id: id ?? this.id,
    amount: amount ?? this.amount,
    date: date ?? this.date,
    paymentMethod: paymentMethod ?? this.paymentMethod,
    notes: notes ?? this.notes,
    expenseId: expenseId ?? this.expenseId,
  );
}

class SupplierDue {
  final String id;
  final String companyName;
  final double totalAmount;
  final double paidAmount;
  final String itemsPurchased; // e.g. "Engine Oil, Oil Filters"
  final DateTime date;
  final String notes;
  final List<SupplierPayment> payments;
  final DateTime createdAt;
  final DateTime updatedAt;

  const SupplierDue({
    required this.id,
    required this.companyName,
    required this.totalAmount,
    this.paidAmount = 0.0,
    required this.itemsPurchased,
    required this.date,
    this.notes = '',
    this.payments = const [],
    required this.createdAt,
    required this.updatedAt,
  });

  double get dueAmount => (totalAmount - paidAmount).clamp(0.0, double.infinity);
  bool get isFullyPaid => dueAmount <= 0.001;
  bool get isPartiallyPaid => paidAmount > 0.001 && !isFullyPaid;
  bool get isUnpaid => paidAmount <= 0.001;

  Map<String, dynamic> toMap() => {
    'id': id,
    'companyName': companyName,
    'totalAmount': totalAmount,
    'paidAmount': paidAmount,
    'itemsPurchased': itemsPurchased,
    'date': date.toIso8601String(),
    'notes': notes,
    'payments': payments.map((p) => p.toMap()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory SupplierDue.fromMap(Map<dynamic, dynamic> map) => SupplierDue(
    id: map['id']?.toString() ?? '',
    companyName: map['companyName']?.toString() ?? '',
    totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
    paidAmount: (map['paidAmount'] as num?)?.toDouble() ?? 0.0,
    itemsPurchased: map['itemsPurchased']?.toString() ?? '',
    date: DateTime.tryParse(map['date']?.toString() ?? '') ?? DateTime.now(),
    notes: map['notes']?.toString() ?? '',
    payments: (map['payments'] as List?)
        ?.map((p) => SupplierPayment.fromMap(p as Map))
        .toList() ??
        const [],
    createdAt: DateTime.tryParse(map['createdAt']?.toString() ?? '') ?? DateTime.now(),
    updatedAt: DateTime.tryParse(map['updatedAt']?.toString() ?? '') ?? DateTime.now(),
  );

  SupplierDue copyWith({
    String? id,
    String? companyName,
    double? totalAmount,
    double? paidAmount,
    String? itemsPurchased,
    DateTime? date,
    String? notes,
    List<SupplierPayment>? payments,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) => SupplierDue(
    id: id ?? this.id,
    companyName: companyName ?? this.companyName,
    totalAmount: totalAmount ?? this.totalAmount,
    paidAmount: paidAmount ?? this.paidAmount,
    itemsPurchased: itemsPurchased ?? this.itemsPurchased,
    date: date ?? this.date,
    notes: notes ?? this.notes,
    payments: payments ?? this.payments,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
