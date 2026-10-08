import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../providers/order_providers.dart';
import '../../router/route_names.dart';

class OrderConfirmationScreen extends ConsumerWidget {
  final OrderModel order;

  const OrderConfirmationScreen({super.key, required this.order});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Listen to real-time status updates of this order if available
    final liveOrders = ref.watch(ordersStreamProvider).asData?.value;
    final currentOrder = liveOrders?.firstWhere(
          (o) => o.id == order.id,
          orElse: () => order,
        ) ??
        order;

    final isReceived = true;
    final isPreparing = currentOrder.status == OrderStatus.preparing ||
        currentOrder.status == OrderStatus.ready ||
        currentOrder.status == OrderStatus.served ||
        currentOrder.status == OrderStatus.completed;
    final isReady = currentOrder.status == OrderStatus.ready ||
        currentOrder.status == OrderStatus.served ||
        currentOrder.status == OrderStatus.completed;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Order sent',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
          child: Column(
            children: [
              const SizedBox(height: 10),
              // Big Green Checkmark
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.availableBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check,
                  size: 40,
                  color: AppColors.available,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Order confirmed',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'The kitchen has received the order and will begin shortly.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),

              // Order Ticket Card (Wireframe Page 12)
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
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
                    // Header row: #DF-1048 & status
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              currentOrder.orderNumber,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Table ${currentOrder.tableNumber} · 4 guests',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: currentOrder.status == OrderStatus.ready
                                ? AppColors.readyBg
                                : (currentOrder.status == OrderStatus.preparing
                                    ? AppColors.occupiedBg
                                    : AppColors.pendingBg),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '• ${currentOrder.status.label}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: currentOrder.status == OrderStatus.ready
                                  ? AppColors.ready
                                  : (currentOrder.status == OrderStatus.preparing
                                      ? AppColors.occupied
                                      : AppColors.pending),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: AppColors.divider),
                    ),

                    // Items list summary
                    ...currentOrder.items.map((item) => Padding(
                          padding: const EdgeInsets.only(bottom: 6.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                '${item.quantity}x  ${item.name}',
                                style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                              ),
                              Text(
                                '₱${item.totalPrice.toStringAsFixed(2)}',
                                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        )),

                    const SizedBox(height: 14),

                    // Expected preparation time box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.reservedBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: const [
                          Icon(Icons.access_time, size: 16, color: AppColors.reserved),
                          SizedBox(width: 8),
                          Text(
                            'Expected to start preparing in 3-5 min',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.reserved,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Live Status Timeline Tracker (Wireframe Page 12)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStepIndicator('Received', isReceived),
                        _buildStepConnector(isPreparing),
                        _buildStepIndicator('Preparing', isPreparing),
                        _buildStepConnector(isReady),
                        _buildStepIndicator('Ready', isReady),
                      ],
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.receipt),
                  label: const Text('View active order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () {
                    context.go(AppRoutes.waiterTables, extra: {'tab': 2, 'orderId': currentOrder.id});
                  },
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => context.go(AppRoutes.waiterTables, extra: {'tab': 0}),
                  child: const Text('Back to tables'),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(String label, bool isDone) {
    return Column(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: isDone ? AppColors.available : Colors.white,
            shape: BoxShape.circle,
            border: Border.all(
              color: isDone ? AppColors.available : Colors.grey.shade300,
              width: 2,
            ),
          ),
          child: isDone
              ? const Icon(Icons.check, size: 14, color: Colors.white)
              : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isDone ? FontWeight.bold : FontWeight.normal,
            color: isDone ? AppColors.textPrimary : AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildStepConnector(bool isDone) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 16),
        color: isDone ? AppColors.available : Colors.grey.shade300,
      ),
    );
  }
}
