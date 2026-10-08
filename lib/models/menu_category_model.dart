import 'package:cloud_firestore/cloud_firestore.dart';

class MenuCategoryModel {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final int sortOrder;
  final bool isActive;

  const MenuCategoryModel({
    required this.id,
    required this.name,
    this.description = '',
    this.imageUrl = '',
    this.sortOrder = 0,
    this.isActive = true,
  });

  factory MenuCategoryModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return MenuCategoryModel.fromMap(doc.id, data);
  }

  factory MenuCategoryModel.fromMap(String id, Map<String, dynamic> data) {
    return MenuCategoryModel(
      id: id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String? ?? '',
      imageUrl: data['imageUrl'] as String? ?? '',
      sortOrder: (data['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }
}
