import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/brand_colors.dart';
import '../../models/table_model.dart';
import '../../providers/customer_session_provider.dart';
import '../../providers/table_providers.dart';
import '../../router/route_names.dart';
import '../../widgets/dineflow_logo.dart';

class TablePickerScreen extends ConsumerStatefulWidget {
  const TablePickerScreen({super.key});

  @override
  ConsumerState<TablePickerScreen> createState() => _TablePickerScreenState();
}

class _TablePickerScreenState extends ConsumerState<TablePickerScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(tablesStreamProvider);

    return Scaffold(
      backgroundColor: BrandColors.creamBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            const DineFlowMark(size: 34, style: DineFlowMarkStyle.appTile),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'DineFlow',
                    style: TextStyle(
                      color: BrandColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Select your table',
                    style: TextStyle(
                      color: BrandColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => context.go(AppRoutes.login),
            child: const Text(
              'Staff sign in',
              style: TextStyle(color: BrandColors.primaryOrange),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome! Please select your table to begin',
                    style: TextStyle(
                      color: BrandColors.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(
                      () => _searchQuery = value.trim().toLowerCase(),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search table number',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isEmpty
                          ? null
                          : IconButton(
                              tooltip: 'Clear search',
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: BrandColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: BrandColors.border),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: tablesAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(
                    color: BrandColors.primaryOrange,
                  ),
                ),
                error: (error, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: BrandColors.error,
                          size: 40,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Could not load tables. Please try again.',
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
                data: (tables) => _buildTableSections(tables),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              color: Colors.white,
              child: const Text(
                "Can't find your table? Ask your waiter for help",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: BrandColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableSections(List<TableModel> tables) {
    if (tables.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'No tables available. Please ask a waiter for assistance.',
            textAlign: TextAlign.center,
            style: TextStyle(color: BrandColors.textSecondary, fontSize: 15),
          ),
        ),
      );
    }

    final filteredTables = tables.where((table) {
      return table.tableNumber.toLowerCase().contains(_searchQuery);
    }).toList();

    if (filteredTables.isEmpty) {
      return const Center(
        child: Text(
          'No tables match your search.',
          style: TextStyle(color: BrandColors.textSecondary),
        ),
      );
    }

    final groupedTables = <String, List<TableModel>>{};
    for (final table in filteredTables) {
      final section = table.section.trim().isEmpty ? 'Other' : table.section;
      groupedTables.putIfAbsent(section, () => []).add(table);
    }
    final sectionNames = groupedTables.keys.toList()..sort();

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1000
            ? 5
            : constraints.maxWidth >= 700
            ? 4
            : 3;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
          children: [
            for (final section in sectionNames) ...[
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 10),
                child: Text(
                  section,
                  style: const TextStyle(
                    color: BrandColors.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: groupedTables[section]!.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.95,
                ),
                itemBuilder: (context, index) {
                  final table = groupedTables[section]![index];
                  return _TableCard(
                    table: table,
                    onTap: _isDisabled(table.status)
                        ? null
                        : () {
                            if (table.status == TableStatus.occupied) {
                              ScaffoldMessenger.of(context)
                                ..hideCurrentSnackBar()
                                ..showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Table ${formatTableName(table.tableNumber)} is occupied. Please choose an available table.',
                                    ),
                                  ),
                                );
                              return;
                            }

                            context.push(
                              AppRoutes.tableGuests(
                                normalizeTableId(table.tableNumber),
                              ),
                            );
                          },
                  );
                },
              ),
            ],
          ],
        );
      },
    );
  }

  bool _isDisabled(TableStatus status) =>
      status == TableStatus.reserved || status == TableStatus.cleaning;
}

class _TableCard extends StatelessWidget {
  final TableModel table;
  final VoidCallback? onTap;

  const _TableCard({required this.table, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final (background, foreground, statusLabel) = switch (table.status) {
      TableStatus.available => (
        const Color(0xFFE6F7EC),
        const Color(0xFF18864B),
        'Available',
      ),
      TableStatus.occupied => (
        const Color(0xFFFFF1E5),
        const Color(0xFFC45A1A),
        'Occupied',
      ),
      TableStatus.reserved => (
        const Color(0xFFF1F1F1),
        BrandColors.textSecondary,
        'Reserved',
      ),
      TableStatus.cleaning => (
        const Color(0xFFF1F1F1),
        BrandColors.textSecondary,
        'Cleaning',
      ),
    };

    return Card(
      color: background,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: BrandColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                formatTableName(table.tableNumber),
                style: TextStyle(
                  color: foreground,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${table.capacity} seats',
                style: const TextStyle(
                  color: BrandColors.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
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
