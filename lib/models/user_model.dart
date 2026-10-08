import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  admin,
  waiter,
  kitchen,
  cashier,
  customer;

  static UserRole fromString(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'waiter':
        return UserRole.waiter;
      case 'kitchen':
        return UserRole.kitchen;
      case 'cashier':
        return UserRole.cashier;
      case 'customer':
      default:
        return UserRole.customer;
    }
  }

  String get displayName {
    switch (this) {
      case UserRole.admin:
        return 'Administrator';
      case UserRole.waiter:
        return 'Waiter';
      case UserRole.kitchen:
        return 'Kitchen Staff';
      case UserRole.cashier:
        return 'Cashier';
      case UserRole.customer:
        return 'Customer';
    }
  }
}

class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String phone;
  final UserRole role;
  final String photoUrl;
  final String status;
  final String employeeId;
  final String assignedSection;
  final String shiftStatus;
  final List<String> fcmTokens;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.phone = '',
    required this.role,
    this.photoUrl = '',
    this.status = 'active',
    this.employeeId = '',
    this.assignedSection = '',
    this.shiftStatus = 'off_duty',
    this.fcmTokens = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserModel.fromMap(doc.id, data);
  }

  factory UserModel.fromMap(String id, Map<String, dynamic> data) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return UserModel(
      uid: id,
      displayName: data['displayName'] as String? ?? '',
      email: data['email'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      role: UserRole.fromString(data['role'] as String? ?? 'customer'),
      photoUrl: data['photoUrl'] as String? ?? '',
      status: data['status'] as String? ?? 'active',
      employeeId: data['employeeId'] as String? ?? '',
      assignedSection: data['assignedSection'] as String? ?? '',
      shiftStatus: data['shiftStatus'] as String? ?? 'off_duty',
      fcmTokens: (data['fcmTokens'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'phone': phone,
      'role': role.name,
      'photoUrl': photoUrl,
      'status': status,
      'employeeId': employeeId,
      'assignedSection': assignedSection,
      'shiftStatus': shiftStatus,
      'fcmTokens': fcmTokens,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  UserModel copyWith({
    String? displayName,
    String? phone,
    UserRole? role,
    String? photoUrl,
    String? status,
    String? employeeId,
    String? assignedSection,
    String? shiftStatus,
    List<String>? fcmTokens,
  }) {
    return UserModel(
      uid: uid,
      displayName: displayName ?? this.displayName,
      email: email,
      phone: phone ?? this.phone,
      role: role ?? this.role,
      photoUrl: photoUrl ?? this.photoUrl,
      status: status ?? this.status,
      employeeId: employeeId ?? this.employeeId,
      assignedSection: assignedSection ?? this.assignedSection,
      shiftStatus: shiftStatus ?? this.shiftStatus,
      fcmTokens: fcmTokens ?? this.fcmTokens,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
