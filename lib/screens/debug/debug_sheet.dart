import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/brand_colors.dart';
import '../../providers/auth_provider.dart';

/// Modal bottom sheet providing developer shortcuts for fast testing.
/// Guarded by [kDebugMode] — returns [SizedBox.shrink] if invoked in release mode.
class DebugSheet extends ConsumerStatefulWidget {
  final void Function(String email, String password)? onQuickLogin;

  const DebugSheet({super.key, this.onQuickLogin});

  @override
  ConsumerState<DebugSheet> createState() => _DebugSheetState();
}

class _DebugSheetState extends ConsumerState<DebugSheet> {
  final _tableInputController = TextEditingController();
  bool _isSigningIn = false;

  // Preset developer role credentials
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

  // Preset demo tables
  static const List<String> _demoTables = ['T01', 'T02', 'T04', 'T06', 'T10'];

  @override
  void dispose() {
    _tableInputController.dispose();
    super.dispose();
  }

  Future<void> _handleRoleLogin(
    String email,
    String password,
    String role,
  ) async {
    if (widget.onQuickLogin != null) {
      Navigator.pop(context);
      widget.onQuickLogin!(email, password);
      return;
    }

    setState(() => _isSigningIn = true);
    try {
      final success = await ref
          .read(authControllerProvider.notifier)
          .signInWithEmail(email: email, password: password);
      if (mounted) {
        Navigator.pop(context);
        if (!success) {
          final err =
              ref.read(authControllerProvider).errorMessage ?? 'Sign in failed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Quick login failed ($role): $err'),
              backgroundColor: BrandColors.error,
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningIn = false);
      }
    }
  }

  void _navigateToTable(String tableId) {
    final sanitized = tableId.trim().toUpperCase().replaceAll(
      RegExp(r'[^A-Z0-9]'),
      '',
    );
    if (sanitized.isEmpty) return;

    Navigator.pop(context);
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
    // Release mode safeguard: completely hide widget
    if (!kDebugMode) {
      return const SizedBox.shrink();
    }

    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sheet Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: BrandColors.primaryOrangeLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.build_circle_outlined,
                          color: BrandColors.primaryOrange,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🛠️ Debug Menu',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: BrandColors.textPrimary,
                            ),
                          ),
                          Text(
                            'Developer shortcuts · Debug build only',
                            style: TextStyle(
                              fontSize: 11,
                              color: BrandColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: BrandColors.textSecondary,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(height: 24, color: BrandColors.divider),

              // Section 1: Quick Role Login
              const Row(
                children: [
                  Text('🚀', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6),
                  Text(
                    'Quick role login',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: BrandColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Auto-fills credentials and signs in as station staff:',
                style: TextStyle(
                  fontSize: 12,
                  color: BrandColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
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
                      padding: const EdgeInsets.symmetric(horizontal: 10),
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

              const SizedBox(height: 20),
              const Divider(height: 1, color: BrandColors.divider),
              const SizedBox(height: 16),

              // Section 2: Customer table selection shortcuts
              const Row(
                children: [
                  Text('🍽️', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6),
                  Text(
                    'Customer table shortcuts',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: BrandColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Opens the guest-count step for a demo table:',
                style: TextStyle(
                  fontSize: 12,
                  color: BrandColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
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
                        color: BrandColors.textPrimary,
                      ),
                    ),
                    backgroundColor: BrandColors.creamBg,
                    side: const BorderSide(color: BrandColors.border),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    onPressed: () => _navigateToTable(tbl),
                  );
                }).toList(),
              ),

              const SizedBox(height: 20),
              const Divider(height: 1, color: BrandColors.divider),
              const SizedBox(height: 16),

              // Section 3: Custom Table ID
              const Row(
                children: [
                  Text('🔗', style: TextStyle(fontSize: 16)),
                  SizedBox(width: 6),
                  Text(
                    'Custom table ID',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: BrandColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Test any arbitrary table (e.g. VIP1, T99, BAR3):',
                style: TextStyle(
                  fontSize: 12,
                  color: BrandColors.textSecondary,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tableInputController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        hintText: 'e.g. T05 or PATIO1',
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
                          borderSide: const BorderSide(
                            color: BrandColors.border,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                            color: BrandColors.border,
                          ),
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
                        horizontal: 18,
                        vertical: 14,
                      ),
                    ),
                    onPressed: () =>
                        _navigateToTable(_tableInputController.text),
                    child: const Text(
                      'Go →',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Bottom subtle close button
              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    foregroundColor: BrandColors.textSecondary,
                  ),
                  child: const Text(
                    'Close Debug Menu',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
