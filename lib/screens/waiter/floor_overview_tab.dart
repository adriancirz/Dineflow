import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../core/sample_data.dart';
import '../../models/table_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_session_provider.dart';
import '../../providers/notification_providers.dart';
import '../../providers/order_providers.dart';
import '../../providers/table_providers.dart';
import '../../router/route_names.dart';
import '../../services/waiter_request_service.dart';
import 'waiter_notifications_sheet.dart';

class FloorOverviewTab extends ConsumerStatefulWidget {
  final Function(int tabIndex)? onNavigateTab;

  const FloorOverviewTab({super.key, this.onNavigateTab});

  @override
  ConsumerState<FloorOverviewTab> createState() => _FloorOverviewTabState();
}

class _FloorOverviewTabState extends ConsumerState<FloorOverviewTab> {
  String _selectedFilter = 'all'; // 'all', 'available', 'my_tables'
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(tablesStreamProvider);
    final user = ref.watch(currentUserProvider).asData?.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Floor overview',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            Text(
              '${user?.assignedSection ?? "Floor"} · Lunch shift',
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final unreadCount = ref.watch(
                unreadWaiterNotificationsCountProvider,
              );
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    icon: Icon(
                      unreadCount > 0
                          ? Icons.notifications_active
                          : Icons.notifications_none,
                      color: unreadCount > 0
                          ? AppColors.primary
                          : AppColors.textPrimary,
                    ),
                    tooltip: 'Customer Requests',
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => WaiterNotificationsSheet(
                          onSelectTable: (tableNum) {
                            final normalizedTableNumber = normalizeTableId(
                              tableNum,
                            );
                            setState(() {
                              _selectedFilter = 'all';
                              _searchQuery = normalizedTableNumber;
                            });
                          },
                        ),
                      );
                    },
                  ),
                  if (unreadCount > 0)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          unreadCount > 9 ? '9+' : '$unreadCount',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.textSecondary),
            tooltip: 'Sign Out',
            onPressed: () =>
                ref.read(authControllerProvider.notifier).signOut(),
          ),
        ],
      ),
      body: tablesAsync.when(
        data: (tablesList) {
          final tables = tablesList.isEmpty
              ? SampleData.defaultTables
              : tablesList;
          return _buildBody(context, tables);
        },
        loading: () => _buildBody(context, SampleData.defaultTables),
        error: (_, _) => _buildBody(context, SampleData.defaultTables),
      ),
    );
  }

  Widget _buildBody(BuildContext context, List<TableModel> tables) {
    final uniqueTables = deduplicateTables(tables);

    // Calculate counts from deduplicated tables
    int avail = uniqueTables
        .where((t) => t.status == TableStatus.available)
        .length;
    int occ = uniqueTables
        .where((t) => t.status == TableStatus.occupied)
        .length;
    int res = uniqueTables
        .where((t) => t.status == TableStatus.reserved)
        .length;

    // Filter tables
    List<TableModel> filtered = uniqueTables;
    if (_selectedFilter == 'available') {
      filtered = filtered
          .where((t) => t.status == TableStatus.available)
          .toList();
    } else if (_selectedFilter == 'my_tables') {
      filtered = filtered
          .where((t) => t.status == TableStatus.occupied)
          .toList();
    }

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      final normalizedTableQuery = normalizeTableId(q).toLowerCase();
      filtered = filtered.where((t) {
        final matchNum = normalizeTableId(t.tableNumber)
            .toLowerCase()
            .contains(normalizedTableQuery);
        final matchRes = (t.reservationName ?? '').toLowerCase().contains(q);
        final matchNote = (t.statusNote ?? '').toLowerCase().contains(q);
        return matchNum || matchRes || matchNote;
      }).toList();
    }

    return Column(
      children: [
        // 1. Stats Counter Cards (Available, Occupied, Reserved)
        Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              _buildStatCard(
                'Available',
                '$avail',
                AppColors.available,
                AppColors.availableBg,
              ),
              const SizedBox(width: 10),
              _buildStatCard(
                'Occupied',
                '$occ',
                AppColors.occupied,
                AppColors.occupiedBg,
              ),
              const SizedBox(width: 10),
              _buildStatCard(
                'Reserved',
                '$res',
                AppColors.reserved,
                AppColors.reservedBg,
              ),
            ],
          ),
        ),

        // 2. Search & Filter Bar
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            children: [
              // Search input
              TextField(
                onChanged: (val) => setState(() => _searchQuery = val),
                decoration: InputDecoration(
                  hintText: 'Search table or guest',
                  hintStyle: const TextStyle(
                    fontSize: 14,
                    color: AppColors.textMuted,
                  ),
                  prefixIcon: const Icon(
                    Icons.search,
                    size: 20,
                    color: AppColors.textMuted,
                  ),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () => setState(() => _searchQuery = ''),
                        )
                      : null,
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 0,
                    horizontal: 16,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Filter Chips: All, Available, My tables
              Row(
                children: [
                  _buildFilterChip('All ${uniqueTables.length}', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Available', 'available'),
                  const SizedBox(width: 8),
                  _buildFilterChip('My tables', 'my_tables'),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1, color: AppColors.divider),

        // 3. Floor Grid of Tables
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text(
                    'No tables match filter',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.35,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final table = filtered[index];
                    return _buildTableCard(context, table);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: color.withValues(alpha: 0.85),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _selectedFilter == value;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.textPrimary : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.textPrimary : AppColors.border,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            color: isSelected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildTableCard(BuildContext context, TableModel table) {
    Color statusColor;
    Color statusBg;
    String statusText;

    switch (table.status) {
      case TableStatus.available:
        statusColor = AppColors.available;
        statusBg = AppColors.availableBg;
        statusText = 'Available';
        break;
      case TableStatus.occupied:
        statusColor = AppColors.occupied;
        statusBg = AppColors.occupiedBg;
        statusText = 'Occupied';
        break;
      case TableStatus.reserved:
        statusColor = AppColors.reserved;
        statusBg = AppColors.reservedBg;
        statusText = 'Reserved';
        break;
      case TableStatus.cleaning:
        statusColor = AppColors.pending;
        statusBg = AppColors.pendingBg;
        statusText = 'Cleaning';
        break;
    }

    final unreadMap = ref.watch(unreadNotificationsByTableProvider);
    final unreadForTable = unreadMap[table.tableNumber] ?? 0;

    return InkWell(
      onTap: () => _handleTableTap(context, table),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: table.status == TableStatus.occupied
              ? statusBg.withValues(alpha: 0.5)
              : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: unreadForTable > 0
                ? AppColors.primary
                : (table.status == TableStatus.occupied
                      ? AppColors.occupied.withValues(alpha: 0.4)
                      : AppColors.border),
            width: unreadForTable > 0
                ? 2
                : (table.status == TableStatus.occupied ? 1.5 : 1),
          ),
          boxShadow: [
            BoxShadow(
              color: unreadForTable > 0
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.black.withValues(alpha: 0.03),
              blurRadius: unreadForTable > 0 ? 8 : 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top Row: Table number & capacity
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  table.tableNumber,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                Row(
                  children: [
                    if (unreadForTable > 0) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.notifications_active,
                              size: 10,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '$unreadForTable',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    const Icon(
                      Icons.person_outline,
                      size: 14,
                      color: AppColors.textMuted,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      '${table.capacity}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            // Status Badge
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ],
            ),

            // Subtitle / Note
            Text(
              table.statusNote ??
                  (table.status == TableStatus.available ? 'Ready now' : ''),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleTableTap(BuildContext context, TableModel table) {
    if (table.status == TableStatus.available) {
      _showStartOrderDialog(context, table);
    } else if (table.status == TableStatus.occupied) {
      _showOccupiedTableOptions(context, table);
    } else if (table.status == TableStatus.reserved) {
      _showReservedTableDialog(context, table);
    }
  }

  void _showStartOrderDialog(BuildContext context, TableModel table) {
    int guests = table.capacity > 2 ? 4 : 2;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Start Order · ${table.tableNumber}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Number of guests:',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 8),
              Row(
                children: [1, 2, 4, 6, 8].map((count) {
                  final isSel = guests == count;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text('$count'),
                      selected: isSel,
                      selectedColor: AppColors.primaryLight,
                      labelStyle: TextStyle(
                        color: isSel
                            ? AppColors.primaryDark
                            : AppColors.textPrimary,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                      ),
                      onSelected: (val) {
                        if (val) setSheetState(() => guests = count);
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.restaurant_menu),
                  label: const Text('Open Menu & Take Order'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(ctx);
                    ref
                        .read(cartProvider.notifier)
                        .setTable(table.id, table.tableNumber);
                    if (widget.onNavigateTab != null) {
                      widget.onNavigateTab!(1); // Go to Menu Tab
                    } else {
                      context.push(AppRoutes.waiterMenu);
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOccupiedTableOptions(BuildContext context, TableModel table) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Table ${table.tableNumber} · Occupied',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Info: ${table.statusNote ?? "Order in progress"}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            if (table.currentOrderId != null &&
                table.currentOrderId!.isNotEmpty)
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: AppColors.readyBg,
                  child: Icon(Icons.receipt_long, color: AppColors.ready),
                ),
                title: const Text('View Active Order'),
                subtitle: const Text('Track kitchen & items status'),
                onTap: () {
                  Navigator.pop(ctx);
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(2);
                  } else {
                    context.push(
                      AppRoutes.waiterTables,
                      extra: {'tab': 2, 'orderId': table.currentOrderId},
                    );
                  }
                },
              ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: Color(0xFFFEF3C7),
                child: Icon(Icons.campaign, color: Color(0xFFD97706)),
              ),
              title: const Text('Call / Notify Customer'),
              subtitle: const Text(
                'Send direct message or alert to customer device',
              ),
              onTap: () {
                Navigator.pop(ctx);
                _showNotifyCustomerDialog(context, table);
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.primaryLight,
                child: Icon(Icons.add_shopping_cart, color: AppColors.primary),
              ),
              title: const Text('Add items to this table'),
              onTap: () {
                Navigator.pop(ctx);
                ref
                    .read(cartProvider.notifier)
                    .setTable(table.id, table.tableNumber);
                if (widget.onNavigateTab != null) {
                  widget.onNavigateTab!(1);
                } else {
                  context.push(AppRoutes.waiterMenu);
                }
              },
            ),
            ListTile(
              leading: const CircleAvatar(
                backgroundColor: AppColors.availableBg,
                child: Icon(Icons.check, color: AppColors.available),
              ),
              title: const Text('Mark Table Available / Cleaned'),
              onTap: () async {
                Navigator.pop(ctx);
                await ref
                    .read(tableRepositoryProvider)
                    .updateTableStatus(
                      table.id,
                      TableStatus.available,
                      note: 'Cleaned just now',
                    );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showNotifyCustomerDialog(BuildContext context, TableModel table) {
    final textController = TextEditingController();
    String selectedPreset = 'Your waiter is on the way to your table.';

    final presets = [
      'Your waiter is on the way to your table.',
      'Your food is currently being prepared.',
      'Your food is ready and being served!',
      'Your bill has been printed at the cashier.',
    ];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Call / Notify Table ${table.tableNumber}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Send an instant alert to the guest device at this table:',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const SizedBox(height: 12),
              ...presets.map((msg) {
                final isSel =
                    selectedPreset == msg && textController.text.isEmpty;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6.0),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setModalState(() {
                        selectedPreset = msg;
                        textController.clear();
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSel
                            ? AppColors.primaryLight
                            : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSel
                              ? AppColors.primary
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isSel
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 18,
                            color: isSel
                                ? AppColors.primary
                                : Colors.grey.shade400,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              msg,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSel
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                                color: isSel
                                    ? AppColors.primaryDark
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 10),
              TextField(
                controller: textController,
                decoration: InputDecoration(
                  hintText: 'Or type custom message...',
                  hintStyle: const TextStyle(fontSize: 13),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onChanged: (_) => setModalState(() {}),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.send),
                  label: const Text('Send Alert to Table'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () async {
                    final message = textController.text.trim().isNotEmpty
                        ? textController.text.trim()
                        : selectedPreset;
                    Navigator.pop(ctx);
                    try {
                      await ref
                          .read(waiterRequestServiceProvider)
                          .notifyCustomer(
                            tableId: table.id,
                            tableNumber: table.tableNumber,
                            orderId: table.currentOrderId,
                            title: 'Waiter Update · Table ${table.tableNumber}',
                            message: message,
                          );
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Notified Table ${table.tableNumber}: "$message"',
                            ),
                            backgroundColor: AppColors.available,
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to notify customer: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showReservedTableDialog(BuildContext context, TableModel table) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reserved Table ${table.tableNumber}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Reservation: ${table.reservationName ?? "Guest"} at ${table.reservationTime ?? "Today"}',
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Seat Guests & Start Order'),
                onPressed: () {
                  Navigator.pop(ctx);
                  ref
                      .read(cartProvider.notifier)
                      .setTable(table.id, table.tableNumber);
                  if (widget.onNavigateTab != null) {
                    widget.onNavigateTab!(1);
                  } else {
                    context.push(AppRoutes.waiterMenu);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
