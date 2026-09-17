class Customer {
  final String id;
  final String name;
  final String phone;
  final String vehicleModel;
  final String plateNumber;
  final double totalDue;
  final double totalBilled;
  final double totalPaid;
  final bool isVip;
  final String notes;
  final String? avatarBase64;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  Customer({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleModel,
    required this.plateNumber,
    this.totalDue = 0.0,
    this.totalBilled = 0.0,
    this.totalPaid = 0.0,
    this.isVip = false,
    this.notes = '',
    this.avatarBase64,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  Customer copyWith({
    String? name,
    String? phone,
    String? vehicleModel,
    String? plateNumber,
    double? totalDue,
    double? totalBilled,
    double? totalPaid,
    bool? isVip,
    String? notes,
    String? avatarBase64,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return Customer(
      id: id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      plateNumber: plateNumber ?? this.plateNumber,
      totalDue: totalDue ?? this.totalDue,
      totalBilled: totalBilled ?? this.totalBilled,
      totalPaid: totalPaid ?? this.totalPaid,
      isVip: isVip ?? this.isVip,
      notes: notes ?? this.notes,
      avatarBase64: avatarBase64 ?? this.avatarBase64,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'vehicleModel': vehicleModel,
      'plateNumber': plateNumber,
      'totalDue': totalDue,
      'totalBilled': totalBilled,
      'totalPaid': totalPaid,
      'isVip': isVip,
      'notes': notes,
      'avatarBase64': avatarBase64,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  Map<String, dynamic> toSupabaseMap(String userId) {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'plate_number': plateNumber,
      'total_due': totalDue,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_id': userId,
    };
  }

  factory Customer.fromMap(Map<dynamic, dynamic> map) {
    return Customer(
      id: (map['id'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      phone: (map['phone'] ?? '') as String,
      vehicleModel: (map['vehicleModel'] ?? map['vehicle_model'] ?? '') as String,
      plateNumber: (map['plateNumber'] ?? map['plate_number'] ?? '') as String,
      totalDue: ((map['totalDue'] ?? map['total_due']) as num?)?.toDouble() ?? 0.0,
      totalBilled: ((map['totalBilled'] ?? map['total_billed']) as num?)?.toDouble() ?? 0.0,
      totalPaid: ((map['totalPaid'] ?? map['total_paid']) as num?)?.toDouble() ?? 0.0,
      isVip: (map['isVip'] ?? map['is_vip']) as bool? ?? false,
      notes: (map['notes'] ?? map['note']) as String? ?? '',
      avatarBase64: (map['avatarBase64'] ?? map['avatar_base64']) as String?,
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
