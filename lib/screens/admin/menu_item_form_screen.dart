import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/brand_colors.dart';
import '../../core/widgets/image_upload_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/menu_item_model.dart';
import '../../providers/firebase_providers.dart';
import '../../providers/menu_providers.dart';

/// Screen for creating a new menu item or editing an existing one with
/// real-time image upload support.
class MenuItemFormScreen extends ConsumerStatefulWidget {
  final MenuItemModel? itemToEdit;

  const MenuItemFormScreen({super.key, this.itemToEdit});

  @override
  ConsumerState<MenuItemFormScreen> createState() => _MenuItemFormScreenState();
}

class _MenuItemFormScreenState extends ConsumerState<MenuItemFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _itemId;
  late TextEditingController _nameController;
  late TextEditingController _descController;
  late TextEditingController _priceController;
  late TextEditingController _costController;
  late TextEditingController _prepTimeController;
  late TextEditingController _badgesController;
  late TextEditingController _allergensController;

  String _imageUrl = '';
  String _selectedCategory = 'cat_pasta';
  bool _isAvailable = true;
  bool _isChefPick = false;
  bool _isFeatured = false;
  bool _isSaving = false;

  final Map<String, String> _defaultCategories = {
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
    final firestore = ref.read(firestoreProvider);

    // Pre-generate doc ID for new item so storage uploads use the final ID
    _itemId = item?.id ?? firestore.collection('menu').doc().id;

    _nameController = TextEditingController(text: item?.name ?? '');
    _descController = TextEditingController(text: item?.description ?? '');
    _priceController = TextEditingController(
      text: item != null ? item.price.toStringAsFixed(2) : '',
    );
    _costController = TextEditingController(
      text: item != null && item.cost > 0 ? item.cost.toStringAsFixed(2) : '',
    );
    _prepTimeController = TextEditingController(
      text: (item?.preparationTimeMin ?? 10).toString(),
    );
    _badgesController = TextEditingController(
      text: item != null ? item.badges.join(', ') : '',
    );
    _allergensController = TextEditingController(
      text: item != null ? item.allergens.join(', ') : '',
    );

    _imageUrl = item?.imageUrl ?? '';
    _selectedCategory = item?.categoryId ?? 'cat_pasta';
    _isAvailable = item?.isAvailable ?? true;
    _isChefPick = item?.isChefPick ?? false;
    _isFeatured = item?.isFeatured ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _priceController.dispose();
    _costController.dispose();
    _prepTimeController.dispose();
    _badgesController.dispose();
    _allergensController.dispose();
    super.dispose();
  }

  List<String> _parseCommaSeparated(String text) {
    if (text.trim().isEmpty) return [];
    return text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }

  Future<void> _saveMenuItem() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final db = ref.read(firestoreProvider);
      final isNew = widget.itemToEdit == null;
      final docRef = db.collection('menu').doc(_itemId);

      final badges = _parseCommaSeparated(_badgesController.text);
      if (_isChefPick && !badges.contains("Chef's Pick") && !badges.contains("Chef Special")) {
        badges.insert(0, "Chef's Pick");
      }

      final allergens = _parseCommaSeparated(_allergensController.text);
      final parsedPrice = double.tryParse(_priceController.text.trim()) ?? 0.0;
      final parsedCost = double.tryParse(_costController.text.trim()) ?? 0.0;
      final parsedPrepTime = int.tryParse(_prepTimeController.text.trim()) ?? 10;

      final categoryLabel = _defaultCategories[_selectedCategory] ?? 'Mains';

      final itemModel = MenuItemModel(
        id: _itemId,
        name: _nameController.text.trim(),
        description: _descController.text.trim(),
        categoryId: _selectedCategory,
        price: parsedPrice,
        cost: parsedCost,
        imageUrl: _imageUrl.trim(),
        galleryUrls: widget.itemToEdit?.galleryUrls ?? [],
        isAvailable: _isAvailable,
        isFeatured: _isFeatured,
        isChefPick: _isChefPick,
        trackInventory: widget.itemToEdit?.trackInventory ?? false,
        preparationTimeMin: parsedPrepTime,
        badges: badges,
        allergens: allergens,
        tags: [categoryLabel],
        stockCount: widget.itemToEdit?.stockCount ?? 0,
        options: widget.itemToEdit?.options ?? [],
      );

      if (isNew) {
        await docRef.set(itemModel.toMap());
      } else {
        await docRef.update(itemModel.toMap());
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isNew
                ? 'Dish "${itemModel.name}" created successfully!'
                : 'Dish "${itemModel.name}" updated successfully!',
          ),
          backgroundColor: BrandColors.success,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save menu item: $e'),
          backgroundColor: BrandColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isNew = widget.itemToEdit == null;
    final categoriesAsync = ref.watch(menuCategoriesStreamProvider);

    return Scaffold(
      backgroundColor: BrandColors.creamBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        title: Text(
          isNew ? 'Create Menu Item' : 'Edit Menu Item',
          style: const TextStyle(
            color: BrandColors.textPrimary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BrandColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton.icon(
              icon: const Icon(Icons.check, size: 18, color: BrandColors.primaryOrange),
              label: Text(
                isNew ? 'Create' : 'Save',
                style: const TextStyle(
                  color: BrandColors.primaryOrange,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              onPressed: _isSaving ? null : _saveMenuItem,
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // SECTION 1: PHOTO UPLOAD
                    _buildSectionCard(
                      title: 'Item Photo',
                      subtitle: 'Upload a high-resolution photo displayed across customer & staff menus',
                      child: ImageUploadField(
                        itemId: _itemId,
                        currentImageUrl: _imageUrl,
                        height: 220,
                        onUploaded: (uploadedUrl) {
                          setState(() {
                            _imageUrl = uploadedUrl;
                          });
                        },
                        onRemoved: () {
                          setState(() {
                            _imageUrl = '';
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 20),

                    // SECTION 2: BASIC DETAILS
                    _buildSectionCard(
                      title: 'General Information',
                      subtitle: 'Dish name, description, and menu categorization',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextFormField(
                            controller: _nameController,
                            decoration: const InputDecoration(
                              labelText: 'Dish Name *',
                              hintText: 'e.g., Crispy Pork Sisig',
                              filled: true,
                              fillColor: Colors.white,
                            ),
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'Dish name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          categoriesAsync.when(
                            data: (categories) {
                              final items = categories.isNotEmpty
                                  ? categories
                                  : _defaultCategories.entries.toList();
                              final categoryIds = items is List<MapEntry<String, String>>
                                  ? items.map((e) => e.key).toList()
                                  : categories.map((c) => c.id).toList();

                              final effectiveCategory = categoryIds.contains(_selectedCategory)
                                  ? _selectedCategory
                                  : (categoryIds.isNotEmpty ? categoryIds.first : 'cat_mains');

                              return DropdownButtonFormField<String>(
                                initialValue: effectiveCategory,
                                decoration: const InputDecoration(
                                  labelText: 'Category *',
                                  filled: true,
                                  fillColor: Colors.white,
                                ),
                                items: items is List<MapEntry<String, String>>
                                    ? items.map((e) {
                                        return DropdownMenuItem(value: e.key, child: Text(e.value));
                                      }).toList()
                                    : categories.map((cat) {
                                        return DropdownMenuItem(value: cat.id, child: Text(cat.name));
                                      }).toList(),
                                onChanged: (val) {
                                  if (val != null) setState(() => _selectedCategory = val);
                                },
                              );
                            },
                            loading: () => const LinearProgressIndicator(),
                            error: (_, _) => DropdownButtonFormField<String>(
                              initialValue: _defaultCategories.containsKey(_selectedCategory)
                                  ? _selectedCategory
                                  : 'cat_pasta',
                              decoration: const InputDecoration(labelText: 'Category *'),
                              items: _defaultCategories.entries.map((e) {
                                return DropdownMenuItem(value: e.key, child: Text(e.value));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCategory = val);
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descController,
                            maxLines: 3,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              hintText: 'Rich description highlighting flavors, ingredients, and portion size',
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // SECTION 3: PRICING & OPERATIONS
                    _buildSectionCard(
                      title: 'Pricing & Operations',
                      subtitle: 'Pricing in Philippine Peso (PHP) and kitchen prep estimates',
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _priceController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Selling Price (₱) *',
                                    prefixText: '₱ ',
                                    hintText: '0.00',
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                  validator: (val) {
                                    if (val == null || val.trim().isEmpty) {
                                      return 'Price is required';
                                    }
                                    final parsed = double.tryParse(val.trim());
                                    if (parsed == null || parsed < 0) {
                                      return 'Enter a valid price';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: TextFormField(
                                  controller: _costController,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: const InputDecoration(
                                    labelText: 'Cost of Goods (₱)',
                                    prefixText: '₱ ',
                                    hintText: '0.00',
                                    filled: true,
                                    fillColor: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _prepTimeController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Prep Time (minutes)',
                              hintText: '10',
                              suffixText: 'min',
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // SECTION 4: BADGES & ALLERGENS
                    _buildSectionCard(
                      title: 'Badges & Dietary Info',
                      subtitle: 'Comma-separated labels for customer awareness',
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _badgesController,
                            decoration: const InputDecoration(
                              labelText: 'Badges (comma-separated)',
                              hintText: 'e.g., Best Seller, Spicy, House Special',
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _allergensController,
                            decoration: const InputDecoration(
                              labelText: 'Allergens (comma-separated)',
                              hintText: 'e.g., Peanuts, Dairy, Shellfish, Gluten',
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // SECTION 5: TOGGLES
                    _buildSectionCard(
                      title: 'Availability & Highlights',
                      subtitle: 'Control whether this item is active and featured on menus',
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Available for Ordering', style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(
                              _isAvailable
                                  ? 'Customers and staff can place orders for this dish'
                                  : 'Marked as Sold Out / Hidden from digital menus',
                              style: const TextStyle(fontSize: 13, color: BrandColors.textSecondary),
                            ),
                            value: _isAvailable,
                            activeThumbColor: BrandColors.primaryOrange,
                            onChanged: (val) => setState(() => _isAvailable = val),
                          ),
                          const Divider(),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text("Chef's Pick", style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: const Text(
                              'Displays special chef highlight badge on customer menu',
                              style: TextStyle(fontSize: 13, color: BrandColors.textSecondary),
                            ),
                            value: _isChefPick,
                            activeThumbColor: BrandColors.primaryOrange,
                            onChanged: (val) => setState(() => _isChefPick = val),
                          ),
                          const Divider(),
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Featured Dish', style: TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: const Text(
                              'Pin item to the top hero banner carousel on customer app',
                              style: TextStyle(fontSize: 13, color: BrandColors.textSecondary),
                            ),
                            value: _isFeatured,
                            activeThumbColor: BrandColors.primaryOrange,
                            onChanged: (val) => setState(() => _isFeatured = val),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // SUBMIT BUTTON
                    PrimaryButton(
                      text: isNew ? 'Create Menu Item' : 'Save Changes',
                      icon: isNew ? Icons.add_circle_outline : Icons.save_outlined,
                      height: 52,
                      width: double.infinity,
                      isLoading: _isSaving,
                      onPressed: _saveMenuItem,
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: BrandColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 13,
              color: BrandColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
