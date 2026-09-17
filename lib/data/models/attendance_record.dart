import 'package:intl/intl.dart';

class AttendanceRecord {
  final String id;
  final String employeeId;
  final DateTime date; // Normalized calendar date (yyyy-MM-dd)
  final bool isPresent; // true: Present, false: Absent
  final DateTime markedAt;
  final String note;
  final String markedBy;

  AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.isPresent,
    required this.markedAt,
    this.note = '',
    this.markedBy = 'Manager',
  });

  String get dateKey => DateFormat('yyyy-MM-dd').format(date);
  String get monthKey => DateFormat('yyyy-MM').format(date);
  int get dayOfMonth => date.day;
  String get dayOfWeekShort => DateFormat('E').format(date);

  AttendanceRecord copyWith({
    String? id,
    String? employeeId,
    DateTime? date,
    bool? isPresent,
    DateTime? markedAt,
    String? note,
    String? markedBy,
  }) {
    return AttendanceRecord(
      id: id ?? this.id,
      employeeId: employeeId ?? this.employeeId,
      date: date ?? this.date,
      isPresent: isPresent ?? this.isPresent,
      markedAt: markedAt ?? this.markedAt,
      note: note ?? this.note,
      markedBy: markedBy ?? this.markedBy,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'employeeId': employeeId,
      'date': date.toIso8601String(),
      'dateKey': dateKey,
      'monthKey': monthKey,
      'isPresent': isPresent,
      'markedAt': markedAt.toIso8601String(),
      'note': note,
      'markedBy': markedBy,
    };
  }

  factory AttendanceRecord.fromMap(Map<dynamic, dynamic> map) {
    return AttendanceRecord(
      id: map['id']?.toString() ?? '',
      employeeId: map['employeeId']?.toString() ?? '',
      date: map['date'] != null
          ? DateTime.parse(map['date'].toString())
          : DateTime.now(),
      isPresent: map['isPresent'] == true,
      markedAt: map['markedAt'] != null
          ? DateTime.parse(map['markedAt'].toString())
          : DateTime.now(),
      note: map['note']?.toString() ?? '',
      markedBy: map['markedBy']?.toString() ?? 'Manager',
    );
  }
}
