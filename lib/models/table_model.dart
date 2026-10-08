import 'package:cloud_firestore/cloud_firestore.dart';

enum TableStatus {
  available,
  occupied,
  reserved,
  cleaning;

  static TableStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'occupied':
        return TableStatus.occupied;
      case 'reserved':
        return TableStatus.reserved;
      case 'cleaning':
        return TableStatus.cleaning;
      case 'available':
      default:
        return TableStatus.available;
    }
  }

  String get label {
    switch (this) {
      case TableStatus.available:
        return 'Available';
      case TableStatus.occupied:
        return 'Occupied';
      case TableStatus.reserved:
        return 'Reserved';
      case TableStatus.cleaning:
        return 'Cleaning';
    }
  }
}

class TableModel {
  final String id;
  final String tableNumber;
  final int capacity;
  final TableStatus status;
  final String section;
  final String? currentOrderId;
  final int? guestCount;
  final DateTime? occupiedSince;
  final String? reservationTime;
  final String? reservationName;
  final String? statusNote; // e.g. "Ready now", "Cleaned 5m ago"

  const TableModel({
    required this.id,
    required this.tableNumber,
    required this.capacity,
    this.status = TableStatus.available,
    this.section = 'Main Dining',
    this.currentOrderId,
    this.guestCount,
    this.occupiedSince,
    this.reservationTime,
    this.reservationName,
    this.statusNote,
  });

  factory TableModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return TableModel.fromMap(doc.id, data);
  }

  factory TableModel.fromMap(String id, Map<String, dynamic> data) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return TableModel(
      id: id,
      tableNumber: data['tableNumber'] as String? ?? id,
      capacity: (data['capacity'] as num?)?.toInt() ?? 4,
      status: TableStatus.fromString(data['status'] as String? ?? 'available'),
      section: data['section'] as String? ?? 'Main Dining',
      currentOrderId: data['currentOrderId'] as String?,
      guestCount: (data['guestCount'] as num?)?.toInt(),
      occupiedSince: parseDate(data['occupiedSince']),
      reservationTime: data['reservationTime'] as String?,
      reservationName: data['reservationName'] as String?,
      statusNote: data['statusNote'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'tableNumber': tableNumber,
      'capacity': capacity,
      'status': status.name,
      'section': section,
      'currentOrderId': currentOrderId,
      'guestCount': guestCount,
      'occupiedSince': occupiedSince != null ? Timestamp.fromDate(occupiedSince!) : null,
      'reservationTime': reservationTime,
      'reservationName': reservationName,
      'statusNote': statusNote,
    };
  }

  TableModel copyWith({
    TableStatus? status,
    String? currentOrderId,
    int? guestCount,
    DateTime? occupiedSince,
    String? reservationTime,
    String? reservationName,
    String? statusNote,
  }) {
    return TableModel(
      id: id,
      tableNumber: tableNumber,
      capacity: capacity,
      status: status ?? this.status,
      section: section,
      currentOrderId: currentOrderId ?? this.currentOrderId,
      guestCount: guestCount ?? this.guestCount,
      occupiedSince: occupiedSince ?? this.occupiedSince,
      reservationTime: reservationTime ?? this.reservationTime,
      reservationName: reservationName ?? this.reservationName,
      statusNote: statusNote ?? this.statusNote,
    );
  }
}
