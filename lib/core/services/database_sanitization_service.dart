import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DatabaseSanitizationService {
  static Future<void> run() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool('db_sanitized_v2') == true) return;

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('🔴 [Sanitization] No user logged in, skipping.');
        return;
      }

      final firestore = FirebaseFirestore.instance;
      final userDoc = await firestore.collection('users').doc(user.uid).get();
      final businessId = userDoc.data()?['businessId'] as String?;
      
      if (businessId == null || businessId.isEmpty) {
         debugPrint('🔴 [Sanitization] No businessId found, skipping.');
         return;
      }

      debugPrint('🟢 [Sanitization] Starting DB Sanitization for business $businessId...');

      // 1. ORDERS & CUSTOMER DEBT
      final ordersSnap = await firestore
          .collection('orders')
          .where('businessId', isEqualTo: businessId)
          .where('hasReturn', isEqualTo: true)
          .get();

      for (final orderDoc in ordersSnap.docs) {
        final orderData = orderDoc.data();
        final orderTotal =
            (orderData['totalAmount'] as num?)?.toDouble() ?? 0.0;
        final currentTotalReturned =
            (orderData['totalReturnedAmount'] as num?)?.toDouble() ?? 0.0;

        final itemsSnap = await firestore
            .collection('order_items')
            .where('businessId', isEqualTo: businessId)
            .where('orderId', isEqualTo: orderDoc.id)
            .get();
            
        double sumOfItems = 0;
        double sumOfReturns = 0;

        for (final itemDoc in itemsSnap.docs) {
          final itemData = itemDoc.data();
          final qty = (itemData['quantity'] as num?)?.toDouble() ?? 0.0;
          final retQty =
              (itemData['returnedQuantity'] as num?)?.toDouble() ?? 0.0;
          final price = (itemData['unitPrice'] as num?)?.toDouble() ?? 0.0;

          sumOfItems += qty * price;
          sumOfReturns += retQty * price;
        }

        final correctionRatio = (sumOfItems > 0 && sumOfItems != orderTotal)
            ? (orderTotal / sumOfItems)
            : 1.0;
        final trueTotalReturned = sumOfReturns * correctionRatio;

        if ((currentTotalReturned - trueTotalReturned).abs() > 0.01) {
          debugPrint(
              '🔴 [Sanitization] Fixing Order ${orderDoc.id}: $currentTotalReturned -> $trueTotalReturned');

          await firestore.collection('orders').doc(orderDoc.id).update({
            'totalReturnedAmount': trueTotalReturned,
          });

          final returnsSnap = await firestore
              .collection('returns')
              .where('businessId', isEqualTo: businessId)
              .where('orderId', isEqualTo: orderDoc.id)
              .get();
              
          for (final returnDoc in returnsSnap.docs) {
            final retData = returnDoc.data();
            final retTotal =
                (retData['totalRefund'] as num?)?.toDouble() ?? 0.0;
            final custId = retData['customerId'] as String?;

            if (retTotal > 0 && custId != null) {
              final scaledRefund = retTotal * correctionRatio;
              if ((retTotal - scaledRefund).abs() > 0.01) {
                final diff = retTotal - scaledRefund; // Amount over-refunded

                debugPrint(
                    '🔴 [Sanitization] Fixing Return ${returnDoc.id}: $retTotal -> $scaledRefund. Diff: $diff');

                final actualDed =
                    (retData['actualDeduction'] as num?)?.toDouble();
                    
                await firestore.collection('returns').doc(returnDoc.id).update({
                  'totalRefund': scaledRefund,
                  if (actualDed != null)
                    'actualDeduction': actualDed * correctionRatio,
                });

                if (!custId.startsWith('walk-in-')) {
                  debugPrint(
                      '🔴 [Sanitization] Fixing Customer $custId debt: +$diff');
                  await firestore.collection('customers').doc(custId).update({
                    'debtBalance': FieldValue.increment(diff),
                  });
                }
              }
            }
          }
        }
      }

      // 2. PURCHASES & SUPPLIER DEBT
      final purchasesSnap = await firestore
          .collection('purchases')
          .where('businessId', isEqualTo: businessId)
          .where('hasReturn', isEqualTo: true)
          .get();

      for (final purchaseDoc in purchasesSnap.docs) {
        final purchaseData = purchaseDoc.data();
        final purchaseTotal =
            (purchaseData['totalAmount'] as num?)?.toDouble() ?? 0.0;
        final currentTotalReturned =
            (purchaseData['totalReturnedAmount'] as num?)?.toDouble() ?? 0.0;

        final itemsSnap = await firestore
            .collection('purchase_items')
            .where('businessId', isEqualTo: businessId)
            .where('purchaseId', isEqualTo: purchaseDoc.id)
            .get();
            
        double sumOfItems = 0;
        double sumOfReturns = 0;

        for (final itemDoc in itemsSnap.docs) {
          final itemData = itemDoc.data();
          final qty = (itemData['quantity'] as num?)?.toDouble() ?? 0.0;
          final retQty =
              (itemData['returnedQuantity'] as num?)?.toDouble() ?? 0.0;
          final price = (itemData['unitPrice'] as num?)?.toDouble() ?? 0.0;

          sumOfItems += qty * price;
          sumOfReturns += retQty * price;
        }

        final correctionRatio =
            (sumOfItems > 0 && sumOfItems != purchaseTotal)
                ? (purchaseTotal / sumOfItems)
                : 1.0;
        final trueTotalReturned = sumOfReturns * correctionRatio;

        if ((currentTotalReturned - trueTotalReturned).abs() > 0.01) {
          debugPrint(
              '🔴 [Sanitization] Fixing Purchase ${purchaseDoc.id}: $currentTotalReturned -> $trueTotalReturned');

          await firestore.collection('purchases').doc(purchaseDoc.id).update({
            'totalReturnedAmount': trueTotalReturned,
          });

          final returnsSnap = await firestore
              .collection('purchase_returns')
              .where('businessId', isEqualTo: businessId)
              .where('purchaseId', isEqualTo: purchaseDoc.id)
              .get();
              
          for (final returnDoc in returnsSnap.docs) {
            final retData = returnDoc.data();
            final retTotal =
                (retData['totalRefund'] as num?)?.toDouble() ?? 0.0;
            final suppId = retData['supplierId'] as String?;

            if (retTotal > 0 && suppId != null) {
              final scaledRefund = retTotal * correctionRatio;
              if ((retTotal - scaledRefund).abs() > 0.01) {
                final diff = retTotal - scaledRefund;

                debugPrint(
                    '🔴 [Sanitization] Fixing Purchase Return ${returnDoc.id}: $retTotal -> $scaledRefund. Diff: $diff');

                final actualDed =
                    (retData['actualDeduction'] as num?)?.toDouble();
                    
                await firestore
                    .collection('purchase_returns')
                    .doc(returnDoc.id)
                    .update({
                  'totalRefund': scaledRefund,
                  if (actualDed != null)
                    'actualDeduction': actualDed * correctionRatio,
                });

                debugPrint(
                    '🔴 [Sanitization] Fixing Supplier $suppId debt: +$diff');
                await firestore.collection('suppliers').doc(suppId).update({
                  'debtBalance': FieldValue.increment(diff),
                });
              }
            }
          }
        }
      }

      await prefs.setBool('db_sanitized_v1', true);
      debugPrint('🟢 [Sanitization] DB Sanitization Complete!');
    } catch (e, stack) {
      debugPrint('🔴 [Sanitization] Failed: $e\n$stack');
    }
  }
}
