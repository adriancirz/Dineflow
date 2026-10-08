import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/sample_data.dart';
import '../../models/menu_item_model.dart';
import '../../providers/firebase_providers.dart';
import '../../providers/menu_providers.dart';
import 'menu_item_form_screen.dart';

class AdminMenuTab extends ConsumerStatefulWidget {
  const AdminMenuTab({super.key});

  @override
  ConsumerState<AdminMenuTab> createState() => _AdminMenuTabState();
}

class _AdminMenuTabState extends ConsumerState<AdminMenuTab> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _openForm([MenuItemModel? item]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => MenuItemFormScreen(itemToEdit: item),
      ),
    );
  }

  Future<void> _deleteItem(MenuItemModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Menu Item'),
        content: Text('Are you sure you want to remove "${item.name}" from the menu?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final db = ref.read(firestoreProvider);
      await db.collection('menu').doc(item.id).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Removed ${item.name} from menu'), backgroundColor: AppColors.available),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final menuItemsAsync = ref.watch(menuItemsStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row (Wireframe Page 18 middle)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text('Menu management', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    SizedBox(height: 4),
                    Text('Configure dishes, pricing, and availability', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
                Row(
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.category_outlined, size: 16),
                      label: const Text('Add category'),
                      style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12)),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Categories managed in Firestore'), backgroundColor: AppColors.available),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.add, size: 16),
                      label: const Text('Add item'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _openForm(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Bar & Filter
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) => setState(() {}),
                      decoration: const InputDecoration(
                        hintText: 'Search menu dishes by name or ingredient...',
                        hintStyle: TextStyle(fontSize: 14, color: AppColors.textMuted),
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Table of Dishes (Wireframe Page 18)
            Expanded(
              child: menuItemsAsync.when(
                data: (itemsList) {
                  final items = itemsList.isEmpty ? SampleData.defaultMenuItems : itemsList;
                  return _buildTable(items);
                },
                loading: () => _buildTable(SampleData.defaultMenuItems),
                error: (_, _) => _buildTable(SampleData.defaultMenuItems),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(List<MenuItemModel> items) {
    final query = _searchController.text.trim().toLowerCase();
    var filtered = items;
    if (query.isNotEmpty) {
      filtered = filtered.where((it) {
        return it.name.toLowerCase().contains(query) ||
            it.description.toLowerCase().contains(query) ||
            it.tags.any((t) => t.toLowerCase().contains(query));
      }).toList();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          // Table Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: const [
                SizedBox(width: 50, child: Text('Dish', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary))),
                Expanded(flex: 3, child: Text('Name', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('Category', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('Price', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary))),
                Expanded(flex: 2, child: Text('Availability', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary))),
                SizedBox(width: 80, child: Text('Actions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textSecondary))),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Items rows
          Expanded(
            child: ListView.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (ctx, i) {
                final it = filtered[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Row(
                    children: [
                      // Thumbnail
                      SizedBox(
                        width: 50,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: it.imageUrl.isNotEmpty
                              ? Image.network(
                                  it.imageUrl,
                                  width: 36,
                                  height: 36,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    width: 36,
                                    height: 36,
                                    color: AppColors.primaryLight,
                                    child: const Icon(Icons.restaurant, size: 20, color: AppColors.primary),
                                  ),
                                )
                              : Container(
                                  width: 36,
                                  height: 36,
                                  color: AppColors.primaryLight,
                                  child: const Icon(Icons.restaurant, size: 20, color: AppColors.primary),
                                ),
                        ),
                      ),

                      // Name
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(it.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            if (it.isChefPick)
                              const Text("★ Chef's pick", style: TextStyle(fontSize: 11, color: AppColors.pending, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),

                      // Category
                      Expanded(
                        flex: 2,
                        child: Text(
                          it.tags.isNotEmpty ? it.tags.first : 'Mains',
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                        ),
                      ),

                      // Price
                      Expanded(
                        flex: 2,
                        child: Text(
                          '₱${it.price.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),

                      // Availability Switch (WB ADM 001)
                      Expanded(
                        flex: 2,
                        child: Row(
                          children: [
                            Switch(
                              value: it.isAvailable,
                              activeThumbColor: AppColors.available,
                              onChanged: (val) async {
                                await ref.read(menuRepositoryProvider).setItemAvailability(it.id, val);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${it.name} is now ${val ? "Available" : "Unavailable"}'),
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                }
                              },
                            ),
                            Text(
                              it.isAvailable ? 'Active' : 'Hidden',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: it.isAvailable ? AppColors.available : AppColors.error,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Actions
                      SizedBox(
                        width: 80,
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                              onPressed: () => _openForm(it),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error),
                              onPressed: () => _deleteItem(it),
                            ),
                          ],
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
