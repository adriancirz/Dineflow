import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationModel {
  final String id;
  final String type;
  final String tableId;
  final String tableNumber;
  final String? orderId;
  final double? total;
  final String? reason;
  final String recipientRole;
  final String title;
  final String message;
  final String status;
  final DateTime? createdAt;

  const NotificationModel({
    required this.id,
    required this.type,
    required this.tableId,
    required this.tableNumber,
    this.orderId,
    this.total,
    this.reason,
    required this.recipientRole,
    required this.title,
    required this.message,
    this.status = 'unread',
    this.createdAt,
  });

  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    DateTime? created;
    final rawTs = data['createdAt'];
    if (rawTs is Timestamp) {
      created = rawTs.toDate();
    } else if (rawTs is String) {
      created = DateTime.tryParse(rawTs);
    }

    return NotificationModel(
      id: doc.id,
      type: data['type'] as String? ?? 'general',
      tableId: data['tableId'] as String? ?? '',
      tableNumber: data['tableNumber'] as String? ?? '',
      orderId: data['orderId'] as String?,
      total: (data['total'] as num?)?.toDouble(),
      reason: data['reason'] as String?,
      recipientRole: data['recipientRole'] as String? ?? 'waiter',
      title: data['title'] as String? ?? '',
      message: data['message'] as String? ?? '',
      status: data['status'] as String? ?? 'unread',
      createdAt: created,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'tableId': tableId,
      'tableNumber': tableNumber,
      'orderId': orderId,
      'total': total,
      'reason': reason,
      'recipientRole': recipientRole,
      'title': title,
      'message': message,
      'status': status,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    };
  }
}
