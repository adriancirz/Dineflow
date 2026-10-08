import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/brand_colors.dart';
import '../../models/table_model.dart';
import '../../providers/customer_cart_provider.dart';
import '../../providers/customer_session_provider.dart';
import '../../providers/firebase_providers.dart';
import '../../router/route_names.dart';
import '../../services/anonymous_auth_service.dart';
import '../../utils/currency.dart';

/// Customer Cart Screen:
/// URL: /t/:tableId/cart
/// Reviews cart items, quantity adjustments, general order notes,
/// displays Philippine VAT (12%) & Dine-in Service Charge (10%),
/// and performs reliable Firestore order submission.
class CustomerCartScreen extends ConsumerStatefulWidget {
  final String tableId;

  const CustomerCartScreen({super.key, required this.tableId});

  @override
  ConsumerState<CustomerCartScreen> createState() => _CustomerCartScreenState();
}

class _CustomerCartScreenState extends ConsumerState<CustomerCartScreen> {
  final TextEditingController _orderNotesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _orderNotesController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder() async {
    final cart = ref.read(customerCartProvider);
    if (cart.isEmpty) return;

    final session = ref.read(customerSessionProvider);
    final normalizedTableId = session.tableNumber ?? normalizeTableId(widget.tableId);

    setState(() => _isSubmitting = true);

    try {
      final firestore = ref.read(firestoreProvider);
      final authService = ref.read(anonymousAuthServiceProvider);

      // Ensure anonymous sign in
      if (!authService.isSignedIn) {
        try {
          await authService.signInAnonymously();
        } catch (_) {}
      }
      final currentUid = authService.currentUid ?? 'anon_${DateTime.now().millisecondsSinceEpoch}';

      // 1. Order document reference
      final orderRef = firestore.collection('orders').doc();
      final orderId = orderRef.id;
      final orderNumber = '#DF-${1000 + (DateTime.now().millisecondsSinceEpoch % 9000)}';
      final orderNotes = _orderNotesController.text.trim();

      final orderData = {
        'orderNumber': orderNumber,
        'customerId': currentUid,
        'customerName': 'Guest',
        'tableId': session.tableId ?? normalizedTableId,
        'tableNumber': normalizedTableId,
        'guestCount': session.guestCount,
        'waiterId': '',
        'waiterName': '',
        'orderType': 'dine_in',
        'status': 'pending',
        'paymentStatus': 'unpaid',
        'paymentMethod': null,
        'subtotal': cart.subtotal,
        'tax': cart.tax, // 12% VAT
        'serviceCharge': cart.serviceCharge, // 10% Service Charge
        'discount': 0.0,
        'total': cart.total,
        'orderNotes': orderNotes.isNotEmpty ? orderNotes : null,
        'specialInstructions': orderNotes.isNotEmpty ? orderNotes : null,
        'placedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await orderRef.set(orderData);

      // 2. Items subcollection
      for (final it in cart.items) {
        final itemRef = orderRef.collection('items').doc();
        await itemRef.set({
          'menuItemId': it.item.id,
          'name': it.item.name,
          'price': it.unitPrice,
          'quantity': it.quantity,
          'lineTotal': it.lineTotal,
          'notes': it.specialInstructions,
          'specialInstructions': it.specialInstructions,
          'status': 'pending',
          'selectedModifiers': it.selectedModifiers.map((m) => m.toMap()).toList(),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // 3. Status history subcollection
      try {
        final historyRef = orderRef.collection('statusHistory').doc();
        await historyRef.set({
          'status': 'pending',
          'changedBy': 'customer',
          'timestamp': FieldValue.serverTimestamp(),
          'note': 'Order submitted from Table $normalizedTableId self-service menu',
        });
      } catch (_) {}

      // 4. Update table status to occupied (graceful update)
      try {
        final targetTableDocId = session.tableId ?? normalizedTableId;
        final tableRef = firestore.collection('tables').doc(targetTableDocId);
        await tableRef.set(
          {
            'status': TableStatus.occupied.name,
            'currentOrderId': orderId,
            'guestCount': session.guestCount,
            'occupiedSince': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } catch (_) {}

      // 5. Notifications for both Kitchen and Waiter staff
      try {
        final notifRefKitchen = firestore.collection('notifications').doc();
        await notifRefKitchen.set({
          'type': 'new_order',
          'tableId': normalizedTableId,
          'tableNumber': normalizedTableId,
          'orderId': orderId,
          'recipientRole': 'kitchen',
          'title': 'New Order · Table $normalizedTableId',
          'message': 'New order $orderNumber with ${cart.itemCount} items sent to kitchen.',
          'status': 'unread',
          'createdAt': FieldValue.serverTimestamp(),
        });

        final notifRefWaiter = firestore.collection('notifications').doc();
        await notifRefWaiter.set({
          'type': 'new_order',
          'tableId': normalizedTableId,
          'tableNumber': normalizedTableId,
          'orderId': orderId,
          'recipientRole': 'waiter',
          'title': 'Customer Placed Order · Table $normalizedTableId',
          'message': 'Table $normalizedTableId placed order $orderNumber with ${cart.itemCount} items.',
          'status': 'unread',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } catch (_) {}

      // Update local Riverpod session
      ref.read(customerSessionProvider.notifier).setActiveOrderId(orderId);
      ref.read(customerCartProvider.notifier).clearCart();

      if (mounted) {
        context.go(AppRoutes.tableOrder(normalizedTableId, orderId));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to place order: $e'),
            backgroundColor: BrandColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalizedTableId = normalizeTableId(widget.tableId);
    final cart = ref.watch(customerCartProvider);

    return Scaffold(
      backgroundColor: BrandColors.creamBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BrandColors.textPrimary),
          onPressed: () => context.go('/t/$normalizedTableId/menu'),
        ),
        title: Text(
          'Your Order · Table $normalizedTableId',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: BrandColors.textPrimary,
          ),
        ),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () => ref.read(customerCartProvider.notifier).clearCart(),
              child: const Text('Clear', style: TextStyle(color: BrandColors.error)),
            ),
        ],
      ),
      body: cart.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.shopping_bag_outlined, size: 72, color: BrandColors.textMuted),
                    const SizedBox(height: 16),
                    const Text(
                      'Your cart is empty',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: BrandColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Explore our delicious dishes and beverages to begin your order.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: BrandColors.textSecondary, height: 1.4),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BrandColors.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.restaurant_menu),
                      label: const Text('Browse Menu', style: TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => context.go('/t/$normalizedTableId/menu'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Line Items List
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: BrandColors.border),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: cart.items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1, color: BrandColors.divider),
                      itemBuilder: (ctx, i) {
                        final it = cart.items[i];
                        return Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Quantity controls
                              Container(
                                decoration: BoxDecoration(
                                  color: BrandColors.creamBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: BrandColors.border),
                                ),
                                child: Column(
                                  children: [
                                    InkWell(
                                      onTap: () => ref.read(customerCartProvider.notifier).updateQuantity(it.id, it.quantity + 1),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.add, size: 16, color: BrandColors.primaryOrange),
                                      ),
                                    ),
                                    Text(
                                      '${it.quantity}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    InkWell(
                                      onTap: () => ref.read(customerCartProvider.notifier).updateQuantity(it.id, it.quantity - 1),
                                      child: const Padding(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(Icons.remove, size: 16, color: BrandColors.textSecondary),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Item Name, Modifiers, Special notes
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      it.item.name,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    if (it.selectedModifiers.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        it.selectedModifiers.map((m) => '+ ${m.name}').join(', '),
                                        style: const TextStyle(fontSize: 12, color: BrandColors.primaryOrange),
                                      ),
                                    ],
                                    if (it.specialInstructions != null && it.specialInstructions!.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          const Icon(Icons.note_outlined, size: 13, color: BrandColors.textMuted),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              it.specialInstructions!,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontStyle: FontStyle.italic,
                                                color: BrandColors.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Line Total & Delete
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    formatPeso(it.lineTotal),
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.delete_outline, size: 18, color: BrandColors.error),
                                    visualDensity: VisualDensity.compact,
                                    onPressed: () => ref.read(customerCartProvider.notifier).removeItem(it.id),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Order-Level Special Instructions
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: BrandColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.edit_note, size: 20, color: BrandColors.primaryOrange),
                            SizedBox(width: 6),
                            Text(
                              'Order Notes for the Kitchen',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _orderNotesController,
                          maxLines: 2,
                          decoration: InputDecoration(
                            hintText: 'e.g. Please serve drinks first, allergy alert for entire table...',
                            hintStyle: const TextStyle(fontSize: 13, color: BrandColors.textMuted),
                            filled: true,
                            fillColor: BrandColors.creamBg,
                            contentPadding: const EdgeInsets.all(12),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: BrandColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: BrandColors.border),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Bill Breakdown Summary Card (12% VAT + 10% Service Charge)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: BrandColors.border),
                    ),
                    child: Column(
                      children: [
                        _buildSummaryRow('Subtotal', formatPeso(cart.subtotal)),
                        const SizedBox(height: 8),
                        _buildSummaryRow('VAT (12%)', formatPeso(cart.tax)),
                        const SizedBox(height: 8),
                        _buildSummaryRow('Dine-In Service Charge (10%)', formatPeso(cart.serviceCharge)),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 10),
                          child: Divider(height: 1, color: BrandColors.divider),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Amount',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              formatPeso(cart.total),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: BrandColors.primaryOrange,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),

      // Place Order CTA Bottom Bar
      bottomNavigationBar: cart.items.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: BrandColors.primaryOrange,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 0,
                    ),
                    onPressed: _isSubmitting ? null : _submitOrder,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.send_rounded, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Place Order (${formatPeso(cart.total)})',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: BrandColors.textSecondary, fontSize: 14)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      ],
    );
  }
}
