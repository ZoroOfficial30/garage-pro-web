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

  factory Employee.fromMap(Map<dynamic, dynamic> map) {
    return Employee(
      id: map['id'] as String,
      name: map['name'] as String,
      role: map['role'] as String,
      pin: (map['pin'] as String?) ?? '0000',
      isLoginEnabled: map['isLoginEnabled'] as bool? ?? true,
      phone: map['phone'] as String,
      avatarBase64: map['avatarBase64'] as String?,
      monthlySalary: (map['monthlySalary'] as num?)?.toDouble() ?? 250.0,
      isSalaryPaid: map['isSalaryPaid'] as bool? ?? false,
      lastSalaryPaidDate: map['lastSalaryPaidDate'] != null
          ? DateTime.tryParse(map['lastSalaryPaidDate'] as String)
          : null,
      isPresent: map['isPresent'] as bool? ?? true,
      lastAttendanceDate: map['lastAttendanceDate'] != null
          ? DateTime.tryParse(map['lastAttendanceDate'] as String)
          : null,
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
      isSynced: map['isSynced'] as bool? ?? false,
    );
  }
}
