import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/brand_colors.dart';
import '../../models/menu_item_model.dart';
import '../../providers/menu_providers.dart';
import '../../utils/currency.dart';
import 'menu_item_form_screen.dart';

/// Screen displaying the complete menu catalog for administrators with
/// live thumbnails, search, availability switches, and item editing.
class MenuManagementScreen extends ConsumerStatefulWidget {
  const MenuManagementScreen({super.key});

  @override
  ConsumerState<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends ConsumerState<MenuManagementScreen> {
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

  @override
  Widget build(BuildContext context) {
    final menuItemsAsync = ref.watch(menuItemsStreamProvider);

    return Scaffold(
      backgroundColor: BrandColors.creamBg,
      appBar: AppBar(
        title: const Text(
          'Menu Management',
          style: TextStyle(
            color: BrandColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: BrandColors.textPrimary),
            tooltip: 'Refresh menu',
            onPressed: () => ref.invalidate(menuItemsStreamProvider),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: BrandColors.primaryOrange,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Dish', style: TextStyle(fontWeight: FontWeight.bold)),
        onPressed: () => _openForm(),
      ),
      body: Column(
        children: [
          // Search & Filter header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Colors.white,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search dishes by name or ingredients...',
                    prefixIcon: const Icon(Icons.search, color: BrandColors.textMuted),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    filled: true,
                    fillColor: BrandColors.creamBg,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: BrandColors.divider),

          // Menu items list
          Expanded(
            child: menuItemsAsync.when(
              data: (items) {
                final query = _searchController.text.trim().toLowerCase();
                var filtered = items;

                if (query.isNotEmpty) {
                  filtered = filtered.where((item) {
                    final nameMatch = item.name.toLowerCase().contains(query);
                    final descMatch = item.description.toLowerCase().contains(query);
                    final tagsMatch = item.tags.any((t) => t.toLowerCase().contains(query));
                    return nameMatch || descMatch || tagsMatch;
                  }).toList();
                }

                if (filtered.isEmpty) {
                  return _buildEmptyState();
                }

                return RefreshIndicator(
                  color: BrandColors.primaryOrange,
                  onRefresh: () async {
                    ref.invalidate(menuItemsStreamProvider);
                  },
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return _buildItemCard(item);
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: BrandColors.primaryOrange),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline, size: 48, color: BrandColors.error),
                      const SizedBox(height: 12),
                      Text('Error loading menu: $err', textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(menuItemsStreamProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(MenuItemModel item) {
    final hasImage = item.imageUrl.isNotEmpty;

    return InkWell(
      onTap: () => _openForm(item),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: BrandColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail with real photo or placeholder icon
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72,
                height: 72,
                child: hasImage
                    ? Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (ctx, child, progress) {
                          if (progress == null) return child;
                          return Container(
                            color: BrandColors.creamBg,
                            child: const Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: BrandColors.primaryOrange,
                                ),
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: BrandColors.primaryOrangeLight,
                          child: const Icon(
                            Icons.restaurant,
                            color: BrandColors.primaryOrange,
                            size: 28,
                          ),
                        ),
                      )
                    : Container(
                        color: BrandColors.primaryOrangeLight,
                        child: const Icon(
                          Icons.restaurant,
                          color: BrandColors.primaryOrange,
                          size: 28,
                        ),
                      ),
              ),
            ),
            const SizedBox(width: 14),

            // Item Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: BrandColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (item.isChefPick) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: BrandColors.warningBg,
                            borderRadius: BorderRadius.circular(4),
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
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description.isNotEmpty
                        ? item.description
                        : (item.tags.isNotEmpty ? item.tags.first : 'No description'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: BrandColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatPeso(item.price),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: BrandColors.primaryOrange,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Availability Switch
            Column(
              children: [
                Switch(
                  value: item.isAvailable,
                  activeThumbColor: BrandColors.primaryOrange,
                  onChanged: (val) async {
                    await ref.read(menuRepositoryProvider).setItemAvailability(item.id, val);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${item.name} is now ${val ? "Available" : "Unavailable"}',
                          ),
                          duration: const Duration(seconds: 1),
                        ),
                      );
                    }
                  },
                ),
                Text(
                  item.isAvailable ? 'Available' : 'Sold Out',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: item.isAvailable ? BrandColors.success : BrandColors.error,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: BrandColors.primaryOrangeLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.restaurant_menu_outlined,
                size: 48,
                color: BrandColors.primaryOrange,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No Menu Items Found',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: BrandColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Start adding delicious dishes with photos to populate your restaurant menu.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: BrandColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              icon: const Icon(Icons.add),
              label: const Text('Add First Item'),
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColors.primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () => _openForm(),
            ),
          ],
        ),
      ),
    );
  }
}
