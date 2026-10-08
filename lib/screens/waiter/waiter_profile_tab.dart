import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/sample_data.dart';
import '../../providers/auth_provider.dart';
import '../../providers/firebase_providers.dart';
import '../../widgets/dineflow_logo.dart';

class WaiterProfileTab extends ConsumerWidget {
  const WaiterProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).asData?.value;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Staff Profile & Shift',
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // DineFlow Logo
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 12.0),
                child: DineFlowLogo(
                  markSize: 36,
                  fontSize: 22,
                  useAppTile: true,
                  tagline: 'Staff Operations & Floor Station',
                  crossAxisAlignment: CrossAxisAlignment.center,
                ),
              ),
            ),
            const SizedBox(height: 12),

            // User Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primaryLight,
                    child: Text(
                      (user?.displayName ?? 'W')[0].toUpperCase(),
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? 'Mark Reyes',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${user?.email ?? "waiter@dineflow.com"} · ${user?.employeeId ?? "EMP-002"}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.availableBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            '● Shift: On Duty',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.available,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'Shift Details',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            _buildInfoTile('Assigned Section', user?.assignedSection ?? 'Main Dining / Section A'),
            _buildInfoTile('Shift Schedule', 'Lunch Service (11:00 AM – 4:00 PM)'),
            _buildInfoTile('Active Register', 'Terminal 2 (Floor)'),

            const SizedBox(height: 24),
            const Text(
              'Data & Testing Controls',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),

            // Seed Demo Data button
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: ListTile(
                leading: const Icon(Icons.cloud_upload_outlined, color: AppColors.primary),
                title: const Text('Seed Tables & Menu to Cloud'),
                subtitle: const Text('Populates default wireframe dishes and tables into Firestore'),
                trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                onTap: () async {
                  final db = ref.read(firestoreProvider);
                  await SampleData.seedFirestoreIfEmpty(db);
                  // Also force populate if requested
                  for (final t in SampleData.defaultTables) {
                    await db.collection('tables').doc(t.id).set(t.toMap(), SetOptions(merge: true));
                  }
                  for (final m in SampleData.defaultMenuItems) {
                    await db.collection('menu').doc(m.id).set(m.toMap(), SetOptions(merge: true));
                  }
                  for (final c in SampleData.defaultCategories) {
                    await db.collection('menuCategories').doc(c.id).set(c.toMap(), SetOptions(merge: true));
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Wireframe Tables & Menu synchronized to Firestore!'),
                        backgroundColor: AppColors.available,
                      ),
                    );
                  }
                },
              ),
            ),
            const SizedBox(height: 32),

            // Sign out
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: const Text('End Shift & Sign Out', style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => ref.read(authControllerProvider.notifier).signOut(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
        ],
      ),
    );
  }
}
