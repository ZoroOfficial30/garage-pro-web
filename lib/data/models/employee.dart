class Employee {
  final String id;
  final String name;
  final String role;
  final String pin;
  final bool isLoginEnabled;
  final String phone;
  final String? avatarBase64;
  final double monthlySalary;
  final bool isSalaryPaid;
  final DateTime? lastSalaryPaidDate;
  final bool isPresent;
  final DateTime? lastAttendanceDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isSynced;

  Employee({
    required this.id,
    required this.name,
    required this.role,
    this.pin = '0000',
    this.isLoginEnabled = true,
    required this.phone,
    this.avatarBase64,
    this.monthlySalary = 250.0,
    this.isSalaryPaid = false,
    this.lastSalaryPaidDate,
    this.isPresent = true,
    this.lastAttendanceDate,
    required this.createdAt,
    required this.updatedAt,
    this.isSynced = false,
  });

  Employee copyWith({
    String? name,
    String? role,
    String? pin,
    bool? isLoginEnabled,
    String? phone,
    String? avatarBase64,
    double? monthlySalary,
    bool? isSalaryPaid,
    DateTime? lastSalaryPaidDate,
    bool? isPresent,
    DateTime? lastAttendanceDate,
    DateTime? updatedAt,
    bool? isSynced,
  }) {
    return Employee(
      id: id,
      name: name ?? this.name,
      role: role ?? this.role,
      pin: pin ?? this.pin,
      isLoginEnabled: isLoginEnabled ?? this.isLoginEnabled,
      phone: phone ?? this.phone,
      avatarBase64: avatarBase64 ?? this.avatarBase64,
      monthlySalary: monthlySalary ?? this.monthlySalary,
      isSalaryPaid: isSalaryPaid ?? this.isSalaryPaid,
      lastSalaryPaidDate: lastSalaryPaidDate ?? this.lastSalaryPaidDate,
      isPresent: isPresent ?? this.isPresent,
      lastAttendanceDate: lastAttendanceDate ?? this.lastAttendanceDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'role': role,
      'pin': pin,
      'isLoginEnabled': isLoginEnabled,
      'phone': phone,
      'avatarBase64': avatarBase64,
      'monthlySalary': monthlySalary,
      'isSalaryPaid': isSalaryPaid,
      'lastSalaryPaidDate': lastSalaryPaidDate?.toIso8601String(),
      'isPresent': isPresent,
      'lastAttendanceDate': lastAttendanceDate?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  Map<String, dynamic> toSupabaseMap(String userId) {
    return {
      'id': id,
      'name': name,
      'role': role,
      'pin': pin,
      'is_login_enabled': isLoginEnabled,
      'phone': phone,
      'avatar_base64': avatarBase64,
      'monthly_salary': monthlySalary,
      'is_salary_paid': isSalaryPaid,
      'last_salary_paid_date': lastSalaryPaidDate?.toIso8601String(),
      'is_present': isPresent,
      'last_attendance_date': lastAttendanceDate?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'user_id': userId,
    };
  }

  factory Employee.fromMap(Map<dynamic, dynamic> map) {
    return Employee(
      id: (map['id'] ?? '') as String,
      name: (map['name'] ?? '') as String,
      role: (map['role'] ?? '') as String,
      pin: ((map['pin']) as String?) ?? '0000',
      isLoginEnabled: (map['isLoginEnabled'] ?? map['is_login_enabled']) as bool? ?? true,
      phone: (map['phone'] ?? '') as String,
      avatarBase64: (map['avatarBase64'] ?? map['avatar_base64']) as String?,
      monthlySalary: ((map['monthlySalary'] ?? map['monthly_salary']) as num?)?.toDouble() ?? 250.0,
      isSalaryPaid: (map['isSalaryPaid'] ?? map['is_salary_paid']) as bool? ?? false,
      lastSalaryPaidDate: (map['lastSalaryPaidDate'] ?? map['last_salary_paid_date']) != null
          ? DateTime.tryParse((map['lastSalaryPaidDate'] ?? map['last_salary_paid_date']) as String)
          : null,
      isPresent: (map['isPresent'] ?? map['is_present']) as bool? ?? true,
      lastAttendanceDate: (map['lastAttendanceDate'] ?? map['last_attendance_date']) != null
          ? DateTime.tryParse((map['lastAttendanceDate'] ?? map['last_attendance_date']) as String)
          : null,
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
