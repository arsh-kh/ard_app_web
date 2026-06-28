import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/customer_entity.dart';
import '../../data/models/product_entity.dart';
import 'package:uuid/uuid.dart';

class DatabaseSeeder {
  static final _firestore = FirebaseFirestore.instance;
  static const _uuid = Uuid();
  static final _random = Random();

  static const List<String> _kurdishNames = [
    'Ahmed Ali',
    'Sarmad Hassan',
    'Karwan Omer',
    'Zana Jamal',
    'Rabar Qadir',
    'Shwan Kareem',
    'Bakhtyar Namiq',
    'Aram Azad',
    'Diyar Fatah',
    'Goran Othman',
  ];

  static const List<String> _flourBrands = [
    'Zer Flour (50kg)',
    'Altunsa Flour (25kg)',
    'Cihan Flour (50kg)',
    'Aland Flour (25kg)',
    'Kurdistan Flour (50kg)',
    'Nergiz Flour (25kg)',
  ];

  static Future<void> seedRealisticData(String businessId) async {
    final batch = _firestore.batch();

    // 1. Generate 20 Products
    final productIds = <String>[];
    for (int i = 0; i < 6; i++) {
      final pid = _uuid.v4();
      productIds.add(pid);
      final product = ProductEntity(
        id: pid,
        businessId: businessId,
        name: _flourBrands[i],
        sellPrice:
            25000 + (_random.nextInt(15) * 1000).toDouble(), // 25k to 40k
        buyPrice: 20000 + (_random.nextInt(10) * 1000).toDouble(),
        stockQuantity: (100 + _random.nextInt(400)).toDouble(),
        unitType: 'bag',
        categoryId: 'flour',
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        updatedAt: DateTime.now(),
      );
      batch.set(_firestore.collection('products').doc(pid), product.toJson());
    }

    // 2. Generate 10 Customers with realistic debt
    for (int i = 0; i < 10; i++) {
      final cid = _uuid.v4();
      final hasDebt = _random.nextBool();
      final debt = hasDebt ? (_random.nextInt(500) * 1000).toDouble() : 0.0;

      final customer = CustomerEntity(
        id: cid,
        businessId: businessId,
        businessName: _kurdishNames[i],
        phone: '0750${1000000 + _random.nextInt(8999999)}',
        address: 'Erbil, Kurdistan',
        debtBalance: debt,
        createdAt: DateTime.now().subtract(
          Duration(days: _random.nextInt(100)),
        ),
        updatedAt: DateTime.now(),
      );
      batch.set(_firestore.collection('customers').doc(cid), customer.toJson());
    }

    await batch.commit();
  }
}
