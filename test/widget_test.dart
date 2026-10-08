import 'package:flutter_test/flutter_test.dart';
import 'package:dineflow/models/user_model.dart';
import 'package:dineflow/models/table_model.dart';

void main() {
  group('Phase 1 Foundation Models Unit Tests', () {
    test('UserModel parse and serialization', () {
      final user = UserModel(
        uid: 'test_uid',
        displayName: 'Adrian Ponce',
        email: 'admin@dineflow.com',
        role: UserRole.admin,
      );

      expect(user.uid, 'test_uid');
      expect(user.role, UserRole.admin);
      expect(user.role.displayName, 'Administrator');

      final map = user.toMap();
      expect(map['role'], 'admin');
      expect(map['displayName'], 'Adrian Ponce');
    });

    test('TableModel status helper and label', () {
      const table = TableModel(
        id: 'T04',
        tableNumber: 'T04',
        capacity: 4,
        status: TableStatus.occupied,
      );

      expect(table.capacity, 4);
      expect(table.status.label, 'Occupied');
    });
  });
}
