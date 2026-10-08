import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/inventory_model.dart';
import 'firebase_providers.dart';

/// Stream of all inventory items
final inventoryStreamProvider = StreamProvider<List<InventoryItemModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('inventory').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => InventoryItemModel.fromFirestore(doc)).toList();
  });
});

/// Count of items with stock at or below minimum threshold
final lowStockItemsCountProvider = Provider<int>((ref) {
  final itemsAsync = ref.watch(inventoryStreamProvider);
  return itemsAsync.maybeWhen(
    data: (items) => items.where((i) => i.isLowStock).length,
    orElse: () => 0,
  );
});

final inventoryRepositoryProvider = Provider<InventoryRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return InventoryRepository(firestore);
});

class InventoryRepository {
  final FirebaseFirestore _firestore;
  InventoryRepository(this._firestore);

  Future<void> adjustStock({
    required String itemId,
    required double delta,
    required String reason,
    required String adjustedBy,
  }) async {
    final docRef = _firestore.collection('inventory').doc(itemId);
    final adjustmentRef = docRef.collection('adjustments').doc();

    await _firestore.runTransaction((transaction) async {
      final snap = await transaction.get(docRef);
      if (!snap.exists) {
        throw StateError('Inventory item $itemId no longer exists.');
      }

      final current = (snap.data()?['currentStock'] as num?)?.toDouble() ?? 0.0;
      final newStock = current + delta;
      if (newStock < 0) {
        throw ArgumentError('Stock cannot be negative.');
      }

      transaction.update(docRef, {
        'currentStock': newStock,
        'lastRestockedAt': FieldValue.serverTimestamp(),
      });
      transaction.set(adjustmentRef, {
        'itemId': itemId,
        'quantityChange': delta,
        'reason': reason,
        'adjustedBy': adjustedBy,
        'timestamp': FieldValue.serverTimestamp(),
      });
    });
  }

  Future<void> addInventoryItem(InventoryItemModel item) async {
    await _firestore.collection('inventory').doc(item.id.isEmpty ? null : item.id).set(item.toMap());
  }

  Future<void> updateInventoryItem(InventoryItemModel item) async {
    await _firestore.collection('inventory').doc(item.id).update(item.toMap());
  }
}
