import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/order_providers.dart';
import 'floor_overview_tab.dart';
import 'waiter_menu_screen.dart';
import 'active_orders_tab.dart';
import 'waiter_profile_tab.dart';

class WaiterHomeScreen extends ConsumerStatefulWidget {
  final int initialIndex;
  final String? initialOrderId;

  const WaiterHomeScreen({
    super.key,
    this.initialIndex = 0,
    this.initialOrderId,
  });

  @override
  ConsumerState<WaiterHomeScreen> createState() => _WaiterHomeScreenState();
}

class _WaiterHomeScreenState extends ConsumerState<WaiterHomeScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(covariant WaiterHomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      setState(() {
        _currentIndex = widget.initialIndex;
      });
    }
  }

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);

    final tabs = [
      FloorOverviewTab(onNavigateTab: _onTabChanged),
      WaiterMenuScreen(
        isTab: true,
        onBack: () => _onTabChanged(0),
      ),
      ActiveOrdersTab(
        initialOrderId: widget.initialOrderId,
        onNavigateTab: _onTabChanged,
      ),
      const WaiterProfileTab(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onTabChanged,
        backgroundColor: Colors.white,
        elevation: 4,
        indicatorColor: AppColors.primaryLight,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.grid_view),
            selectedIcon: Icon(Icons.grid_view, color: AppColors.primary),
            label: 'Tables',
          ),
          NavigationDestination(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.restaurant_menu),
                if (cart.itemCount > 0)
                  Positioned(
                    top: -4,
                    right: -6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        '${cart.itemCount}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            selectedIcon: const Icon(Icons.restaurant_menu, color: AppColors.primary),
            label: 'Menu',
          ),
          const NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long, color: AppColors.primary),
            label: 'Orders',
          ),
          const NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: AppColors.primary),
            label: 'Me',
          ),
        ],
      ),
    );
  }
}
