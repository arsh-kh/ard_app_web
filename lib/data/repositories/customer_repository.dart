import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/audit_service.dart';
import '../models/customer_entity.dart';
import 'package:uuid/uuid.dart';

class CustomerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService;

  CustomerRepository(this._auditService);

  Stream<List<CustomerEntity>> watchCustomers() {
    return _firestore.collection('customers').snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => CustomerEntity.fromJson({'id': doc.id, ...doc.data()})).toList());
  }

  Future<void> addCustomer(CustomerEntity customer) async {
    await _firestore.collection('customers').doc(customer.id).set({
      ...customer.toJson(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    await _auditService.logAction(
      action: 'ADDED',
      entityType: 'Customer',
      entityId: customer.id,
      details: 'Added customer ${customer.businessName}',
    );
  }

  Future<void> updateCustomer(CustomerEntity customer) async {
    await _firestore.collection('customers').doc(customer.id).update({
      ...customer.toJson(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await _auditService.logAction(
      action: 'UPDATED',
      entityType: 'Customer',
      entityId: customer.id,
      details: 'Updated customer ${customer.businessName}',
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
      details: 'Deleted customer $name',
    );
  }

  Future<void> ensureWalkInCustomerExists() async {
    final walkInId = 'walk-in-customer-id';
    final doc = await _firestore.collection('customers').doc(walkInId).get();
    if (!doc.exists) {
      await _firestore.collection('customers').doc(walkInId).set({
        'id': walkInId,
        'businessName': 'Walk-in Customer',
        'debtBalance': 0.0,
      });
    }
  }
  Stream<List<CustomerEntity>> watchAllCustomers() {
    return watchCustomers();
  }

  Future<List<CustomerEntity>> getAllCustomers() async {
    final snapshot = await _firestore.collection('customers').get();
    return snapshot.docs.map((doc) => CustomerEntity.fromJson({'id': doc.id, ...doc.data()})).toList();
  }

  Future<CustomerEntity?> getCustomerById(String id) async {
    final doc = await _firestore.collection('customers').doc(id).get();
    if (!doc.exists) return null;
    return CustomerEntity.fromJson({'id': doc.id, ...doc.data()!});
  }
}
