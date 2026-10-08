import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/settings_model.dart';
import 'firebase_providers.dart';

/// Stream of restaurant settings from settings/general
final restaurantSettingsProvider = StreamProvider<SettingsModel>((ref) {
  final firestore = ref.watch(firestoreProvider);
  return firestore.collection('settings').doc('general').snapshots().map((snapshot) {
    if (!snapshot.exists || snapshot.data() == null) {
      return const SettingsModel();
    }
    return SettingsModel.fromFirestore(snapshot);
  });
});
