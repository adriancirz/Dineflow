import 'package:cloud_firestore/cloud_firestore.dart';

class InventoryItemModel {
  final String id;
  final String name;
  final String sku;
  final String category;
  final double currentStock;
  final String unit;
  final double minThreshold;
  final double costPerUnit;
  final String supplier;
  final DateTime? lastRestockedAt;

  const InventoryItemModel({
    required this.id,
    required this.name,
    this.sku = '',
    this.category = 'General',
    required this.currentStock,
    this.unit = 'units',
    this.minThreshold = 5.0,
    this.costPerUnit = 0.0,
    this.supplier = '',
    this.lastRestockedAt,
  });

  bool get isLowStock => currentStock <= minThreshold;

  factory InventoryItemModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return InventoryItemModel.fromMap(doc.id, data);
  }

  factory InventoryItemModel.fromMap(String id, Map<String, dynamic> data) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return InventoryItemModel(
      id: id,
      name: data['name'] as String? ?? '',
      sku: data['sku'] as String? ?? '',
      category: data['category'] as String? ?? 'General',
      currentStock: (data['currentStock'] as num?)?.toDouble() ?? 0.0,
      unit: data['unit'] as String? ?? 'units',
      minThreshold: (data['minThreshold'] as num?)?.toDouble() ?? 5.0,
      costPerUnit: (data['costPerUnit'] as num?)?.toDouble() ?? 0.0,
      supplier: data['supplier'] as String? ?? '',
      lastRestockedAt: parseDate(data['lastRestockedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'sku': sku,
      'category': category,
      'currentStock': currentStock,
      'unit': unit,
      'minThreshold': minThreshold,
      'costPerUnit': costPerUnit,
      'supplier': supplier,
      'lastRestockedAt': lastRestockedAt != null ? Timestamp.fromDate(lastRestockedAt!) : null,
    };
  }

  InventoryItemModel copyWith({
    String? id,
    String? name,
    String? sku,
    String? category,
    double? currentStock,
    String? unit,
    double? minThreshold,
    double? costPerUnit,
    String? supplier,
    DateTime? lastRestockedAt,
  }) {
    return InventoryItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      currentStock: currentStock ?? this.currentStock,
      unit: unit ?? this.unit,
      minThreshold: minThreshold ?? this.minThreshold,
      costPerUnit: costPerUnit ?? this.costPerUnit,
      supplier: supplier ?? this.supplier,
      lastRestockedAt: lastRestockedAt ?? this.lastRestockedAt,
    );
  }
}

class InventoryAdjustmentModel {
  final String id;
  final String itemId;
  final String itemName;
  final double quantityChange;
  final String reason; // 'restock', 'spoilage', 'usage', 'manual'
  final String adjustedBy;
  final DateTime timestamp;

  const InventoryAdjustmentModel({
    required this.id,
    required this.itemId,
    required this.itemName,
    required this.quantityChange,
    required this.reason,
    required this.adjustedBy,
    required this.timestamp,
  });

  factory InventoryAdjustmentModel.fromMap(String id, Map<String, dynamic> data) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return InventoryAdjustmentModel(
      id: id,
      itemId: data['itemId'] as String? ?? '',
      itemName: data['itemName'] as String? ?? '',
      quantityChange: (data['quantityChange'] as num?)?.toDouble() ?? 0.0,
      reason: data['reason'] as String? ?? 'manual',
      adjustedBy: data['adjustedBy'] as String? ?? '',
      timestamp: parseDate(data['timestamp']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'quantityChange': quantityChange,
      'reason': reason,
      'adjustedBy': adjustedBy,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
