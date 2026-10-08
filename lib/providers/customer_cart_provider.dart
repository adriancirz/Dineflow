import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_item_model.dart';
import '../models/order_model.dart';

/// Single item in the customer's ordering cart.
class CustomerCartItem {
  final String id;
  final MenuItemModel item;
  final int quantity;
  final String? specialInstructions;
  final List<SelectedModifier> selectedModifiers;

  const CustomerCartItem({
    required this.id,
    required this.item,
    this.quantity = 1,
    this.specialInstructions,
    this.selectedModifiers = const [],
  });

  double get unitPrice {
    final modSum = selectedModifiers.fold(0.0, (sum, m) => sum + m.additionalCost);
    return item.price + modSum;
  }

  double get lineTotal => unitPrice * quantity;

  CustomerCartItem copyWith({
    int? quantity,
    String? specialInstructions,
    List<SelectedModifier>? selectedModifiers,
  }) {
    return CustomerCartItem(
      id: id,
      item: item,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      selectedModifiers: selectedModifiers ?? this.selectedModifiers,
    );
  }
}

/// Cart state calculating Philippine restaurant standards:
/// Subtotal + 12% VAT + 10% Service Charge = Total.
class CustomerCartState {
  final List<CustomerCartItem> items;
  final String? orderNotes;

  const CustomerCartState({
    this.items = const [],
    this.orderNotes,
  });

  int get itemCount => items.fold(0, (sum, it) => sum + it.quantity);

  double get subtotal => items.fold(0.0, (sum, it) => sum + it.lineTotal);

  /// Standard Philippine VAT: 12%
  double get tax => subtotal * 0.12;

  /// Standard Philippine Dine-In Service Charge: 10%
  double get serviceCharge => subtotal * 0.10;

  double get total => subtotal + tax + serviceCharge;

  bool get isEmpty => items.isEmpty;

  CustomerCartState copyWith({
    List<CustomerCartItem>? items,
    String? orderNotes,
  }) {
    return CustomerCartState(
      items: items ?? this.items,
      orderNotes: orderNotes ?? this.orderNotes,
    );
  }
}

class CustomerCartNotifier extends Notifier<CustomerCartState> {
  @override
  CustomerCartState build() => const CustomerCartState();

  void addItem({
    required MenuItemModel item,
    int quantity = 1,
    String? specialInstructions,
    List<SelectedModifier>? modifiers,
  }) {
    if (quantity <= 0) return;

    final existingIndex = state.items.indexWhere(
      (it) =>
          it.item.id == item.id &&
          it.specialInstructions == specialInstructions &&
          it.selectedModifiers.length == (modifiers?.length ?? 0),
    );

    if (existingIndex >= 0) {
      final existing = state.items[existingIndex];
      final updatedList = List<CustomerCartItem>.from(state.items);
      updatedList[existingIndex] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
      state = state.copyWith(items: updatedList);
    } else {
      final newItem = CustomerCartItem(
        id: '${item.id}_${DateTime.now().millisecondsSinceEpoch}',
        item: item,
        quantity: quantity,
        specialInstructions: specialInstructions,
        selectedModifiers: modifiers ?? const [],
      );
      state = state.copyWith(items: [...state.items, newItem]);
    }
  }

  void updateQuantity(String id, int quantity) {
    if (quantity <= 0) {
      removeItem(id);
      return;
    }

    final updated = state.items.map((it) {
      if (it.id == id) {
        return it.copyWith(quantity: quantity);
      }
      return it;
    }).toList();

    state = state.copyWith(items: updated);
  }

  void removeItem(String id) {
    state = state.copyWith(
      items: state.items.where((it) => it.id != id).toList(),
    );
  }

  void setOrderNotes(String notes) {
    state = state.copyWith(orderNotes: notes);
  }

  void clearCart() {
    state = const CustomerCartState();
  }
}

final customerCartProvider =
    NotifierProvider<CustomerCartNotifier, CustomerCartState>(CustomerCartNotifier.new);
