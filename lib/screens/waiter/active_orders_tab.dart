import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../providers/order_providers.dart';
import '../../services/waiter_request_service.dart';

class ActiveOrdersTab extends ConsumerStatefulWidget {
  final String? initialOrderId;
  final Function(int tabIndex)? onNavigateTab;

  const ActiveOrdersTab({super.key, this.initialOrderId, this.onNavigateTab});

  @override
  ConsumerState<ActiveOrdersTab> createState() => _ActiveOrdersTabState();
}

class _ActiveOrdersTabState extends ConsumerState<ActiveOrdersTab>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String? _handledOrderId;
  final Set<String> _servingOrderIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void didUpdateWidget(covariant ActiveOrdersTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialOrderId != null &&
        widget.initialOrderId != _handledOrderId) {
      _handledOrderId = null;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String _formatTimeAgo(DateTime? time) {
    if (time == null) return 'Just now';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    return '${diff.inHours} hr ago';
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Active orders',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '3 open · Lunch shift',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textPrimary),
            onPressed: () => ref.invalidate(ordersStreamProvider),
          ),
        ],
        bottom: ordersAsync.maybeWhen(
          data: (orders) {
            final pendingCount = orders
                .where((o) => o.status == OrderStatus.pending)
                .length;
            final prepCount = orders
                .where((o) => o.status == OrderStatus.preparing)
                .length;
            final readyCount = orders
                .where((o) => o.status == OrderStatus.ready)
                .length;
            final servedCount = orders
                .where((o) => o.status == OrderStatus.served)
                .length;
            final doneCount = orders
                .where((o) => o.status == OrderStatus.completed)
                .length;

            return TabBar(
              controller: _tabController,
              isScrollable: true,
              labelColor: AppColors.textPrimary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              tabs: [
                Tab(text: 'Pending ($pendingCount)'),
                Tab(text: 'Preparing ($prepCount)'),
                Tab(text: 'Ready ($readyCount)'),
                Tab(text: 'Served ($servedCount)'),
                Tab(text: 'Done ($doneCount)'),
              ],
            );
          },
          orElse: () => TabBar(
            controller: _tabController,
            isScrollable: true,
            labelColor: AppColors.textPrimary,
            unselectedLabelColor: AppColors.textSecondary,
            indicatorColor: AppColors.primary,
            tabs: const [
              Tab(text: 'Pending (0)'),
              Tab(text: 'Preparing (0)'),
              Tab(text: 'Ready (0)'),
              Tab(text: 'Served (0)'),
              Tab(text: 'Done (0)'),
            ],
          ),
        ),
      ),
      body: ordersAsync.when(
        data: (orders) {
          _checkAndFocusInitialOrder(orders);
          final pending = orders
              .where((o) => o.status == OrderStatus.pending)
              .toList();
          final preparing = orders
              .where((o) => o.status == OrderStatus.preparing)
              .toList();
          final ready = orders
              .where((o) => o.status == OrderStatus.ready)
              .toList();
          final served = orders
              .where((o) => o.status == OrderStatus.served)
              .toList();
          final done = orders
              .where((o) => o.status == OrderStatus.completed)
              .toList();

          return TabBarView(
            controller: _tabController,
            children: [
              _buildOrdersList(pending, 'No pending orders'),
              _buildOrdersList(preparing, 'No orders currently preparing'),
              _buildOrdersList(ready, 'No orders ready for pickup'),
              _buildOrdersList(served, 'No orders served to customers yet'),
              _buildOrdersList(
                done,
                'No completed orders yet\nOrders closed this shift will appear here.',
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error loading orders: $err')),
      ),
    );
  }

  Widget _buildOrdersList(List<OrderModel> list, String emptyMessage) {
    if (list.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.inbox_outlined, size: 56, color: Colors.grey.shade400),
              const SizedBox(height: 16),
              Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = list[index];
        return _buildOrderCard(order);
      },
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    Color statusColor;
    Color statusBg;

    switch (order.status) {
      case OrderStatus.pending:
        statusColor = AppColors.pending;
        statusBg = AppColors.pendingBg;
        break;
      case OrderStatus.preparing:
        statusColor = AppColors.occupied;
        statusBg = AppColors.occupiedBg;
        break;
      case OrderStatus.ready:
        statusColor = AppColors.ready;
        statusBg = AppColors.readyBg;
        break;
      case OrderStatus.served:
        statusColor = AppColors.available;
        statusBg = AppColors.availableBg;
        break;
      case OrderStatus.completed:
        statusColor = AppColors.textSecondary;
        statusBg = AppColors.background;
        break;
      case OrderStatus.cancelled:
        statusColor = AppColors.textMuted;
        statusBg = AppColors.background;
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order number and Status Badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order.orderNumber,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '• ${order.status.label}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Table, items count, total
            Text(
              'Table ${order.tableNumber} · ${order.items.fold(0, (s, i) => s + i.quantity)} items · ₱${order.total.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 10),

            // Time, Call Table, and View Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTimeAgo(order.placedAt),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textMuted,
                  ),
                ),
                Row(
                  children: [
                    InkWell(
                      onTap: () => _showNotifyCustomerDialog(order),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.campaign_outlined,
                            size: 15,
                            color: AppColors.primary,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Call Table',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    InkWell(
                      onTap: () => _showOrderDetailsSheet(order),
                      child: Row(
                        children: const [
                          Text(
                            'View details',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            size: 12,
                            color: AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            if (order.status == OrderStatus.ready) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: _servingOrderIds.contains(order.id)
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.check_circle_outline),
                  label: Text(
                    _servingOrderIds.contains(order.id)
                        ? 'Marking served...'
                        : 'Mark Served',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.available,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _servingOrderIds.contains(order.id)
                      ? null
                      : () => _markOrderServed(order),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _markOrderServed(
    OrderModel order, {
    VoidCallback? beforeUpdate,
  }) async {
    if (_servingOrderIds.contains(order.id)) return;

    beforeUpdate?.call();
    setState(() => _servingOrderIds.add(order.id));
    try {
      await ref
          .read(orderRepositoryProvider)
          .updateOrderStatus(order.id, OrderStatus.served);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order ${order.orderNumber} marked as served.'),
            backgroundColor: AppColors.available,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not mark order as served: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _servingOrderIds.remove(order.id));
      }
    }
  }

  void _checkAndFocusInitialOrder(List<OrderModel> orders) {
    final orderId = widget.initialOrderId;
    if (orderId == null || orderId == _handledOrderId) return;
    final matchIndex = orders.indexWhere((o) => o.id == orderId);
    if (matchIndex != -1) {
      _handledOrderId = orderId;
      final match = orders[matchIndex];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        int targetTab = 0;
        if (match.status == OrderStatus.pending) {
          targetTab = 0;
        } else if (match.status == OrderStatus.preparing) {
          targetTab = 1;
        } else if (match.status == OrderStatus.ready) {
          targetTab = 2;
        } else if (match.status == OrderStatus.served) {
          targetTab = 3;
        } else if (match.status == OrderStatus.completed) {
          targetTab = 4;
        }
        _tabController.animateTo(targetTab);
        _showOrderDetailsSheet(match);
      });
    }
  }

  void _showOrderDetailsSheet(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order ${order.orderNumber}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
            Text(
              'Table ${order.tableNumber} · Status: ${order.status.label}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const Divider(height: 24),
            const Text(
              'Items:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                itemCount: order.items.length,
                separatorBuilder: (_, _) => const Divider(height: 12),
                itemBuilder: (ctx, i) {
                  final it = order.items[i];
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${it.quantity}x ${it.name}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
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
                      Text('₱${it.totalPrice.toStringAsFixed(2)}'),
                    ],
                  );
                },
              ),
            ),
            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Bill:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                Text(
                  '₱${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (order.status == OrderStatus.ready) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Mark Served to Table'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.available,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _markOrderServed(
                    order,
                    beforeUpdate: () => Navigator.pop(ctx),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(
                  Icons.campaign_outlined,
                  color: AppColors.primary,
                ),
                label: Text(
                  'Notify / Call Table ${order.tableNumber} Customer',
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  _showNotifyCustomerDialog(order);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifyCustomerDialog(OrderModel order) {
    final textController = TextEditingController();
    String selectedPreset = 'Your food is ready and on the way!';

    final presets = [
      'Your food is ready and on the way!',
      'Your waiter is on the way to your table.',
      'We are attending to your request.',
      'Your bill has been printed at the cashier.',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Call / Notify Table ${order.tableNumber}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Send a real-time message or alert to the customer at this table:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              ...presets.map((msg) {
                final isSel =
                    selectedPreset == msg && textController.text.isEmpty;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setModalState(() {
                        selectedPreset = msg;
                        textController.clear();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.primaryLight
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSel
                              ? AppColors.primary
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSel
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: isSel
                                ? AppColors.primary
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              msg,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSel
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSel
                                    ? AppColors.primaryDark
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
              TextField(
                controller: textController,
                decoration: InputDecoration(
                  hintText: 'Or type custom message...',
                  hintStyle: const TextStyle(fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (_) => setModalState(() {}),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text('Send Alert to Table'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final message = textController.text.trim().isNotEmpty
                        ? textController.text.trim()
                        : selectedPreset;
                    Navigator.pop(ctx);
                    try {
                      await ref
                          .read(waiterRequestServiceProvider)
                          .notifyCustomer(
                            tableId: order.tableId.isNotEmpty
                                ? order.tableId
                                : order.tableNumber,
                            tableNumber: order.tableNumber,
                            orderId: order.id,
                            title: 'Waiter Update · Table ${order.tableNumber}',
                            message: message,
                          );
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Notified Table ${order.tableNumber}: "$message"',
                            ),
                            backgroundColor: AppColors.available,
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to notify customer: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
