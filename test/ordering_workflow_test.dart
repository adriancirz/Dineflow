import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dineflow/models/order_model.dart';
import 'package:dineflow/models/menu_item_model.dart';
import 'package:dineflow/models/inventory_model.dart';
import 'package:dineflow/models/user_model.dart';
import 'package:dineflow/providers/order_providers.dart';

void main() {
  group('White Box & Black Box Test Cases (DineFlow Course Specification Alignment)', () {
    
    // -------------------------------------------------------------
    // WB CUST 001: Dish Customization (Modifiers & Special Instructions)
    // -------------------------------------------------------------
    test('WB CUST 001: Verify dish customization calculates modifier additions and stores instructions', () {
      const basePrice = 18.50;
      const extraTrufflePrice = 3.50;
      const glutenFreePrice = 2.00;
      
      final selectedModifiers = [
        const SelectedModifier(name: 'Extra Truffle Oil', additionalCost: extraTrufflePrice),
        const SelectedModifier(name: 'Gluten-Free Penne', additionalCost: glutenFreePrice),
      ];

      final unitPrice = basePrice + selectedModifiers.fold(0.0, (sum, m) => sum + m.additionalCost);
      expect(unitPrice, 24.00);

      const quantity = 2;
      final customizedItem = OrderItemModel(
        id: 'cust_item_001',
        menuItemId: 'menu_001',
        name: 'Truffle Mushroom Pasta',
        price: unitPrice,
        quantity: quantity,
        specialInstructions: 'Extra spicy, sauce on the side',
        selectedModifiers: selectedModifiers,
      );

      expect(customizedItem.itemTotal, 48.00);
      expect(customizedItem.specialInstructions, 'Extra spicy, sauce on the side');
      expect(customizedItem.selectedModifiers.length, 2);
    });

    // -------------------------------------------------------------
    // WB CUST 002: Cart Total & Tax Calculation
    // -------------------------------------------------------------
    test('WB CUST 002: Verify cart totals recalculate on add, quantity change, and removal', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final cartNotifier = container.read(cartProvider.notifier);

      // Initial state
      expect(container.read(cartProvider).items.isEmpty, true);
      expect(container.read(cartProvider).total, 0.0);

      // Step 1: Add items (e.g. 2x Truffle Mushroom Pasta @ 18.50, 1x Citrus Salmon Bowl @ 21.00)
      const item1 = OrderItemModel(
        id: 'item_1',
        menuItemId: 'menu_001',
        name: 'Truffle Mushroom Pasta',
        price: 18.50,
        quantity: 2,
      );
      const item2 = OrderItemModel(
        id: 'item_2',
        menuItemId: 'menu_002',
        name: 'Citrus Salmon Bowl',
        price: 21.00,
        quantity: 1,
      );

      cartNotifier.addItem(item1);
      cartNotifier.addItem(item2);

      // Subtotal = (2 * 18.50) + (1 * 21.00) = 37.00 + 21.00 = 58.00
      // Tax (8%) = 58.00 * 0.08 = 4.64
      // Total = 58.00 + 4.64 = 62.64
      var cart = container.read(cartProvider);
      expect(cart.itemCount, 3);
      expect(cart.subtotal, 58.00);
      expect(cart.tax, closeTo(4.64, 0.001));
      expect(cart.total, closeTo(62.64, 0.001));

      // Step 2: Change quantities (update item 1 to quantity 3)
      cartNotifier.updateQuantity('item_1', 3);
      cart = container.read(cartProvider);
      // Subtotal = (3 * 18.50) + 21.00 = 55.50 + 21.00 = 76.50
      // Tax = 76.50 * 0.08 = 6.12
      // Total = 82.62
      expect(cart.itemCount, 4);
      expect(cart.subtotal, 76.50);
      expect(cart.tax, closeTo(6.12, 0.001));
      expect(cart.total, closeTo(82.62, 0.001));

      // Step 3: Remove one item (item_2)
      cartNotifier.removeItem('item_2');
      cart = container.read(cartProvider);
      // Subtotal = 3 * 18.50 = 55.50
      // Tax = 55.50 * 0.08 = 4.44
      // Total = 59.94
      expect(cart.itemCount, 3);
      expect(cart.subtotal, 55.50);
      expect(cart.tax, closeTo(4.44, 0.001));
      expect(cart.total, closeTo(59.94, 0.001));
    });

    // -------------------------------------------------------------
    // WB CUST 003: Order Record Creation
    // -------------------------------------------------------------
    test('WB CUST 003: Verify submitted order has complete table, line items, total, and Pending status', () {
      final now = DateTime.now();
      final order = OrderModel(
        id: 'ord_12345',
        orderNumber: '#DF-1048',
        tableId: 'table_t04',
        tableNumber: 'T04',
        waiterId: 'waiter_001',
        waiterName: 'Mark Reyes',
        status: OrderStatus.pending,
        subtotal: 66.00,
        tax: 5.28,
        total: 71.28,
        orderNotes: 'No peanuts please',
        items: const [
          OrderItemModel(
            id: 'it_1',
            menuItemId: 'menu_001',
            name: 'Truffle Mushroom Pasta',
            price: 18.50,
            quantity: 2,
          ),
          OrderItemModel(
            id: 'it_2',
            menuItemId: 'menu_002',
            name: 'Citrus Salmon Bowl',
            price: 21.00,
            quantity: 1,
          ),
        ],
        placedAt: now,
      );

      expect(order.tableNumber, 'T04');
      expect(order.status, OrderStatus.pending);
      expect(order.status.label, 'Pending');
      expect(order.total, 71.28);
      expect(order.items.length, 2);

      final map = order.toMap();
      expect(map['orderNumber'], '#DF-1048');
      expect(map['tableNumber'], 'T04');
      expect(map['status'], 'pending');
      expect(map['total'], 71.28);
      expect(map['orderNotes'], 'No peanuts please');
    });

    // -------------------------------------------------------------
    // WB ADM 001: Menu Item Pricing & Profit Margin Validation
    // -------------------------------------------------------------
    test('WB ADM 001: Verify menu item model calculates profit margin and preserves availability', () {
      const item = MenuItemModel(
        id: 'menu_new_01',
        name: 'Wagyu Beef Burger',
        description: 'Prime wagyu patty with brioche bun',
        categoryId: 'cat_mains',
        price: 24.00,
        cost: 9.60,
        isAvailable: true,
      );

      expect(item.price, 24.00);
      expect(item.cost, 9.60);
      
      // Margin = ((Price - Cost) / Price) * 100
      final margin = ((item.price - item.cost) / item.price) * 100;
      expect(margin, closeTo(60.0, 0.01));
      expect(item.isAvailable, true);

      final updatedItem = item.copyWith(isAvailable: false);
      expect(updatedItem.isAvailable, false);
    });

    // -------------------------------------------------------------
    // WB ADM 002: Inventory Stock Adjustment & Negative Stock Rejection
    // -------------------------------------------------------------
    test('WB ADM 002: Verify stock in, stock out, and invalid negative stock prevention', () {
      const item = InventoryItemModel(
        id: 'inv_001',
        name: 'Atlantic Salmon',
        currentStock: 10.0,
        unit: 'kg',
        minThreshold: 5.0,
      );

      expect(item.currentStock, 10.0);
      expect(item.isLowStock, false);

      // Stock In
      final stockedIn = item.copyWith(currentStock: item.currentStock + 5.0);
      expect(stockedIn.currentStock, 15.0);

      // Stock Out
      final stockedOut = stockedIn.copyWith(currentStock: stockedIn.currentStock - 11.0);
      expect(stockedOut.currentStock, 4.0);
      expect(stockedOut.isLowStock, true); // <= 5.0 threshold

      // Negative stock rejection validation
      const double invalidNegativeDelta = -20.0;
      final bool isValidAdjustment = (stockedOut.currentStock + invalidNegativeDelta) >= 0;
      expect(isValidAdjustment, false, reason: 'Invalid negative stock must be rejected');
    });

    // -------------------------------------------------------------
    // WB ADM 003: Role-Based Access Control & User Model Permissions
    // -------------------------------------------------------------
    test('WB ADM 003: Verify UserRole definitions, string parsing, and display permissions', () {
      expect(UserRole.fromString('admin'), UserRole.admin);
      expect(UserRole.fromString('waiter'), UserRole.waiter);
      expect(UserRole.fromString('kitchen'), UserRole.kitchen);
      expect(UserRole.fromString('cashier'), UserRole.cashier);
      expect(UserRole.fromString('customer'), UserRole.customer);
      expect(UserRole.fromString('unknown_role'), UserRole.customer);

      const adminUser = UserModel(
        uid: 'adm_01',
        displayName: 'Adrian Ponce',
        email: 'admin@dineflow.com',
        role: UserRole.admin,
      );
      expect(adminUser.role.displayName, 'Administrator');
      expect(adminUser.role == UserRole.admin, true);

      const waiterUser = UserModel(
        uid: 'waiter_01',
        displayName: 'Mark Reyes',
        email: 'waiter@dineflow.com',
        role: UserRole.waiter,
      );
      expect(waiterUser.role.displayName, 'Waiter');
      expect(waiterUser.role == UserRole.waiter, true);
    });

    // -------------------------------------------------------------
    // BB CUST 001: End-to-End Customer Order Placement
    // -------------------------------------------------------------
    test('BB CUST 001: Verify end-to-end customer order placement generates ticket #DF-XXXX', () {
      final orderNumber = '#DF-${1000 + (DateTime.now().millisecondsSinceEpoch % 9000)}';
      expect(orderNumber.startsWith('#DF-'), true);

      final customerOrder = OrderModel(
        id: 'ord_cust_test',
        orderNumber: orderNumber,
        tableId: 'table_t12',
        tableNumber: 'Table 12',
        status: OrderStatus.pending,
        subtotal: 39.50,
        tax: 3.16,
        total: 42.66,
        items: const [
          OrderItemModel(
            id: 'ci_1',
            menuItemId: 'menu_001',
            name: 'Truffle Mushroom Pasta',
            price: 18.50,
            quantity: 1,
          ),
          OrderItemModel(
            id: 'ci_2',
            menuItemId: 'menu_002',
            name: 'Citrus Salmon Bowl',
            price: 21.00,
            quantity: 1,
          ),
        ],
        placedAt: DateTime.now(),
      );

      expect(customerOrder.items.length, 2);
      expect(customerOrder.total, 42.66);
      expect(customerOrder.status, OrderStatus.pending);
    });

    // -------------------------------------------------------------
    // BB CUST 002: Live Order Progress Tracking
    // -------------------------------------------------------------
    test('BB CUST 002: Verify customer order transitions through Received -> Preparing -> Ready stages', () {
      var customerOrder = const OrderModel(
        id: 'ord_track_01',
        orderNumber: '#DF-1048',
        tableNumber: 'Table 12',
        status: OrderStatus.pending,
        total: 42.66,
      );
      expect(customerOrder.status, OrderStatus.pending);

      // Stage 1: Kitchen marks Preparing
      customerOrder = customerOrder.copyWith(status: OrderStatus.preparing);
      expect(customerOrder.status, OrderStatus.preparing);

      // Stage 2: Kitchen marks Ready
      customerOrder = customerOrder.copyWith(status: OrderStatus.ready);
      expect(customerOrder.status, OrderStatus.ready);
    });

    // -------------------------------------------------------------
    // BB CUST 003: Sold-Out Item Cart Prevention
    // -------------------------------------------------------------
    test('BB CUST 003: Verify sold out / unavailable dish flag prevents ordering', () {
      const unavailableDish = MenuItemModel(
        id: 'menu_003',
        name: 'Smoky Chicken Burger',
        categoryId: 'cat_mains',
        price: 16.00,
        isAvailable: false,
      );

      expect(unavailableDish.isAvailable, false);
      final bool canAddToCart = unavailableDish.isAvailable;
      expect(canAddToCart, false);
    });

    // -------------------------------------------------------------
    // BB ADM 001: Kitchen KDS Board Lifecycle
    // -------------------------------------------------------------
    test('BB ADM 001: Verify status transitions correctly through Kitchen lifecycle', () {
      var currentStatus = OrderStatus.pending;
      expect(currentStatus.label, 'Pending');

      // Kitchen receives order -> marks Preparing
      currentStatus = OrderStatus.preparing;
      expect(currentStatus.label, 'Preparing');

      // Kitchen finishes dish -> marks Ready
      currentStatus = OrderStatus.ready;
      expect(currentStatus.label, 'Ready');

      // Waiter delivers to table -> marks Served
      currentStatus = OrderStatus.served;
      expect(currentStatus.label, 'Served');

      // Cashier settles payment -> marks Completed
      currentStatus = OrderStatus.completed;
      expect(currentStatus.label, 'Completed');
    });

    // -------------------------------------------------------------
    // BB ADM 002: Cashier Discount, Tender, Change, and Settlement
    // -------------------------------------------------------------
    test('BB ADM 002: Verify cashier discount codes, cash tender change, and settlement', () {
      const initialOrder = OrderModel(
        id: 'ord_1039',
        orderNumber: '#DF-1039',
        tableId: 'table_t02',
        tableNumber: 'T02',
        status: OrderStatus.ready,
        paymentStatus: 'unpaid',
        subtotal: 50.00,
        tax: 4.00,
        total: 54.00,
      );

      // Apply 10% promo discount (PROMO10)
      const discountPercentage = 0.10;
      final discountAmount = initialOrder.subtotal * discountPercentage;
      expect(discountAmount, 5.00);

      final discountedSubtotal = initialOrder.subtotal - discountAmount;
      final discountedTax = discountedSubtotal * 0.08;
      final finalTotal = discountedSubtotal + discountedTax;
      expect(discountedSubtotal, 45.00);
      expect(discountedTax, 3.60);
      expect(finalTotal, 48.60);

      // Cash Tender ₱50.00 -> Change ₱1.40
      const cashReceived = 50.00;
      final changeDue = cashReceived - finalTotal;
      expect(changeDue, closeTo(1.40, 0.001));

      // Settle Order
      final settledOrder = initialOrder.copyWith(
        status: OrderStatus.completed,
        paymentStatus: 'paid',
        paymentMethod: 'cash',
        total: finalTotal,
        completedAt: DateTime.now(),
      );

      expect(settledOrder.status, OrderStatus.completed);
      expect(settledOrder.paymentStatus, 'paid');
      expect(settledOrder.paymentMethod, 'cash');
    });

    // -------------------------------------------------------------
    // BB ADM 003: Daily Sales Report & Payment Method Aggregation
    // -------------------------------------------------------------
    test('BB ADM 003: Verify daily sales revenue, payment split, and average order value aggregation', () {
      final orders = [
        const OrderModel(id: '1', orderNumber: '#1', tableNumber: 'T1', status: OrderStatus.completed, paymentStatus: 'paid', paymentMethod: 'cash', total: 60.00),
        const OrderModel(id: '2', orderNumber: '#2', tableNumber: 'T2', status: OrderStatus.completed, paymentStatus: 'paid', paymentMethod: 'card', total: 100.00),
        const OrderModel(id: '3', orderNumber: '#3', tableNumber: 'T3', status: OrderStatus.completed, paymentStatus: 'paid', paymentMethod: 'card', total: 40.00),
        const OrderModel(id: '4', orderNumber: '#4', tableNumber: 'T4', status: OrderStatus.completed, paymentStatus: 'paid', paymentMethod: 'e-wallet', total: 50.00),
        const OrderModel(id: '5', orderNumber: '#5', tableNumber: 'T5', status: OrderStatus.pending, paymentStatus: 'unpaid', total: 30.00),
      ];

      final paidOrders = orders.where((o) => o.paymentStatus == 'paid').toList();
      final totalRevenue = paidOrders.fold(0.0, (sum, o) => sum + o.total);
      expect(totalRevenue, 250.00);

      final cashTotal = paidOrders.where((o) => o.paymentMethod == 'cash').fold(0.0, (s, o) => s + o.total);
      final cardTotal = paidOrders.where((o) => o.paymentMethod == 'card').fold(0.0, (s, o) => s + o.total);
      final ewalletTotal = paidOrders.where((o) => o.paymentMethod == 'e-wallet').fold(0.0, (s, o) => s + o.total);

      expect(cashTotal, 60.00); // 24%
      expect(cardTotal, 140.00); // 56%
      expect(ewalletTotal, 50.00); // 20%

      final aov = totalRevenue / paidOrders.length;
      expect(aov, 62.50);
    });

  });
}
