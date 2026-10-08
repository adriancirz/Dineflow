import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/menu_category_model.dart';
import '../models/menu_item_model.dart';
import 'firebase_providers.dart';

/// Stream of all active menu categories sorted by sortOrder
final menuCategoriesStreamProvider = StreamProvider<List<MenuCategoryModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('menuCategories').snapshots().map((snapshot) {
    final list = snapshot.docs.map((doc) => MenuCategoryModel.fromFirestore(doc)).toList();
    list.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return list;
  });
});

/// Stream of all menu items
final menuItemsStreamProvider = StreamProvider<List<MenuItemModel>>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('menu').snapshots().map((snapshot) {
    return snapshot.docs.map((doc) => MenuItemModel.fromFirestore(doc)).toList();
  });
});

/// Currently selected category ID for filtering (null = all / popular)
class SelectedCategoryFilterNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void selectCategory(String? categoryId) {
    state = categoryId;
  }
}

final selectedCategoryFilterProvider =
    NotifierProvider<SelectedCategoryFilterNotifier, String?>(
  SelectedCategoryFilterNotifier.new,
);

/// Search query for menu items
class MenuSearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String q) => state = q;
  void clear() => state = '';
}

final menuSearchQueryProvider = NotifierProvider<MenuSearchQueryNotifier, String>(
  MenuSearchQueryNotifier.new,
);

/// Filtered menu items based on search and category
final filteredMenuItemsProvider = Provider<List<MenuItemModel>>((ref) {
  final itemsAsync = ref.watch(menuItemsStreamProvider);
  final selectedCat = ref.watch(selectedCategoryFilterProvider);
  final query = ref.watch(menuSearchQueryProvider).trim().toLowerCase();

  return itemsAsync.maybeWhen(
    data: (items) {
      var result = items;
      if (selectedCat != null && selectedCat.isNotEmpty) {
        result = result.where((item) => item.categoryId == selectedCat).toList();
      }
      if (query.isNotEmpty) {
        result = result.where((item) {
          final nameMatch = item.name.toLowerCase().contains(query);
          final descMatch = item.description.toLowerCase().contains(query);
          final tagsMatch = item.tags.any((t) => t.toLowerCase().contains(query));
          return nameMatch || descMatch || tagsMatch;
        }).toList();
      }
      return result;
    },
    orElse: () => [],
  );
});

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return MenuRepository(firestore);
});

class MenuRepository {
  final FirebaseFirestore _firestore;
  MenuRepository(this._firestore);

  Future<void> setItemAvailability(String itemId, bool isAvailable) async {
    await _firestore.collection('menu').doc(itemId).update({
      'isAvailable': isAvailable,
    });
  }

  Future<void> updateItemPrice(String itemId, double newPrice) async {
    await _firestore.collection('menu').doc(itemId).update({
      'price': newPrice,
    });
  }
}

