import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/audit_service.dart';
import '../models/customer_entity.dart';
import '../../core/utils/data_sanitizer.dart';

class CustomerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService;
  final String businessId;

  CustomerRepository(this._auditService, this.businessId);

  void _checkBusinessId() {
    if (businessId.isEmpty) throw Exception('tenant_isolation_error: No business selected.');
  }

  Stream<List<CustomerEntity>> watchCustomers() {
    if (businessId.isEmpty) return Stream.value([]);
    return _firestore
        .collection('customers')
        .where('businessId', isEqualTo: businessId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map(
                (doc) {
                final data = doc.data() as Map<String, dynamic>? ?? {};
                return CustomerEntity.fromJson(
                  DataSanitizer.sanitize({'id': doc.id, ...data}),
                );
              },
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
    _checkBusinessId();
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

  Future<void> updateCustomerImageUrl(
    String customerId,
    String imageUrl,
  ) async {
    _checkBusinessId();
    final doc = await _firestore.collection('customers').doc(customerId).get();
    if (!doc.exists || (doc.data())?['businessId'] != businessId) {
      throw Exception('Customer not found or unauthorized access.');
    }
    await _firestore.collection('customers').doc(customerId).update({
      'imageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateCustomer(CustomerEntity customer) async {
    _checkBusinessId();
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
        
    if (!oldDoc.exists || (oldDoc.data())?['businessId'] != businessId) {
      throw Exception('Customer not found or unauthorized access.');
    }

    final Map<String, dynamic> changes = {};
    if (oldDoc.exists && oldDoc.data() != null) {
      final oldData = oldDoc.data() ?? {};
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
    _checkBusinessId();

    // Enforce referential integrity: prevent deletion if records exist
    final ordersQuery = await _firestore.collection('orders')
        .where('businessId', isEqualTo: businessId)
        .where('customerId', isEqualTo: id)
        .limit(1).get();
    if (ordersQuery.docs.isNotEmpty) {
      throw Exception('Cannot delete a customer with existing orders.');
    }

    final paymentsQuery = await _firestore.collection('payments')
        .where('businessId', isEqualTo: businessId)
        .where('customerId', isEqualTo: id)
        .limit(1).get();
    if (paymentsQuery.docs.isNotEmpty) {
      throw Exception('Cannot delete a customer with existing payments.');
    }

    final returnsQuery = await _firestore.collection('returns')
        .where('businessId', isEqualTo: businessId)
        .where('customerId', isEqualTo: id)
        .limit(1).get();
    if (returnsQuery.docs.isNotEmpty) {
      throw Exception('Cannot delete a customer with existing returns.');
    }

    final doc = await _firestore.collection('customers').doc(id).get();
    final name = (doc.data())?['businessName'] ?? id;

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
    if (businessId.isEmpty) return;
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
    if (businessId.isEmpty) return [];
    final snapshot = await _firestore
        .collection('customers')
        .where('businessId', isEqualTo: businessId)
        .get();
    final list = snapshot.docs
        .map(
          (doc) {
          final data = doc.data() as Map<String, dynamic>? ?? {};
          return CustomerEntity.fromJson(
            DataSanitizer.sanitize({'id': doc.id, ...data}),
          );
        },
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
    if (businessId.isEmpty) return null;
    final doc = await _firestore.collection('customers').doc(id).get();
    if (!doc.exists) return null;
    final data = doc.data() ?? {};
    if (data['businessId'] != businessId) return null; // Security check
    return CustomerEntity.fromJson(
      DataSanitizer.sanitize({'id': doc.id, ...data}),
    );
  }
}
