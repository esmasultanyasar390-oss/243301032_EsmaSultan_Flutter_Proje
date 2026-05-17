import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';

class FirestoreService {
  static bool get _firebaseAvailable => Firebase.apps.isNotEmpty;
  static FirebaseFirestore get _db => FirebaseFirestore.instance;

  static final List<ProductModel> _demoProducts = const [
    ProductModel(id: 'p1', name: 'Fondöten No:30', brand: "L'Oreal", category: 'Makyaj', wholesalePrice: 45.90, stock: 50),
    ProductModel(id: 'p2', name: 'Volume Express Maskara', brand: 'Maybelline', category: 'Makyaj', wholesalePrice: 32.50, stock: 100),
    ProductModel(id: 'p3', name: 'Q10 Nemlendirici', brand: 'Nivea', category: 'Cilt Bakımı', wholesalePrice: 28.75, stock: 75),
    ProductModel(id: 'p4', name: 'Tonik 250ml', brand: 'The Body Shop', category: 'Cilt Bakımı', wholesalePrice: 89.00, stock: 30),
    ProductModel(id: 'p5', name: 'Lasting Finish Ruj', brand: 'Rimmel', category: 'Makyaj', wholesalePrice: 24.99, stock: 200),
    ProductModel(id: 'p6', name: 'SPF50 Güneş Kremi', brand: 'Garnier', category: 'Cilt Bakımı', wholesalePrice: 42.00, stock: 60),
    ProductModel(id: 'p7', name: 'Studio Fix Pudra', brand: 'MAC', category: 'Makyaj', wholesalePrice: 125.00, stock: 25),
    ProductModel(id: 'p8', name: 'Turnaround Serum', brand: 'Clinique', category: 'Cilt Bakımı', wholesalePrice: 210.00, stock: 15),
  ];

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
      items: const [OrderItem(productId: 'p7', productName: 'Studio Fix Pudra', quantity: 4, unitPrice: 125.00)],
      totalAmount: 500.00,
      status: 'hazirlaniyor',
      createdAt: DateTime(2024, 3, 22),
    ),
    OrderModel(
      id: '#1003',
      userId: 'demo_uid',
      items: const [OrderItem(productId: 'p8', productName: 'Turnaround Serum', quantity: 2, unitPrice: 210.00)],
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
    {'action': 'Giriş yapıldı', 'timestamp': DateTime(2024, 3, 28), 'details': 'E-posta: demo@kosmetic.com'},
    {'action': 'Sipariş oluşturuldu', 'timestamp': DateTime(2024, 3, 28), 'details': 'Sipariş #1003, Tutar: 420 ₺'},
    {'action': 'Ödeme yapıldı', 'timestamp': DateTime(2024, 3, 10), 'details': 'Tutar: 1000 ₺, Tür: Havale'},
    {'action': 'Sipariş oluşturuldu', 'timestamp': DateTime(2024, 3, 22), 'details': 'Sipariş #1002, Tutar: 500 ₺'},
    {'action': 'Giriş yapıldı', 'timestamp': DateTime(2024, 3, 15), 'details': 'E-posta: demo@kosmetic.com'},
  ];

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
    if (!_firebaseAvailable) {
      var list = List<ProductModel>.from(_demoProducts);
      if (category != null && category.isNotEmpty) {
        list = list.where((p) => p.category == category).toList();
      }
      if (brand != null && brand.isNotEmpty) {
        list = list.where((p) => p.brand == brand).toList();
      }
      return list;
    }
    Query query = _db.collection('products');
    if (category != null && category.isNotEmpty) {
      query = query.where('category', isEqualTo: category);
    }
    if (brand != null && brand.isNotEmpty) {
      query = query.where('brand', isEqualTo: brand);
    }
    final snap = await query.get();
    return snap.docs
        .map((d) => ProductModel.fromMap(d.id, d.data() as Map<String, dynamic>))
        .toList();
  }

  static Future<List<OrderModel>> getUserOrders(String userId) async {
    if (!_firebaseAvailable) return List.from(_demoOrders);
    final snap = await _db
        .collection('orders')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => OrderModel.fromMap(d.id, d.data())).toList();
  }

  static Future<void> createOrder(OrderModel order) async {
    if (!_firebaseAvailable) return;
    final ref = await _db.collection('orders').add(order.toMap());
    await _db.collection('users').doc(order.userId).update({
      'currentDebt': FieldValue.increment(order.totalAmount),
    });
    await addLog(
      userId: order.userId,
      action: 'Sipariş oluşturuldu',
      details: 'Sipariş ID: ${ref.id}, Tutar: ${order.totalAmount} ₺',
    );
  }

  static Future<void> makePayment({
    required String userId,
    required double amount,
    required String paymentType,
  }) async {
    if (!_firebaseAvailable) return;
    await _db.collection('payments').add({
      'userId': userId,
      'amount': amount,
      'paymentType': paymentType,
      'date': FieldValue.serverTimestamp(),
    });
    await _db.collection('users').doc(userId).update({
      'currentDebt': FieldValue.increment(-amount),
    });
    await addLog(
      userId: userId,
      action: 'Ödeme yapıldı',
      details: 'Tutar: $amount ₺, Tür: $paymentType',
    );
  }

  static Future<List<Map<String, dynamic>>> getUserPayments(String userId) async {
    if (!_firebaseAvailable) return List.from(_demoPayments);
    final snap = await _db
        .collection('payments')
        .where('userId', isEqualTo: userId)
        .orderBy('date', descending: true)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  static Future<List<Map<String, dynamic>>> getUserLogs(String userId) async {
    if (!_firebaseAvailable) return List.from(_demoLogs);
    final snap = await _db
        .collection('logs')
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true)
        .limit(50)
        .get();
    return snap.docs.map((d) => d.data()).toList();
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

  static Future<List<OrderModel>> getAllOrders() async {
    if (!_firebaseAvailable) return List.from(_demoOrders);
    final snap = await _db
        .collection('orders')
        .orderBy('createdAt', descending: true)
        .get();
    return snap.docs.map((d) => OrderModel.fromMap(d.id, d.data())).toList();
  }

  static Future<List<Map<String, dynamic>>> getAllLogs() async {
    if (!_firebaseAvailable) return List.from(_demoLogs);
    final snap = await _db
        .collection('logs')
        .orderBy('timestamp', descending: true)
        .limit(100)
        .get();
    return snap.docs.map((d) => d.data()).toList();
  }

  static Future<void> updateOrderStatus({
    required String orderId,
    required String status,
  }) async {
    if (!_firebaseAvailable) return;
    await _db.collection('orders').doc(orderId).update({'status': status});
  }
}
