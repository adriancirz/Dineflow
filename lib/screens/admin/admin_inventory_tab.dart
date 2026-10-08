import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/sample_data.dart';
import '../../models/inventory_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_providers.dart';

class AdminInventoryTab extends ConsumerStatefulWidget {
  const AdminInventoryTab({super.key});

  @override
  ConsumerState<AdminInventoryTab> createState() => _AdminInventoryTabState();
}

class _AdminInventoryTabState extends ConsumerState<AdminInventoryTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAdjustStockDialog(InventoryItemModel item) {
    bool isStockIn = true; // true = Stock In, false = Stock Out
    final quantityController = TextEditingController();
    String reason = 'restock';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final qty = double.tryParse(quantityController.text.trim()) ?? 0.0;
          final double delta = isStockIn ? qty : -qty;
          final double predictedNewStock = item.currentStock + delta;
          final bool isNegative = predictedNewStock < 0;

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Adjust Stock · ${item.name}',
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
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Current stock display (Wireframe Page 19 bottom)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Current Stock:'),
                        Text(
                          '${item.currentStock.toStringAsFixed(1)} ${item.unit}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Stock In vs Stock Out toggle
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Stock In'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isStockIn
                                ? AppColors.available
                                : Colors.grey.shade200,
                            foregroundColor: isStockIn
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              isStockIn = true;
                              reason = 'restock';
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.remove, size: 16),
                          label: const Text('Stock Out'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: !isStockIn
                                ? AppColors.error
                                : Colors.grey.shade200,
                            foregroundColor: !isStockIn
                                ? Colors.white
                                : AppColors.textPrimary,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              isStockIn = false;
                              reason = 'usage';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Quantity input
                  TextField(
                    controller: quantityController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    onChanged: (_) => setDialogState(() {}),
                    decoration: InputDecoration(
                      labelText:
                          'Quantity to ${isStockIn ? "Add" : "Deduct"} (${item.unit}) *',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Reason dropdown
                  DropdownButtonFormField<String>(
                    initialValue: reason,
                    decoration: const InputDecoration(
                      labelText: 'Reason for Adjustment',
                    ),
                    items: (isStockIn
                        ? [
                            const DropdownMenuItem(
                              value: 'restock',
                              child: Text('Supplier Delivery / Restock'),
                            ),
                            const DropdownMenuItem(
                              value: 'recount',
                              child: Text('Inventory Count Correction'),
                            ),
                          ]
                        : [
                            const DropdownMenuItem(
                              value: 'usage',
                              child: Text('Kitchen Daily Usage'),
                            ),
                            const DropdownMenuItem(
                              value: 'spoilage',
                              child: Text('Expired / Spoilage'),
                            ),
                            const DropdownMenuItem(
                              value: 'damage',
                              child: Text('Damaged / Spilled'),
                            ),
                            const DropdownMenuItem(
                              value: 'recount',
                              child: Text('Inventory Count Correction'),
                            ),
                          ]),
                    onChanged: (val) {
                      if (val != null) setDialogState(() => reason = val);
                    },
                  ),
                  const SizedBox(height: 16),

                  // New Stock Result Preview & Negative Stock Rejection (WB ADM 002)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isNegative
                          ? AppColors.errorBg
                          : AppColors.availableBg,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isNegative
                            ? AppColors.error
                            : AppColors.available.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Resulting Stock Level:',
                          style: TextStyle(fontSize: 13),
                        ),
                        Text(
                          '${predictedNewStock.toStringAsFixed(1)} ${item.unit}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isNegative
                                ? AppColors.error
                                : AppColors.available,
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (isNegative) ...[
                    const SizedBox(height: 8),
                    const Text(
                      '❌ Invalid adjustment: Stock cannot be negative!',
                      style: TextStyle(
                        color: AppColors.error,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                onPressed: (qty <= 0 || isNegative)
                    ? null
                    : () async {
                        final user = ref
                            .read(currentUserProvider)
                            .asData
                            ?.value;
                        final adjustedBy = user?.displayName ?? 'Admin';

                        try {
                          await ref
                              .read(inventoryRepositoryProvider)
                              .adjustStock(
                                itemId: item.id,
                                delta: delta,
                                reason: reason,
                                adjustedBy: adjustedBy,
                              );
                          if (ctx.mounted) Navigator.pop(ctx);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Updated ${item.name} stock to ${predictedNewStock.toStringAsFixed(1)} ${item.unit}',
                                ),
                                backgroundColor: AppColors.available,
                              ),
                            );
                          }
                        } on FirebaseException catch (e) {
                          if (mounted) {
                            final message = e.code == 'permission-denied'
                                ? 'Permission denied. Deploy firestore.rules and confirm you are signed in as admin.'
                                : 'Could not save stock adjustment (${e.code}): ${e.message ?? e.toString()}';
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(message),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Could not adjust stock: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                child: const Text('Confirm Adjustment'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inventoryAsync = ref.watch(inventoryStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row (Wireframe Page 19 middle)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Inventory & Stock',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Track ingredient quantities, units, and safety thresholds',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add_shopping_cart, size: 16),
                  label: const Text('Add stock item'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Tap "Adjust" on any ingredient row below to record stock in/out',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Summary Stats (Wireframe Page 19)
            inventoryAsync.when(
              data: (list) {
                final items = list.isEmpty ? SampleData.defaultInventory : list;
                final lowStock = items.where((i) => i.isLowStock).length;
                final outOfStock = items
                    .where((i) => i.currentStock <= 0)
                    .length;

                return Row(
                  children: [
                    _buildStatCard(
                      'Tracked Items',
                      '${items.length}',
                      AppColors.textPrimary,
                      Colors.white,
                    ),
                    const SizedBox(width: 14),
                    _buildStatCard(
                      'Low Stock',
                      '$lowStock',
                      AppColors.occupied,
                      AppColors.occupiedBg,
                    ),
                    const SizedBox(width: 14),
                    _buildStatCard(
                      'Out of Stock',
                      '$outOfStock',
                      AppColors.error,
                      AppColors.errorBg,
                    ),
                  ],
                );
              },
              loading: () => const SizedBox(height: 60),
              error: (_, _) => const SizedBox(height: 60),
            ),
            const SizedBox(height: 20),

            // Inventory Table
            Expanded(
              child: inventoryAsync.when(
                data: (list) {
                  final items = list.isEmpty
                      ? SampleData.defaultInventory
                      : list;
                  return _buildInventoryTable(items);
                },
                loading: () =>
                    _buildInventoryTable(SampleData.defaultInventory),
                error: (_, _) =>
                    _buildInventoryTable(SampleData.defaultInventory),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        decoration: BoxDecoration(
          color: bg,
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
                  value,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryTable(List<InventoryItemModel> items) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: const [
                Expanded(
                  flex: 3,
                  child: Text(
                    'Item Name',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Category',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Current Stock',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Min. Safety',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: Text(
                    'Status',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'Action',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Items
          Expanded(
            child: ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (ctx, i) {
                final it = items[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: Row(
                    children: [
                      // Name
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              it.name,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              'SKU: ${it.sku} · ${it.supplier}',
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Category
                      Expanded(
                        flex: 2,
                        child: Text(
                          it.category,
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ),

                      // Current Stock
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${it.currentStock.toStringAsFixed(1)} ${it.unit}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: it.isLowStock
                                ? AppColors.error
                                : AppColors.textPrimary,
                          ),
                        ),
                      ),

                      // Min Safety Threshold
                      Expanded(
                        flex: 2,
                        child: Text(
                          '${it.minThreshold.toStringAsFixed(1)} ${it.unit}',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ),

                      // Status Badge
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: it.isLowStock
                                ? AppColors.errorBg
                                : AppColors.availableBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            it.isLowStock ? '⚠️ Low Stock' : '✓ Normal',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: it.isLowStock
                                  ? AppColors.error
                                  : AppColors.available,
                            ),
                          ),
                        ),
                      ),

                      // Adjust Action Button (WB ADM 002)
                      SizedBox(
                        width: 80,
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            side: const BorderSide(color: AppColors.primary),
                            foregroundColor: AppColors.primary,
                          ),
                          onPressed: () => _showAdjustStockDialog(it),
                          child: const Text(
                            'Adjust',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
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
}
