import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/table_model.dart';

/// State representation of an active dine-in customer session.
class CustomerSessionState {
  final String? tableId;
  final String? tableNumber;
  final int guestCount;
  final String? activeOrderId;
  final TableModel? tableModel;
  final bool isLoading;
  final String? errorMessage;

  const CustomerSessionState({
    this.tableId,
    this.tableNumber,
    this.guestCount = 2,
    this.activeOrderId,
    this.tableModel,
    this.isLoading = false,
    this.errorMessage,
  });

  CustomerSessionState copyWith({
    String? tableId,
    String? tableNumber,
    int? guestCount,
    String? activeOrderId,
    TableModel? tableModel,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CustomerSessionState(
      tableId: tableId ?? this.tableId,
      tableNumber: tableNumber ?? this.tableNumber,
      guestCount: guestCount ?? this.guestCount,
      activeOrderId: activeOrderId ?? this.activeOrderId,
      tableModel: tableModel ?? this.tableModel,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Normalizes table route parameters: e.g. "t04", "t-04", "T-04" -> "T04".
String normalizeTableId(String raw) {
  var clean = raw.trim().toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
  if (clean.startsWith('TABLE')) clean = clean.substring('TABLE'.length);
  final tableMatch = RegExp(r'^T+(\d+)$').firstMatch(clean);
  if (tableMatch != null) {
    return 'T${tableMatch.group(1)!.padLeft(2, '0')}';
  }
  if (RegExp(r'^\d+$').hasMatch(clean)) {
    return 'T${clean.padLeft(2, '0')}';
  }
  return clean;
}

String formatTableName(String raw) {
  final normalized = normalizeTableId(raw);
  final number = normalized.startsWith('T')
      ? normalized.substring(1)
      : normalized;
  return 'Table $number';
}

class CustomerSessionNotifier extends Notifier<CustomerSessionState> {
  @override
  CustomerSessionState build() => const CustomerSessionState();

  void setTable({
    required String tableId,
    required String tableNumber,
    TableModel? table,
  }) {
    state = CustomerSessionState(
      tableId: tableId,
      tableNumber: normalizeTableId(tableNumber),
      tableModel: table,
      activeOrderId: table?.currentOrderId,
      guestCount: state.guestCount,
    );
  }

  void setGuestCount(int count) {
    final maxGuests = (state.tableModel?.capacity ?? 10) + 2;
    if (count < 1 || count > (maxGuests < 12 ? 12 : maxGuests)) return;
    state = state.copyWith(guestCount: count);
  }

  void setActiveOrderId(String orderId) {
    state = state.copyWith(activeOrderId: orderId);
  }

  void clearSession() {
    state = const CustomerSessionState();
  }
}

final customerSessionProvider =
    NotifierProvider<CustomerSessionNotifier, CustomerSessionState>(
      CustomerSessionNotifier.new,
    );
