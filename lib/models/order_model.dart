import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pending,
  preparing,
  ready,
  served,
  completed,
  cancelled;

  static OrderStatus fromString(String val) {
    switch (val.toLowerCase()) {
      case 'preparing':
        return OrderStatus.preparing;
      case 'ready':
        return OrderStatus.ready;
      case 'served':
        return OrderStatus.served;
      case 'completed':
      case 'done':
        return OrderStatus.completed;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'pending':
      default:
        return OrderStatus.pending;
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.pending:
        return 'Pending';
      case OrderStatus.preparing:
        return 'Preparing';
      case OrderStatus.ready:
        return 'Ready';
      case OrderStatus.served:
        return 'Served';
      case OrderStatus.completed:
        return 'Completed';
      case OrderStatus.cancelled:
        return 'Cancelled';
    }
  }
}

class SelectedModifier {
  final String name;
  final double additionalCost;

  const SelectedModifier({
    required this.name,
    this.additionalCost = 0.0,
  });

  factory SelectedModifier.fromMap(Map<String, dynamic> data) {
    return SelectedModifier(
      name: data['name'] as String? ?? '',
      additionalCost: (data['additionalCost'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'additionalCost': additionalCost,
    };
  }
}

class OrderItemModel {
  final String id;
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final String? notes;
  final String? specialInstructions;
  final List<SelectedModifier> selectedModifiers;
  final Map<String, dynamic>? selectedOptions;
  final String status; // 'pending', 'preparing', 'ready'

  const OrderItemModel({
    required this.id,
    required this.menuItemId,
    required this.name,
    required this.price,
    this.quantity = 1,
    this.notes,
    this.specialInstructions,
    this.selectedModifiers = const [],
    this.selectedOptions,
    this.status = 'pending',
  });

  double get itemTotal => price * quantity;
  double get totalPrice => itemTotal;

  factory OrderItemModel.fromMap(String id, Map<String, dynamic> data) {
    return OrderItemModel(
      id: id,
      menuItemId: data['menuItemId'] as String? ?? '',
      name: data['name'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      notes: data['notes'] as String?,
      specialInstructions: data['specialInstructions'] as String?,
      selectedModifiers: (data['selectedModifiers'] as List<dynamic>?)
              ?.map((m) => SelectedModifier.fromMap(m as Map<String, dynamic>))
              .toList() ??
          [],
      selectedOptions: data['selectedOptions'] as Map<String, dynamic>?,
      status: data['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'notes': notes,
      'specialInstructions': specialInstructions,
      'selectedModifiers': selectedModifiers.map((m) => m.toMap()).toList(),
      'selectedOptions': selectedOptions,
      'status': status,
    };
  }

  OrderItemModel copyWith({
    int? quantity,
    String? notes,
    String? specialInstructions,
    List<SelectedModifier>? selectedModifiers,
    String? status,
  }) {
    return OrderItemModel(
      id: id,
      menuItemId: menuItemId,
      name: name,
      price: price,
      quantity: quantity ?? this.quantity,
      notes: notes ?? this.notes,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      selectedModifiers: selectedModifiers ?? this.selectedModifiers,
      selectedOptions: selectedOptions,
      status: status ?? this.status,
    );
  }
}

class OrderModel {
  final String id;
  final String orderNumber; // e.g. "#DF-1048"
  final String tableId;
  final String tableNumber;
  final String waiterId;
  final String waiterName;
  final OrderStatus status;
  final String paymentStatus; // 'unpaid', 'paid', 'refunded'
  final String? paymentMethod; // 'cash', 'card', 'ewallet'
  final double subtotal;
  final double tax;
  final double discount;
  final double serviceCharge;
  final double total;
  final String? orderNotes;
  final String? customerId;
  final String? customerName;
  final int? guestCount;
  final String orderType; // 'dine_in', 'takeout', etc.
  final List<OrderItemModel> items;
  final DateTime? placedAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;

  String? get specialInstructions => orderNotes;

  const OrderModel({
    required this.id,
    required this.orderNumber,
    this.customerId,
    this.customerName,
    this.guestCount,
    this.orderType = 'dine_in',
    this.tableId = '',
    required this.tableNumber,
    this.waiterId = '',
    this.waiterName = '',
    this.status = OrderStatus.pending,
    this.paymentStatus = 'unpaid',
    this.paymentMethod,
    this.subtotal = 0.0,
    this.tax = 0.0,
    this.discount = 0.0,
    this.serviceCharge = 0.0,
    required this.total,
    this.orderNotes,
    this.items = const [],
    this.placedAt,
    this.updatedAt,
    this.completedAt,
  });

  factory OrderModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc, [
    List<OrderItemModel>? loadedItems,
  ]) {
    final data = doc.data() ?? {};
    return OrderModel.fromMap(doc.id, data, loadedItems);
  }

  factory OrderModel.fromMap(
    String id,
    Map<String, dynamic> data, [
    List<OrderItemModel>? loadedItems,
  ]) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    return OrderModel(
      id: id,
      orderNumber: data['orderNumber'] as String? ?? '#DF-${id.substring(0, 4)}',
      customerId: data['customerId'] as String?,
      customerName: data['customerName'] as String?,
      guestCount: (data['guestCount'] as num?)?.toInt(),
      orderType: data['orderType'] as String? ?? 'dine_in',
      tableId: data['tableId'] as String? ?? '',
      tableNumber: data['tableNumber'] as String? ?? '',
      waiterId: data['waiterId'] as String? ?? '',
      waiterName: data['waiterName'] as String? ?? '',
      status: OrderStatus.fromString(data['status'] as String? ?? 'pending'),
      paymentStatus: data['paymentStatus'] as String? ?? 'unpaid',
      paymentMethod: data['paymentMethod'] as String?,
      subtotal: (data['subtotal'] as num?)?.toDouble() ?? 0.0,
      tax: (data['tax'] as num?)?.toDouble() ?? 0.0,
      discount: (data['discount'] as num?)?.toDouble() ?? 0.0,
      serviceCharge: (data['serviceCharge'] as num?)?.toDouble() ?? 0.0,
      total: (data['total'] as num?)?.toDouble() ?? 0.0,
      orderNotes: (data['orderNotes'] ?? data['specialInstructions']) as String?,
      items: loadedItems ?? [],
      placedAt: parseDate(data['placedAt']),
      updatedAt: parseDate(data['updatedAt']),
      completedAt: parseDate(data['completedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderNumber': orderNumber,
      'customerId': customerId,
      'customerName': customerName,
      'guestCount': guestCount,
      'orderType': orderType,
      'tableId': tableId,
      'tableNumber': tableNumber,
      'waiterId': waiterId,
      'waiterName': waiterName,
      'status': status.name,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'subtotal': subtotal,
      'tax': tax,
      'discount': discount,
      'serviceCharge': serviceCharge,
      'total': total,
      'orderNotes': orderNotes,
      'specialInstructions': orderNotes,
      'placedAt': placedAt != null ? Timestamp.fromDate(placedAt!) : FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  OrderModel copyWith({
    String? customerId,
    String? customerName,
    int? guestCount,
    String? orderType,
    OrderStatus? status,
    String? paymentStatus,
    String? paymentMethod,
    double? subtotal,
    double? tax,
    double? discount,
    double? serviceCharge,
    double? total,
    String? orderNotes,
    List<OrderItemModel>? items,
    DateTime? completedAt,
  }) {
    return OrderModel(
      id: id,
      orderNumber: orderNumber,
      customerId: customerId ?? this.customerId,
      customerName: customerName ?? this.customerName,
      guestCount: guestCount ?? this.guestCount,
      orderType: orderType ?? this.orderType,
      tableId: tableId,
      tableNumber: tableNumber,
      waiterId: waiterId,
      waiterName: waiterName,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      discount: discount ?? this.discount,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      total: total ?? this.total,
      orderNotes: orderNotes ?? this.orderNotes,
      items: items ?? this.items,
      placedAt: placedAt,
      updatedAt: updatedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
