import 'package:cloud_firestore/cloud_firestore.dart';

class SettingsModel {
  final String restaurantName;
  final String tagline;
  final String address;
  final String phone;
  final String currency;
  final String currencySymbol;
  final double taxRate;
  final double serviceChargeRate;
  final String openingTime;
  final String closingTime;

  const SettingsModel({
    this.restaurantName = 'DineFlow Restaurant',
    this.tagline = 'Modern Dining & Flow',
    this.address = '123 Gourmet Ave',
    this.phone = '+63 912 345 6789',
    this.currency = 'PHP',
    this.currencySymbol = '₱',
    this.taxRate = 0.08,
    this.serviceChargeRate = 0.05,
    this.openingTime = '11:00',
    this.closingTime = '22:00',
  });

  factory SettingsModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return SettingsModel(
      restaurantName: data['restaurantName'] as String? ?? 'DineFlow Restaurant',
      tagline: data['tagline'] as String? ?? 'Modern Dining & Flow',
      address: data['address'] as String? ?? '',
      phone: data['phone'] as String? ?? '',
      currency: data['currency'] as String? ?? 'PHP',
      currencySymbol: data['currencySymbol'] as String? ?? '₱',
      taxRate: (data['taxRate'] as num?)?.toDouble() ?? 0.08,
      serviceChargeRate: (data['serviceChargeRate'] as num?)?.toDouble() ?? 0.05,
      openingTime: data['openingTime'] as String? ?? '11:00',
      closingTime: data['closingTime'] as String? ?? '22:00',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'restaurantName': restaurantName,
      'tagline': tagline,
      'address': address,
      'phone': phone,
      'currency': currency,
      'currencySymbol': currencySymbol,
      'taxRate': taxRate,
      'serviceChargeRate': serviceChargeRate,
      'openingTime': openingTime,
      'closingTime': closingTime,
    };
  }
}
