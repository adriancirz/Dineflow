import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/brand_colors.dart';
import '../../providers/auth_provider.dart';

/// Full-screen debug page for developer shortcuts and table simulations.
/// Guarded by [kDebugMode] — returns an empty widget if accessed in release mode.
class DebugTablesScreen extends ConsumerStatefulWidget {
  const DebugTablesScreen({super.key});

  @override
  ConsumerState<DebugTablesScreen> createState() => _DebugTablesScreenState();
}

class _DebugTablesScreenState extends ConsumerState<DebugTablesScreen> {
  final _tableInputController = TextEditingController();
  bool _isSigningIn = false;

  static const List<Map<String, String>> _roles = [
    {
      'role': 'Admin',
      'email': 'admin@dineflow.com',
      'password': 'Admin123!',
      'icon': 'admin_panel_settings',
    },
    {
      'role': 'Waiter',
      'email': 'waiter@dineflow.com',
      'password': 'Waiter123!',
      'icon': 'room_service',
    },
    {
      'role': 'Kitchen',
      'email': 'kitchen@dineflow.com',
      'password': 'Kitchen123!',
      'icon': 'restaurant',
    },
    {
      'role': 'Cashier',
      'email': 'cashier@dineflow.com',
      'password': 'Cashier123!',
      'icon': 'point_of_sale',
    },
  ];

  static const List<String> _demoTables = ['T01', 'T02', 'T04', 'T06', 'T10'];

  @override
  void dispose() {
    _tableInputController.dispose();
    super.dispose();
  }

  Future<void> _handleRoleLogin(String email, String password, String role) async {
    setState(() => _isSigningIn = true);
    try {
      final success = await ref.read(authControllerProvider.notifier).signInWithEmail(
            email: email,
            password: password,
          );
      if (mounted) {
        if (!success) {
          final err = ref.read(authControllerProvider).errorMessage ?? 'Sign in failed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Quick login failed ($role): $err'),
              backgroundColor: BrandColors.error,
            ),
          );
        } else {
          context.go('/');
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  void _navigateToTable(String tableId) {
    final sanitized = tableId.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
    if (sanitized.isEmpty) return;

    context.push('/t/$sanitized/guests');
  }

  IconData _iconForRole(String iconName) {
    switch (iconName) {
      case 'admin_panel_settings':
        return Icons.admin_panel_settings_outlined;
      case 'room_service':
        return Icons.room_service_outlined;
      case 'restaurant':
        return Icons.restaurant_outlined;
      case 'point_of_sale':
        return Icons.point_of_sale_outlined;
      default:
        return Icons.badge_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Release mode safeguard
    if (!kDebugMode) {
      return const Scaffold(
        body: Center(child: Text('404 Not Found')),
      );
    }

    return Scaffold(
      backgroundColor: BrandColors.creamBg,
      appBar: AppBar(
        title: const Text(
          '🛠️ Debug Tools & Tables',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: BrandColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: BrandColors.textPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Info Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: BrandColors.primaryOrangeLight,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: BrandColors.primaryOrange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: BrandColors.primaryOrange, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Debug screen active only during development (kDebugMode). Not accessible in release builds.',
                          style: TextStyle(
                            fontSize: 12,
                            color: BrandColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Card: Quick Role Login
                _buildCard(
                  title: '🚀 Quick Role Login',
                  subtitle: 'Direct authentication into staff stations',
                  content: GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 2.6,
                    children: _roles.map((item) {
                      return OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: BrandColors.textPrimary,
                          backgroundColor: Colors.white,
                          side: const BorderSide(color: BrandColors.border),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.centerLeft,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        icon: Icon(
                          _iconForRole(item['icon']!),
                          size: 18,
                          color: BrandColors.primaryOrange,
                        ),
                        label: Text(
                          item['role']!,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        onPressed: _isSigningIn
                            ? null
                            : () => _handleRoleLogin(
                                  item['email']!,
                                  item['password']!,
                                  item['role']!,
                                ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Card: Customer table selection shortcuts
                _buildCard(
                    title: '🍽️ Customer Table Shortcuts',
                    subtitle: 'Open the guest-count step for a demo table',
                  content: Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _demoTables.map((tbl) {
                      return ActionChip(
                        avatar: const Icon(
                          Icons.table_restaurant_outlined,
                          size: 16,
                          color: BrandColors.primaryOrange,
                        ),
                        label: Text(
                          tbl,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        backgroundColor: BrandColors.creamBg,
                        side: const BorderSide(color: BrandColors.border),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                        onPressed: () => _navigateToTable(tbl),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 20),

                // Card: Custom Table ID
                _buildCard(
                  title: '🔗 Custom Table ID',
                  subtitle: 'Test any custom table string',
                  content: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _tableInputController,
                          textCapitalization: TextCapitalization.characters,
                          decoration: InputDecoration(
                            hintText: 'e.g. BAR1, T12, OUTDOOR2',
                            hintStyle: const TextStyle(
                              fontSize: 13,
                              color: BrandColors.textMuted,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: BrandColors.border),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(color: BrandColors.border),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: BrandColors.primaryOrange,
                                width: 1.5,
                              ),
                            ),
                          ),
                          onSubmitted: _navigateToTable,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: BrandColors.primaryOrange,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                        ),
                        onPressed: () => _navigateToTable(_tableInputController.text),
                        child: const Text(
                          'Go →',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCard({
    required String title,
    required String subtitle,
    required Widget content,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BrandColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: BrandColors.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: BrandColors.textSecondary,
            ),
          ),
          const SizedBox(height: 14),
          content,
        ],
      ),
    );
  }
}
