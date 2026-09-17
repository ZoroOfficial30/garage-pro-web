class ExpenseRecord {
  final String id;
  final String title;
  final String category;
  final double amount;
  final String paymentMethod;
  final DateTime date;
  final String? receiptPath;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  ExpenseRecord({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    this.paymentMethod = 'Cash',
    required this.date,
    this.receiptPath,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  bool get isCash => paymentMethod.toLowerCase() == 'cash';

  ExpenseRecord copyWith({
    String? title,
    String? category,
    double? amount,
    String? paymentMethod,
    DateTime? date,
    String? receiptPath,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return ExpenseRecord(
      id: id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      receiptPath: receiptPath ?? this.receiptPath,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category,
      'amount': amount,
      'paymentMethod': paymentMethod,
      'date': date.toIso8601String(),
      'receiptPath': receiptPath,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  factory ExpenseRecord.fromMap(Map<dynamic, dynamic> map) {
    return ExpenseRecord(
      id: map['id'] as String,
      title: map['title'] as String,
      category: map['category'] as String,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] as String? ?? 'Cash',
      date: DateTime.parse(map['date'] as String),
      receiptPath: map['receiptPath'] as String?,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isSynced: map['isSynced'] as bool? ?? false,
    );
  }
}
