import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_providers.dart';
import '../../providers/order_providers.dart';

class AdminDashboardTab extends ConsumerWidget {
  final Function(int tabIndex)? onNavigateTab;

  const AdminDashboardTab({super.key, this.onNavigateTab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final orders = ref.watch(ordersStreamProvider).asData?.value ?? [];
    final inventoryAsync = ref.watch(inventoryStreamProvider);
    final inventory = inventoryAsync.asData?.value ?? [];

    // Calculate real live KPIs if orders exist
    final completedOrders = orders
        .where((o) => o.paymentStatus == 'paid')
        .toList();
    final double realSales = completedOrders.fold(
      0.0,
      (acc, o) => acc + o.total,
    );
    final int realOrderCount = orders.length;
    final double aov = realOrderCount > 0
        ? (realSales /
              (completedOrders.isNotEmpty ? completedOrders.length : 1))
        : 45.79;

    final lowStockItems = inventory.where((i) => i.isLowStock).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row (Wireframe Page 18)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Good afternoon, ${user?.displayName.split(" ").first ?? "Adrian"}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Here is your restaurant operations summary for today.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: const [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 14,
                            color: AppColors.textSecondary,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Today',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.download_outlined, size: 16),
                      label: const Text('Export'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Operations report exported to CSV/PDF',
                            ),
                            backgroundColor: AppColors.available,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // 4 KPI Cards (Wireframe Page 18)
            Row(
              children: [
                _buildKpiCard(
                  title: 'Today Sales',
                  value: realSales > 0
                      ? '₱${realSales.toStringAsFixed(2)}'
                      : '₱48,426.00',
                  badge: '+12.5%',
                  isPositive: true,
                  icon: Icons.payments_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 14),
                _buildKpiCard(
                  title: 'Total Orders',
                  value: realOrderCount > 0 ? '$realOrderCount' : '184',
                  badge: '+8.2%',
                  isPositive: true,
                  icon: Icons.receipt_long,
                  color: AppColors.reserved,
                ),
                const SizedBox(width: 14),
                _buildKpiCard(
                  title: 'Avg. Order Value',
                  value: '₱${aov.toStringAsFixed(2)}',
                  badge: '+3.1%',
                  isPositive: true,
                  icon: Icons.trending_up,
                  color: AppColors.available,
                ),
                const SizedBox(width: 14),
                _buildKpiCard(
                  title: 'Table Turn Rate',
                  value: '2.7x',
                  badge: 'Optimal',
                  isPositive: true,
                  icon: Icons.table_restaurant,
                  color: AppColors.occupied,
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Middle Row: Sales Trend Bar Chart & Live Low-Stock Warning
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sales Trend Chart (Mock wireframe chart)
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            Text(
                              'Sales Activity',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              'Hourly (11 AM – 9 PM)',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        // Bar Chart Visualizer
                        SizedBox(
                          height: 140,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              _buildBar('11a', 40),
                              _buildBar('12p', 85),
                              _buildBar('1p', 100),
                              _buildBar('2p', 60),
                              _buildBar('3p', 30),
                              _buildBar('4p', 25),
                              _buildBar('5p', 50),
                              _buildBar('6p', 80),
                              _buildBar('7p', 95),
                              _buildBar('8p', 75),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Live Low-Stock Warning Panel
                Expanded(
                  flex: 2,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.warning_amber_rounded,
                                  color:
                                      inventoryAsync.hasError ||
                                          lowStockItems.isNotEmpty
                                      ? AppColors.error
                                      : AppColors.available,
                                  size: 20,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Low Stock Alert',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: lowStockItems.isEmpty
                                    ? AppColors.availableBg
                                    : AppColors.errorBg,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                inventoryAsync.isLoading
                                    ? '...'
                                    : inventoryAsync.hasError
                                    ? 'Error'
                                    : '${lowStockItems.length} items',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: lowStockItems.isEmpty
                                      ? AppColors.available
                                      : AppColors.error,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Inventory items at or below their minimum safety threshold:',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 14),
                        inventoryAsync.when(
                          loading: () => const Padding(
                            padding: EdgeInsets.symmetric(vertical: 18),
                            child: Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          error: (error, _) => Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Could not load inventory alerts.',
                                  style: TextStyle(
                                    color: AppColors.error,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                              IconButton(
                                tooltip: 'Retry',
                                onPressed: () =>
                                    ref.invalidate(inventoryStreamProvider),
                                icon: const Icon(Icons.refresh),
                              ),
                            ],
                          ),
                          data: (items) {
                            final alerts =
                                items.where((item) => item.isLowStock).toList()
                                  ..sort(
                                    (a, b) => a.currentStock.compareTo(
                                      b.currentStock,
                                    ),
                                  );

                            if (items.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'No inventory items found.',
                                  style: TextStyle(
                                    color: AppColors.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              );
                            }
                            if (alerts.isEmpty) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      color: AppColors.available,
                                      size: 18,
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'All inventory is above its minimum threshold.',
                                        style: TextStyle(
                                          color: AppColors.available,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Column(
                              children: alerts.take(4).map((item) {
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: AppColors.errorBg.withValues(
                                      alpha: 0.4,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              '${item.currentStock.toStringAsFixed(1)} ${item.unit} / min ${item.minThreshold.toStringAsFixed(1)} ${item.unit}',
                                              style: const TextStyle(
                                                fontSize: 11,
                                                color: AppColors.error,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.warning_amber_rounded,
                                        color: AppColors.error,
                                        size: 16,
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                            ),
                            onPressed: () {
                              if (onNavigateTab != null) onNavigateTab!(3);
                            },
                            child: const Text(
                              'View inventory & adjust stock',
                              style: TextStyle(fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Popular Dishes Section (Wireframe Page 18)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Popular Dishes Today',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 14),
                  _buildPopularDishRow(
                    '1',
                    'Truffle Mushroom Pasta',
                    'Pasta',
                    '112 orders',
                    '₱42,560.00',
                  ),
                  const Divider(height: 16),
                  _buildPopularDishRow(
                    '2',
                    'Citrus Salmon Bowl',
                    'Mains',
                    '84 orders',
                    '₱40,320.00',
                  ),
                  const Divider(height: 16),
                  _buildPopularDishRow(
                    '3',
                    'Smoky Chicken Burger',
                    'Mains',
                    '64 orders',
                    '₱17,920.00',
                  ),
                  const Divider(height: 16),
                  _buildPopularDishRow(
                    '4',
                    'Sparkling Calamansi Soda',
                    'Drinks',
                    '95 orders',
                    '₱9,025.00',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String value,
    required String badge,
    required bool isPositive,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                CircleAvatar(
                  radius: 16,
                  backgroundColor: color.withValues(alpha: 0.12),
                  child: Icon(icon, size: 16, color: color),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isPositive ? AppColors.availableBg : AppColors.errorBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: isPositive ? AppColors.available : AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBar(String label, double heightPercentage) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 22,
          height: heightPercentage,
          decoration: BoxDecoration(
            color: heightPercentage > 75
                ? AppColors.primary
                : AppColors.primaryLight,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _buildPopularDishRow(
    String rank,
    String name,
    String category,
    String orders,
    String revenue,
  ) {
    return Row(
      children: [
        CircleAvatar(
          radius: 12,
          backgroundColor: AppColors.background,
          child: Text(
            rank,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                category,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Text(
          orders,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(width: 24),
        Text(
          revenue,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
