import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/utils/data_sanitizer.dart';
import '../../core/services/audit_service.dart';
import '../models/payment_entity.dart';
import 'package:uuid/uuid.dart';

class PaymentRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuditService _auditService;
  final String businessId;

  PaymentRepository(this._auditService, this.businessId);

  Map<String, dynamic> _sanitizeData(Map<String, dynamic> data) {
    return DataSanitizer.sanitize(data);
  }

  Stream<List<PaymentEntity>> watchPaymentsByCustomer(String customerId) {
    return _firestore
        .collection('payments')
        .where('businessId', isEqualTo: businessId)
        .where('customerId', isEqualTo: customerId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map(
                (doc) => PaymentEntity.fromJson(
                  _sanitizeData({'id': doc.id, ...doc.data()}),
                ),
              )
              .toList();
          list.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
          return list;
        });
  }

  Future<List<PaymentEntity>> getPaymentsByCustomer(String customerId) async {
    final snapshot = await _firestore
        .collection('payments')
        .where('businessId', isEqualTo: businessId)
        .where('customerId', isEqualTo: customerId)
        .get();
    final list = snapshot.docs
        .map(
          (doc) => PaymentEntity.fromJson(
            _sanitizeData({'id': doc.id, ...doc.data()}),
          ),
        )
        .toList();
    list.sort((a, b) => b.paymentDate.compareTo(a.paymentDate));
    return list;
  }

  Future<void> addPayment(PaymentEntity payment) async {
    final batch = _firestore.batch();

    final paymentRef = _firestore.collection('payments').doc(payment.id);
    final finalPayment = payment.copyWith(businessId: businessId);
    batch.set(paymentRef, finalPayment.toJson());

    if (!finalPayment.customerId.startsWith('walk-in-')) {
      final custRef = _firestore
          .collection('customers')
          .doc(finalPayment.customerId);
      final custDoc = await custRef.get();
      if (custDoc.exists) {
        batch.update(custRef, {
          'debtBalance': FieldValue.increment(-finalPayment.amount),
        });
      }
    }

    await batch.commit();

    String customerName = 'Walk-In';
    if (!finalPayment.customerId.startsWith('walk-in-')) {
      final custDoc = await _firestore
          .collection('customers')
          .doc(finalPayment.customerId)
          .get();
      if (custDoc.exists) {
        customerName = custDoc.data()?['businessName'] ?? 'Unknown Client';
      }
    }

    await _auditService.logAction(
      action: 'COLLECTED_DEBT',
      entityType: 'Payment',
      entityId: finalPayment.id,
      details: 'Collected payment of ${finalPayment.amount} IQD from $customerName',
      metadata: {
        'amount': finalPayment.amount,
        'customerId': finalPayment.customerId,
        'customerName': customerName,
      },
    );
  }

  Future<void> deletePayment(String paymentId) async {
    final doc = await _firestore.collection('payments').doc(paymentId).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    if (data['businessId'] != businessId) return;

    final payment = PaymentEntity.fromJson(
      _sanitizeData({'id': doc.id, ...data}),
    );

    final batch = _firestore.batch();
    batch.delete(doc.reference);

    if (!payment.customerId.startsWith('walk-in-')) {
      final custRef = _firestore
          .collection('customers')
          .doc(payment.customerId);
      final custDoc = await custRef.get();
      if (custDoc.exists) {
        batch.update(custRef, {
          'debtBalance': FieldValue.increment(payment.amount),
        });
      }
    }

    await batch.commit();

    String customerName = 'Walk-In';
    if (!payment.customerId.startsWith('walk-in-')) {
      final custDoc = await _firestore
          .collection('customers')
          .doc(payment.customerId)
          .get();
      if (custDoc.exists) {
        customerName = custDoc.data()?['businessName'] ?? 'Unknown Client';
      }
    }

    await _auditService.logAction(
      action: 'DELETED',
      entityType: 'Payment',
      entityId: paymentId,
      details:
          'Deleted payment of ${payment.amount} IQD from $customerName. Debt balance reverted.',
      metadata: {
        'amount': payment.amount,
        'customerId': payment.customerId,
        'customerName': customerName,
        'revertedDebt': payment.amount,
      },
    );
  }

  Stream<List<PaymentEntity>> watchAllPayments() {
    return _firestore
        .collection('payments')
        .where('businessId', isEqualTo: businessId)
        .orderBy('paymentDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => PaymentEntity.fromJson(
                  _sanitizeData({'id': doc.id, ...doc.data()}),
                ),
              )
              .toList(),
        );
  }

  Stream<List<PaymentEntity>> watchPaymentsByDateRange(DateTime start, DateTime end) {
    return _firestore
        .collection('payments')
        .where('businessId', isEqualTo: businessId)
        .where('paymentDate', isGreaterThanOrEqualTo: start)
        .where('paymentDate', isLessThanOrEqualTo: end)
        .orderBy('paymentDate', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map(
                (doc) => PaymentEntity.fromJson(
                  _sanitizeData({'id': doc.id, ...doc.data()}),
                ),
              )
              .toList(),
        );
  }

  Future<List<PaymentEntity>> getPaymentsByDateRange(DateTime start, DateTime end) async {
    final snapshot = await _firestore
        .collection('payments')
        .where('businessId', isEqualTo: businessId)
        .where('paymentDate', isGreaterThanOrEqualTo: start)
        .where('paymentDate', isLessThanOrEqualTo: end)
        .orderBy('paymentDate', descending: true)
        .get();
    return snapshot.docs
        .map(
          (doc) => PaymentEntity.fromJson(
            _sanitizeData({'id': doc.id, ...doc.data()}),
          ),
        )
        .toList();
  }

  Future<List<PaymentEntity>> getAllPayments() async {
    final snapshot = await _firestore
        .collection('payments')
        .where('businessId', isEqualTo: businessId)
        .orderBy('paymentDate', descending: true)
        .get();
    return snapshot.docs
        .map(
          (doc) => PaymentEntity.fromJson(
            _sanitizeData({'id': doc.id, ...doc.data()}),
          ),
        )
        .toList();
  }

  Future<void> recordPayment({
    required String customerId,
    required double amount,
  }) async {
    final payment = PaymentEntity(
      id: const Uuid().v4(),
      businessId: businessId,
      customerId: customerId,
      amount: amount,
      paymentDate: DateTime.now(),
    );
    await addPayment(payment);
  }
}
