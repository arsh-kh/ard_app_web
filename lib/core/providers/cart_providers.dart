import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/product_entity.dart';
import '../../data/models/customer_entity.dart';

class CartItem {
  final ProductEntity product;
  final double quantity;
  final double customPrice;

  CartItem({required this.product, required this.quantity, required this.customPrice});

  double get totalPrice => customPrice * quantity;
}

class CartNotifier extends StateNotifier<List<CartItem>> {
  CartNotifier() : super([]);

  void addProduct(ProductEntity product, double quantity) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      final updated = List<CartItem>.from(state);
      final newQty = updated[existingIndex].quantity + quantity;
      if (newQty <= 0) {
        removeProduct(product.id);
      } else {
        updated[existingIndex] = CartItem(
          product: product, 
          quantity: newQty,
          customPrice: updated[existingIndex].customPrice,
        );
        state = updated;
      }
    } else if (quantity > 0) {
      state = [...state, CartItem(product: product, quantity: quantity, customPrice: product.sellPrice)];
    }
  }

  void updateProductQuantity(ProductEntity product, double quantity) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      if (quantity <= 0) {
        removeProduct(product.id);
      } else {
        final updated = List<CartItem>.from(state);
        updated[existingIndex] = CartItem(product: product, quantity: quantity, customPrice: updated[existingIndex].customPrice);
        state = updated;
      }
    } else if (quantity > 0) {
      state = [...state, CartItem(product: product, quantity: quantity, customPrice: product.sellPrice)];
    }
  }

  void updateProductPrice(ProductEntity product, double price) {
    final existingIndex = state.indexWhere((item) => item.product.id == product.id);
    if (existingIndex >= 0) {
      final updated = List<CartItem>.from(state);
      updated[existingIndex] = CartItem(product: product, quantity: updated[existingIndex].quantity, customPrice: price);
      state = updated;
    }
  }

  void removeProduct(String productId) {
    state = state.where((item) => item.product.id != productId).toList();
  }

  void clearCart() {
    state = [];
  }

  double get totalCartPrice {
    return state.fold(0.0, (total, item) => total + item.totalPrice);
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, List<CartItem>>((ref) {
  return CartNotifier();
});

