import 'package:cloud_firestore/cloud_firestore.dart';

class ShiftModel {
  final String id;
  final String userId;
  final String userName;
  final String role;
  final String date;
  final DateTime? clockIn;
  final DateTime? clockOut;
  final double totalHours;
  final String status; // 'active', 'closed'

  const ShiftModel({
    required this.id,
    required this.userId,
    required this.userName,
    required this.role,
    required this.date,
    this.clockIn,
    this.clockOut,
    this.totalHours = 0.0,
    this.status = 'active',
  });

  factory ShiftModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return ShiftModel.fromMap(doc.id, data);
  }

  factory ShiftModel.fromMap(String id, Map<String, dynamic> data) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return ShiftModel(
      id: id,
      userId: data['userId'] as String? ?? '',
      userName: data['userName'] as String? ?? '',
      role: data['role'] as String? ?? '',
      date: data['date'] as String? ?? '',
      clockIn: parseDate(data['clockIn']),
      clockOut: parseDate(data['clockOut']),
      totalHours: (data['totalHours'] as num?)?.toDouble() ?? 0.0,
      status: data['status'] as String? ?? 'active',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'role': role,
      'date': date,
      'clockIn': clockIn != null ? Timestamp.fromDate(clockIn!) : FieldValue.serverTimestamp(),
      'clockOut': clockOut != null ? Timestamp.fromDate(clockOut!) : null,
      'totalHours': totalHours,
      'status': status,
    };
  }
}
