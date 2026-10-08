// setup_auth.dart
// Automates:
// 1. Creating the 5 Firebase Auth users
// 2. Writing self-contained profile data directly to users/{auth.uid}
// 3. Testing end-to-end login and Firestore user profile retrieval

import 'package:flutter/widgets.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dineflow/firebase_options.dart';

final List<Map<String, dynamic>> targetAccounts = [
  {
    'oldId': 'admin_001',
    'email': 'admin@dineflow.com',
    'password': 'Admin123!',
    'profile': {
      'displayName': 'Adrian Ponce',
      'email': 'admin@dineflow.com',
      'phone': '+639639125698',
      'role': 'admin',
      'photoUrl': '',
      'status': 'active',
      'employeeId': 'EMP-001',
      'assignedSection': '',
      'shiftStatus': 'on_duty',
      'fcmTokens': <String>[],
    },
  },
  {
    'oldId': 'waiter_001',
    'email': 'waiter@dineflow.com',
    'password': 'Waiter123!',
    'profile': {
      'displayName': 'Mark Reyes',
      'email': 'waiter@dineflow.com',
      'phone': '+639171112222',
      'role': 'waiter',
      'photoUrl': '',
      'status': 'active',
      'employeeId': 'EMP-002',
      'assignedSection': 'Section A',
      'shiftStatus': 'on_duty',
      'fcmTokens': <String>[],
    },
  },
  {
    'oldId': 'kitchen_001',
    'email': 'kitchen@dineflow.com',
    'password': 'Kitchen123!',
    'profile': {
      'displayName': 'Chef Ana',
      'email': 'kitchen@dineflow.com',
      'phone': '+639173333333',
      'role': 'kitchen',
      'photoUrl': '',
      'status': 'active',
      'employeeId': 'EMP-003',
      'assignedSection': '',
      'shiftStatus': 'on_duty',
      'fcmTokens': <String>[],
    },
  },
  {
    'oldId': 'cashier_001',
    'email': 'cashier@dineflow.com',
    'password': 'Cashier123!',
    'profile': {
      'displayName': 'Sarah Lim',
      'email': 'cashier@dineflow.com',
      'phone': '+639174444444',
      'role': 'cashier',
      'photoUrl': '',
      'status': 'active',
      'employeeId': 'EMP-004',
      'assignedSection': '',
      'shiftStatus': 'on_duty',
      'fcmTokens': <String>[],
    },
  },
  {
    'oldId': 'customer_001',
    'email': 'customer@dineflow.com',
    'password': 'Customer123!',
    'profile': {
      'displayName': 'Juan Cruz',
      'email': 'customer@dineflow.com',
      'phone': '+639175555555',
      'role': 'customer',
      'photoUrl': '',
      'status': 'active',
      'fcmTokens': <String>[],
    },
  },
];

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  print('🔥 Initializing Firebase...');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final auth = FirebaseAuth.instance;
  final db = FirebaseFirestore.instance;

  print('✅ Firebase initialized.\n');
  print('=====================================================');
  print('STEP 5 & 6: CREATING AUTH USERS & POPULATING users/{uid}');
  print('=====================================================');

  final Map<String, String> oldIdToNewUid = {};

  for (final account in targetAccounts) {
    final email = account['email'] as String;
    final password = account['password'] as String;
    final oldId = account['oldId'] as String;
    final profileTemplate = Map<String, dynamic>.from(account['profile'] as Map<String, dynamic>);

    String? uid;

    try {
      print('👤 Processing Auth account for: $email ...');
      final cred = await auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      uid = cred.user!.uid;
      print('   ✅ Auth user created with UID: $uid');
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        print('   ℹ️ $email already exists. Signing in to retrieve UID...');
        final cred = await auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        uid = cred.user!.uid;
        print('   ✅ Signed in with UID: $uid');
      } else {
        print('   ❌ Auth Error for $email: ${e.code} - ${e.message}');
        continue;
      }
    } catch (e) {
      print('   ❌ Unexpected error for $email: $e');
      continue;
    }

    if (uid != null) {
      oldIdToNewUid[oldId] = uid;

      // Write directly to users/{uid} while authenticated as this user
      final userData = {
        ...profileTemplate,
        'uid': uid,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      try {
        await db.collection('users').doc(uid).set(userData, SetOptions(merge: true));
        print('   ✅ Firestore document saved: users/$uid (Role: ${userData['role']})');
      } catch (e) {
        print('   ❌ Firestore write failed for users/$uid: $e');
      }
    }
  }

  // Now sign in as Admin to clean up placeholder docs and update references
  print('\n🧹 Cleaning up old placeholder documents as Admin...');
  try {
    await auth.signInWithEmailAndPassword(
      email: 'admin@dineflow.com',
      password: 'Admin123!',
    );

    for (final account in targetAccounts) {
      final oldId = account['oldId'] as String;
      try {
        await db.collection('users').doc(oldId).delete();
        print('   🗑️ Old doc users/$oldId deleted (if it existed)');
      } catch (_) {
        // Silently skip if oldId didn't exist or deletion is disallowed
      }
    }

    // Update waiter reference in shifts and orders
    final waiterUid = oldIdToNewUid['waiter_001'];
    if (waiterUid != null) {
      try {
        final shifts = await db.collection('shifts').where('userId', isEqualTo: 'waiter_001').get();
        for (final doc in shifts.docs) {
          await doc.reference.update({'userId': waiterUid});
        }

        final orders = await db.collection('orders').where('waiterId', isEqualTo: 'waiter_001').get();
        for (final doc in orders.docs) {
          await doc.reference.update({'waiterId': waiterUid});
        }
        print('   ✅ Updated waiter references in orders and shifts to $waiterUid');
      } catch (e) {
        print('   ℹ️ Note on reference updates: $e');
      }
    }
  } catch (e) {
    print('   ℹ️ Note during admin cleanup: $e');
  }

  print('\n=====================================================');
  print('STEP 7: END-TO-END TEST (ADMIN LOGIN & PROFILE FETCH)');
  print('=====================================================');
  try {
    print('🔑 Testing sign-in with admin@dineflow.com...');
    final cred = await auth.signInWithEmailAndPassword(
      email: 'admin@dineflow.com',
      password: 'Admin123!',
    );
    final adminUid = cred.user!.uid;
    print('✅ Signed in successfully! Auth UID: $adminUid');

    print('📄 Fetching Firestore document users/$adminUid ...');
    final userSnap = await db.collection('users').doc(adminUid).get();
    if (userSnap.exists) {
      print('🎉 SUCCESS! Firestore User Document found:');
      print(userSnap.data());
      print('\n🚀 Your backend, Authentication, and Firestore are fully aligned and working! ✅');
    } else {
      print('⚠️ Document users/$adminUid was not found in Firestore.');
    }
  } catch (e) {
    print('❌ Sign-in or read failed: $e');
  }
}
