import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/brand_colors.dart';
import '../../models/order_model.dart';
import '../../providers/customer_session_provider.dart';
import '../../providers/notification_providers.dart';
import '../../providers/order_providers.dart';
import '../../services/waiter_request_service.dart';
import '../../utils/currency.dart';

/// Customer Order Tracking Screen:
/// URL: /t/:tableId/order/:orderId
/// Real-time live status timeline: Received → Preparing → Ready → Served.
/// Includes idempotent "Ask for the bill" CTA with Philippine payment methods notice,
/// and "Call Waiter" assistance.
class CustomerOrderTrackingScreen extends ConsumerStatefulWidget {
  final String tableId;
  final String orderId;

  const CustomerOrderTrackingScreen({
    super.key,
    required this.tableId,
    required this.orderId,
  });

  @override
  ConsumerState<CustomerOrderTrackingScreen> createState() =>
      _CustomerOrderTrackingScreenState();
}

class _CustomerOrderTrackingScreenState
    extends ConsumerState<CustomerOrderTrackingScreen> {
  bool _billRequested = false;
  bool _isRequestingBill = false;
  bool _isCallingWaiter = false;

  Future<void> _handleAskForBill(
    OrderModel order,
    String normalizedTableId,
  ) async {
    if (_billRequested || _isRequestingBill) return;

    setState(() => _isRequestingBill = true);

    try {
      await ref
          .read(waiterRequestServiceProvider)
          .requestBill(
            tableId: order.tableId.isNotEmpty
                ? order.tableId
                : normalizedTableId,
            tableNumber: normalizedTableId,
            orderId: order.id,
            total: order.total,
          );

      if (mounted) {
        setState(() {
          _billRequested = true;
          _isRequestingBill = false;
        });

        _showBillModal(order);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isRequestingBill = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not notify waiter: $e'),
            backgroundColor: BrandColors.error,
          ),
        );
      }
    }
  }

  void _showBillModal(OrderModel order) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  color: BrandColors.successBg,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_outline,
                  color: BrandColors.success,
                  size: 28,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Waiter Notified',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: BrandColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your waiter is on the way with your printed bill from the Cashier.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: BrandColors.textSecondary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 16),

              // Total to prepare
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: BrandColors.creamBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: BrandColors.border),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total to Prepare:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      formatPeso(order.total),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: BrandColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Accepted payment channels
              const Text(
                'Payment Methods Accepted by Cashier:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: BrandColors.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              const Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Chip(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: BrandColors.border),
                    avatar: Text('💵'),
                    label: Text('Cash', style: TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: BrandColors.border),
                    avatar: Text('📱'),
                    label: Text('GCash', style: TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: BrandColors.border),
                    avatar: Text('📱'),
                    label: Text('Maya', style: TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: BrandColors.border),
                    avatar: Text('💳'),
                    label: Text('Card', style: TextStyle(fontSize: 12)),
                    visualDensity: VisualDensity.compact,
                  ),
                  Chip(
                    backgroundColor: Colors.white,
                    side: BorderSide(color: BrandColors.border),
                    avatar: Text('🏦'),
                    label: Text(
                      'Bank Transfer',
                      style: TextStyle(fontSize: 12),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                ],
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrandColors.primaryOrange,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text(
                    'Got it',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleCallWaiter(String normalizedTableId) async {
    if (_isCallingWaiter) return;
    setState(() => _isCallingWaiter = true);

    try {
      await ref
          .read(waiterRequestServiceProvider)
          .callWaiter(
            tableId: normalizedTableId,
            tableNumber: normalizedTableId,
            reason: 'Assistance requested at table',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Assistance requested for Table $normalizedTableId!'),
            backgroundColor: BrandColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not alert waiter: $e'),
            backgroundColor: BrandColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCallingWaiter = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalizedTableId = normalizeTableId(widget.tableId);
    final orderAsync = ref.watch(orderByIdProvider(widget.orderId));

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
          'Order Tracking · Table $normalizedTableId',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: BrandColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Call Waiter',
            icon: const Icon(
              Icons.room_service_outlined,
              color: BrandColors.primaryOrange,
            ),
            onPressed: () => _handleCallWaiter(normalizedTableId),
          ),
        ],
      ),
      body: orderAsync.when(
        data: (order) {
          if (order == null) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.receipt_long,
                      size: 54,
                      color: BrandColors.textMuted,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Order ${widget.orderId} not found in database.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BrandColors.primaryOrange,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => context.go('/t/$normalizedTableId/menu'),
                      child: const Text('Back to Menu'),
                    ),
                  ],
                ),
              ),
            );
          }

          return _buildOrderContent(order, normalizedTableId);
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: BrandColors.primaryOrange),
        ),
        error: (err, _) => Center(child: Text('Error loading order: $err')),
      ),
    );
  }

  Widget _buildOrderContent(OrderModel order, String normalizedTableId) {
    final isPaid = order.paymentStatus.toLowerCase() == 'paid';
    final notifsAsync = ref.watch(
      customerNotificationsStreamProvider(normalizedTableId),
    );
    final activeAlerts = (notifsAsync.asData?.value ?? [])
        .where((n) => n.status == 'unread')
        .toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Real-time Staff Alerts Banner (Waiter calling / notifying table)
          if (activeAlerts.isNotEmpty) ...[
            ...activeAlerts.map(
              (alert) => Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFF59E0B),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.amber.withValues(alpha: 0.12),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFDE68A),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.campaign,
                        color: Color(0xFFB45309),
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            alert.title.isNotEmpty
                                ? alert.title
                                : 'Staff Notification',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF92400E),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            alert.message,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF78350F),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                        foregroundColor: const Color(0xFFB45309),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                      ),
                      onPressed: () {
                        ref
                            .read(notificationActionsProvider)
                            .markAsRead(alert.id);
                      },
                      child: const Text(
                        'OK',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],

          // Order Header Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: BrandColors.border),
            ),
            child: Column(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: const BoxDecoration(
                    color: BrandColors.successBg,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: BrandColors.success,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Order Confirmed!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: BrandColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Order ${order.orderNumber} · Table $normalizedTableId',
                  style: const TextStyle(
                    fontSize: 14,
                    color: BrandColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),

                // Wait time estimate badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: BrandColors.primaryOrangeLight,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 18,
                        color: BrandColors.primaryOrange,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Estimated Preparation: 15–20 min',
                        style: TextStyle(
                          color: BrandColors.primaryOrange,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Real-Time Status Timeline
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: BrandColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Live Order Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: BrandColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                _buildTimeline(order.status),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Items Summary List
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: BrandColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: BrandColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                ...order.items.map((it) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${it.quantity}x ${it.name}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              if (it.notes != null && it.notes!.isNotEmpty)
                                Text(
                                  it.notes!,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: BrandColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Text(
                          formatPeso(it.totalPrice),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const Divider(height: 20, color: BrandColors.divider),
                _buildReceiptRow('Subtotal', formatPeso(order.subtotal)),
                const SizedBox(height: 6),
                _buildReceiptRow('VAT (12%)', formatPeso(order.tax)),
                const SizedBox(height: 6),
                _buildReceiptRow(
                  'Dine-In Service Charge (10%)',
                  formatPeso(order.serviceCharge),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: BrandColors.divider),
                ),
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
                      formatPeso(order.total),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: BrandColors.primaryOrange,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // Main Action CTA: "Ask for the Bill" or "Bill Settled"
          if (isPaid) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: BrandColors.successBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: BrandColors.success),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: BrandColors.success),
                  SizedBox(width: 8),
                  Text(
                    '✓ Bill settled · Thank you for dining with us!',
                    style: TextStyle(
                      color: BrandColors.success,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ] else ...[
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _billRequested
                      ? Colors.grey.shade400
                      : BrandColors.primaryOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                icon: _isRequestingBill
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Icon(_billRequested ? Icons.check : Icons.receipt_long),
                label: Text(
                  _billRequested ? 'Bill Requested ✓' : 'Ask for the Bill',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onPressed: _billRequested
                    ? null
                    : () => _handleAskForBill(order, normalizedTableId),
              ),
            ),
          ],

          const SizedBox(height: 12),

          // Secondary Action: Add more items / back to menu
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: BrandColors.primaryOrange,
                side: const BorderSide(color: BrandColors.primaryOrange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.restaurant_menu, size: 18),
              label: const Text(
                'Back to Menu / Add More Items',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () => context.go('/t/$normalizedTableId/menu'),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildTimeline(OrderStatus status) {
    final stages = [
      {'title': 'Received', 'status': OrderStatus.pending},
      {'title': 'Preparing', 'status': OrderStatus.preparing},
      {'title': 'Ready', 'status': OrderStatus.ready},
      {'title': 'Served', 'status': OrderStatus.served},
    ];

    int currentIdx = 0;
    switch (status) {
      case OrderStatus.pending:
        currentIdx = 0;
        break;
      case OrderStatus.preparing:
        currentIdx = 1;
        break;
      case OrderStatus.ready:
        currentIdx = 2;
        break;
      case OrderStatus.served:
      case OrderStatus.completed:
        currentIdx = 3;
        break;
      case OrderStatus.cancelled:
        currentIdx = -1;
        break;
    }

    if (currentIdx == -1) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: BrandColors.errorBg,
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Row(
          children: [
            Icon(Icons.cancel, color: BrandColors.error),
            SizedBox(width: 8),
            Text(
              'This order was cancelled.',
              style: TextStyle(
                color: BrandColors.error,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: List.generate(stages.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIndex = i ~/ 2;
          final isPast = stepIndex < currentIdx;
          return Expanded(
            child: Container(
              height: 3,
              color: isPast ? BrandColors.primaryOrange : BrandColors.divider,
            ),
          );
        }

        final stepIndex = i ~/ 2;
        final isCompleted =
            stepIndex < currentIdx ||
            (stepIndex == currentIdx &&
                (status == OrderStatus.served ||
                    status == OrderStatus.completed));
        final isCurrent = stepIndex == currentIdx;
        final stageTitle = stages[stepIndex]['title'] as String;

        return Column(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isCompleted || isCurrent
                    ? BrandColors.primaryOrange
                    : Colors.white,
                border: Border.all(
                  color: isCompleted || isCurrent
                      ? BrandColors.primaryOrange
                      : BrandColors.border,
                  width: 2,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 16, color: Colors.white)
                    : isCurrent
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        '${stepIndex + 1}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: BrandColors.textMuted,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              stageTitle,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                color: isCurrent
                    ? BrandColors.primaryOrange
                    : BrandColors.textSecondary,
              ),
            ),
          ],
        );
      }),
    );
  }

  Widget _buildReceiptRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: BrandColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
