import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../providers/auth_provider.dart';
import '../screens/splash_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/debug/debug_tables_screen.dart';
import '../screens/waiter/waiter_home_screen.dart';
import '../screens/waiter/waiter_menu_screen.dart';
import '../screens/waiter/order_cart_screen.dart';
import '../screens/waiter/order_confirmation_screen.dart';
import '../screens/kitchen/kitchen_home_screen.dart';
import '../screens/cashier/cashier_home_screen.dart';
import '../screens/admin/admin_home_screen.dart';
import '../screens/admin/menu_management_screen.dart';
import '../screens/customer/table_picker_screen.dart';
import '../screens/customer/guest_count_screen.dart';
import '../screens/customer/customer_menu_screen.dart';
import '../screens/customer/customer_item_details_screen.dart';
import '../screens/customer/customer_cart_screen.dart';
import '../screens/customer/customer_order_tracking_screen.dart';
import 'route_names.dart';

/// Riverpod-based GoRouter configuration with role-based auth guard for staff
/// and open, public access for customer self-service dining routes.
final routerProvider = Provider<GoRouter>((ref) {
  final authNotifier = ValueNotifier<int>(0);

  // Trigger router refresh whenever auth state or user profile changes
  ref.listen(authStateProvider, (_, _) => authNotifier.value++);
  ref.listen(currentUserProvider, (_, _) => authNotifier.value++);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    refreshListenable: authNotifier,
    redirect: (context, state) {
      final loc = state.matchedLocation;

      // Public customer routes do not require a staff login.
      if (loc == AppRoutes.customerTablePicker || loc.startsWith('/t/')) {
        return null;
      }

      // Bypass staff redirect for debug routes in debug builds
      if (kDebugMode && loc.startsWith('/debug/')) {
        return null;
      }

      final authAsync = ref.read(authStateProvider);
      final userAsync = ref.read(currentUserProvider);

      final isAuthLoading = authAsync.isLoading;
      final firebaseUser = authAsync.asData?.value;
      final isLoggingIn = loc == AppRoutes.login;
      final isSplash = loc == AppRoutes.splash;

      // 2. Still determining Firebase Auth state
      if (isAuthLoading) {
        return null;
      }

      // 3. Unauthenticated users start in the public customer table picker.
      if (firebaseUser == null) {
        return isLoggingIn ? null : AppRoutes.customerTablePicker;
      }

      // 4. Staff authenticated, wait for Firestore profile to load
      if (userAsync.isLoading) {
        return isSplash ? null : AppRoutes.splash;
      }

      final userProfile = userAsync.asData?.value;

      // Determine home route based on staff role
      final role = userProfile?.role ?? UserRole.waiter;
      String homeRoute;
      switch (role) {
        case UserRole.admin:
          homeRoute = AppRoutes.admin;
          break;
        case UserRole.waiter:
          homeRoute = AppRoutes.waiterTables;
          break;
        case UserRole.kitchen:
          homeRoute = AppRoutes.kitchen;
          break;
        case UserRole.cashier:
          homeRoute = AppRoutes.cashier;
          break;
        case UserRole.customer:
          homeRoute = AppRoutes.customerTablePicker;
          break;
      }

      // 5. If logged in and currently on /login or /, redirect to staff role home
      if (isLoggingIn || isSplash) {
        return homeRoute;
      }

      return null;
    },
    routes: [
      // Splash
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Staff Auth
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),

      // Waiter Flow
      GoRoute(
        path: AppRoutes.waiterTables,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final initialIndex = extra?['tab'] as int? ?? 0;
          final initialOrderId = extra?['orderId'] as String?;
          return WaiterHomeScreen(
            initialIndex: initialIndex,
            initialOrderId: initialOrderId,
          );
        },
      ),
      GoRoute(
        path: AppRoutes.waiterMenu,
        builder: (context, state) => const WaiterMenuScreen(),
      ),
      GoRoute(
        path: AppRoutes.waiterCart,
        builder: (context, state) => const OrderCartScreen(),
      ),
      GoRoute(
        path: AppRoutes.waiterConfirmation,
        builder: (context, state) {
          final order = state.extra as OrderModel?;
          if (order == null) {
            return const WaiterHomeScreen();
          }
          return OrderConfirmationScreen(order: order);
        },
      ),

      // Kitchen Flow
      GoRoute(
        path: AppRoutes.kitchen,
        builder: (context, state) => const KitchenHomeScreen(),
      ),

      // Cashier Flow
      GoRoute(
        path: AppRoutes.cashier,
        builder: (context, state) => const CashierHomeScreen(),
      ),

      // Admin Flow
      GoRoute(
        path: AppRoutes.admin,
        builder: (context, state) => const AdminHomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.adminMenu,
        builder: (context, state) => const MenuManagementScreen(),
      ),

      // Public customer flow
      GoRoute(
        path: AppRoutes.customerTablePicker,
        builder: (context, state) => const TablePickerScreen(),
      ),
      GoRoute(
        path: AppRoutes.customerGuests,
        builder: (context, state) {
          final tableId = state.pathParameters['tableId'] ?? 'T01';
          return GuestCountScreen(tableId: tableId);
        },
      ),

      // 2. Menu: /t/:tableId/menu
      GoRoute(
        path: AppRoutes.customerMenu,
        builder: (context, state) {
          final tableId = state.pathParameters['tableId'] ?? 'T01';
          return CustomerMenuScreen(tableId: tableId);
        },
      ),

      // 3. Item Details: /t/:tableId/menu/item/:itemId
      GoRoute(
        path: AppRoutes.customerItemDetails,
        builder: (context, state) {
          final tableId = state.pathParameters['tableId'] ?? 'T01';
          final itemId = state.pathParameters['itemId'] ?? '';
          return CustomerItemDetailsScreen(tableId: tableId, itemId: itemId);
        },
      ),

      // 4. Cart: /t/:tableId/cart
      GoRoute(
        path: AppRoutes.customerCart,
        builder: (context, state) {
          final tableId = state.pathParameters['tableId'] ?? 'T01';
          return CustomerCartScreen(tableId: tableId);
        },
      ),

      // 5. Order Tracking: /t/:tableId/order/:orderId
      GoRoute(
        path: AppRoutes.customerTracking,
        builder: (context, state) {
          final tableId = state.pathParameters['tableId'] ?? 'T01';
          final orderId = state.pathParameters['orderId'] ?? '';
          return CustomerOrderTrackingScreen(tableId: tableId, orderId: orderId);
        },
      ),

      // Debug fallback route (Active ONLY in debug builds)
      if (kDebugMode)
        GoRoute(
          path: '/debug/tables',
          builder: (context, state) => const DebugTablesScreen(),
        ),
    ],
  );
});
