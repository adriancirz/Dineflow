import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/brand_colors.dart';
import '../../core/sample_data.dart';
import '../../models/menu_item_model.dart';
import '../../providers/customer_cart_provider.dart';
import '../../providers/customer_session_provider.dart';
import '../../providers/menu_providers.dart';
import '../../providers/notification_providers.dart';
import '../../services/waiter_request_service.dart';
import '../../utils/currency.dart';

/// Customer Menu Screen:
/// URL: /t/:tableId/menu
/// Browse menu categories, search dishes, view Philippine Peso prices,
/// and access floating cart checkout bar.
class CustomerMenuScreen extends ConsumerStatefulWidget {
  final String tableId;

  const CustomerMenuScreen({super.key, required this.tableId});

  @override
  ConsumerState<CustomerMenuScreen> createState() => _CustomerMenuScreenState();
}

class _CustomerMenuScreenState extends ConsumerState<CustomerMenuScreen> {
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _callWaiterQuick() async {
    final session = ref.read(customerSessionProvider);
    final normalizedId =
        session.tableNumber ?? normalizeTableId(widget.tableId);

    try {
      await ref
          .read(waiterRequestServiceProvider)
          .callWaiter(
            tableId: session.tableId ?? normalizedId,
            tableNumber: normalizedId,
            reason: 'Assistance at table',
          );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Waiter notified for Table $normalizedId! Someone will be with you shortly.',
            ),
            backgroundColor: BrandColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not reach waiter: $e'),
            backgroundColor: BrandColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalizedId = normalizeTableId(widget.tableId);
    final cart = ref.watch(customerCartProvider);
    final itemsAsync = ref.watch(menuItemsStreamProvider);
    final categoriesAsync = ref.watch(menuCategoriesStreamProvider);
    final notifsAsync = ref.watch(
      customerNotificationsStreamProvider(normalizedId),
    );
    final activeAlerts = (notifsAsync.asData?.value ?? [])
        .where((n) => n.status == 'unread')
        .toList();

    return Scaffold(
      backgroundColor: BrandColors.creamBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          tooltip: 'Back to guest count',
          icon: const Icon(Icons.arrow_back, color: BrandColors.textPrimary),
          onPressed: () => context.go('/t/$normalizedId/guests'),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Table $normalizedId',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: BrandColors.textPrimary,
              ),
            ),
            const Text(
              'DineFlow Restaurant',
              style: TextStyle(fontSize: 12, color: BrandColors.textSecondary),
            ),
          ],
        ),
        actions: [
          // Assistance Call Button
          IconButton(
            tooltip: 'Call Waiter',
            icon: const Icon(
              Icons.room_service_outlined,
              color: BrandColors.primaryOrange,
            ),
            onPressed: _callWaiterQuick,
          ),

          // Cart Icon with badge
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(
                  Icons.shopping_bag_outlined,
                  color: BrandColors.textPrimary,
                ),
                onPressed: () => context.go('/t/$normalizedId/cart'),
              ),
              if (cart.itemCount > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: BrandColors.primaryOrange,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
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
          // Active Staff Alerts
          if (activeAlerts.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Column(
                children: activeAlerts
                    .map(
                      (alert) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFF59E0B),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.campaign,
                              color: Color(0xFFB45309),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    alert.title.isNotEmpty
                                        ? alert.title
                                        : 'Staff Alert',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: Color(0xFF92400E),
                                    ),
                                  ),
                                  Text(
                                    alert.message,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF78350F),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                foregroundColor: const Color(0xFFB45309),
                              ),
                              onPressed: () => ref
                                  .read(notificationActionsProvider)
                                  .markAsRead(alert.id),
                              child: const Text(
                                'OK',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search dishes, drinks, desserts...',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: BrandColors.textMuted,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: BrandColors.textSecondary,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: BrandColors.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: BrandColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: BrandColors.primaryOrange,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (val) =>
                  setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
          ),

          // Categories Chips Bar
          categoriesAsync.when(
            data: (cats) {
              final catNames = ['All', ...cats.map((c) => c.name)];
              return _buildCategoryBar(catNames);
            },
            loading: () => _buildCategoryBar(const [
              'All',
              'Mains',
              'Pasta',
              'Sides',
              'Desserts',
              'Drinks',
            ]),
            error: (_, _) => _buildCategoryBar(const [
              'All',
              'Mains',
              'Pasta',
              'Sides',
              'Desserts',
              'Drinks',
            ]),
          ),

          // Menu Items List
          Expanded(
            child: itemsAsync.when(
              data: (items) {
                final source = items.isEmpty
                    ? SampleData.defaultMenuItems
                    : items;
                return _buildItemsList(source, normalizedId);
              },
              loading: () =>
                  _buildItemsList(SampleData.defaultMenuItems, normalizedId),
              error: (_, _) =>
                  _buildItemsList(SampleData.defaultMenuItems, normalizedId),
            ),
          ),
        ],
      ),

      // Sticky Bottom Cart Bar
      bottomNavigationBar: cart.itemCount > 0
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${cart.itemCount} ${cart.itemCount == 1 ? "item" : "items"} in cart',
                            style: const TextStyle(
                              fontSize: 12,
                              color: BrandColors.textSecondary,
                            ),
                          ),
                          Text(
                            formatPeso(cart.subtotal),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: BrandColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BrandColors.primaryOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      label: const Text(
                        'View Cart',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      onPressed: () => context.go('/t/$normalizedId/cart'),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildCategoryBar(List<String> categories) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (ctx, i) {
          final cat = categories[i];
          final isSelected =
              _selectedCategory.toLowerCase() == cat.toLowerCase();
          return ChoiceChip(
            label: Text(cat),
            selected: isSelected,
            selectedColor: BrandColors.primaryOrange,
            backgroundColor: Colors.white,
            labelStyle: TextStyle(
              color: isSelected ? Colors.white : BrandColors.textPrimary,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
            side: BorderSide(
              color: isSelected
                  ? BrandColors.primaryOrange
                  : BrandColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            onSelected: (_) => setState(() => _selectedCategory = cat),
          );
        },
      ),
    );
  }

  Widget _buildItemsList(List<MenuItemModel> allItems, String tableId) {
    final filtered = allItems.where((it) {
      final matchesSearch =
          _searchQuery.isEmpty ||
          it.name.toLowerCase().contains(_searchQuery) ||
          it.description.toLowerCase().contains(_searchQuery);

      final matchesCategory =
          _selectedCategory == 'All' ||
          it.category.toLowerCase() == _selectedCategory.toLowerCase() ||
          it.tags.any(
            (t) => t.toLowerCase() == _selectedCategory.toLowerCase(),
          );

      return matchesSearch && matchesCategory;
    }).toList();

    if (filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off,
              size: 48,
              color: BrandColors.textMuted,
            ),
            const SizedBox(height: 12),
            Text(
              'No items found',
              style: TextStyle(
                color: BrandColors.textSecondary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Try changing your category or search term',
              style: TextStyle(color: BrandColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: filtered.length,
      itemBuilder: (ctx, i) {
        final item = filtered[i];
        return _buildDishCard(item, tableId);
      },
    );
  }

  Widget _buildDishCard(MenuItemModel item, String tableId) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: BrandColors.border),
      ),
      color: Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: item.isAvailable
            ? () => context.go('/t/$tableId/menu/item/${item.id}')
            : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dish Image / Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  width: 90,
                  height: 90,
                  color: item.isAvailable
                      ? BrandColors.primaryOrangeLight
                      : Colors.grey.shade200,
                  child: item.imageUrl.isNotEmpty
                      ? Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.restaurant,
                            color: BrandColors.primaryOrange,
                            size: 32,
                          ),
                        )
                      : const Icon(
                          Icons.restaurant,
                          color: BrandColors.primaryOrange,
                          size: 32,
                        ),
                ),
              ),
              const SizedBox(width: 14),

              // Title, Description, Tags, Price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: item.isAvailable
                                  ? BrandColors.textPrimary
                                  : BrandColors.textMuted,
                            ),
                          ),
                        ),
                        if (item.isChefPick)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: BrandColors.warningBg,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              "Chef's Pick",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: BrandColors.warning,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        color: item.isAvailable
                            ? BrandColors.textSecondary
                            : BrandColors.textMuted,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          formatPeso(item.price),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: item.isAvailable
                                ? BrandColors.primaryOrange
                                : BrandColors.textMuted,
                          ),
                        ),
                        if (item.isAvailable)
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: BrandColors.primaryOrange,
                              side: const BorderSide(
                                color: BrandColors.primaryOrange,
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              visualDensity: VisualDensity.compact,
                            ),
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text(
                              'Add',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            onPressed: () =>
                                context.go('/t/$tableId/menu/item/${item.id}'),
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade200,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Sold Out',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
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
    );
  }
}
