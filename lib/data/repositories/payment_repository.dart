import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/services/audit_service.dart';
import '../models/payment_entity.dart';
import 'package:uuid/uuid.dart';
class PaymentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService;

  PaymentRepository(this._auditService);

  Stream<List<PaymentEntity>> watchPaymentsByCustomer(String customerId) {
    return _firestore
        .collection('payments')
        .where('customerId', isEqualTo: customerId)
        .orderBy('paymentDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => PaymentEntity.fromJson({'id': doc.id, ...doc.data()}))
            .toList());
  }

  Future<List<PaymentEntity>> getPaymentsByCustomer(String customerId) async {
    final snapshot = await _firestore
        .collection('payments')
        .where('customerId', isEqualTo: customerId)
        .orderBy('paymentDate', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => PaymentEntity.fromJson({'id': doc.id, ...doc.data()}))
        .toList();
  }

  Future<void> addPayment(PaymentEntity payment) async {
    final batch = _firestore.batch();

    final paymentRef = _firestore.collection('payments').doc(payment.id);
    batch.set(paymentRef, payment.toJson());

    final custRef = _firestore.collection('customers').doc(payment.customerId);
    batch.update(custRef, {'debtBalance': FieldValue.increment(-payment.amount)});

    await batch.commit();

    await _auditService.logAction(
      action: 'ADDED',
      entityType: 'Payment',
      entityId: payment.id,
      details: 'Added payment of ${payment.amount}',
    );
  }

  Future<void> deletePayment(String paymentId) async {
    final doc = await _firestore.collection('payments').doc(paymentId).get();
    if (!doc.exists) return;
    
    final payment = PaymentEntity.fromJson({'id': doc.id, ...doc.data()!});
    
    final batch = _firestore.batch();
    batch.delete(doc.reference);

    final custRef = _firestore.collection('customers').doc(payment.customerId);
    batch.update(custRef, {'debtBalance': FieldValue.increment(payment.amount)});

    await batch.commit();

    await _auditService.logAction(
      action: 'DELETED',
      entityType: 'Payment',
      entityId: paymentId,
      details: 'Deleted payment of ${payment.amount}',
    );
  }
  Stream<List<PaymentEntity>> watchAllPayments() {
    return _firestore.collection('payments').orderBy('paymentDate', descending: true).snapshots().map((snapshot) =>
        snapshot.docs.map((doc) => PaymentEntity.fromJson({'id': doc.id, ...doc.data()})).toList());
  }

  Future<List<PaymentEntity>> getAllPayments() async {
    final snapshot = await _firestore.collection('payments').orderBy('paymentDate', descending: true).get();
    return snapshot.docs.map((doc) => PaymentEntity.fromJson({'id': doc.id, ...doc.data()})).toList();
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
