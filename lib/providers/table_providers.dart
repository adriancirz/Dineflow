import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/table_model.dart';
import 'firebase_providers.dart';

bool _shouldPreferTable(TableModel candidate, TableModel existing) {
  if (candidate.currentOrderId != null && existing.currentOrderId == null) return true;
  if (candidate.status != TableStatus.available && existing.status == TableStatus.available) return true;
  if (candidate.guestCount != null &&
      (existing.guestCount == null || candidate.guestCount! > existing.guestCount!)) {
    return true;
  }
  final candidateKey = candidate.tableNumber.trim().toUpperCase();
  final existingKey = existing.tableNumber.trim().toUpperCase();
  if (candidate.id.toUpperCase() == candidateKey && existing.id.toUpperCase() != candidateKey) {
    return true;
  }
  if (candidateKey == existingKey && candidate.id.toUpperCase() != existing.id.toUpperCase()) {
    return candidate.section.isNotEmpty && existing.section.isEmpty;
  }
  return false;
}

List<TableModel> deduplicateTables(List<TableModel> tables) {
  final uniqueTables = <String, TableModel>{};

  for (final table in tables) {
    final key = table.tableNumber.trim().toUpperCase();
    if (key.isEmpty) continue;

    final existing = uniqueTables[key];
    if (existing == null) {
      uniqueTables[key] = table;
      continue;
    }

    if (_shouldPreferTable(table, existing)) {
      uniqueTables[key] = table;
    }
  }

  final deduplicated = uniqueTables.values.toList();
  deduplicated.sort((a, b) => a.tableNumber.compareTo(b.tableNumber));
  return deduplicated;
}

/// Stream of all tables ordered by tableNumber (deduplicated by tableNumber)
final tablesStreamProvider = StreamProvider<List<TableModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('tables').snapshots().map((snapshot) {
    final tables = snapshot.docs.map(TableModel.fromFirestore).toList();
    return deduplicateTables(tables);
  });
});

/// Single table stream by ID
final singleTableStreamProvider = StreamProvider.family<TableModel?, String>((ref, tableId) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('tables').doc(tableId).snapshots().map((snapshot) {
    if (!snapshot.exists || snapshot.data() == null) return null;
    return TableModel.fromFirestore(snapshot);
  });
});

/// Summary count of tables by status
class TableCounts {
  final int total;
  final int available;
  final int occupied;
  final int reserved;

  const TableCounts({
    this.total = 0,
    this.available = 0,
    this.occupied = 0,
    this.reserved = 0,
  });
}

final tableCountsProvider = Provider<TableCounts>((ref) {
  final tablesAsync = ref.watch(tablesStreamProvider);
  return tablesAsync.maybeWhen(
    data: (tables) {
      int avail = 0;
      int occ = 0;
      int res = 0;
      for (final t in tables) {
        if (t.status == TableStatus.available) avail++;
        if (t.status == TableStatus.occupied) occ++;
        if (t.status == TableStatus.reserved) res++;
      }
      return TableCounts(
        total: tables.length,
        available: avail,
        occupied: occ,
        reserved: res,
      );
    },
    orElse: () => const TableCounts(),
  );
});

final tableRepositoryProvider = Provider<TableRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return TableRepository(firestore);
});

class TableRepository {
  final FirebaseFirestore _firestore;
  TableRepository(this._firestore);

  Future<void> updateTableStatus(
    String tableId,
    TableStatus status, {
    String? note,
    int? guestCount,
    String? currentOrderId,
  }) async {
    final data = <String, dynamic>{
      'status': status.name,
      if (note != null) ...{'statusNote': note},
      if (guestCount != null) ...{'guestCount': guestCount},
      if (currentOrderId != null) ...{'currentOrderId': currentOrderId},
    };
    if (status == TableStatus.available) {
      data['currentOrderId'] = null;
      data['occupiedSince'] = null;
      data['guestCount'] = null;
      data['statusNote'] = note ?? 'Ready now';
    } else if (status == TableStatus.occupied) {
      data['occupiedSince'] = FieldValue.serverTimestamp();
    }
    await _firestore.collection('tables').doc(tableId).set(data, SetOptions(merge: true));
  }
}
