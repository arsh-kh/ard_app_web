import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/audit_service.dart';
import '../models/payment_entity.dart';
import 'package:uuid/uuid.dart';
class PaymentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService;

  PaymentRepository(this._auditService);

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

  Stream<List<PaymentEntity>> watchPaymentsByCustomer(String customerId) {
    return _firestore
        .collection('payments')
        .where('customerId', isEqualTo: customerId)
        .orderBy('paymentDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentEntity.fromJson(_sanitizeData({'id': doc.id, ...doc.data()})))
            .toList());
  }

  Future<List<PaymentEntity>> getPaymentsByCustomer(String customerId) async {
    final snapshot = await _firestore
        .collection('payments')
        .where('customerId', isEqualTo: customerId)
        .orderBy('paymentDate', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => PaymentEntity.fromJson(_sanitizeData({'id': doc.id, ...doc.data()})))
        .toList();
  }

  Future<void> addPayment(PaymentEntity payment) async {
    final batch = _firestore.batch();

    final paymentRef = _firestore.collection('payments').doc(payment.id);
    batch.set(paymentRef, payment.toJson());

    if (payment.customerId != 'walk-in' && payment.customerId != 'walk-in-customer-id') {
      final custRef = _firestore.collection('customers').doc(payment.customerId);
      batch.update(custRef, {'debtBalance': FieldValue.increment(-payment.amount)});
    }

    await batch.commit();

    String customerName = 'Walk-In';
    if (payment.customerId != 'walk-in' && payment.customerId != 'walk-in-customer-id') {
      final custDoc = await _firestore.collection('customers').doc(payment.customerId).get();
      if (custDoc.exists) {
        customerName = custDoc.data()?['businessName'] ?? 'Unknown Client';
      }
    }

    await _auditService.logAction(
      action: 'COLLECTED_DEBT',
      entityType: 'Payment',
      entityId: payment.id,
      details: 'Collected payment of ${payment.amount} IQD from $customerName',
    );
  }

  Future<void> deletePayment(String paymentId) async {
    final doc = await _firestore.collection('payments').doc(paymentId).get();
    if (!doc.exists) return;
    
    final payment = PaymentEntity.fromJson(_sanitizeData({'id': doc.id, ...doc.data()!}));
    
    final batch = _firestore.batch();
    batch.delete(doc.reference);

    if (payment.customerId != 'walk-in' && payment.customerId != 'walk-in-customer-id') {
      final custRef = _firestore.collection('customers').doc(payment.customerId);
      batch.update(custRef, {'debtBalance': FieldValue.increment(payment.amount)});
    }

    await batch.commit();

    String customerName = 'Walk-In';
    if (payment.customerId != 'walk-in' && payment.customerId != 'walk-in-customer-id') {
      final custDoc = await _firestore.collection('customers').doc(payment.customerId).get();
      if (custDoc.exists) {
        customerName = custDoc.data()?['businessName'] ?? 'Unknown Client';
      }
    }

    await _auditService.logAction(
      action: 'DELETED',
      entityType: 'Payment',
      entityId: paymentId,
      details: 'Deleted payment of ${payment.amount} IQD from $customerName. Debt balance reverted.',
    );
  }
  Stream<List<PaymentEntity>> watchAllPayments() {
    return _firestore.collection('payments').orderBy('paymentDate', descending: true).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => PaymentEntity.fromJson(_sanitizeData({'id': doc.id, ...doc.data()}))).toList());
  }

  Future<List<PaymentEntity>> getAllPayments() async {
    final snapshot = await _firestore.collection('payments').orderBy('paymentDate', descending: true).get();
    return snapshot.docs.map((doc) => PaymentEntity.fromJson(_sanitizeData({'id': doc.id, ...doc.data()}))).toList();
  }

  Future<void> recordPayment({required String customerId, required double amount}) async {
    final payment = PaymentEntity(
      id: const Uuid().v4(),
      customerId: customerId,
      amount: amount,
      paymentDate: DateTime.now(),
    );
    await addPayment(payment);
  }
}
