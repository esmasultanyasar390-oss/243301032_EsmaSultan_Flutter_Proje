import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  static bool get _firebaseAvailable => Firebase.apps.isNotEmpty;
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static final Map<String, List<OrderModel>> _localOrdersByUser = {};
  static final Map<String, List<Map<String, dynamic>>> _localPaymentsByUser = {};
  static final Map<String, int> _stockById = {};
  static final Set<String> _usersWithRealOrders = {};
  static final Set<String> _adminUserIds = {'demo_admin_uid'};

  static final List<ProductModel> _seedProducts = const [
    ProductModel(id: 'p1', name: 'Fondöten No:30', brand: "L'Oreal", category: 'Makyaj', wholesalePrice: 45.90, stock: 50),
    ProductModel(id: 'p2', name: 'Volume Maskara', brand: 'Maybelline', category: 'Makyaj', wholesalePrice: 32.50, stock: 100),
    ProductModel(id: 'p3', name: 'Nemlendirici Krem', brand: 'Nivea', category: 'Cilt Bakımı', wholesalePrice: 28.75, stock: 75),
    ProductModel(id: 'p4', name: 'Yüz Tonik 250ml', brand: 'The Body Shop', category: 'Cilt Bakımı', wholesalePrice: 89.00, stock: 30),
    ProductModel(id: 'p5', name: 'Mat Ruj', brand: 'Rimmel', category: 'Makyaj', wholesalePrice: 24.99, stock: 200),
    ProductModel(id: 'p6', name: 'Güneş Kremi SPF50', brand: 'Garnier', category: 'Cilt Bakımı', wholesalePrice: 42.00, stock: 60),
    ProductModel(id: 'p7', name: 'Compact Pudra', brand: 'MAC', category: 'Makyaj', wholesalePrice: 125.00, stock: 25),
    ProductModel(id: 'p8', name: 'Cilt Serumu', brand: 'Clinique', category: 'Cilt Bakımı', wholesalePrice: 210.00, stock: 15),
  ];

  static List<ProductModel> _catalog = [];

  static void _ensureCatalog() {
    if (_catalog.isNotEmpty) return;
    _catalog = _seedProducts.map((p) => p).toList();
    _ensureStockInit();
  }

  static void registerAdminUid(String uid) => _adminUserIds.add(uid);

  static bool isAdminUserId(String userId) =>
      _adminUserIds.contains(userId) ||
      userId.contains('admin');

  static void _ensureStockInit() {
    _ensureCatalog();
    for (final p in _catalog) {
      _stockById.putIfAbsent(p.id, () => p.stock);
    }
  }

  static int getStock(String productId) {
    _ensureStockInit();
    return _stockById[productId] ?? 0;
  }

  static ProductModel? getProductById(String productId) {
    _ensureStockInit();
    final base = _canonicalProduct(productId);
    if (base == null) return null;
    return base.copyWith(stock: getStock(productId));
  }

  /// Stok düşürür. Yeterli stok yoksa false döner.
  static Future<bool> decreaseStock(String productId, int quantity) async {
    if (quantity < 1) return false;
    _ensureStockInit();
    final current = getStock(productId);
    if (quantity > current) return false;

    final newStock = current - quantity;
    _stockById[productId] = newStock;

    if (_firebaseAvailable) {
      try {
        await _db.collection('products').doc(productId).update({
          'stock': newStock,
        });
      } catch (_) {}
    }
    return true;
  }

  /// Sepetten çıkarıldığında stoku geri yükler.
  static Future<void> increaseStock(String productId, int quantity) async {
    if (quantity < 1) return;
    _ensureStockInit();
    final newStock = getStock(productId) + quantity;
    _stockById[productId] = newStock;

    if (_firebaseAvailable) {
      try {
        await _db.collection('products').doc(productId).update({
          'stock': newStock,
        });
      } catch (_) {}
    }
  }

  static List<ProductModel> _filteredDemoProducts({
    String? category,
    String? brand,
  }) {
    _ensureStockInit();
    var list = _catalog
        .map((p) => p.copyWith(stock: getStock(p.id)))
        .toList();
    if (category != null && category.isNotEmpty) {
      list = list.where((p) => p.category == category).toList();
    }
    if (brand != null && brand.isNotEmpty) {
      list = list.where((p) => p.brand == brand).toList();
    }
    return list;
  }

  static List<OrderModel> _demoOrdersForUser(String userId) {
    return _demoOrders
        .map(
          (o) => OrderModel(
            id: o.id,
            userId: userId,
            items: o.items,
            totalAmount: o.totalAmount,
            status: o.status,
            createdAt: o.createdAt,
          ),
        )
        .toList();
  }

  static final List<OrderModel> _demoOrders = [
    OrderModel(
      id: '#1001',
      userId: 'demo_uid',
      items: const [OrderItem(productId: 'p1', productName: 'Fondöten No:30', quantity: 5, unitPrice: 45.90)],
      totalAmount: 229.50,
      status: 'tamamlandi',
      createdAt: DateTime(2024, 3, 15),
    ),
    OrderModel(
      id: '#1002',
      userId: 'demo_uid',
      items: const [OrderItem(productId: 'p7', productName: 'Compact Pudra', quantity: 4, unitPrice: 125.00)],
      totalAmount: 500.00,
      status: 'hazirlaniyor',
      createdAt: DateTime(2024, 3, 22),
    ),
    OrderModel(
      id: '#1003',
      userId: 'demo_uid',
      items: const [OrderItem(productId: 'p8', productName: 'Cilt Serumu', quantity: 2, unitPrice: 210.00)],
      totalAmount: 420.00,
      status: 'beklemede',
      createdAt: DateTime(2024, 3, 28),
    ),
  ];

  static final List<Map<String, dynamic>> _demoPayments = [
    {'date': DateTime(2024, 3, 10), 'amount': 1000.0, 'paymentType': 'Havale'},
    {'date': DateTime(2024, 3, 5), 'amount': 500.0, 'paymentType': 'Kredi Kartı'},
  ];

  static final List<Map<String, dynamic>> _demoLogs = [
    {
      'userId': 'system',
      'action': 'Sistem başlatıldı',
      'timestamp': DateTime(2024, 3, 1),
      'details': 'Katalog ve log kayıtları hazırlandı',
    },
    {
      'userId': 'system',
      'action': 'Ürün kataloğu oluşturuldu',
      'timestamp': DateTime(2024, 3, 1, 1),
      'details': '8 ürün Firestore\'a eklendi',
    },
    {
      'userId': 'demo_uid',
      'action': 'Giriş yapıldı',
      'timestamp': DateTime(2024, 3, 28),
      'details': 'E-posta: demo@kosmetic.com',
    },
    {
      'userId': 'demo_uid',
      'action': 'Sipariş oluşturuldu',
      'timestamp': DateTime(2024, 3, 28),
      'details': 'Sipariş #1003, Tutar: 420 ₺',
    },
    {
      'userId': 'demo_uid',
      'action': 'Ödeme yapıldı',
      'timestamp': DateTime(2024, 3, 10),
      'details': 'Tutar: 1000 ₺, Tür: Havale',
    },
    {
      'userId': 'demo_uid',
      'action': 'Sipariş oluşturuldu',
      'timestamp': DateTime(2024, 3, 22),
      'details': 'Sipariş #1002, Tutar: 500 ₺',
    },
    {
      'userId': 'demo_uid',
      'action': 'Giriş yapıldı',
      'timestamp': DateTime(2024, 3, 15),
      'details': 'E-posta: demo@kosmetic.com',
    },
  ];

  static ProductModel? _canonicalProduct(String id) {
    _ensureCatalog();
    for (final p in _catalog) {
      if (p.id == id) return p;
    }
    return null;
  }

  static double resolveUnitPrice({
    required String userId,
    required String role,
    required ProductModel product,
    Map<String, double>? userCustomPrices,
  }) {
    if (role == 'bayi') return product.wholesalePrice;
    if (role == 'kullanici') {
      final custom = userCustomPrices?[product.id];
      if (custom != null) return custom;
      return (product.wholesalePrice * 1.15);
    }
    return product.wholesalePrice;
  }

  static ProductModel productForViewer(
    ProductModel base, {
    required String userId,
    required String role,
    Map<String, double>? userCustomPrices,
  }) {
    final price = resolveUnitPrice(
      userId: userId,
      role: role,
      product: base,
      userCustomPrices: userCustomPrices,
    );
    return base.copyWith(stock: getStock(base.id), wholesalePrice: price);
  }

  static Future<List<ProductModel>> getProductsForViewer({
    required String userId,
    required String role,
    Map<String, double>? userCustomPrices,
    String? category,
    String? brand,
  }) async {
    final list = await getProducts(category: category, brand: brand);
    return list
        .map(
          (p) => productForViewer(
            p,
            userId: userId,
            role: role,
            userCustomPrices: userCustomPrices,
          ),
        )
        .toList();
  }

  static Future<List<ProductModel>> getAllProductsAdmin() async {
    final list = await getProducts();
    return list;
  }

  static Future<String> addProduct(ProductModel product) async {
    _ensureCatalog();
    final id = 'p${DateTime.now().millisecondsSinceEpoch}';
    final p = ProductModel(
      id: id,
      name: product.name,
      brand: product.brand,
      category: product.category,
      wholesalePrice: product.wholesalePrice,
      stock: product.stock,
      imageUrl: product.imageUrl,
    );
    _catalog.insert(0, p);
    _stockById[id] = p.stock;

    if (_firebaseAvailable) {
      try {
        await _db.collection('products').doc(id).set(p.toMap());
      } catch (_) {}
    }
    await addLog(
      userId: 'system',
      action: 'Ürün eklendi',
      details: '${p.name} (${p.wholesalePrice} ₺)',
    );
    return id;
  }

  static Future<void> updateProduct(ProductModel product) async {
    _ensureCatalog();
    final i = _catalog.indexWhere((p) => p.id == product.id);
    final updated = product.copyWith(stock: getStock(product.id));
    if (i >= 0) {
      _catalog[i] = updated;
    } else {
      _catalog.add(updated);
    }
    _stockById[product.id] = updated.stock;

    if (_firebaseAvailable) {
      try {
        await _db.collection('products').doc(product.id).set(
              updated.toMap(),
              SetOptions(merge: true),
            );
      } catch (_) {}
    }
  }

  static Future<void> deleteProduct(String productId) async {
    _ensureCatalog();
    _catalog.removeWhere((p) => p.id == productId);
    _stockById.remove(productId);

    if (_firebaseAvailable) {
      try {
        await _db.collection('products').doc(productId).delete();
      } catch (_) {}
    }
    await addLog(
      userId: 'system',
      action: 'Ürün silindi',
      details: 'Ürün ID: $productId',
    );
  }

  static Future<void> setUserCustomPrices(
    String userId,
    Map<String, double> prices,
  ) async {
    if (_firebaseAvailable) {
      try {
        await _db.collection('users').doc(userId).set(
          {'customPrices': prices},
          SetOptions(merge: true),
        );
      } catch (_) {}
    }
  }

  static ProductModel _productFromFirestore(String id, Map<String, dynamic> data) {
    _ensureStockInit();
    final dbStock = (data['stock'] as num?)?.toInt();
    if (dbStock != null) {
      _stockById[id] = dbStock;
    }
    final stock = getStock(id);

    final canonical = _canonicalProduct(id);
    if (canonical != null) {
      return canonical.copyWith(stock: stock);
    }
    return ProductModel.fromMap(id, data).copyWith(stock: stock);
  }

  /// Katalog meta verisini günceller; mevcut stok değerini korur.
  static Future<void> _syncProductCatalog() async {
    _ensureCatalog();
    for (final p in _catalog) {
      final ref = _db.collection('products').doc(p.id);
      final doc = await ref.get();
      if (!doc.exists) {
        await ref.set(p.toMap());
        _stockById[p.id] = p.stock;
      } else {
        final data = doc.data() ?? {};
        _stockById[p.id] = (data['stock'] as num?)?.toInt() ?? p.stock;
        await ref.set(
          {
            'name': p.name,
            'brand': p.brand,
            'category': p.category,
            'wholesalePrice': p.wholesalePrice,
            'imageUrl': p.imageUrl,
            'stock': _stockById[p.id],
          },
          SetOptions(merge: true),
        );
      }
    }
  }

  /// Firestore izni varsa katalog ve logları senkronize eder.
  static Future<void> seedInitialData() async {
    if (!_firebaseAvailable) return;
    try {
      await _syncProductCatalog();
      final productsSnap = await _db.collection('products').limit(1).get();
      if (productsSnap.docs.isEmpty) {
        await addLog(
          userId: 'system',
          action: 'Ürün kataloğu oluşturuldu',
          details: '${_catalog.length} ürün eklendi',
        );
      }

      final logsSnap = await _db.collection('logs').limit(1).get();
      if (logsSnap.docs.isEmpty) {
        for (final log in _demoLogs) {
          final ts = log['timestamp'];
          await _db.collection('logs').add({
            'userId': log['userId'] ?? 'system',
            'action': log['action'],
            'details': log['details'],
            'timestamp': ts is DateTime
                ? Timestamp.fromDate(ts)
                : FieldValue.serverTimestamp(),
          });
        }
      }
    } catch (_) {
      // İzin yoksa uygulama yerel demo veriyle çalışmaya devam eder.
    }
  }

  /// Kullanıcının siparişi yoksa örnek siparişler oluşturur.
  static Future<void> ensureSampleOrdersForUser(String userId) async {
    if (!_firebaseAvailable || userId.isEmpty) return;

    final existing = await _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;

    for (final order in _demoOrders) {
      await _db.collection('orders').add({
        'userId': userId,
        'items': order.items.map((e) => e.toMap()).toList(),
        'totalAmount': order.totalAmount,
        'status': order.status,
        'createdAt': Timestamp.fromDate(order.createdAt),
      });
    }

    await addLog(
      userId: userId,
      action: 'Örnek siparişler yüklendi',
      details: '${_demoOrders.length} sipariş oluşturuldu',
    );
  }

  static Future<void> addLog({
    required String userId,
    required String action,
    required String details,
  }) async {
    if (!_firebaseAvailable) return;
    await _db.collection('logs').add({
      'userId': userId,
      'action': action,
      'details': details,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  static Future<List<ProductModel>> getProducts({
    String? category,
    String? brand,
  }) async {
    _ensureCatalog();
    if (!_firebaseAvailable) {
      return _filteredDemoProducts(category: category, brand: brand);
    }
    try {
      final snap = await _db.collection('products').get();
      if (snap.docs.isNotEmpty) {
        final fromDb = <String, ProductModel>{};
        for (final d in snap.docs) {
          fromDb[d.id] = _productFromFirestore(
            d.id,
            d.data() as Map<String, dynamic>,
          );
        }
        for (final p in _catalog) {
          fromDb.putIfAbsent(p.id, () => p.copyWith(stock: getStock(p.id)));
        }
        _catalog = fromDb.values.toList();
        var list = _catalog.map((p) => p.copyWith(stock: getStock(p.id))).toList();
        if (category != null && category.isNotEmpty) {
          list = list.where((p) => p.category == category).toList();
        }
        if (brand != null && brand.isNotEmpty) {
          list = list.where((p) => p.brand == brand).toList();
        }
        return list;
      }
      return _filteredDemoProducts(category: category, brand: brand);
    } catch (_) {
      return _filteredDemoProducts(category: category, brand: brand);
    }
  }

  static Future<List<OrderModel>> getUserOrders(String userId) async {
    if (isAdminUserId(userId)) return [];

    final local = List<OrderModel>.from(_localOrdersByUser[userId] ?? []);
    final List<OrderModel> remote = [];

    if (_firebaseAvailable) {
      try {
        final snap = await _db
            .collection('orders')
            .where('userId', isEqualTo: userId)
            .get();
        remote.addAll(
          snap.docs.map((d) => OrderModel.fromMap(d.id, d.data())).toList(),
        );
      } catch (_) {}
    }

    final merged = <String, OrderModel>{};
    for (final o in [...local, ...remote]) {
      merged[o.id] = o;
    }
    final all = merged.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (all.isNotEmpty) return all;
    if (_usersWithRealOrders.contains(userId)) return [];

    if (!_firebaseAvailable) return _demoOrdersForUser(userId);
    return _demoOrdersForUser(userId);
  }

  static Future<String> createOrder(
    OrderModel order, {
    bool increaseDebt = false,
  }) async {
    final localId = _saveLocalOrder(order);

    if (!_firebaseAvailable) {
      await addLog(
        userId: order.userId,
        action: 'Sipariş oluşturuldu',
        details: 'Sipariş ID: $localId, Tutar: ${order.totalAmount} ₺',
      );
      return localId;
    }
    try {
      final ref = await _db.collection('orders').add({
        ...order.toMap(),
        'createdAt': Timestamp.fromDate(order.createdAt),
      });
      if (increaseDebt) {
        try {
          await _db.collection('users').doc(order.userId).update({
            'currentDebt': FieldValue.increment(order.totalAmount),
          });
        } catch (_) {}
      }
      await addLog(
        userId: order.userId,
        action: 'Sipariş oluşturuldu',
        details: 'Sipariş ID: ${ref.id}, Tutar: ${order.totalAmount} ₺',
      );
      return ref.id;
    } catch (_) {
      return localId;
    }
  }

  static String _saveLocalOrder(OrderModel order) {
    final id = '#${DateTime.now().millisecondsSinceEpoch}';
    final saved = OrderModel(
      id: id,
      userId: order.userId,
      items: order.items,
      totalAmount: order.totalAmount,
      status: order.status,
      createdAt: order.createdAt,
    );
    _localOrdersByUser.putIfAbsent(order.userId, () => []).insert(0, saved);
    _usersWithRealOrders.add(order.userId);
    return id;
  }

  static Future<void> persistUserFinances(UserModel user) async {
    if (!_firebaseAvailable) return;
    try {
      await _db.collection('users').doc(user.uid).set(
        {
          'accountBalance': user.accountBalance,
          'currentDebt': user.currentDebt,
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  static Future<void> makePayment({
    required String userId,
    required double amount,
    required String paymentType,
    bool reduceDebt = true,
  }) async {
    _saveLocalPayment(userId, amount, paymentType);

    if (_firebaseAvailable) {
      try {
        await _db.collection('payments').add({
          'userId': userId,
          'amount': amount,
          'paymentType': paymentType,
          'date': FieldValue.serverTimestamp(),
        });
        if (reduceDebt) {
          try {
            await _db.collection('users').doc(userId).update({
              'currentDebt': FieldValue.increment(-amount),
            });
          } catch (_) {}
        }
        await addLog(
          userId: userId,
          action: 'Ödeme yapıldı',
          details: 'Tutar: $amount ₺, Tür: $paymentType',
        );
      } catch (_) {}
    }
  }

  static void _saveLocalPayment(
    String userId,
    double amount,
    String paymentType,
  ) {
    _localPaymentsByUser.putIfAbsent(userId, () => []).insert(0, {
      'amount': amount,
      'paymentType': paymentType,
      'date': DateTime.now(),
    });
  }

  static Future<List<Map<String, dynamic>>> getUserPayments(String userId) async {
    final local = List<Map<String, dynamic>>.from(
      _localPaymentsByUser[userId] ?? [],
    );

    if (!_firebaseAvailable) {
      if (local.isNotEmpty) return local;
      return List.from(_demoPayments);
    }
    try {
      final snap = await _db
          .collection('payments')
          .where('userId', isEqualTo: userId)
          .orderBy('date', descending: true)
          .get();
      final remote = snap.docs.map((d) => d.data()).toList();
      if (remote.isNotEmpty || local.isNotEmpty) {
        return [...local, ...remote];
      }
      return List.from(_demoPayments);
    } catch (_) {
      if (local.isNotEmpty) return local;
      return List.from(_demoPayments);
    }
  }

  static Future<List<Map<String, dynamic>>> getUserLogs(String userId) async {
    if (!_firebaseAvailable) {
      return _demoLogs
          .where((l) => l['userId'] == userId || l['userId'] == 'system')
          .toList();
    }
    try {
      final snap = await _db
          .collection('logs')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();
      final logs = snap.docs.map((d) => d.data()).toList();
      if (logs.isEmpty) {
        return _demoLogs
            .where((l) => l['userId'] == userId || l['userId'] == 'system')
            .toList();
      }
      return logs;
    } catch (_) {
      return _demoLogs
          .where((l) => l['userId'] == userId || l['userId'] == 'system')
          .toList();
    }
  }

  static final List<UserModel> _demoUsers = [
    UserModel(
      uid: 'demo_uid',
      email: 'demo@kosmetic.com',
      companyName: 'Kozmetik Ltd.',
      taxNumber: '1234567890',
      role: 'bayi',
      creditLimit: 50000,
      currentDebt: 1575.25,
      createdAt: DateTime(2024, 1, 15),
    ),
    UserModel(
      uid: 'uid_2',
      email: 'bayi2@example.com',
      companyName: 'Güzellik Dünyası A.Ş.',
      taxNumber: '9876543210',
      role: 'bayi',
      creditLimit: 30000,
      currentDebt: 850.00,
      createdAt: DateTime(2024, 2, 10),
    ),
    UserModel(
      uid: 'uid_3',
      email: 'kullanici@example.com',
      displayName: 'Ayşe Yıldız',
      role: 'kullanici',
      createdAt: DateTime(2024, 3, 5),
    ),
  ];

  static Future<List<UserModel>> getAllUsers() async {
    if (!_firebaseAvailable) return List.from(_demoUsers);
    // Adminler hariç tüm kullanıcıları getir
    final snap = await _db.collection('users').get();
    return snap.docs
        .map((d) => UserModel.fromMap(d.data()))
        .where((u) => u.role != 'admin')
        .toList();
  }

  static List<OrderModel> _customerOrdersFromLocal() {
    final list = <OrderModel>[];
    _localOrdersByUser.forEach((uid, orders) {
      if (!isAdminUserId(uid)) {
        list.addAll(orders);
      }
    });
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static Future<List<OrderModel>> getAllOrders() async {
    final localCustomers = _customerOrdersFromLocal();
    final List<OrderModel> remote = [];

    if (_firebaseAvailable) {
      try {
        final snap = await _db.collection('orders').get();
        remote.addAll(
          snap.docs.map((d) => OrderModel.fromMap(d.id, d.data())),
        );
      } catch (_) {}
    } else {
      remote.addAll(
        _demoOrders.where((o) => !isAdminUserId(o.userId)),
      );
    }

    final merged = <String, OrderModel>{};
    for (final o in [...localCustomers, ...remote]) {
      if (!isAdminUserId(o.userId)) {
        merged[o.id] = o;
      }
    }
    final all = merged.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return all;
  }

  static Future<List<Map<String, dynamic>>> getAllLogs() async {
    if (!_firebaseAvailable) return List.from(_demoLogs);
    try {
      final snap = await _db
          .collection('logs')
          .orderBy('timestamp', descending: true)
          .limit(100)
          .get();
      final logs = snap.docs.map((d) => d.data()).toList();
      if (logs.isEmpty) return List.from(_demoLogs);
      return logs;
    } catch (_) {
      return List.from(_demoLogs);
    }
  }

  static Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    if (!_firebaseAvailable) return;
    await _db.collection('orders').doc(orderId).update({'status': status});
  }
}
