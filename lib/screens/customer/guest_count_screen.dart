import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/brand_colors.dart';
import '../../core/widgets/primary_button.dart';
import '../../models/table_model.dart';
import '../../providers/customer_session_provider.dart';
import '../../providers/table_providers.dart';
import '../../router/route_names.dart';
import '../../services/anonymous_auth_service.dart';

class GuestCountScreen extends ConsumerStatefulWidget {
  final String tableId;

  const GuestCountScreen({super.key, required this.tableId});

  @override
  ConsumerState<GuestCountScreen> createState() => _GuestCountScreenState();
}

class _GuestCountScreenState extends ConsumerState<GuestCountScreen> {
  int _guestCount = 2;
  bool _isStarting = false;

  Future<void> _startBrowsing(TableModel table) async {
    setState(() => _isStarting = true);
    try {
      final authService = ref.read(anonymousAuthServiceProvider);
      if (!authService.isSignedIn) {
        await authService.signInAnonymously();
      }

      final session = ref.read(customerSessionProvider.notifier);
      session.setTable(
        tableId: table.id,
        tableNumber: table.tableNumber,
        table: table,
      );
      session.setGuestCount(_guestCount);

      if (mounted) {
        context.go(AppRoutes.tableMenu(normalizeTableId(table.tableNumber)));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not start your dining session: $error'),
            backgroundColor: BrandColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isStarting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final normalizedTableId = normalizeTableId(widget.tableId);
    final tablesAsync = ref.watch(tablesStreamProvider);

    return Scaffold(
      backgroundColor: BrandColors.creamBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          tooltip: 'Change table',
          icon: const Icon(Icons.arrow_back, color: BrandColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.customerTablePicker);
            }
          },
        ),
        title: const Text(
          'Guest count',
          style: TextStyle(
            color: BrandColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: tablesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: BrandColors.primaryOrange),
        ),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Could not load this table. Please try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: BrandColors.textPrimary),
                ),
                const SizedBox(height: 12),
                TextButton.icon(
                  onPressed: () => ref.invalidate(tablesStreamProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (tables) {
          TableModel? selectedTable;
          for (final table in tables) {
            if (normalizeTableId(table.tableNumber) == normalizedTableId ||
                normalizeTableId(table.id) == normalizedTableId) {
              selectedTable = table;
              break;
            }
          }

          if (selectedTable == null) {
            return _buildUnavailableMessage(
              'This table could not be found. Please select another table.',
            );
          }

          final table = selectedTable;
          final maxGuests = math.max(12, table.capacity + 2);
          final tableUnavailable =
              table.status == TableStatus.reserved ||
              table.status == TableStatus.cleaning;

          if (tableUnavailable) {
            return _buildUnavailableMessage(
              '${formatTableName(table.tableNumber)} is '
              '${table.status.label.toLowerCase()}. '
              'Please select another table.',
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "You're at ${formatTableName(table.tableNumber)}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: BrandColors.textPrimary,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This table seats up to ${table.capacity}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: BrandColors.textSecondary,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: BrandColors.border),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            tooltip: 'Remove one guest',
                            iconSize: 34,
                            color: _guestCount > 1
                                ? BrandColors.primaryOrange
                                : BrandColors.textMuted,
                            onPressed: _guestCount > 1
                                ? () => setState(() => _guestCount--)
                                : null,
                            icon: const Icon(Icons.remove_circle_outline),
                          ),
                          Column(
                            children: [
                              Text(
                                '$_guestCount',
                                style: const TextStyle(
                                  color: BrandColors.textPrimary,
                                  fontSize: 30,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                _guestCount == 1 ? 'Guest' : 'Guests',
                                style: const TextStyle(
                                  color: BrandColors.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                          IconButton(
                            tooltip: 'Add one guest',
                            iconSize: 34,
                            color: _guestCount < maxGuests
                                ? BrandColors.primaryOrange
                                : BrandColors.textMuted,
                            onPressed: _guestCount < maxGuests
                                ? () => setState(() => _guestCount++)
                                : null,
                            icon: const Icon(Icons.add_circle_outline),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    PrimaryButton(
                      text: 'Start browsing menu',
                      icon: Icons.arrow_forward,
                      height: 52,
                      isLoading: _isStarting,
                      onPressed: _isStarting
                          ? null
                          : () => _startBrowsing(table),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _isStarting
                          ? null
                          : () => context.go(AppRoutes.customerTablePicker),
                      child: const Text(
                        'Change table',
                        style: TextStyle(color: BrandColors.primaryOrange),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildUnavailableMessage(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.table_restaurant_outlined,
              color: BrandColors.textMuted,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: BrandColors.textSecondary),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => context.go(AppRoutes.customerTablePicker),
              child: const Text(
                'Choose another table',
                style: TextStyle(color: BrandColors.primaryOrange),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
