import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_providers.dart';
import 'order_confirmation_screen.dart';

class OrderCartScreen extends ConsumerStatefulWidget {
  const OrderCartScreen({super.key});

  @override
  ConsumerState<OrderCartScreen> createState() => _OrderCartScreenState();
}

class _OrderCartScreenState extends ConsumerState<OrderCartScreen> {
  final TextEditingController _noteController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _noteController.text = ref.read(cartProvider).orderNote ?? '';
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitOrder(CartState cart) async {
    if (cart.items.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      final user = ref.read(currentUserProvider).asData?.value;
      final waiterId = user?.uid ?? 'waiter_001';
      final waiterName = user?.displayName ?? 'Waiter';

      final createdOrder = await ref.read(orderRepositoryProvider).createOrder(
            cart: cart,
            waiterId: waiterId,
            waiterName: waiterName,
            guestCount: 4,
          );

      // Clear cart
      ref.read(cartProvider.notifier).clearCart();

      if (!mounted) return;

      // Navigate to Order Confirmation Screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => OrderConfirmationScreen(order: createdOrder),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to submit order: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Review order',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () {
                ref.read(cartProvider.notifier).clearCart();
              },
              child: const Text('Clear', style: TextStyle(color: AppColors.error)),
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? _buildEmptyCart(context)
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Table Card Header
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Table ${cart.tableNumber ?? "T04"}',
                                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 2),
                                  const Text(
                                    'Order #DF-New · 4 guests',
                                    style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${cart.itemCount} Items',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Items List (Satisfies WB CUST 002)
                        ...cart.items.map((item) => _buildCartItemCard(context, item)),

                        const SizedBox(height: 16),

                        // Order Note input
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: TextField(
                            controller: _noteController,
                            onChanged: (val) => ref.read(cartProvider.notifier).setNote(val),
                            decoration: const InputDecoration(
                              icon: Icon(Icons.edit_note, color: AppColors.textMuted),
                              hintText: 'Add general order note for kitchen...',
                              hintStyle: TextStyle(fontSize: 13, color: AppColors.textMuted),
                              border: InputBorder.none,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Bill Calculation Summary (8% tax)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            children: [
                              _buildSummaryRow('Subtotal', '₱${cart.subtotal.toStringAsFixed(2)}'),
                              const SizedBox(height: 8),
                              _buildSummaryRow('Tax · 8%', '₱${cart.tax.toStringAsFixed(2)}'),
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Divider(height: 1, color: AppColors.divider),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'Total',
                                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    '₱${cart.total.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Bottom Action Button: Confirm & send to kitchen
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          _isSubmitting ? 'Sending to Kitchen...' : 'Confirm & send to kitchen',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: _isSubmitting ? null : () => _submitOrder(cart),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildCartItemCard(BuildContext context, OrderItemModel item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quantity Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              '${item.quantity}x',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title & notes
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                if (item.notes != null && item.notes!.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    item.notes!,
                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  children: [
                    // Quantity adjustments
                    InkWell(
                      onTap: () {
                        ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity - 1);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.remove, size: 14),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        ref.read(cartProvider.notifier).updateQuantity(item.id, item.quantity + 1);
                      },
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Icon(Icons.add, size: 14),
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => ref.read(cartProvider.notifier).removeItem(item.id),
                      child: const Text(
                        'Remove',
                        style: TextStyle(fontSize: 12, color: AppColors.error, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Total line price
          Text(
            '₱${item.totalPrice.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppColors.primaryLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.shopping_basket_outlined, size: 56, color: AppColors.primary),
            ),
            const SizedBox(height: 20),
            const Text(
              'Cart is empty',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 8),
            const Text(
              'Add dishes from the menu to start this order',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Browse menu'),
            ),
          ],
        ),
      ),
    );
  }
}
