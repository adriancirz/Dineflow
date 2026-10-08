import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/brand_colors.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/dineflow_logo.dart';
import '../debug/debug_sheet.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController(text: 'admin@dineflow.com');
  final _passwordController = TextEditingController(text: 'Admin123!');
  bool _obscurePassword = true;
  bool _rememberMe = true;
  String _selectedRole = 'Admin';

  void _showDebugSheet() {
    if (!kDebugMode) return;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DebugSheet(
        onQuickLogin: (email, password) {
          _emailController.text = email;
          _passwordController.text = password;
          _handleSignIn();
        },
      ),
    );
  }

  final List<Map<String, String>> _roleQuickLogins = [
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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _selectRole(Map<String, String> item) {
    setState(() {
      _selectedRole = item['role']!;
      _emailController.text = item['email']!;
      _passwordController.text = item['password']!;
    });
  }

  Future<void> _handleSignIn() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter both email and password.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await ref.read(authControllerProvider.notifier).signInWithEmail(
          email: email,
          password: password,
        );

    if (!success && mounted) {
      final err = ref.read(authControllerProvider).errorMessage ?? 'Login failed';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo and brand header (Long press in debug mode opens debug menu)
                  GestureDetector(
                    onLongPress: kDebugMode ? _showDebugSheet : null,
                    child: const DineFlowLogo(
                      markSize: 42,
                      fontSize: 24,
                      useAppTile: true,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Heading
                  const Text(
                    'Welcome back',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sign in to access your ${_selectedRole.toLowerCase()} station and live orders.',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Role Selector Chips
                  const Text(
                    'QUICK ROLE LOGIN',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _roleQuickLogins.map((item) {
                        final isSelected = item['role'] == _selectedRole;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(item['role']!),
                            selected: isSelected,
                            onSelected: (_) => _selectRole(item),
                            selectedColor: AppColors.primaryLight,
                            backgroundColor: Colors.white,
                            labelStyle: TextStyle(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected ? AppColors.primary : AppColors.textSecondary,
                            ),
                            side: BorderSide(
                              color: isSelected ? AppColors.primary : AppColors.border,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Staff ID or Email Input
                  const Text(
                    'Staff ID or email',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'e.g. admin@dineflow.com',
                      prefixIcon: Icon(Icons.person_outline, size: 20),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // Password Input
                  const Text(
                    'Password',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      hintText: '••••••••',
                      prefixIcon: const Icon(Icons.lock_outline, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                          size: 20,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Remember me & Forgot Password
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _rememberMe,
                              activeColor: AppColors.primary,
                              onChanged: (val) {
                                setState(() {
                                  _rememberMe = val ?? true;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Remember this device',
                            style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {},
                        style: TextButton.styleFrom(padding: EdgeInsets.zero),
                        child: const Text(
                          'Forgot password?',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: authState.isLoading ? null : _handleSignIn,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: authState.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Footer help
                  const Center(
                    child: Text(
                      'Need help? Ask your shift manager.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Subtle customer fallback link
                  Center(
                    child: TextButton(
                      onPressed: () => context.go('/select-table'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        visualDensity: VisualDensity.compact,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: const Text(
                        '🪑 Are you a customer?  View menu →',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ),

                  // Debug build badge (Visible only when kDebugMode is true)
                  if (kDebugMode) ...[
                    const SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFDBA74)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bug_report,
                              size: 12,
                              color: BrandColors.primaryOrange,
                            ),
                            SizedBox(width: 4),
                            Text(
                              'DEBUG BUILD',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                                color: BrandColors.primaryOrange,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
