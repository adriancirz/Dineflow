import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/menu_item_model.dart';
import '../../models/order_model.dart';
import '../../providers/order_providers.dart';

class DishDetailSheet extends ConsumerStatefulWidget {
  final MenuItemModel item;

  const DishDetailSheet({super.key, required this.item});

  static Future<void> show(BuildContext context, MenuItemModel item) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DishDetailSheet(item: item),
    );
  }

  @override
  ConsumerState<DishDetailSheet> createState() => _DishDetailSheetState();
}

class _DishDetailSheetState extends ConsumerState<DishDetailSheet> {
  int _quantity = 1;
  MenuItemOption? _selectedOption;
  final TextEditingController _instructionsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.item.options.isNotEmpty) {
      _selectedOption = widget.item.options.first;
    }
  }

  @override
  void dispose() {
    _instructionsController.dispose();
    super.dispose();
  }

  double get _itemUnitPrice {
    return widget.item.price + (_selectedOption?.extraPrice ?? 0.0);
  }

  double get _totalPrice {
    return _itemUnitPrice * _quantity;
  }

  void _addToCart() {
    final orderItem = OrderItemModel(
      id: '${widget.item.id}_${DateTime.now().millisecondsSinceEpoch}',
      menuItemId: widget.item.id,
      name: widget.item.name,
      price: _itemUnitPrice,
      quantity: _quantity,
      notes: _instructionsController.text.trim().isEmpty
          ? (_selectedOption != null ? 'Option: ${_selectedOption!.name}' : null)
          : '${_selectedOption != null ? "Option: ${_selectedOption!.name} | " : ""}${_instructionsController.text.trim()}',
      selectedOptions: _selectedOption != null
          ? {'name': _selectedOption!.name, 'extraPrice': _selectedOption!.extraPrice}
          : null,
    );

    ref.read(cartProvider.notifier).addItem(orderItem);
    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $_quantity x ${widget.item.name} to cart'),
        duration: const Duration(seconds: 2),
        backgroundColor: AppColors.available,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 10, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image / Visual placeholder
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      color: AppColors.primaryLight,
                      child: item.imageUrl.isNotEmpty
                          ? Image.network(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => _buildPlaceholder(),
                            )
                          : _buildPlaceholder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Header with Title & Price
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (item.isChefPick)
                              Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.pendingBg,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  "★ Chef's pick",
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.pending,
                                  ),
                                ),
                              ),
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '₱${item.price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Description
                  if (item.description.isNotEmpty)
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  const SizedBox(height: 12),

                  // Dietary Badges
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (item.isAvailable)
                        _buildBadge('AVAILABLE NOW', AppColors.availableBg, AppColors.available)
                      else
                        _buildBadge('SOLD OUT', AppColors.errorBg, AppColors.error),
                      ...item.badges.map((b) => _buildBadge(b, AppColors.background, AppColors.textSecondary)),
                      ...item.tags.map((t) => _buildBadge(t, AppColors.primaryLight, AppColors.primary)),
                      ...item.allergens.map((a) => _buildBadge('Contains $a', AppColors.pendingBg, AppColors.pending)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Options / Modifiers (if available)
                  if (item.options.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Choose option',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'REQUIRED',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.textMuted),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...item.options.map((opt) {
                      final isSelected = _selectedOption?.name == opt.name;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedOption = opt;
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primaryLight : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.primary : AppColors.border,
                              width: isSelected ? 1.5 : 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                opt.name,
                                style: TextStyle(
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? AppColors.primaryDark : AppColors.textPrimary,
                                ),
                              ),
                              Text(
                                opt.extraPrice == 0
                                    ? 'Included'
                                    : '+₱${opt.extraPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 16),
                  ],

                  // Special Instructions Text Field
                  const Text(
                    'Special instructions',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _instructionsController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: 'e.g. no garlic, sauce on the side...',
                      hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                      contentPadding: const EdgeInsets.all(12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Allergen Warning
                  Row(
                    children: const [
                      Icon(Icons.info_outline, size: 14, color: AppColors.pending),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Allergy notes must be confirmed with the kitchen',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          // Bottom Action Bar: Quantity & Add Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                // Quantity Stepper
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove, size: 18),
                        onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                      ),
                      Text(
                        '$_quantity',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add, size: 18),
                        onPressed: () => setState(() => _quantity++),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                // Add to Cart Button
                Expanded(
                  child: ElevatedButton(
                    onPressed: item.isAvailable ? _addToCart : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      item.isAvailable
                          ? 'Add • ₱${_totalPrice.toStringAsFixed(2)}'
                          : 'Sold Out',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.restaurant_menu, size: 48, color: AppColors.primary.withValues(alpha: 0.6)),
          const SizedBox(height: 4),
          Text(
            widget.item.name,
            style: const TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color bg, Color textCol) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: textCol),
      ),
    );
  }
}
