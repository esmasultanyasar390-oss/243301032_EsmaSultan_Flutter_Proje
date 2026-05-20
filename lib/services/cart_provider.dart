import 'package:flutter/foundation.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import 'firestore_service.dart';
import 'auth_service.dart';

class CartItem {
  ProductModel product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});

  double get unitPrice => product.wholesalePrice;
  double get total => unitPrice * quantity;
}

class CartProvider extends ChangeNotifier {
  static CartProvider? _instance;

  static void attach(CartProvider provider) => _instance = provider;

  static void bindToCurrentUser() {
    final uid = AuthService.currentUser?.uid;
    final role = AuthService.currentUser?.role;
    if (role == 'admin') {
      _instance?._resetForUser(null);
      return;
    }
    _instance?._resetForUser(uid);
  }

  static void clearOnLogout() => _instance?._resetForUser(null);

  final Map<String, Map<String, CartItem>> _cartsByUser = {};
  String? _ownerId;
  final Map<String, CartItem> _items = {};

  int _stockRevision = 0;
  int _ordersRevision = 0;

  Map<String, CartItem> get items => Map.unmodifiable(_items);
  int get itemCount => _items.length;
  double get totalPrice => _items.values.fold(0, (s, i) => s + i.total);
  int get totalQuantity => _items.values.fold(0, (s, i) => s + i.quantity);
  int get stockRevision => _stockRevision;
  int get ordersRevision => _ordersRevision;

  void _resetForUser(String? userId) {
    if (_ownerId != null) {
      _cartsByUser[_ownerId!] = Map.from(_items);
    }
    _ownerId = userId;
    _items.clear();
    if (userId != null && _cartsByUser.containsKey(userId)) {
      _items.addAll(_cartsByUser[userId]!);
    }
    notifyListeners();
  }

  void _bumpCatalog() {
    _stockRevision++;
    notifyListeners();
  }

  void _bumpOrders() {
    _ordersRevision++;
    notifyListeners();
  }

  Future<bool> addItem(ProductModel product, {int quantity = 1}) async {
    if (_ownerId == null || AuthService.isAdmin) return false;
    if (quantity < 1) return false;

    final available = FirestoreService.getStock(product.id);
    if (available < 1) return false;

    final qty = quantity > available ? available : quantity;
    final ok = await FirestoreService.decreaseStock(product.id, qty);
    if (!ok) return false;

    final user = AuthService.currentUser!;
    final updated = FirestoreService.productForViewer(
      FirestoreService.getProductById(product.id) ?? product,
      userId: user.uid,
      role: user.role,
      userCustomPrices: user.customPrices,
    ).copyWith(stock: available - qty);

    if (_items.containsKey(product.id)) {
      _items[product.id]!.quantity += qty;
      _items[product.id]!.product = updated;
    } else {
      _items[product.id] = CartItem(product: updated, quantity: qty);
    }
    _cartsByUser[_ownerId!] = Map.from(_items);
    _bumpCatalog();
    return true;
  }

  Future<void> decreaseItem(String productId) async {
    if (!_items.containsKey(productId)) return;

    if (_items[productId]!.quantity > 1) {
      _items[productId]!.quantity--;
      await FirestoreService.increaseStock(productId, 1);
      final user = AuthService.currentUser;
      if (user != null) {
        final base = FirestoreService.getProductById(productId);
        if (base != null) {
          _items[productId]!.product = FirestoreService.productForViewer(
            base,
            userId: user.uid,
            role: user.role,
            userCustomPrices: user.customPrices,
          );
        }
      }
    } else {
      await removeItem(productId);
      return;
    }
    if (_ownerId != null) _cartsByUser[_ownerId!] = Map.from(_items);
    _bumpCatalog();
  }

  Future<void> removeItem(String productId) async {
    if (!_items.containsKey(productId)) return;
    final qty = _items[productId]!.quantity;
    _items.remove(productId);
    await FirestoreService.increaseStock(productId, qty);
    if (_ownerId != null) _cartsByUser[_ownerId!] = Map.from(_items);
    _bumpCatalog();
  }

  void clear() {
    _items.clear();
    if (_ownerId != null) _cartsByUser.remove(_ownerId);
    notifyListeners();
  }

  Future<bool> completeCheckout({
    required double paidAmount,
    required String paymentType,
  }) async {
    if (_items.isEmpty || AuthService.currentUser == null) return false;
    if (AuthService.isAdmin) return false;
    if (paidAmount < totalPrice) return false;
    if (!AuthService.canAfford(paidAmount)) return false;

    final uid = AuthService.currentUser!.uid;
    final order = OrderModel(
      id: '',
      userId: uid,
      items: _items.values
          .map(
            (ci) => OrderItem(
              productId: ci.product.id,
              productName: ci.product.name,
              quantity: ci.quantity,
              unitPrice: ci.unitPrice,
            ),
          )
          .toList(),
      totalAmount: totalPrice,
      status: 'beklemede',
      createdAt: DateTime.now(),
    );

    final orderId =
        await FirestoreService.createOrder(order, increaseDebt: false);
    if (orderId.isEmpty) return false;

    await FirestoreService.makePayment(
      userId: uid,
      amount: paidAmount,
      paymentType: paymentType,
      reduceDebt: false,
    );

    AuthService.deductBalance(paidAmount);

    await FirestoreService.addLog(
      userId: uid,
      action: 'Sipariş ödemesi',
      details:
          'Sipariş $orderId, ${paidAmount.toStringAsFixed(2)} ₺, $paymentType',
    );

    clear();
    _bumpCatalog();
    _bumpOrders();
    return true;
  }
}
