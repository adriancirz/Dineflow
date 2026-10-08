import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notification_model.dart';
import 'firebase_providers.dart';

final waiterNotificationsStreamProvider = StreamProvider<List<NotificationModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('notifications').snapshots().map((snapshot) {
    final list = snapshot.docs
        .map((doc) => NotificationModel.fromFirestore(doc))
        .where((n) => n.recipientRole == 'waiter' || n.recipientRole == 'all')
        .toList();
    list.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return list;
  });
});

final customerNotificationsStreamProvider =
    StreamProvider.family<List<NotificationModel>, String>((ref, tableNumber) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('notifications').snapshots().map((snapshot) {
    final list = snapshot.docs
        .map((doc) => NotificationModel.fromFirestore(doc))
        .where((n) {
          final isCustomer = n.recipientRole == 'customer' || n.recipientRole == 'all';
          final matchTable = n.tableNumber == tableNumber || n.tableId == tableNumber;
          return isCustomer && matchTable;
        })
        .toList();
    list.sort((a, b) {
      final aDate = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      final bDate = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
      return bDate.compareTo(aDate);
    });
    return list;
  });
});

final unreadWaiterNotificationsCountProvider = Provider<int>((ref) {
  final notifications = ref.watch(waiterNotificationsStreamProvider).asData?.value ?? [];
  return notifications.where((n) => n.status == 'unread').length;
});

final unreadNotificationsByTableProvider = Provider<Map<String, int>>((ref) {
  final notifications = ref.watch(waiterNotificationsStreamProvider).asData?.value ?? [];
  final map = <String, int>{};
  for (final n in notifications) {
    if (n.status == 'unread' && n.tableNumber.isNotEmpty) {
      map[n.tableNumber] = (map[n.tableNumber] ?? 0) + 1;
    }
  }
  return map;
});

class NotificationActions {
  final Ref _ref;

  NotificationActions(this._ref);

  Future<void> markAsRead(String notificationId) async {
    final firestore = _ref.read(firestoreProvider);
    try {
      await firestore.collection('notifications').doc(notificationId).update({
        'status': 'read',
      });
    } catch (_) {}
  }

  Future<void> dismiss(String notificationId) async {
    final firestore = _ref.read(firestoreProvider);
    try {
      await firestore.collection('notifications').doc(notificationId).delete();
    } catch (_) {}
  }

  Future<void> clearAll() async {
    final firestore = _ref.read(firestoreProvider);
    final notifications = _ref.read(waiterNotificationsStreamProvider).asData?.value ?? [];
    for (final notif in notifications) {
      try {
        await firestore.collection('notifications').doc(notif.id).delete();
      } catch (_) {}
    }
  }
}

final notificationActionsProvider = Provider<NotificationActions>((ref) {
  return NotificationActions(ref);
});
