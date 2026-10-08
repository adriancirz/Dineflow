import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../models/menu_item_model.dart';
import '../../providers/firebase_providers.dart';

class MenuItemDialog extends ConsumerStatefulWidget {
  final MenuItemModel? itemToEdit;

  const MenuItemDialog({super.key, this.itemToEdit});

  static Future<void> show(BuildContext context, {MenuItemModel? item}) {
    return showDialog(
      context: context,
      builder: (ctx) => MenuItemDialog(itemToEdit: item),
    );
  }

  @override
  ConsumerState<MenuItemDialog> createState() => _MenuItemDialogState();
}

class _MenuItemDialogState extends ConsumerState<MenuItemDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _costController;
  late TextEditingController _imageUrlController;
  String _selectedCategory = 'cat_pasta';
  bool _isAvailable = true;
  bool _isChefPick = false;
  bool _isSubmitting = false;

  final Map<String, String> _categories = {
    'cat_popular': 'Popular',
    'cat_starters': 'Starters',
    'cat_mains': 'Mains',
    'cat_pasta': 'Pasta',
    'cat_drinks': 'Drinks',
    'cat_dessert': 'Dessert',
  };

  @override
  void initState() {
    super.initState();
    final item = widget.itemToEdit;
    _nameController = TextEditingController(text: item?.name ?? '');
    _descController = TextEditingController(text: item?.description ?? '');
    _priceController = TextEditingController(text: item != null ? item.price.toStringAsFixed(2) : '');
    _costController = TextEditingController(text: item != null ? item.cost.toStringAsFixed(2) : '');
    _imageUrlController = TextEditingController(text: item?.imageUrl ?? '');
    _selectedCategory = item?.categoryId ?? 'cat_pasta';
    _isAvailable = item?.isAvailable ?? true;
    _isChefPick = item?.isChefPick ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final db = ref.read(firestoreProvider);
      final isNew = widget.itemToEdit == null;
      final docRef = isNew ? db.collection('menu').doc() : db.collection('menu').doc(widget.itemToEdit!.id);

      final itemModel = MenuItemModel(
        id: docRef.id,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        categoryId: _selectedCategory,
        price: double.tryParse(_priceController.text.trim()) ?? 0.0,
        cost: double.tryParse(_costController.text.trim()) ?? 0.0,
        imageUrl: _imageUrlController.text.trim(),
        isAvailable: _isAvailable,
        isChefPick: _isChefPick,
        badges: _isChefPick ? ['Chef Special'] : [],
        tags: [_categories[_selectedCategory] ?? 'Dishes'],
      );

      await docRef.set(itemModel.toMap());

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isNew ? 'Added new menu dish!' : 'Updated dish details!'),
          backgroundColor: AppColors.available,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save menu item: $e'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.itemToEdit == null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 550),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      isNew ? 'Add Menu Item' : 'Edit Menu Item',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Dish Name *',
                    hintText: 'e.g. Truffle Mushroom Pasta',
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 14),

                // Category & Chef Pick
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _categories.containsKey(_selectedCategory) ? _selectedCategory : 'cat_pasta',
                        decoration: const InputDecoration(labelText: 'Category'),
                        items: _categories.entries.map((e) {
                          return DropdownMenuItem(value: e.key, child: Text(e.value));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedCategory = val);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Row(
                      children: [
                        Checkbox(
                          value: _isChefPick,
                          onChanged: (val) => setState(() => _isChefPick = val ?? false),
                        ),
                        const Text("Chef's Pick", style: TextStyle(fontSize: 13)),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Price & Cost (WB ADM 001: edit price)
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Selling Price (₱) *',
                          prefixText: '₱ ',
                        ),
                        validator: (val) => (double.tryParse(val ?? '') == null) ? 'Enter valid price' : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _costController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          labelText: 'Ingredient Cost (₱) *',
                          prefixText: '₱ ',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Image URL
                TextFormField(
                  controller: _imageUrlController,
                  decoration: const InputDecoration(
                    labelText: 'Image URL (Optional)',
                    hintText: 'https://...',
                  ),
                ),
                const SizedBox(height: 14),

                // Description
                TextFormField(
                  controller: _descController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Ingredients and flavor profile...',
                  ),
                ),
                const SizedBox(height: 14),

                // Availability Switch (WB ADM 001)
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Available for ordering'),
                  subtitle: Text(
                    _isAvailable ? 'Customers & waitstaff can order this item' : 'Marked SOLD OUT / Unavailable',
                    style: const TextStyle(fontSize: 12),
                  ),
                  value: _isAvailable,
                  activeThumbColor: AppColors.available,
                  onChanged: (val) => setState(() => _isAvailable = val),
                ),
                const SizedBox(height: 24),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: _isSubmitting ? null : _saveItem,
                    child: _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(isNew ? 'Create Dish' : 'Save Changes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
