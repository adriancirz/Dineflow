import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/brand_colors.dart';
import '../../core/sample_data.dart';
import '../../models/order_model.dart';
import '../../providers/customer_cart_provider.dart';
import '../../providers/customer_session_provider.dart';
import '../../providers/menu_providers.dart';
import '../../utils/currency.dart';

/// Customer Item Details Screen:
/// URL: /t/:tableId/menu/item/:itemId
/// Large dish photography, allergen indicators, chef badge,
/// special preparation instructions, and add-to-cart button.
class CustomerItemDetailsScreen extends ConsumerStatefulWidget {
  final String tableId;
  final String itemId;

  const CustomerItemDetailsScreen({
    super.key,
    required this.tableId,
    required this.itemId,
  });

  @override
  ConsumerState<CustomerItemDetailsScreen> createState() =>
      _CustomerItemDetailsScreenState();
}

class _CustomerItemDetailsScreenState
    extends ConsumerState<CustomerItemDetailsScreen> {
  int _quantity = 1;
  final TextEditingController _instructionsController = TextEditingController();
  final Set<String> _selectedModifierNames = {};

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  void _increment() => setState(() => _quantity++);
  void _decrement() {
    if (_quantity > 1) {
      setState(() => _quantity--);
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalizedTableId = normalizeTableId(widget.tableId);
    final itemsAsync = ref.watch(menuItemsStreamProvider);

    // Resolve MenuItemModel from stream or fallback to SampleData
    final allItems = itemsAsync.asData?.value ?? SampleData.defaultMenuItems;
    final item = allItems.firstWhere(
      (it) => it.id == widget.itemId,
      orElse: () => SampleData.defaultMenuItems.firstWhere(
        (it) => it.id == widget.itemId,
        orElse: () => SampleData.defaultMenuItems.first,
      ),
    );

    // Calculate dynamic line total with selected options/modifiers
    double extraCost = 0.0;
    final selectedMods = <SelectedModifier>[];
    for (final opt in item.options) {
      if (_selectedModifierNames.contains(opt.name)) {
        extraCost += opt.extraPrice;
        selectedMods.add(
          SelectedModifier(name: opt.name, additionalCost: opt.extraPrice),
        );
      }
    }

    final unitPrice = item.price + extraCost;
    final totalPrice = unitPrice * _quantity;

    return Scaffold(
      backgroundColor: BrandColors.creamBg,
      body: CustomScrollView(
        slivers: [
          // Hero Image Header
          SliverAppBar(
            expandedHeight: 260,
            pinned: true,
            backgroundColor: Colors.white,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back,
                  color: BrandColors.textPrimary,
                  size: 20,
                ),
              ),
              onPressed: () => context.go('/t/$normalizedTableId/menu'),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: BrandColors.primaryOrangeLight,
                child: item.imageUrl.isNotEmpty
                    ? Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => const Center(
                          child: Icon(
                            Icons.restaurant,
                            size: 72,
                            color: BrandColors.primaryOrange,
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.restaurant,
                          size: 72,
                          color: BrandColors.primaryOrange,
                        ),
                      ),
              ),
            ),
          ),

          // Content body
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges: Category & Chef Pick
                  Row(
                    children: [
                      if (item.isChefPick) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: BrandColors.warningBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(
                                Icons.star,
                                size: 14,
                                color: BrandColors.warning,
                              ),
                              SizedBox(width: 4),
                              Text(
                                "Chef's Pick",
                                style: TextStyle(
                                  color: BrandColors.warning,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),

                  // Name and Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          item.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: BrandColors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        formatPeso(unitPrice),
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: BrandColors.primaryOrange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Description
                  Text(
                    item.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: BrandColors.textSecondary,
                      height: 1.5,
                    ),
                  ),

                  // Allergen Warning Chips
                  if (item.allergens.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    const Text(
                      'Allergens',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: BrandColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: item.allergens.map((allergen) {
                        return Chip(
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: BrandColors.border),
                          avatar: const Icon(
                            Icons.info_outline,
                            size: 14,
                            color: BrandColors.textMuted,
                          ),
                          label: Text(
                            allergen,
                            style: const TextStyle(
                              fontSize: 12,
                              color: BrandColors.textSecondary,
                            ),
                          ),
                          visualDensity: VisualDensity.compact,
                        );
                      }).toList(),
                    ),
                  ],

                  // Options and Modifiers
                  if (item.options.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const Text(
                      'Customization Options',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: BrandColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...item.options.map((opt) {
                      final isSelected = _selectedModifierNames.contains(
                        opt.name,
                      );
                      return CheckboxListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        activeColor: BrandColors.primaryOrange,
                        title: Text(
                          opt.name,
                          style: const TextStyle(fontSize: 14),
                        ),
                        subtitle: opt.extraPrice > 0
                            ? Text(
                                '+ ${formatPeso(opt.extraPrice)}',
                                style: const TextStyle(
                                  color: BrandColors.primaryOrange,
                                ),
                              )
                            : null,
                        value: isSelected,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _selectedModifierNames.add(opt.name);
                            } else {
                              _selectedModifierNames.remove(opt.name);
                            }
                          });
                        },
                      );
                    }),
                  ],

                  const SizedBox(height: 20),
                  const Divider(color: BrandColors.divider),
                  const SizedBox(height: 14),

                  // Special Preparation Instructions
                  const Text(
                    'Special Instructions',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: BrandColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Let the chef know about allergies, temperature preferences, or ingredient removals.',
                    style: TextStyle(
                      fontSize: 12,
                      color: BrandColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _instructionsController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText:
                          'e.g. Less spicy, dressing on the side, no onions...',
                      hintStyle: const TextStyle(
                        fontSize: 13,
                        color: BrandColors.textMuted,
                      ),
                      filled: true,
                      fillColor: Colors.white,
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
                  ),

                  const SizedBox(height: 24),

                  // Quantity Stepper
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quantity',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: BrandColors.textPrimary,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: BrandColors.border),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 20),
                              color: _quantity > 1
                                  ? BrandColors.primaryOrange
                                  : BrandColors.textMuted,
                              onPressed: _decrement,
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                              ),
                              child: Text(
                                '$_quantity',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: BrandColors.textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, size: 20),
                              color: BrandColors.primaryOrange,
                              onPressed: _increment,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),

      // Bottom Add to Cart CTA Button
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
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
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: BrandColors.primaryOrange,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: () {
                final notes = _instructionsController.text.trim();
                ref
                    .read(customerCartProvider.notifier)
                    .addItem(
                      item: item,
                      quantity: _quantity,
                      specialInstructions: notes.isNotEmpty ? notes : null,
                      modifiers: selectedMods.isNotEmpty ? selectedMods : null,
                    );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Added $_quantity x ${item.name} to cart'),
                    backgroundColor: BrandColors.success,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );

                context.go('/t/$normalizedTableId/menu');
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add $_quantity to Cart',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    formatPeso(totalPrice),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
