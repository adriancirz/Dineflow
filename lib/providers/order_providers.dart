import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/order_model.dart';
import '../models/table_model.dart';
import 'firebase_providers.dart';

/// Stream of all orders (ordered by placedAt descending)
final ordersStreamProvider = StreamProvider<List<OrderModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore
      .collection('orders')
      .orderBy('placedAt', descending: true)
      .snapshots()
      .asyncMap((snapshot) async {
    final List<OrderModel> orders = [];
    for (final doc in snapshot.docs) {
      // Fetch items subcollection
      final itemsSnap = await doc.reference.collection('items').get();
      final items = itemsSnap.docs
          .map((itemDoc) => OrderItemModel.fromMap(itemDoc.id, itemDoc.data()))
          .toList();
      orders.add(OrderModel.fromFirestore(doc, items));
    }
    return orders;
  });
});

/// Stream a single order by ID with its subcollection items
final orderByIdProvider = StreamProvider.family<OrderModel?, String>((ref, orderId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('orders').doc(orderId).snapshots().asyncMap((doc) async {
    if (!doc.exists) return null;
    final itemsSnap = await doc.reference.collection('items').get();
    final items = itemsSnap.docs
        .map((itemDoc) => OrderItemModel.fromMap(itemDoc.id, itemDoc.data()))
        .toList();
    return OrderModel.fromFirestore(doc, items);
  });
});

/// Kitchen Display System (KDS) orders: pending, preparing, ready
final kitchenOrdersProvider = Provider<List<OrderModel>>((ref) {
  final ordersAsync = ref.watch(ordersStreamProvider);
  return ordersAsync.maybeWhen(
    data: (orders) => orders.where((o) =>
        o.status == OrderStatus.pending ||
        o.status == OrderStatus.preparing ||
        o.status == OrderStatus.ready).toList(),
    orElse: () => [],
  );
});

/// Cashier Payment Queue: orders ready for payment or completed dining
final cashierPaymentQueueProvider = Provider<List<OrderModel>>((ref) {
  final ordersAsync = ref.watch(ordersStreamProvider);
  return ordersAsync.maybeWhen(
    data: (orders) => orders
        .where((o) => o.paymentStatus == 'unpaid' && o.status != OrderStatus.cancelled)
        .toList(),
    orElse: () => [],
  );
});

/// Waiter active orders
final waiterActiveOrdersProvider = Provider.family<List<OrderModel>, String?>((ref, waiterId) {
  final ordersAsync = ref.watch(ordersStreamProvider);
  return ordersAsync.maybeWhen(
    data: (orders) {
      var filtered = orders.where((o) =>
          o.status != OrderStatus.completed && o.status != OrderStatus.cancelled);
      if (waiterId != null && waiterId.isNotEmpty) {
        filtered = filtered.where((o) => o.waiterId == waiterId);
      }
      return filtered.toList();
    },
    orElse: () => [],
  );
});

/// In-memory Order Cart state for waiter or customer creating an order
class CartState {
  final String? tableId;
  final String? tableNumber;
  final List<OrderItemModel> items;
  final String? orderNote;

  const CartState({
    this.tableId,
    this.tableNumber,
    this.items = const [],
    this.orderNote,
  });

  int get itemCount => items.fold(0, (totalAcc, i) => totalAcc + i.quantity);

  double get subtotal => items.fold(0.0, (totalAcc, i) => totalAcc + i.totalPrice);
  double get tax => subtotal * 0.08;
  double get total => subtotal + tax;

  CartState copyWith({
    String? tableId,
    String? tableNumber,
    List<OrderItemModel>? items,
    String? orderNote,
  }) {
    return CartState(
      tableId: tableId ?? this.tableId,
      tableNumber: tableNumber ?? this.tableNumber,
      items: items ?? this.items,
      orderNote: orderNote ?? this.orderNote,
    );
  }
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() => const CartState();

  void setTable(String tableId, String tableNumber) {
    state = state.copyWith(tableId: tableId, tableNumber: tableNumber);
  }

  void addItem(OrderItemModel item) {
    final existingIndex = state.items.indexWhere((i) =>
        i.menuItemId == item.menuItemId && i.notes == item.notes);

    if (existingIndex >= 0) {
      final updated = List<OrderItemModel>.from(state.items);
      final current = updated[existingIndex];
      updated[existingIndex] = current.copyWith(quantity: current.quantity + item.quantity);
      state = state.copyWith(items: updated);
    } else {
      state = state.copyWith(items: [...state.items, item]);
    }
  }

  void updateQuantity(String itemId, int newQuantity) {
    if (newQuantity <= 0) {
      removeItem(itemId);
      return;
    }
    final updated = state.items.map((i) {
      if (i.id == itemId) {
        return i.copyWith(quantity: newQuantity);
      }
      return i;
    }).toList();
    state = state.copyWith(items: updated);
  }

  void removeItem(String itemId) {
    state = state.copyWith(
      items: state.items.where((i) => i.id != itemId).toList(),
    );
  }

  void setNote(String note) {
    state = state.copyWith(orderNote: note);
  }

  void clearCart() {
    state = const CartState();
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return OrderRepository(firestore);
});

class OrderRepository {
  final FirebaseFirestore _firestore;
  OrderRepository(this._firestore);

  Future<OrderModel> createOrder({
    required CartState cart,
    required String waiterId,
    required String waiterName,
    int guestCount = 2,
  }) async {
    final randNum = 1000 + (DateTime.now().millisecondsSinceEpoch % 9000);
    final orderNumber = '#DF-$randNum';

    final orderDoc = _firestore.collection('orders').doc();
    final orderId = orderDoc.id;

    final orderData = {
      'orderNumber': orderNumber,
      'tableId': cart.tableId ?? '',
      'tableNumber': cart.tableNumber ?? 'T01',
      'waiterId': waiterId,
      'waiterName': waiterName,
      'status': OrderStatus.pending.name,
      'paymentStatus': 'unpaid',
      'paymentMethod': null,
      'subtotal': cart.subtotal,
      'tax': cart.tax,
      'discount': 0.0,
      'serviceCharge': 0.0,
      'total': cart.total,
      'orderNotes': cart.orderNote,
      'placedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'completedAt': null,
    };

    await orderDoc.set(orderData);

    for (final item in cart.items) {
      final itemDoc = orderDoc.collection('items').doc();
      await itemDoc.set(item.toMap());
    }

    if (cart.tableId != null && cart.tableId!.isNotEmpty) {
      await _firestore.collection('tables').doc(cart.tableId).set({
        'status': TableStatus.occupied.name,
        'currentOrderId': orderId,
        'occupiedSince': FieldValue.serverTimestamp(),
        'guestCount': guestCount,
      }, SetOptions(merge: true));
    }

    return OrderModel.fromMap(orderId, orderData, cart.items);
  }

  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final updateData = <String, dynamic>{
      'status': newStatus.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (newStatus == OrderStatus.completed) {
      updateData['completedAt'] = FieldValue.serverTimestamp();
      updateData['paymentStatus'] = 'paid';
    }
    await _firestore.collection('orders').doc(orderId).update(updateData);

    if (newStatus == OrderStatus.completed || newStatus == OrderStatus.cancelled) {
      final snap = await _firestore.collection('orders').doc(orderId).get();
      final tableId = snap.data()?['tableId'] as String?;
      if (tableId != null && tableId.isNotEmpty) {
        await _firestore.collection('tables').doc(tableId).set({
          'status': TableStatus.available.name,
          'currentOrderId': null,
          'occupiedSince': null,
          'statusNote': 'Ready now',
        }, SetOptions(merge: true));
      }
    }
  }

  Future<void> recordPayment({
    required String orderId,
    required String paymentMethod,
    required double amountTendered,
    required double change,
    double discount = 0.0,
  }) async {
    final snap = await _firestore.collection('orders').doc(orderId).get();
    final data = snap.data() ?? {};
    final subtotal = (data['subtotal'] as num?)?.toDouble() ?? 0.0;
    final tax = (data['tax'] as num?)?.toDouble() ?? 0.0;
    final finalTotal = (subtotal + tax) - discount;

    final updateData = <String, dynamic>{
      'paymentStatus': 'paid',
      'paymentMethod': paymentMethod,
      'discount': discount,
      'total': finalTotal > 0 ? finalTotal : 0.0,
      'status': OrderStatus.completed.name,
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'amountTendered': amountTendered,
      'change': change,
    };
    await _firestore.collection('orders').doc(orderId).update(updateData);

    final tableId = data['tableId'] as String?;
    if (tableId != null && tableId.isNotEmpty) {
      await _firestore.collection('tables').doc(tableId).set({
        'status': TableStatus.available.name,
        'currentOrderId': null,
        'occupiedSince': null,
        'statusNote': 'Ready now',
      }, SetOptions(merge: true));
    }
  }
}
