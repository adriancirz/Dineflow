import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/firebase_providers.dart';

/// Service for customer requests (asking for bill, calling waiter).
/// All requests are written to the `notifications` collection for the staff module.
class WaiterRequestService {
  final FirebaseFirestore _firestore;

  WaiterRequestService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Requests the printed bill from the waiter for a specific table and order.
  Future<void> requestBill({
    required String tableId,
    required String tableNumber,
    required String orderId,
    required double total,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'type': 'bill_request',
        'tableId': tableId,
        'tableNumber': tableNumber,
        'orderId': orderId,
        'total': total,
        'recipientRole': 'waiter',
        'title': 'Bill Requested · Table $tableNumber',
        'message': 'Table $tableNumber requested their printed bill (Total: ₱${total.toStringAsFixed(2)}).',
        'status': 'unread',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to request bill from waiter: $e');
    }
  }

  /// Sends a general assistance call to the waiter for a specific table.
  Future<void> callWaiter({
    required String tableId,
    required String tableNumber,
    String? reason,
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'type': 'waiter_call',
        'tableId': tableId,
        'tableNumber': tableNumber,
        'reason': reason ?? 'Assistance requested',
        'recipientRole': 'waiter',
        'title': 'Service Call · Table $tableNumber',
        'message': 'Guest at Table $tableNumber requested assistance${reason != null && reason.isNotEmpty ? ": $reason" : "."}',
        'status': 'unread',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to call waiter: $e');
    }
  }

  /// Sends a message/call/alert from waiter or staff directly to a specific customer table.
  Future<void> notifyCustomer({
    required String tableId,
    required String tableNumber,
    required String title,
    required String message,
    String? orderId,
    String type = 'staff_call',
  }) async {
    try {
      await _firestore.collection('notifications').add({
        'type': type,
        'tableId': tableId,
        'tableNumber': tableNumber,
        'orderId': ?orderId,
        'recipientRole': 'customer',
        'title': title,
        'message': message,
        'status': 'unread',
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to notify customer: $e');
    }
  }
}

final waiterRequestServiceProvider = Provider<WaiterRequestService>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return WaiterRequestService(firestore: firestore);
});
