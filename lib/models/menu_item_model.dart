import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItemOption {
  final String name;
  final double extraPrice;

  double get additionalCost => extraPrice;

  const MenuItemOption({
    required this.name,
    this.extraPrice = 0.0,
  });

  factory MenuItemOption.fromMap(Map<String, dynamic> data) {
    return MenuItemOption(
      name: data['name'] as String? ?? '',
      extraPrice: (data['extraPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'extraPrice': extraPrice,
    };
  }
}

class MenuItemModel {
  final String id;
  final String name;
  final String description;
  final String categoryId;
  final double price;
  final double cost;
  final String imageUrl;
  final List<String> galleryUrls;
  final bool isAvailable;
  final bool isFeatured;
  final bool isChefPick;
  final bool trackInventory;
  final int preparationTimeMin;
  final List<String> badges;
  final List<String> allergens;
  final List<String> tags;
  final int stockCount;
  final List<MenuItemOption> options;

  String get category => categoryId.isNotEmpty ? categoryId : (tags.isNotEmpty ? tags.first : 'Mains');

  const MenuItemModel({
    required this.id,
    required this.name,
    this.description = '',
    required this.categoryId,
    required this.price,
    this.cost = 0.0,
    this.imageUrl = '',
    this.galleryUrls = const [],
    this.isAvailable = true,
    this.isFeatured = false,
    this.isChefPick = false,
    this.trackInventory = false,
    this.preparationTimeMin = 10,
    this.badges = const [],
    this.allergens = const [],
    this.tags = const [],
    this.stockCount = 0,
    this.options = const [],
  });

  factory MenuItemModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return MenuItemModel.fromMap(doc.id, data);
  }

  factory MenuItemModel.fromMap(String id, Map<String, dynamic> data) {
    return MenuItemModel(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      categoryId: data['categoryId'] as String? ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0.0,
      cost: (data['cost'] as num?)?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'] as String? ?? '',
      galleryUrls: (data['galleryUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      isAvailable: data['isAvailable'] as bool? ?? true,
      isFeatured: data['isFeatured'] as bool? ?? false,
      isChefPick: data['isChefPick'] as bool? ?? false,
      trackInventory: data['trackInventory'] as bool? ?? false,
      preparationTimeMin: (data['preparationTimeMin'] as num?)?.toInt() ?? 10,
      badges: (data['badges'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      allergens: (data['allergens'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      tags: (data['tags'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      stockCount: (data['stockCount'] as num?)?.toInt() ?? 0,
      options: (data['options'] as List<dynamic>?)
              ?.map((e) => MenuItemOption.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'categoryId': categoryId,
      'price': price,
      'cost': cost,
      'imageUrl': imageUrl,
      'galleryUrls': galleryUrls,
      'isAvailable': isAvailable,
      'isFeatured': isFeatured,
      'isChefPick': isChefPick,
      'trackInventory': trackInventory,
      'preparationTimeMin': preparationTimeMin,
      'badges': badges,
      'allergens': allergens,
      'tags': tags,
      'stockCount': stockCount,
      'options': options.map((e) => e.toMap()).toList(),
    };
  }

  MenuItemModel copyWith({
    String? id,
    String? name,
    String? description,
    String? categoryId,
    double? price,
    double? cost,
    String? imageUrl,
    List<String>? galleryUrls,
    bool? isAvailable,
    bool? isFeatured,
    bool? isChefPick,
    bool? trackInventory,
    int? preparationTimeMin,
    List<String>? badges,
    List<String>? allergens,
    List<String>? tags,
    int? stockCount,
    List<MenuItemOption>? options,
  }) {
    return MenuItemModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      price: price ?? this.price,
      cost: cost ?? this.cost,
      imageUrl: imageUrl ?? this.imageUrl,
      galleryUrls: galleryUrls ?? this.galleryUrls,
      isAvailable: isAvailable ?? this.isAvailable,
      isFeatured: isFeatured ?? this.isFeatured,
      isChefPick: isChefPick ?? this.isChefPick,
      trackInventory: trackInventory ?? this.trackInventory,
      preparationTimeMin: preparationTimeMin ?? this.preparationTimeMin,
      badges: badges ?? this.badges,
      allergens: allergens ?? this.allergens,
      tags: tags ?? this.tags,
      stockCount: stockCount ?? this.stockCount,
      options: options ?? this.options,
    );
  }
}
