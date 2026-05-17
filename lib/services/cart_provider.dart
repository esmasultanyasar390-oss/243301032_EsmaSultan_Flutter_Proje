import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import 'firestore_service.dart';
import 'auth_service.dart';

class CartItem {
  final ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get total => product.wholesalePrice * quantity;
}

class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => Map.unmodifiable(_items);
  int get itemCount => _items.length;
  double get totalPrice => _items.values.fold(0, (s, i) => s + i.total);
  int get totalQuantity => _items.values.fold(0, (s, i) => s + i.quantity);

  void addItem(ProductModel product) {
    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity++;
    } else {
      _items[product.id] = CartItem(product: product);
    }
    notifyListeners();
  }

  void decreaseItem(String productId) {
    if (_items.containsKey(productId)) {
      if (_items[productId]!.quantity > 1) {
        _items[productId]!.quantity--;
      } else {
        _items.remove(productId);
      }
      notifyListeners();
    }
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  Future<bool> placeOrder() async {
    if (_items.isEmpty || AuthService.currentUser == null) return false;
    final order = OrderModel(
      id: '',
      userId: AuthService.currentUser!.uid,
      items: _items.values
          .map((ci) => OrderItem(
                productId: ci.product.id,
                productName: ci.product.name,
                quantity: ci.quantity,
                unitPrice: ci.product.wholesalePrice,
              ))
          .toList(),
      totalAmount: totalPrice,
      status: 'beklemede',
      createdAt: DateTime.now(),
    );
    await FirestoreService.createOrder(order);
    clear();
    return true;
  }
}
