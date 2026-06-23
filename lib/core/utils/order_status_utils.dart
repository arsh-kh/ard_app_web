import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Shared utility for order status colors, icons, and badges.
/// Eliminates duplication across admin_orders_screen and customer_detail_screen.
class OrderStatusUtils {
  OrderStatusUtils._();

  static Color getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.blue;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  static IconData getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.hourglass_top;
      case 'approved':
        return Icons.local_shipping;
      case 'delivered':
        return Icons.done_all;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.receipt_long;
    }
  }

  static Widget buildStatusBadge(String status) {
    final color = getStatusColor(status);

    final bool isArabic = AppConstants.languageCode == 'ar';
    final bool isKurdish = AppConstants.languageCode == 'ku';

    String displayStatus = status.toUpperCase();
    if (isKurdish) {
      if (status == 'pending') {
        displayStatus = 'چاوەڕێکراو';
      } else if (status == 'approved') {
        displayStatus = 'پەسەندکراو';
      } else if (status == 'delivered') {
        displayStatus = 'گەیەنراو';
      } else if (status == 'cancelled') {
        displayStatus = 'هەڵوەشاوە';
      }
    } else if (isArabic) {
      if (status == 'pending') {
        displayStatus = 'قيد الانتظار';
      } else if (status == 'approved') {
        displayStatus = 'موافق عليه';
      } else if (status == 'delivered') {
        displayStatus = 'تم التوصيل';
      } else if (status == 'cancelled') {
        displayStatus = 'ملغى';
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        displayStatus,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
