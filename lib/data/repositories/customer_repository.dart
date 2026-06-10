import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/audit_service.dart';
import '../models/customer_entity.dart';

class CustomerRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService;

  CustomerRepository(this._auditService);

  Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
    final sanitized = Map<String, dynamic>.from(data);
    final doubleFields = ['amount', 'totalAmount', 'debtBalance', 'buyPrice', 'sellPrice', 'unitPrice', 'stockQuantity', 'quantity', 'discount', 'totalReturnedAmount', 'returnedQuantity', 'totalRefund', 'returnedQty', 'actualDeduction', 'debtBefore', 'debtAfter'];
    final intFields = ['orderNumber'];
    final dateFields = ['createdAt', 'updatedAt', 'date', 'timestamp', 'orderDate', 'paymentDate'];

    sanitized.forEach((key, value) {
      if (value is Timestamp) {
        sanitized[key] = value.toDate().toIso8601String();
      } else if (value is int) {
        if (dateFields.contains(key)) {
          sanitized[key] = DateTime.fromMillisecondsSinceEpoch(value).toIso8601String();
        } else if (doubleFields.contains(key)) {
          sanitized[key] = value.toDouble();
        } else if (!intFields.contains(key)) {
          sanitized[key] = value.toString();
        }
      } else if (value is double) {
        if (intFields.contains(key)) {
          sanitized[key] = value.toInt();
        } else if (!doubleFields.contains(key)) {
           sanitized[key] = value.toString();
        }
      } else if (value is String && dateFields.contains(key)) {
        final parsedInt = int.tryParse(value);
        if (parsedInt != null) {
          sanitized[key] = DateTime.fromMillisecondsSinceEpoch(parsedInt).toIso8601String();
        }
      }
    });
    return sanitized;
  }

  Stream<List<CustomerEntity>> watchCustomers() {
    return _firestore.collection('customers').snapshots().map((snapshot) =>
        snapshot.docs
            .map((doc) => CustomerEntity.fromJson(_sanitizeData({'id': doc.id, ...doc.data()})))
            .where((c) => c.id != 'walk-in-customer-id' && c.id != 'walk-in')
            .toList());
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
      details: 'Registered new client: ${customer.businessName}',
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
      details: 'Updated profile details for client: ${customer.businessName}',
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
    return snapshot.docs
        .map((doc) => CustomerEntity.fromJson(_sanitizeData({'id': doc.id, ...doc.data()})))
        .where((c) => c.id != 'walk-in-customer-id' && c.id != 'walk-in')
        .toList();
  }

  Future<CustomerEntity?> getCustomerById(String id) async {
    final doc = await _firestore.collection('customers').doc(id).get();
    if (!doc.exists) return null;
    return CustomerEntity.fromJson(_sanitizeData({'id': doc.id, ...doc.data()!}));
  }
}
