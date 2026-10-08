import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/notification_providers.dart';
import '../../services/waiter_request_service.dart';

class WaiterNotificationsSheet extends ConsumerWidget {
  final void Function(String tableNumber)? onSelectTable;

  const WaiterNotificationsSheet({super.key, this.onSelectTable});

  String _formatTimeAgo(DateTime? time) {
    if (time == null) return 'Just now';
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    return '${diff.inHours}h ago';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(waiterNotificationsStreamProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Handle bar
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 12),

            // Header Row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_active, color: AppColors.primary, size: 22),
                      const SizedBox(width: 8),
                      const Text(
                        'Customer Requests',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Consumer(
                        builder: (ctx, ref, _) {
                          final count = ref.watch(unreadWaiterNotificationsCountProvider);
                          if (count == 0) return const SizedBox.shrink();
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '$count new',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () {
                      ref.read(notificationActionsProvider).clearAll();
                    },
                    child: const Text('Clear All', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ),
                ],
              ),
            ),
            const Divider(height: 16),

            // List of notifications
            Expanded(
              child: notificationsAsync.when(
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 56, color: Colors.grey.shade300),
                            const SizedBox(height: 14),
                            const Text(
                              'No Customer Requests',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'When dining guests ask for the bill or call for assistance, they will appear here.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: notifications.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (ctx, index) {
                      final notif = notifications[index];
                      final isBill = notif.type == 'bill_request';
                      final isUnread = notif.status == 'unread';

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isUnread ? (isBill ? const Color(0xFFFFF7ED) : const Color(0xFFF0FDF4)) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isUnread ? (isBill ? const Color(0xFFFDBA74) : const Color(0xFF86EFAC)) : AppColors.border,
                            width: isUnread ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isBill ? const Color(0xFFFFEDD5) : const Color(0xFFDCFCE7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    isBill ? Icons.receipt_long : Icons.room_service_outlined,
                                    size: 18,
                                    color: isBill ? const Color(0xFFEA580C) : const Color(0xFF16A34A),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            'Table ${notif.tableNumber}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15,
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          Text(
                                            _formatTimeAgo(notif.createdAt),
                                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        notif.title,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: isBill ? const Color(0xFFC2410C) : const Color(0xFF15803D),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              notif.message,
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                if (isUnread) ...[
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      visualDensity: VisualDensity.compact,
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                      side: BorderSide(color: Colors.grey.shade300),
                                    ),
                                    onPressed: () {
                                      ref.read(notificationActionsProvider).markAsRead(notif.id);
                                    },
                                    child: const Text('Mark Read', style: TextStyle(fontSize: 12)),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: isBill ? const Color(0xFFEA580C) : AppColors.primary,
                                    foregroundColor: Colors.white,
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                    elevation: 0,
                                  ),
                                  onPressed: () async {
                                    ref.read(notificationActionsProvider).markAsRead(notif.id);
                                    // Send instant alert back to customer device
                                    try {
                                      await ref.read(waiterRequestServiceProvider).notifyCustomer(
                                            tableId: notif.tableId.isNotEmpty ? notif.tableId : notif.tableNumber,
                                            tableNumber: notif.tableNumber,
                                            orderId: notif.orderId,
                                            title: isBill
                                                ? 'Bill on the Way · Table ${notif.tableNumber}'
                                                : 'Waiter Responded · Table ${notif.tableNumber}',
                                            message: isBill
                                                ? 'Your waiter has received your bill request and is bringing it to your table.'
                                                : 'Your waiter has responded and is on the way to assist your table.',
                                          );
                                    } catch (_) {}

                                    if (ctx.mounted) {
                                      Navigator.pop(ctx);
                                    }
                                    if (onSelectTable != null) {
                                      onSelectTable!(notif.tableNumber);
                                    }
                                  },
                                  child: Text(
                                    isBill ? 'Bring Bill to Table' : 'Attend Table',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.textMuted),
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () {
                                    ref.read(notificationActionsProvider).dismiss(notif.id);
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('Error loading notifications: $e')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
