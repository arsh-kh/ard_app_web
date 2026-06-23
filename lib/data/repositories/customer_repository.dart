import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/audit_service.dart';
import '../models/customer_entity.dart';
import '../../core/utils/data_sanitizer.dart';

class CustomerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService;
  final String businessId;

  CustomerRepository(this._auditService, this.businessId);

  Stream<List<CustomerEntity>> watchCustomers() {
    return _firestore
        .collection('customers')
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map(
            (doc) => CustomerEntity.fromJson(
              DataSanitizer.sanitize({'id': doc.id, ...doc.data()}),
            ),
          )
          .where((c) => !c.id.startsWith('walk-in-'))
          .toList();
      list.sort((a, b) {
        final aDate = a.updatedAt ?? a.createdAt ?? DateTime(2000);
        final bDate = b.updatedAt ?? b.createdAt ?? DateTime(2000);
        return bDate.compareTo(aDate);
      });
      return list;
    });
  }

  Future<void> addCustomer(CustomerEntity customer) async {
    await _firestore.collection('customers').doc(customer.id).set({
      ...customer.toJson(),
      'businessId': businessId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _auditService.logAction(
      action: 'ADDED',
      entityType: 'Customer',
      entityId: customer.id,
      details: 'Registered new client: ${customer.businessName}',
      metadata: {
        'customerName': customer.businessName,
        'initialDebt': customer.debtBalance,
        'phone': customer.phone,
      },
    );
  }

  Future<void> updateCustomer(CustomerEntity customer) async {
    final Map<String, dynamic> data = customer.toJson();
    if (customer.imageUrl == null) {
      data['imageUrl'] = FieldValue.delete();
    }
    // ensure businessId is retained
    data['businessId'] = businessId;

    final oldDoc = await _firestore
        .collection('customers')
        .doc(customer.id)
        .get();
    final Map<String, dynamic> changes = {};
    if (oldDoc.exists && oldDoc.data() != null) {
      final oldData = oldDoc.data()!;
      if (oldData['businessName'] != customer.businessName) {
        changes['businessName'] = {
          'old': oldData['businessName'],
          'new': customer.businessName,
        };
      }
      if (oldData['phone'] != customer.phone) {
        changes['phone'] = {'old': oldData['phone'], 'new': customer.phone};
      }
      if (oldData['debtBalance'] != customer.debtBalance) {
        changes['debtBalance'] = {
          'old': oldData['debtBalance'],
          'new': customer.debtBalance,
        };
      }
      if (oldData['address'] != customer.address) {
        changes['address'] = {
          'old': oldData['address'],
          'new': customer.address,
        };
      }
    }

    await _firestore.collection('customers').doc(customer.id).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _auditService.logAction(
      action: 'UPDATED',
      entityType: 'Customer',
      entityId: customer.id,
      details: 'Updated profile details for client: ${customer.businessName}',
      metadata: {
        'customerName': customer.businessName,
        'debtBalance': customer.debtBalance,
        'phone': customer.phone,
        if (changes.isNotEmpty) 'changes': changes,
      },
    );
  }

  Future<void> deleteCustomer(String id) async {
    final doc = await _firestore.collection('customers').doc(id).get();
    final name = doc.data()?['businessName'] ?? id;

    await _firestore.collection('customers').doc(id).delete();
    await _auditService.logAction(
      action: 'DELETED',
      entityType: 'Customer',
      entityId: id,
      details: 'Deleted client profile: $name',
      metadata: {'customerName': name, 'customerId': id},
    );
  }

  Future<void> ensureWalkInCustomerExists() async {
    final walkInId = 'walk-in-$businessId';
    final doc = await _firestore.collection('customers').doc(walkInId).get();
    if (!doc.exists) {
      await _firestore.collection('customers').doc(walkInId).set({
        'id': walkInId,
        'businessId': businessId,
        'businessName': 'Walk-in Customer',
        'debtBalance': 0.0,
      });
    }
  }

  Stream<List<CustomerEntity>> watchAllCustomers() {
    return watchCustomers();
  }

  Future<List<CustomerEntity>> getAllCustomers() async {
    final snapshot = await _firestore
        .collection('customers')
        .where('businessId', isEqualTo: businessId)
        .get();
    final list = snapshot.docs
        .map(
          (doc) => CustomerEntity.fromJson(
            DataSanitizer.sanitize({'id': doc.id, ...doc.data()}),
          ),
        )
        .where((c) => !c.id.startsWith('walk-in-'))
        .toList();
    list.sort((a, b) {
      final aDate = a.updatedAt ?? a.createdAt ?? DateTime(2000);
      final bDate = b.updatedAt ?? b.createdAt ?? DateTime(2000);
      return bDate.compareTo(aDate);
    });
    return list;
  }

  Future<CustomerEntity?> getCustomerById(String id) async {
    final doc = await _firestore.collection('customers').doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data()!;
    if (data['businessId'] != businessId) return null; // Security check
    return CustomerEntity.fromJson(
      DataSanitizer.sanitize({'id': doc.id, ...data}),
    );
  }
}
