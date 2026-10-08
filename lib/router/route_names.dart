class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';

  // Waiter
  static const String waiterTables = '/waiter';
  static const String waiterMenu = '/waiter/menu';
  static const String waiterCart = '/waiter/cart';
  static const String waiterOrders = '/waiter/orders';
  static const String waiterConfirmation = '/waiter/confirmation';

  // Kitchen
  static const String kitchen = '/kitchen';

  // Cashier
  static const String cashier = '/cashier';

  // Admin
  static const String admin = '/admin';
  static const String adminMenu = '/admin/menu';
  static const String adminTables = '/admin/tables';
  static const String adminInventory = '/admin/inventory';
  static const String adminReports = '/admin/reports';

  // Public customer self-service flow
  static const String customerTablePicker = '/select-table';
  static const String customerGuests = '/t/:tableId/guests';
  static const String customerMenu = '/t/:tableId/menu';
  static const String customerItemDetails = '/t/:tableId/menu/item/:itemId';
  static const String customerCart = '/t/:tableId/cart';
  static const String customerTracking = '/t/:tableId/order/:orderId';

  // Helper route builders
  static String tableGuests(String tableId) => '/t/$tableId/guests';
  static String tableMenu(String tableId) => '/t/$tableId/menu';
  static String tableItem(String tableId, String itemId) => '/t/$tableId/menu/item/$itemId';
  static String tableCart(String tableId) => '/t/$tableId/cart';
  static String tableOrder(String tableId, String orderId) => '/t/$tableId/order/$orderId';
}
