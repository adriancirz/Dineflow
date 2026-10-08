import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/order_providers.dart';
import '../../widgets/dineflow_logo.dart';

class KitchenHomeScreen extends ConsumerStatefulWidget {
  const KitchenHomeScreen({super.key});

  @override
  ConsumerState<KitchenHomeScreen> createState() => _KitchenHomeScreenState();
}

class _KitchenHomeScreenState extends ConsumerState<KitchenHomeScreen> {
  String _selectedStation = 'All';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Update timers periodically
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatElapsed(DateTime? placedAt) {
    if (placedAt == null) return '0 min';
    final diff = DateTime.now().difference(placedAt);
    if (diff.inMinutes < 1) return '< 1 min';
    return '${diff.inMinutes} min';
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
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
              children: const [
                Text(
                  'DineFlow - Kitchen ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                Text(
                  'Real-time preparation queue',
                  style: TextStyle(fontSize: 11, color: Colors.white70),
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
      body: Column(
        children: [
          // Station Filter Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Text(
                  'Station: ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          [
                            'All',
                            'Hot Kitchen',
                            'Grill & Oven',
                            'Pasta',
                            'Beverages',
                          ].map((st) {
                            final isSel = _selectedStation == st;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: ChoiceChip(
                                label: Text(st),
                                selected: isSel,
                                selectedColor: AppColors.primaryLight,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  color: isSel
                                      ? AppColors.primaryDark
                                      : AppColors.textPrimary,
                                  fontWeight: isSel
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                ),
                                onSelected: (val) {
                                  if (val)
                                    setState(() => _selectedStation = st);
                                },
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // 3 Columns: Pending, Preparing, Ready (Wireframe Page 16)
          Expanded(
            child: ordersAsync.when(
              data: (orders) {
                final pending = orders
                    .where((o) => o.status == OrderStatus.pending)
                    .toList();
                final preparing = orders
                    .where((o) => o.status == OrderStatus.preparing)
                    .toList();
                final ready = orders
                    .where((o) => o.status == OrderStatus.ready)
                    .toList();

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth > 800;

                    if (isWide) {
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: _buildQueueColumn(
                              title: 'Pending',
                              count: pending.length,
                              badgeColor: AppColors.pending,
                              bgColor: AppColors.pendingBg,
                              orders: pending,
                              nextActionLabel: 'Start preparing',
                              nextActionColor: AppColors.occupied,
                              onAdvanceStatus: (o) => ref
                                  .read(orderRepositoryProvider)
                                  .updateOrderStatus(
                                    o.id,
                                    OrderStatus.preparing,
                                  ),
                            ),
                          ),
                          Container(width: 1, color: AppColors.divider),
                          Expanded(
                            child: _buildQueueColumn(
                              title: 'Preparing',
                              count: preparing.length,
                              badgeColor: AppColors.occupied,
                              bgColor: AppColors.occupiedBg,
                              orders: preparing,
                              nextActionLabel: 'Mark as ready',
                              nextActionColor: AppColors.available,
                              onAdvanceStatus: (o) => ref
                                  .read(orderRepositoryProvider)
                                  .updateOrderStatus(o.id, OrderStatus.ready),
                            ),
                          ),
                          Container(width: 1, color: AppColors.divider),
                          Expanded(
                            child: _buildQueueColumn(
                              title: 'Ready',
                              count: ready.length,
                              badgeColor: AppColors.available,
                              bgColor: AppColors.availableBg,
                              orders: ready,
                              nextActionLabel: 'Call waiter / Served',
                              nextActionColor: AppColors.reserved,
                              onAdvanceStatus: (o) => ref
                                  .read(orderRepositoryProvider)
                                  .updateOrderStatus(o.id, OrderStatus.served),
                            ),
                          ),
                        ],
                      );
                    } else {
                      // Tabbed view for mobile
                      return DefaultTabController(
                        length: 3,
                        child: Column(
                          children: [
                            TabBar(
                              labelColor: AppColors.textPrimary,
                              indicatorColor: AppColors.primary,
                              tabs: [
                                Tab(text: 'Pending (${pending.length})'),
                                Tab(text: 'Preparing (${preparing.length})'),
                                Tab(text: 'Ready (${ready.length})'),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _buildMobileQueueList(
                                    pending,
                                    'Start preparing',
                                    AppColors.occupied,
                                    (o) => ref
                                        .read(orderRepositoryProvider)
                                        .updateOrderStatus(
                                          o.id,
                                          OrderStatus.preparing,
                                        ),
                                  ),
                                  _buildMobileQueueList(
                                    preparing,
                                    'Mark as ready',
                                    AppColors.available,
                                    (o) => ref
                                        .read(orderRepositoryProvider)
                                        .updateOrderStatus(
                                          o.id,
                                          OrderStatus.ready,
                                        ),
                                  ),
                                  _buildMobileQueueList(
                                    ready,
                                    'Call waiter / Served',
                                    AppColors.reserved,
                                    (o) => ref
                                        .read(orderRepositoryProvider)
                                        .updateOrderStatus(
                                          o.id,
                                          OrderStatus.served,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) =>
                  Center(child: Text('Error loading kitchen orders: $err')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQueueColumn({
    required String title,
    required int count,
    required Color badgeColor,
    required Color bgColor,
    required List<OrderModel> orders,
    required String nextActionLabel,
    required Color nextActionColor,
    required Function(OrderModel) onAdvanceStatus,
  }) {
    return Container(
      color: Colors.transparent,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Column Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: badgeColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: badgeColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$count',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: badgeColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Orders List
          Expanded(
            child: orders.isEmpty
                ? Center(
                    child: Text(
                      'No $title orders',
                      style: const TextStyle(color: AppColors.textMuted),
                    ),
                  )
                : ListView.separated(
                    itemCount: orders.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (ctx, i) {
                      final order = orders[i];
                      return _buildKitchenTicketCard(
                        order,
                        nextActionLabel,
                        nextActionColor,
                        onAdvanceStatus,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileQueueList(
    List<OrderModel> orders,
    String nextActionLabel,
    Color nextActionColor,
    Function(OrderModel) onAdvanceStatus,
  ) {
    if (orders.isEmpty) {
      return const Center(
        child: Text(
          'No orders in this column',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (ctx, i) {
        final order = orders[i];
        return _buildKitchenTicketCard(
          order,
          nextActionLabel,
          nextActionColor,
          onAdvanceStatus,
        );
      },
    );
  }

  Widget _buildKitchenTicketCard(
    OrderModel order,
    String nextActionLabel,
    Color nextActionColor,
    Function(OrderModel) onAdvanceStatus,
  ) {
    final elapsed = _formatElapsed(order.placedAt);
    final isDelayed =
        (order.placedAt != null &&
        DateTime.now().difference(order.placedAt!).inMinutes > 20);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDelayed ? AppColors.error : AppColors.border,
          width: isDelayed ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showFocusedOrderSheet(order),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ticket Header: Table & Elapsed Time (Wireframe Page 16)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(
                        'Table ${order.tableNumber}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        order.orderNumber,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: isDelayed
                            ? AppColors.error
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        elapsed,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDelayed
                              ? AppColors.error
                              : AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Divider(height: 14, color: AppColors.divider),

              // Items breakdown with quantities
              ...order.items.map(
                (it) => Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${it.quantity}x',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              it.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            if (it.notes != null && it.notes!.isNotEmpty)
                              Text(
                                it.notes!,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.occupied,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              if (order.orderNotes != null && order.orderNotes!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.pendingBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Note: ${order.orderNotes}',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // Status Advance Action Button (satisfies BB ADM 001)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: nextActionColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => onAdvanceStatus(order),
                  child: Text(
                    nextActionLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Kitchen Focused Order Modal (Wireframe Page 16 middle)
  void _showFocusedOrderSheet(OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.85,
            ),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Modal Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Order ${order.orderNumber}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Table ${order.tableNumber} · Status: ${order.status.label}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Large Elapsed Timer box
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 10,
                    horizontal: 16,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Elapsed preparation time:'),
                      Text(
                        _formatElapsed(order.placedAt),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text(
                  'Preparation Checklist:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 8),

                // Items list
                Expanded(
                  child: ListView.separated(
                    itemCount: order.items.length,
                    separatorBuilder: (_, _) => const Divider(height: 10),
                    itemBuilder: (ctx, i) {
                      final it = order.items[i];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primaryLight,
                          child: Text(
                            '${it.quantity}x',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(
                          it.name,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: it.notes != null ? Text(it.notes!) : null,
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),

                // Rapid Actions (Wireframe Page 16)
                Row(
                  children: [
                    if (order.status != OrderStatus.pending)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            Navigator.pop(ctx);
                            await ref
                                .read(orderRepositoryProvider)
                                .updateOrderStatus(
                                  order.id,
                                  OrderStatus.pending,
                                );
                          },
                          child: const Text('Return to pending'),
                        ),
                      ),
                    if (order.status != OrderStatus.pending)
                      const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.available,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await ref
                              .read(orderRepositoryProvider)
                              .updateOrderStatus(order.id, OrderStatus.ready);
                        },
                        child: const Text(
                          'Mark order ready',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
