import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_colors.dart';
import '../../core/sample_data.dart';
import '../../models/table_model.dart';
import '../../providers/firebase_providers.dart';
import '../../providers/table_providers.dart';

class AdminTablesTab extends ConsumerStatefulWidget {
  const AdminTablesTab({super.key});

  @override
  ConsumerState<AdminTablesTab> createState() => _AdminTablesTabState();
}

class _AdminTablesTabState extends ConsumerState<AdminTablesTab> {
  TableModel? _selectedTable;

  void _showAddTableDialog() {
    final numberController = TextEditingController();
    int capacity = 4;
    String section = 'Main Dining';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          title: const Text('Add Dining Table'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: numberController,
                decoration: const InputDecoration(
                  labelText: 'Table Number *',
                  hintText: 'e.g. T13',
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Capacity (Seats):',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              Row(
                children: [2, 4, 6, 8].map((c) {
                  final isSel = capacity == c;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text('$c'),
                      selected: isSel,
                      onSelected: (val) {
                        if (val) setDialogState(() => capacity = c);
                      },
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: section,
                decoration: const InputDecoration(labelText: 'Section'),
                items: ['Main Dining', 'Patio', 'Bar Area', 'VIP Room'].map((
                  s,
                ) {
                  return DropdownMenuItem(value: s, child: Text(s));
                }).toList(),
                onChanged: (val) {
                  if (val != null) setDialogState(() => section = val);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final tableNum = numberController.text.trim();
                if (tableNum.isEmpty) return;

                final normalizedNum = tableNum.toUpperCase();
                final db = ref.read(firestoreProvider);
                final docRef = db.collection('tables').doc(normalizedNum);
                final newTable = TableModel(
                  id: normalizedNum,
                  tableNumber: normalizedNum,
                  capacity: capacity,
                  status: TableStatus.available,
                  section: section,
                  statusNote: 'Ready now',
                );

                await docRef.set(newTable.toMap(), SetOptions(merge: true));
                if (ctx.mounted) Navigator.pop(ctx);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added Table $tableNum'),
                      backgroundColor: AppColors.available,
                    ),
                  );
                }
              },
              child: const Text('Add Table'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(tablesStreamProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row (Wireframe Page 19 top)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Table management',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Floor plan, seating capacity, and table statuses',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add table'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _showAddTableDialog,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Floor Plan Grid & Table Detail Inspector
            Expanded(
              child: tablesAsync.when(
                data: (tablesList) {
                  final tables = tablesList.isEmpty
                      ? SampleData.defaultTables
                      : tablesList;
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Floor Grid
                      Expanded(
                        flex: 3,
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 3,
                                mainAxisSpacing: 14,
                                crossAxisSpacing: 14,
                                childAspectRatio: 1.3,
                              ),
                          itemCount: tables.length,
                          itemBuilder: (ctx, i) {
                            final table = tables[i];
                            final isSel = _selectedTable?.id == table.id;
                            return _buildTableGridItem(table, isSel);
                          },
                        ),
                      ),
                      const SizedBox(width: 20),

                      // Selected Table Inspector Panel (Wireframe Page 19)
                      Expanded(
                        flex: 2,
                        child: _buildTableInspector(
                          _selectedTable ??
                              (tables.isNotEmpty
                                  ? tables.first
                                  : SampleData.defaultTables.first),
                        ),
                      ),
                    ],
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, _) =>
                    const Center(child: Text('Error loading tables')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableGridItem(TableModel table, bool isSelected) {
    Color statusColor;
    Color statusBg;

    switch (table.status) {
      case TableStatus.available:
        statusColor = AppColors.available;
        statusBg = AppColors.availableBg;
        break;
      case TableStatus.occupied:
        statusColor = AppColors.occupied;
        statusBg = AppColors.occupiedBg;
        break;
      case TableStatus.reserved:
        statusColor = AppColors.reserved;
        statusBg = AppColors.reservedBg;
        break;
      case TableStatus.cleaning:
        statusColor = AppColors.pending;
        statusBg = AppColors.pendingBg;
        break;
    }

    return InkWell(
      onTap: () => setState(() => _selectedTable = table),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  table.tableNumber,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${table.capacity} seats',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '● ${table.status.label}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
            Text(
              table.statusNote ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableInspector(TableModel table) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Table ${table.tableNumber}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  table.section,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _buildInfoRow('Seating Capacity', '${table.capacity} Guests'),
          _buildInfoRow('Current Status', table.status.label),
          _buildInfoRow('Current Order', table.currentOrderId ?? 'None (Idle)'),
          if (table.guestCount != null)
            _buildInfoRow('Seated Guests', '${table.guestCount}'),
          if (table.statusNote != null)
            _buildInfoRow('Note / Elapsed', table.statusNote!),
          const SizedBox(height: 20),
          const Text(
            'Update Status:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildStatusButton(
                table,
                TableStatus.available,
                AppColors.available,
                'Available',
              ),
              _buildStatusButton(
                table,
                TableStatus.occupied,
                AppColors.occupied,
                'Occupied',
              ),
              _buildStatusButton(
                table,
                TableStatus.reserved,
                AppColors.reserved,
                'Reserved',
              ),
              _buildStatusButton(
                table,
                TableStatus.cleaning,
                AppColors.pending,
                'Cleaning',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton(
    TableModel table,
    TableStatus status,
    Color color,
    String label,
  ) {
    final isCurrent = table.status == status;
    return OutlinedButton(
      style: OutlinedButton.styleFrom(
        foregroundColor: isCurrent ? Colors.white : color,
        backgroundColor: isCurrent ? color : Colors.transparent,
        side: BorderSide(color: color),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      onPressed: () async {
        await ref
            .read(tableRepositoryProvider)
            .updateTableStatus(
              table.id,
              status,
              note: status == TableStatus.available ? 'Ready now' : null,
            );
        setState(() {
          _selectedTable = table.copyWith(status: status);
        });
      },
      child: Text(label, style: const TextStyle(fontSize: 12)),
    );
  }
}
