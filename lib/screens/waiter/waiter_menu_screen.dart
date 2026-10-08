import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/sample_data.dart';
import '../../models/menu_item_model.dart';
import '../../providers/menu_providers.dart';
import '../../providers/order_providers.dart';
import '../../router/route_names.dart';
import '../common/dish_detail_sheet.dart';

class WaiterMenuScreen extends ConsumerStatefulWidget {
  final bool isTab;
  final VoidCallback? onBack;

  const WaiterMenuScreen({super.key, this.isTab = false, this.onBack});

  @override
  ConsumerState<WaiterMenuScreen> createState() => _WaiterMenuScreenState();
}

class _WaiterMenuScreenState extends ConsumerState<WaiterMenuScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final selectedCategory = ref.watch(selectedCategoryFilterProvider);
    final categoriesAsync = ref.watch(menuCategoriesStreamProvider);
    final itemsAsync = ref.watch(menuItemsStreamProvider);

    final tableLabel = cart.tableNumber != null ? 'Add items · ${cart.tableNumber}' : 'Menu Browsing';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: widget.isTab
            ? (widget.onBack != null
                ? IconButton(
                    icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                    onPressed: widget.onBack,
                  )
                : null)
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                onPressed: () => Navigator.of(context).pop(),
              ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tableLabel,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const Text(
              'Select items to build ticket',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
          ],
        ),
        actions: [
          // Cart Button in App Bar
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.receipt_long_outlined, color: AppColors.textPrimary),
                onPressed: () => context.push(AppRoutes.waiterCart),
              ),
              if (cart.itemCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    child: Text(
                      '${cart.itemCount}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // 1. Search Bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => ref.read(menuSearchQueryProvider.notifier).setQuery(val),
              decoration: InputDecoration(
                hintText: 'Search dishes, drinks...',
                hintStyle: const TextStyle(fontSize: 14, color: AppColors.textMuted),
                prefixIcon: const Icon(Icons.search, size: 20, color: AppColors.textMuted),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          ref.read(menuSearchQueryProvider.notifier).clear();
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          // 2. Category Filter Chips (Wireframe Page 9: Popular, Mains, Pasta, Drinks)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.only(bottom: 12),
            child: categoriesAsync.when(
              data: (categories) {
                final cats = categories.isEmpty ? SampleData.defaultCategories : categories;
                return SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      // "All" chip
                      _buildCategoryChip(
                        label: 'All Items',
                        isSelected: selectedCategory == null,
                        onTap: () => ref.read(selectedCategoryFilterProvider.notifier).selectCategory(null),
                      ),
                      const SizedBox(width: 8),
                      ...cats.map((cat) {
                        final isSel = selectedCategory == cat.id;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: _buildCategoryChip(
                            label: cat.name,
                            isSelected: isSel,
                            onTap: () => ref
                                .read(selectedCategoryFilterProvider.notifier)
                                .selectCategory(isSel ? null : cat.id),
                          ),
                        );
                      }),
                    ],
                  ),
                );
              },
              loading: () => const SizedBox(height: 36),
              error: (_, _) => const SizedBox(height: 36),
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // 3. Items Count & Cart Info Banner
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedCategory != null ? 'Filtered Category' : 'All Menu Dishes',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textSecondary),
                ),
                if (cart.itemCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Cart · ${cart.itemCount}  ₱${cart.total.toStringAsFixed(2)}',
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

          // 4. Menu Items List
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                final source = items.isEmpty ? SampleData.defaultMenuItems : items;
                return _buildMenuList(context, source);
              },
              loading: () => _buildMenuList(context, SampleData.defaultMenuItems),
              error: (_, _) => _buildMenuList(context, SampleData.defaultMenuItems),
            ),
          ),
        ],
      ),

      // Floating Bottom Cart Bar
      bottomNavigationBar: cart.itemCount > 0
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cart.itemCount} items selected',
                            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                          Text(
                            '₱${cart.total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text('Review Order'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => context.push(AppRoutes.waiterCart),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildCategoryChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.textPrimary : AppColors.border),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuList(BuildContext context, List<MenuItemModel> allItems) {
    final selectedCat = ref.watch(selectedCategoryFilterProvider);
    final query = ref.watch(menuSearchQueryProvider).toLowerCase().trim();

    var filtered = allItems;
    if (selectedCat != null && selectedCat.isNotEmpty) {
      filtered = filtered.where((i) => i.categoryId == selectedCat).toList();
    }
    if (query.isNotEmpty) {
      filtered = filtered.where((i) {
        return i.name.toLowerCase().contains(query) ||
            i.description.toLowerCase().contains(query) ||
            i.tags.any((t) => t.toLowerCase().contains(query));
      }).toList();
    }

    if (filtered.isEmpty) {
      return const Center(
        child: Text('No dishes match your search or filter'),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: filtered.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final item = filtered[index];
        return _buildDishCard(context, item);
      },
    );
  }

  Widget _buildDishCard(BuildContext context, MenuItemModel item) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: item.isAvailable ? () => DishDetailSheet.show(context, item) : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Dish Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 72,
                  height: 72,
                  color: item.isAvailable ? AppColors.primaryLight : Colors.grey.shade200,
                  child: item.imageUrl.isNotEmpty
                      ? Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => _buildItemIcon(item),
                        )
                      : _buildItemIcon(item),
                ),
              ),
              const SizedBox(width: 14),

              // Title, Tags, Price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: item.isAvailable ? AppColors.textPrimary : AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (item.badges.isNotEmpty)
                      Text(
                        item.badges.join(' · '),
                        style: TextStyle(
                          fontSize: 12,
                          color: item.isAvailable ? AppColors.textSecondary : AppColors.textMuted,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      '₱${item.price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: item.isAvailable ? AppColors.primary : AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),

              // Add Button or Unavailable Badge (satisfies BB CUST 003)
              if (item.isAvailable)
                IconButton(
                  icon: const Icon(Icons.add_circle, color: AppColors.primary, size: 30),
                  onPressed: () => DishDetailSheet.show(context, item),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.errorBg,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Unavailable',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.error),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildItemIcon(MenuItemModel item) {
    return Center(
      child: Icon(
        Icons.restaurant,
        size: 32,
        color: item.isAvailable ? AppColors.primary : AppColors.textMuted,
      ),
    );
  }
}
