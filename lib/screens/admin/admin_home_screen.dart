import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/inventory_providers.dart';
import '../../widgets/dineflow_logo.dart';
import 'admin_dashboard_tab.dart';
import 'admin_inventory_tab.dart';
import 'admin_menu_tab.dart';
import 'admin_reports_tab.dart';
import 'admin_tables_tab.dart';

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  int _currentIndex = 0;

  void _onTabChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).asData?.value;
    final lowStockCount = ref.watch(lowStockItemsCountProvider);

    final tabs = [
      AdminDashboardTab(onNavigateTab: _onTabChanged),
      const AdminMenuTab(),
      const AdminTablesTab(),
      const AdminInventoryTab(),
      const AdminReportsTab(),
    ];

    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;

    if (isDesktop) {
      return Scaffold(
        body: Row(
          children: [
            // Persistent Admin Sidebar (Wireframe pp. 18-20)
            Container(
              width: 260,
              decoration: const BoxDecoration(
                color: AppColors.darkNavBg,
                border: Border(
                  right: BorderSide(color: Color(0xFF334155), width: 1),
                ),
              ),
              child: Column(
                children: [
                  // Restaurant / App Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    alignment: Alignment.centerLeft,
                    child: Row(
                      children: [
                        const DineFlowMark(
                          size: 40,
                          style: DineFlowMarkStyle.appTile,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              RichText(
                                text: const TextSpan(
                                  children: [
                                    TextSpan(
                                      text: 'Dine',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'Flow',
                                      style: TextStyle(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 18,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: AppColors.available,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  const Text(
                                    'Admin Console',
                                    style: TextStyle(
                                      color: Color(0xFF94A3B8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: Color(0xFF334155), height: 1),
                  const SizedBox(height: 16),

                  // Nav Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: [
                        _buildSidebarItem(
                          index: 0,
                          title: 'Dashboard',
                          icon: Icons.dashboard_outlined,
                          selectedIcon: Icons.dashboard,
                        ),
                        _buildSidebarItem(
                          index: 1,
                          title: 'Menu Items',
                          icon: Icons.restaurant_menu_outlined,
                          selectedIcon: Icons.restaurant_menu,
                        ),
                        _buildSidebarItem(
                          index: 2,
                          title: 'Floor & Tables',
                          icon: Icons.table_restaurant_outlined,
                          selectedIcon: Icons.table_restaurant,
                        ),
                        _buildSidebarItem(
                          index: 3,
                          title: 'Inventory & Stock',
                          icon: Icons.inventory_2_outlined,
                          selectedIcon: Icons.inventory_2,
                          badgeCount: lowStockCount,
                        ),
                        _buildSidebarItem(
                          index: 4,
                          title: 'Sales & Reports',
                          icon: Icons.bar_chart_outlined,
                          selectedIcon: Icons.bar_chart,
                        ),
                      ],
                    ),
                  ),

                  const Divider(color: Color(0xFF334155), height: 1),

                  // User Info & Sign Out
                  Container(
                    padding: const EdgeInsets.all(16),
                    color: AppColors.darkNavSurface,
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            (user?.displayName.isNotEmpty == true)
                                ? user!.displayName[0].toUpperCase()
                                : 'A',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                user?.displayName ?? 'Admin Manager',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                user?.email ?? 'admin@dineflow.com',
                                style: const TextStyle(
                                  color: Color(0xFF94A3B8),
                                  fontSize: 11,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Color(0xFF94A3B8), size: 20),
                          tooltip: 'Sign Out',
                          onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Tab Content
            Expanded(
              child: IndexedStack(
                index: _currentIndex,
                children: tabs,
              ),
            ),
          ],
        ),
      );
    }

    // Mobile / Tablet Navigation
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
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard, color: AppColors.primary),
            label: 'Dashboard',
          ),
          const NavigationDestination(
            icon: Icon(Icons.restaurant_menu_outlined),
            selectedIcon: Icon(Icons.restaurant_menu, color: AppColors.primary),
            label: 'Menu',
          ),
          const NavigationDestination(
            icon: Icon(Icons.table_restaurant_outlined),
            selectedIcon: Icon(Icons.table_restaurant, color: AppColors.primary),
            label: 'Tables',
          ),
          NavigationDestination(
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.inventory_2_outlined),
                if (lowStockCount > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        '$lowStockCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            selectedIcon: const Icon(Icons.inventory_2, color: AppColors.primary),
            label: 'Inventory',
          ),
          const NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart, color: AppColors.primary),
            label: 'Reports',
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required int index,
    required String title,
    required IconData icon,
    required IconData selectedIcon,
    int badgeCount = 0,
  }) {
    final isSelected = _currentIndex == index;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Material(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.15) : Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: () => _onTabChanged(index),
          borderRadius: BorderRadius.circular(10),
          hoverColor: Colors.white.withValues(alpha: 0.05),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isSelected ? AppColors.primary.withValues(alpha: 0.4) : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? selectedIcon : icon,
                  color: isSelected ? AppColors.primary : const Color(0xFF94A3B8),
                  size: 20,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFFCBD5E1),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
                if (badgeCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
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
