class BayJob {
  final String id;
  final String bayNumber; // e.g. "Bay 1", "Bay 2", "Bay 3"
  final String? customerId;
  final String customerName;
  final String customerPhone;
  final String vehicleModel;
  final String plateNumber;
  final String taskDescription;
  final double estimatedCost;
  final String technicianName;
  final String status; // 'waiting', 'ready_for_pickup', 'completed'
  final double? settledAmount;
  final double? paidAmount;
  final double? dueAmount;
  final String? paymentMethod; // 'cash', 'bank', 'card', 'credit'
  final DateTime date;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  BayJob({
    required this.id,
    required this.bayNumber,
    this.customerId,
    required this.customerName,
    this.customerPhone = '',
    required this.vehicleModel,
    this.plateNumber = '',
    required this.taskDescription,
    this.estimatedCost = 0.0,
    this.technicianName = '',
    this.status = 'waiting',
    this.settledAmount,
    this.paidAmount,
    this.dueAmount,
    this.paymentMethod,
    required this.date,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  bool get isWaiting =>
      status == 'waiting' || status == 'in_progress' || status == 'waiting_for_parts';
  bool get isReadyForPickup => status == 'ready_for_pickup';
  bool get isInProgress => status == 'in_progress' || status == 'waiting';
  bool get isWaitingForParts => status == 'waiting_for_parts';
  bool get isCompleted => status == 'completed';

  String get displayStatus {
    switch (status) {
      case 'ready_for_pickup':
        return 'READY FOR PICKUP';
      case 'waiting':
      case 'in_progress':
        return 'WAITING';
      case 'waiting_for_parts':
        return 'WAITING FOR PARTS';
      case 'completed':
        return 'COMPLETED';
      default:
        return status.toUpperCase();
    }
  }

  BayJob copyWith({
    String? bayNumber,
    String? customerId,
    String? customerName,
    String? customerPhone,
    String? vehicleModel,
    String? plateNumber,
    String? taskDescription,
    double? estimatedCost,
    String? technicianName,
    String? status,
    double? settledAmount,
    double? paidAmount,
    double? dueAmount,
    String? paymentMethod,
    DateTime? date,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return BayJob(
      id: id,
      bayNumber: bayNumber ?? this.bayNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      plateNumber: plateNumber ?? this.plateNumber,
      taskDescription: taskDescription ?? this.taskDescription,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      technicianName: technicianName ?? this.technicianName,
      status: status ?? this.status,
      settledAmount: settledAmount ?? this.settledAmount,
      paidAmount: paidAmount ?? this.paidAmount,
      dueAmount: dueAmount ?? this.dueAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      date: date ?? this.date,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'bayNumber': bayNumber,
      'customerId': customerId,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'vehicleModel': vehicleModel,
      'plateNumber': plateNumber,
      'taskDescription': taskDescription,
      'estimatedCost': estimatedCost,
      'technicianName': technicianName,
      'status': status,
      'settledAmount': settledAmount,
      'paidAmount': paidAmount,
      'dueAmount': dueAmount,
      'paymentMethod': paymentMethod,
      'date': date.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  Map<String, dynamic> toSupabaseMap(String userId) {
    return {
      'id': id,
      'customer_id': customerId,
      'customer_name': customerName,
      'customer_phone': customerPhone,
      'vehicle_model': vehicleModel,
      'plate_number': plateNumber,
      'status': status,
      'settled_amount': settledAmount,
      'paid_amount': paidAmount,
      'due_amount': dueAmount,
      'payment_method': paymentMethod,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_id': userId,
    };
  }

  factory BayJob.fromMap(Map<dynamic, dynamic> map) {
    return BayJob(
      id: (map['id'] ?? '') as String,
      bayNumber: (map['bayNumber'] ?? map['bay_number'] ?? 'Bay 1') as String,
      customerId: (map['customerId'] ?? map['customer_id']) as String?,
      customerName: (map['customerName'] ?? map['customer_name'] ?? 'Unknown Customer') as String,
      customerPhone: (map['customerPhone'] ?? map['customer_phone'] ?? '') as String,
      vehicleModel: (map['vehicleModel'] ?? map['vehicle_model'] ?? '') as String,
      plateNumber: (map['plateNumber'] ?? map['plate_number'] ?? '') as String,
      taskDescription: (map['taskDescription'] ?? map['task_description'] ?? 'General Inspection') as String,
      estimatedCost: ((map['estimatedCost'] ?? map['estimated_cost']) as num?)?.toDouble() ?? 0.0,
      technicianName: (map['technicianName'] ?? map['technician_name'] ?? '') as String,
      status: (map['status'] ?? 'waiting') as String,
      settledAmount: ((map['settledAmount'] ?? map['settled_amount']) as num?)?.toDouble(),
      paidAmount: ((map['paidAmount'] ?? map['paid_amount']) as num?)?.toDouble(),
      dueAmount: ((map['dueAmount'] ?? map['due_amount']) as num?)?.toDouble(),
      paymentMethod: (map['paymentMethod'] ?? map['payment_method']) as String?,
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
