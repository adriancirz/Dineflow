import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_providers.dart';
import '../../widgets/dineflow_logo.dart';

class CashierHomeScreen extends ConsumerStatefulWidget {
  const CashierHomeScreen({super.key});

  @override
  ConsumerState<CashierHomeScreen> createState() => _CashierHomeScreenState();
}

class _CashierHomeScreenState extends ConsumerState<CashierHomeScreen> {
  OrderModel? _selectedOrder;
  int _currentStep = 0; // 0 = Queue, 1 = Itemized Bill, 2 = Payment Method, 3 = Confirmation / Receipt

  // Payment states
  String _selectedPaymentMethod =
      'Cash'; // 'Cash', 'GCash', 'Maya', 'Card', 'Bank Transfer'
  final TextEditingController _cashTenderedController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _referenceNoController = TextEditingController();
  double _appliedDiscount = 0.0;
  double _amountTendered = 0.0;
  double _changeDue = 0.0;

  @override
  void dispose() {
    _cashTenderedController.dispose();
    _discountController.dispose();
    _referenceNoController.dispose();
    super.dispose();
  }

  void _selectOrder(OrderModel order) {
    setState(() {
      _selectedOrder = order;
      _currentStep = 1; // Open bill
      _appliedDiscount = 0.0;
      _discountController.clear();
      _referenceNoController.clear();
      _amountTendered = order.total;
      _cashTenderedController.text = order.total.toStringAsFixed(2);
      _changeDue = 0.0;
    });
  }

  void _applyDiscount() {
    final code = _discountController.text.trim().toUpperCase();
    if (code == 'STAFF10' || code == 'PROMO10') {
      if (_selectedOrder != null) {
        setState(() {
          _appliedDiscount = _selectedOrder!.subtotal * 0.10;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('10% discount applied!'),
            backgroundColor: AppColors.available,
          ),
        );
      }
    } else if (code == 'VIP50' || code == 'VIP5') {
      setState(() {
        _appliedDiscount = code == 'VIP50' ? 50.0 : 5.0;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '₱${_appliedDiscount.toStringAsFixed(2)} discount applied!',
          ),
          backgroundColor: AppColors.available,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid promo code (Try PROMO10 or VIP50)'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  double get _finalTotal {
    if (_selectedOrder == null) return 0.0;
    final tot =
        _selectedOrder!.subtotal + _selectedOrder!.tax - _appliedDiscount;
    return tot > 0 ? tot : 0.0;
  }

  void _calculateChange(String val) {
    final tendered = double.tryParse(val) ?? 0.0;
    setState(() {
      _amountTendered = tendered;
      _changeDue = tendered >= _finalTotal ? (tendered - _finalTotal) : 0.0;
    });
  }

  Future<void> _processPayment() async {
    if (_selectedOrder == null) return;

    if (_selectedPaymentMethod == 'Cash' && _amountTendered < _finalTotal) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tendered cash is less than final total!'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    try {
      await ref
          .read(orderRepositoryProvider)
          .recordPayment(
            orderId: _selectedOrder!.id,
            paymentMethod: _selectedPaymentMethod.toLowerCase(),
            amountTendered: _selectedPaymentMethod == 'Cash'
                ? _amountTendered
                : _finalTotal,
            change: _selectedPaymentMethod == 'Cash' ? _changeDue : 0.0,
            discount: _appliedDiscount,
          );

      if (!mounted) return;
      setState(() {
        _currentStep = 3; // Go to Receipt confirmation
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to process settlement: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final ordersAsync = ref.watch(ordersStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: AppColors.darkNavBg,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            const DineFlowMark(size: 32, style: DineFlowMarkStyle.appTile),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DineFlow - Cashier',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  '${user?.displayName ?? "Sarah Lim"} · Active Register',
                  style: const TextStyle(fontSize: 11, color: Colors.white70),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            tooltip: 'Refresh Queue',
            onPressed: () => ref.invalidate(ordersStreamProvider),
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white70),
            tooltip: 'Sign Out',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: Row(
        children: [
          // 1. Sidebar Nav (Wireframe Page 16)
          Container(
            width: 80,
            color: AppColors.darkNavSurface,
            child: Column(
              children: [
                const SizedBox(height: 16),
                _buildSidebarIcon(Icons.payment, 'Payments', _currentStep != 3),
                _buildSidebarIcon(Icons.receipt, 'Receipts', _currentStep == 3),
                const Spacer(),
                IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    color: Colors.white70,
                  ),
                  onPressed: () {},
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),

          // 2. Main Content Area
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                // If firestore is empty, use sample data orders
                final activeOrders = orders.isEmpty
                    ? [
                        const OrderModel(
                          id: 'ord_sample_01',
                          orderNumber: '#DF-1039',
                          tableNumber: 'T02',
                          tableId: 'table_t02',
                          waiterName: 'Mark Reyes',
                          status: OrderStatus.ready,
                          paymentStatus: 'unpaid',
                          subtotal: 860.00,
                          tax: 68.80,
                          total: 928.80,
                          items: [
                            OrderItemModel(
                              id: 'it1',
                              menuItemId: 'menu_001',
                              name: 'Truffle Mushroom Pasta',
                              price: 380.00,
                              quantity: 2,
                            ),
                            OrderItemModel(
                              id: 'it2',
                              menuItemId: 'menu_007',
                              name: 'Iced Citrus Tea',
                              price: 120.00,
                              quantity: 1,
                            ),
                          ],
                        ),
                        const OrderModel(
                          id: 'ord_sample_02',
                          orderNumber: '#DF-1048',
                          tableNumber: 'T04',
                          tableId: 'table_t04',
                          waiterName: 'Mark Reyes',
                          status: OrderStatus.served,
                          paymentStatus: 'unpaid',
                          subtotal: 1350.00,
                          tax: 108.00,
                          total: 1458.00,
                          items: [
                            OrderItemModel(
                              id: 'it3',
                              menuItemId: 'menu_002',
                              name: 'Citrus Salmon Bowl',
                              price: 480.00,
                              quantity: 2,
                            ),
                            OrderItemModel(
                              id: 'it4',
                              menuItemId: 'menu_005',
                              name: 'Truffle Rigatoni',
                              price: 420.00,
                              quantity: 1,
                            ),
                          ],
                        ),
                      ]
                    : orders;

                final readyForPaymentOrders = activeOrders
                    .where(
                      (o) =>
                          o.paymentStatus != 'paid' &&
                          o.status != OrderStatus.cancelled,
                    )
                    .toList();

                if (_currentStep == 0) {
                  return _buildReadyForPaymentQueue(readyForPaymentOrders);
                } else if (_currentStep == 1) {
                  return _buildItemizedBillView();
                } else if (_currentStep == 2) {
                  return _buildPaymentMethodView();
                } else {
                  return _buildReceiptConfirmationView();
                }
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, _) =>
                  Center(child: Text('Error loading orders: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarIcon(IconData icon, String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: isSelected
            ? AppColors.primary.withValues(alpha: 0.15)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? AppColors.primary : Colors.transparent,
        ),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : Colors.white60,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white60,
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Step 0: Ready for Payment Queue (Wireframe Page 16) ---
  Widget _buildReadyForPaymentQueue(List<OrderModel> orders) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Payment Settlement Queue',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${orders.length} active tables waiting for bill settlement',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.availableBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.available.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.available,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${orders.length} Unsettled',
                      style: const TextStyle(
                        color: AppColors.available,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Orders List
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.receipt_long,
                          size: 64,
                          color: AppColors.textMuted,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'No pending payments',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'All active tables are settled and paid.',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final order = orders[i];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: AppColors.occupiedBg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Center(
                                    child: Text(
                                      order.tableNumber,
                                      style: const TextStyle(
                                        color: AppColors.occupied,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Table ${order.tableNumber} · ${order.orderNumber}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${order.items.fold(0, (s, it) => s + it.quantity)} items · Placed by ${order.waiterName}',
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Text(
                                  '₱${order.total.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  onPressed: () => _selectOrder(order),
                                  child: const Text('Open bill'),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // --- Step 1: Itemized Bill (Wireframe Page 17 top) ---
  Widget _buildItemizedBillView() {
    if (_selectedOrder == null) return const SizedBox();
    final order = _selectedOrder!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _currentStep = 0),
              ),
              const SizedBox(width: 8),
              Text(
                'Bill · Table ${order.tableNumber}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                order.orderNumber,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const Divider(height: 24),

          // Items table
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Items',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 12),
                ...order.items.map(
                  (it) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6.0),
                    child: Row(
                      children: [
                        Text(
                          '${it.quantity}x',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                it.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (it.notes != null && it.notes!.isNotEmpty)
                                Text(
                                  it.notes!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          '₱${it.totalPrice.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Discount Code row
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _discountController,
                    decoration: const InputDecoration(
                      hintText: 'Enter discount code (e.g. PROMO10, VIP50)',
                      hintStyle: TextStyle(
                        fontSize: 13,
                        color: AppColors.textMuted,
                      ),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: _applyDiscount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Apply'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bill Financial Summary
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                _buildSummaryLine(
                  'Subtotal',
                  '₱${order.subtotal.toStringAsFixed(2)}',
                ),
                const SizedBox(height: 8),
                _buildSummaryLine(
                  'VAT · 8%',
                  '₱${order.tax.toStringAsFixed(2)}',
                ),
                if (_appliedDiscount > 0) ...[
                  const SizedBox(height: 8),
                  _buildSummaryLine(
                    'Discount',
                    '-₱${_appliedDiscount.toStringAsFixed(2)}',
                    isDiscount: true,
                  ),
                ],
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Divider(height: 1, color: AppColors.divider),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total Due',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '₱${_finalTotal.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Proceed to Payment button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => setState(() => _currentStep = 2),
              child: const Text(
                'Select Payment Method',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Step 2: Payment Method & Tender (Wireframe Page 17 middle) ---
  Widget _buildPaymentMethodView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => setState(() => _currentStep = 1),
              ),
              const SizedBox(width: 8),
              const Text(
                'Take Payment',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const Divider(height: 20),

          // Total amount banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Amount to charge:',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
                Text(
                  '₱${_finalTotal.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'Choose PH Payment Method:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          // Philippine Payment Method cards
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildMethodCard('Cash', Icons.payments_outlined),
              _buildMethodCard('GCash', Icons.qr_code_2),
              _buildMethodCard('Maya', Icons.account_balance_wallet_outlined),
              _buildMethodCard('Card', Icons.credit_card),
              _buildMethodCard('Bank Transfer', Icons.account_balance),
            ],
          ),
          const SizedBox(height: 24),

          // Cash Tender Section
          if (_selectedPaymentMethod == 'Cash') ...[
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cash Tendered (PHP ₱):',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 10),

                  // Quick amounts chips for PH Currency bills
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildQuickAmountChip('Exact', _finalTotal),
                      _buildQuickAmountChip('₱500', 500.0),
                      _buildQuickAmountChip('₱1,000', 1000.0),
                      _buildQuickAmountChip('₱2,000', 2000.0),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Input field
                  TextField(
                    controller: _cashTenderedController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: _calculateChange,
                    decoration: InputDecoration(
                      prefixText: '₱ ',
                      labelText: 'Payment Received',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Change Due Output
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.availableBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.available.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Change due:',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          '₱${_changeDue.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.available,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ] else if (_selectedPaymentMethod == 'GCash' ||
              _selectedPaymentMethod == 'Maya') ...[
            // GCash / Maya QR Ph Section
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _selectedPaymentMethod == 'GCash'
                          ? const Color(0xFF007DFE).withValues(alpha: 0.1)
                          : const Color(0xFF00C853).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          color: _selectedPaymentMethod == 'GCash'
                              ? const Color(0xFF007DFE)
                              : const Color(0xFF00C853),
                          size: 18,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Scan to Pay via $_selectedPaymentMethod (QR Ph)',
                          style: TextStyle(
                            color: _selectedPaymentMethod == 'GCash'
                                ? const Color(0xFF007DFE)
                                : const Color(0xFF00C853),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border, width: 2),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.qr_code_2,
                        size: 110,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'DineFlow Bistro · Merchant #0917-888-3463',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  Text(
                    'Amount: ₱${_finalTotal.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _referenceNoController,
                    decoration: InputDecoration(
                      labelText: 'GCash / Maya Reference No. (Optional)',
                      hintText: 'e.g. 1004 8923 1184',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            // Card / Bank Transfer Section
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      _selectedPaymentMethod == 'Card'
                          ? Icons.credit_card
                          : Icons.account_balance,
                      size: 56,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _selectedPaymentMethod == 'Card'
                          ? 'BancNet / Visa / Mastercard Terminal Ready'
                          : 'InstaPay / PESONet Direct Bank Transfer',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _selectedPaymentMethod == 'Card'
                          ? 'Tap, insert, or swipe card on the connected POS terminal'
                          : 'Customer sends payment to BDO / BPI DineFlow account',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _referenceNoController,
                      decoration: InputDecoration(
                        labelText: 'Approval Code / Reference No.',
                        hintText: 'e.g. AUTH-98234',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),

          // Complete payment button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _processPayment,
              child: Text(
                'Complete Settlement (₱${_finalTotal.toStringAsFixed(2)})',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodCard(String method, IconData icon) {
    final isSelected = _selectedPaymentMethod == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedPaymentMethod = method),
      child: Container(
        width: 100,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              size: 24,
            ),
            const SizedBox(height: 6),
            Text(
              method,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 12,
                color: isSelected
                    ? AppColors.primaryDark
                    : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickAmountChip(String label, double amount) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        _cashTenderedController.text = amount.toStringAsFixed(2);
        _calculateChange(amount.toString());
      },
    );
  }

  // --- Step 3: Payment Confirmation & Receipt (Wireframe Page 17 bottom) ---
  Widget _buildReceiptConfirmationView() {
    if (_selectedOrder == null) return const SizedBox();
    final order = _selectedOrder!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            children: [
              // Checkmark
              Container(
                width: 64,
                height: 64,
                decoration: const BoxDecoration(
                  color: AppColors.availableBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 36,
                  color: AppColors.available,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '₱${_finalTotal.toStringAsFixed(2)} Paid',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Transaction complete · Table ${order.tableNumber} is now ready for new guests',
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 24),

              // Printed Receipt Card (Wireframe Page 17)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Column(
                        children: const [
                          DineFlowLogo(
                            markSize: 28,
                            fontSize: 18,
                            useAppTile: true,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Official BIR Sales Receipt',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'TIN: 432-891-002-000 · VAT Registered',
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 24),
                    _buildReceiptRow('Receipt #', order.orderNumber),
                    _buildReceiptRow('Table', order.tableNumber),
                    _buildReceiptRow(
                      'Date & Time',
                      '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, "0")} PM',
                    ),
                    _buildReceiptRow('Payment Method', _selectedPaymentMethod),
                    if (_referenceNoController.text.isNotEmpty)
                      _buildReceiptRow('Ref No.', _referenceNoController.text),
                    const Divider(height: 20),
                    ...order.items.map(
                      (it) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${it.quantity}x ${it.name}',
                              style: const TextStyle(fontSize: 13),
                            ),
                            Text(
                              '₱${it.totalPrice.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Divider(height: 20),
                    _buildReceiptRow(
                      'Subtotal',
                      '₱${order.subtotal.toStringAsFixed(2)}',
                    ),
                    _buildReceiptRow(
                      'VAT (8%)',
                      '₱${order.tax.toStringAsFixed(2)}',
                    ),
                    if (_appliedDiscount > 0)
                      _buildReceiptRow(
                        'Discount',
                        '-₱${_appliedDiscount.toStringAsFixed(2)}',
                      ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '₱${_finalTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    if (_selectedPaymentMethod == 'Cash') ...[
                      const SizedBox(height: 8),
                      _buildReceiptRow(
                        'Cash Tendered',
                        '₱${_amountTendered.toStringAsFixed(2)}',
                      ),
                      _buildReceiptRow(
                        'Change',
                        '₱${_changeDue.toStringAsFixed(2)}',
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.print_outlined),
                      label: const Text('Print Receipt'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Receipt sent to thermal POS printer',
                            ),
                            backgroundColor: AppColors.available,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _selectedOrder = null;
                          _currentStep = 0; // Return to queue
                        });
                      },
                      child: const Text(
                        'Next Transaction',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryLine(
    String label,
    String value, {
    bool isDiscount = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: isDiscount ? AppColors.available : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
