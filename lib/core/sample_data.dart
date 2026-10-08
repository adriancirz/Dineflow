import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/inventory_model.dart';
import '../models/table_model.dart';
import '../models/menu_item_model.dart';
import '../models/menu_category_model.dart';

class SampleData {
  static final List<MenuCategoryModel> defaultCategories = [
    const MenuCategoryModel(id: 'cat_popular', name: 'Popular', sortOrder: 1),
    const MenuCategoryModel(id: 'cat_starters', name: 'Starters', sortOrder: 2),
    const MenuCategoryModel(id: 'cat_mains', name: 'Mains', sortOrder: 3),
    const MenuCategoryModel(id: 'cat_pasta', name: 'Pasta', sortOrder: 4),
    const MenuCategoryModel(id: 'cat_drinks', name: 'Drinks', sortOrder: 5),
    const MenuCategoryModel(id: 'cat_dessert', name: 'Dessert', sortOrder: 6),
  ];

  static final List<MenuItemModel> defaultMenuItems = [
    const MenuItemModel(
      id: 'menu_001',
      name: 'Truffle Mushroom Pasta',
      description: 'Tagliatelle, wild mushrooms, truffle cream, parmesan, and fresh herbs.',
      categoryId: 'cat_pasta',
      price: 380.00,
      cost: 130.00,
      isAvailable: true,
      isFeatured: true,
      isChefPick: true,
      badges: ['Vegetarian', 'Contains dairy'],
      tags: ['Popular', 'Chef special'],
      options: [
        MenuItemOption(name: 'Tagliatelle', extraPrice: 0.0),
        MenuItemOption(name: 'Gluten-free penne', extraPrice: 45.0),
      ],
    ),
    const MenuItemModel(
      id: 'menu_002',
      name: 'Citrus Salmon Bowl',
      description: 'Charred broccolini, herbed farro, citrus glaze, and lemon butter.',
      categoryId: 'cat_mains',
      price: 480.00,
      cost: 180.00,
      isAvailable: true,
      isFeatured: true,
      badges: ['Gluten-free'],
      tags: ['Popular', 'Seafood'],
    ),
    const MenuItemModel(
      id: 'menu_003',
      name: 'Smoky Chicken Burger',
      description: 'Buttermilk fried chicken, chipotle slaw, brioche bun, house pickles.',
      categoryId: 'cat_mains',
      price: 320.00,
      cost: 110.00,
      isAvailable: false, // Wireframe p. 9: marked Unavailable
      isFeatured: false,
      badges: ['Unavailable'],
      tags: ['Poultry'],
    ),
    const MenuItemModel(
      id: 'menu_004',
      name: 'Burrata Garden',
      description: 'Heirloom tomatoes, basil oil, toasted sourdough, aged balsamic.',
      categoryId: 'cat_starters',
      price: 390.00,
      cost: 140.00,
      isAvailable: false, // Wireframe p. 14: marked SOLD OUT
      isFeatured: false,
      badges: ['Vegetarian', 'Sold Out'],
      tags: ['Starters'],
    ),
    const MenuItemModel(
      id: 'menu_005',
      name: 'Truffle Rigatoni',
      description: 'Rigatoni tossed in parmesan cream with roasted wild mushrooms and black truffle.',
      categoryId: 'cat_pasta',
      price: 420.00,
      cost: 150.00,
      isAvailable: true,
      isFeatured: true,
      isChefPick: true,
      badges: ['Vegetarian', 'Contains dairy'],
      tags: ['Most loved'],
    ),
    const MenuItemModel(
      id: 'menu_006',
      name: 'Sparkling Water',
      description: 'Chilled natural mineral sparkling water with a slice of lemon.',
      categoryId: 'cat_drinks',
      price: 95.00,
      cost: 30.00,
      isAvailable: true,
      badges: ['Chilled'],
      tags: ['Drinks'],
    ),
    const MenuItemModel(
      id: 'menu_007',
      name: 'Iced Citrus Tea',
      description: 'Freshly brewed black tea infused with calamansi, lemon, and organic cane sugar.',
      categoryId: 'cat_drinks',
      price: 120.00,
      cost: 35.00,
      isAvailable: true,
      badges: ['Cold'],
      tags: ['Drinks'],
    ),
    const MenuItemModel(
      id: 'menu_008',
      name: 'Chocolate Torte',
      description: 'Dark Belgian chocolate ganache with salted caramel cream and fresh raspberries.',
      categoryId: 'cat_dessert',
      price: 250.00,
      cost: 85.00,
      isAvailable: true,
      badges: ['Sweet'],
      tags: ['Dessert'],
    ),
  ];

  static final List<TableModel> defaultTables = [
    const TableModel(
      id: 'T01',
      tableNumber: 'T01',
      capacity: 2,
      status: TableStatus.available,
      statusNote: 'Ready now',
    ),
    const TableModel(
      id: 'T04',
      tableNumber: 'T04',
      capacity: 4,
      status: TableStatus.occupied,
      statusNote: '24 min · #DF-1048',
      guestCount: 4,
    ),
    const TableModel(
      id: 'T07',
      tableNumber: 'T07',
      capacity: 6,
      status: TableStatus.reserved,
      statusNote: '12:30 · Alvarez',
      reservationName: 'Alvarez',
      reservationTime: '12:30',
    ),
    const TableModel(
      id: 'T08',
      tableNumber: 'T08',
      capacity: 4,
      status: TableStatus.occupied,
      statusNote: '8 min · #DF-1052',
      guestCount: 4,
    ),
    const TableModel(
      id: 'T11',
      tableNumber: 'T11',
      capacity: 2,
      status: TableStatus.available,
      statusNote: 'Cleaned 5m ago',
    ),
    const TableModel(
      id: 'T12',
      tableNumber: 'T12',
      capacity: 8,
      status: TableStatus.reserved,
      statusNote: '13:00 · Santos',
      reservationName: 'Santos',
      reservationTime: '13:00',
    ),
    const TableModel(
      id: 'T02',
      tableNumber: 'T02',
      capacity: 4,
      status: TableStatus.available,
      statusNote: 'Ready now',
    ),
    const TableModel(
      id: 'T03',
      tableNumber: 'T03',
      capacity: 2,
      status: TableStatus.available,
      statusNote: 'Ready now',
    ),
    const TableModel(
      id: 'T05',
      tableNumber: 'T05',
      capacity: 4,
      status: TableStatus.available,
      statusNote: 'Ready now',
    ),
    const TableModel(
      id: 'T06',
      tableNumber: 'T06',
      capacity: 6,
      status: TableStatus.available,
      statusNote: 'Ready now',
    ),
    const TableModel(
      id: 'T09',
      tableNumber: 'T09',
      capacity: 4,
      status: TableStatus.available,
      statusNote: 'Ready now',
    ),
    const TableModel(
      id: 'T10',
      tableNumber: 'T10',
      capacity: 2,
      status: TableStatus.available,
      statusNote: 'Ready now',
    ),
  ];

  static final List<InventoryItemModel> defaultInventory = [
    const InventoryItemModel(
      id: 'inv_001',
      name: 'Atlantic Salmon',
      sku: 'SEA-001',
      category: 'Seafood',
      currentStock: 3.2,
      unit: 'kg',
      minThreshold: 5.0, // Low stock alert!
      costPerUnit: 850.0,
      supplier: 'Ocean Catch Manila',
    ),
    const InventoryItemModel(
      id: 'inv_002',
      name: 'Truffle Cream',
      sku: 'DAI-004',
      category: 'Dairy',
      currentStock: 1.8,
      unit: 'L',
      minThreshold: 4.0, // Low stock alert!
      costPerUnit: 650.00,
      supplier: 'Artisan Dairy PH',
    ),
    const InventoryItemModel(
      id: 'inv_003',
      name: 'Tagliatelle Pasta',
      sku: 'DRY-012',
      category: 'Dry Goods',
      currentStock: 25.0,
      unit: 'kg',
      minThreshold: 10.0,
      costPerUnit: 180.00,
      supplier: 'Bella Pasta Imports',
    ),
    const InventoryItemModel(
      id: 'inv_004',
      name: 'Chicken Breast',
      sku: 'POU-003',
      category: 'Poultry',
      currentStock: 15.0,
      unit: 'kg',
      minThreshold: 8.0,
      costPerUnit: 280.00,
      supplier: 'Batangas Fresh Poultry',
    ),
    const InventoryItemModel(
      id: 'inv_005',
      name: 'Sparkling Water',
      sku: 'BEV-008',
      category: 'Beverages',
      currentStock: 48.0,
      unit: 'bottles',
      minThreshold: 20.0,
      costPerUnit: 45.00,
      supplier: 'Pure Springs PH',
    ),
    const InventoryItemModel(
      id: 'inv_006',
      name: 'Belgian Chocolate',
      sku: 'BAK-002',
      category: 'Bakery',
      currentStock: 8.5,
      unit: 'kg',
      minThreshold: 4.0,
      costPerUnit: 550.00,
      supplier: 'Sweet Imports Manila',
    ),
  ];

  static Future<void> seedFirestoreIfEmpty(FirebaseFirestore db) async {
    try {
      final tablesSnap = await db.collection('tables').limit(1).get();
      if (tablesSnap.docs.isEmpty) {
        for (final t in defaultTables) {
          await db.collection('tables').doc(t.id).set(t.toMap());
        }
      }

      final catsSnap = await db.collection('menuCategories').limit(1).get();
      if (catsSnap.docs.isEmpty) {
        for (final c in defaultCategories) {
          await db.collection('menuCategories').doc(c.id).set(c.toMap());
        }
      }

      final menuSnap = await db.collection('menu').limit(1).get();
      if (menuSnap.docs.isEmpty) {
        for (final m in defaultMenuItems) {
          await db.collection('menu').doc(m.id).set(m.toMap());
        }
      }

      final invSnap = await db.collection('inventory').limit(1).get();
      if (invSnap.docs.isEmpty) {
        for (final inv in defaultInventory) {
          await db.collection('inventory').doc(inv.id).set(inv.toMap());
        }
      }
    } catch (_) {
      // Offline or permission issue, fallback in-memory is safe
    }
  }
}
