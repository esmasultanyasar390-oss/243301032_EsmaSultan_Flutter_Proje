import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';
import 'cart_provider.dart';

class AuthService {
  static UserModel? currentUser;

  static bool get isAdmin => currentUser?.role == 'admin';
  static bool get isBayi => currentUser?.role == 'bayi';
  static bool get isKullanici => currentUser?.role == 'kullanici';

  bool get _firebaseAvailable => Firebase.apps.isNotEmpty;

  // Bu listedeki e-postalar otomatik olarak yönetici rolü alır.
  static const List<String> adminEmails = ['admin@kosmetic.com'];

  // ── Demo hesaplar (Firebase bağlantısı olmadan test için) ──────────────
  static final _demoAccounts = <String, (String, UserModel)>{
    'admin@kosmetic.com': (
      'admin123',
      UserModel(
        uid: 'demo_admin_uid',
        email: 'admin@kosmetic.com',
        role: 'admin',
        companyName: 'Kosmetic Yönetim',
        taxNumber: 'ADMIN001',
        createdAt: DateTime(2024, 1, 1),
      ),
    ),
    'demo@kosmetic.com': (
      '123456',
      UserModel(
        uid: 'demo_bayi_uid',
        email: 'demo@kosmetic.com',
        role: 'bayi',
        companyName: 'Kozmetik Ltd.',
        taxNumber: '1234567890',
        creditLimit: 50000,
        currentDebt: 1575.25,
        accountBalance: 48424.75,
        createdAt: DateTime(2024, 1, 15),
      ),
    ),
    'kullanici@kosmetic.com': (
      '123456',
      UserModel(
        uid: 'demo_kullanici_uid',
        email: 'kullanici@kosmetic.com',
        role: 'kullanici',
        displayName: 'Ayşe Yıldız',
        accountBalance: 5000,
        createdAt: DateTime(2024, 2, 1),
      ),
    ),
  };
  // ────────────────────────────────────────────────────────────────────────

  /// Uygulama açılışında Firebase'den oturum bilgisini yükler.
  static Future<UserModel?> loadCurrentUser(String uid) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      if (doc.exists) {
        currentUser = UserModel.fromMap(doc.data()!);
        if (currentUser!.role == 'admin') {
          FirestoreService.registerAdminUid(uid);
        }
        return currentUser;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<UserModel?> signIn(String email, String password) async {
    // ── Demo mod ──────────────────────────────────────────────────────────
    if (!_firebaseAvailable) {
      final entry = _demoAccounts[email.trim().toLowerCase()];
      if (entry != null && password == entry.$1) {
        currentUser = entry.$2;
        CartProvider.bindToCurrentUser();
        return currentUser;
      }
      throw 'E-posta veya şifre hatalı.';
    }
    // ── Firebase mod ──────────────────────────────────────────────────────
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final uid = cred.user!.uid;
      final isAdmin = adminEmails.contains(email.trim().toLowerCase());
      final docRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final doc = await docRef.get();

      if (doc.exists) {
        currentUser = UserModel.fromMap(doc.data()!);
        if (isAdmin && currentUser!.role != 'admin') {
          await docRef.update({'role': 'admin'});
          currentUser = _withRole(currentUser!, 'admin');
        }
      } else {
        final user = UserModel(
          uid: uid,
          email: email.trim(),
          companyName: isAdmin ? 'Kosmetic Yönetim' : '',
          taxNumber: isAdmin ? 'ADMIN' : '',
          role: isAdmin ? 'admin' : 'bayi',
          accountBalance: isAdmin ? 0 : 10000,
          createdAt: DateTime.now(),
        );
        await docRef.set(user.toMap());
        currentUser = user;
      }

      await FirestoreService.addLog(
        userId: uid,
        action: 'Giriş yapıldı',
        details: 'E-posta: $email',
      );
      if (currentUser!.role == 'admin') {
        FirestoreService.registerAdminUid(uid);
      }
      if (currentUser!.role == 'bayi') {
        await FirestoreService.ensureSampleOrdersForUser(uid);
      }
      CartProvider.bindToCurrentUser();
      return currentUser;
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  Future<UserModel?> register({
    required String email,
    required String password,
    required String role,
    String displayName = '',
    String companyName = '',
    String taxNumber = '',
  }) async {
    if (adminEmails.contains(email.trim().toLowerCase())) {
      throw 'Bu e-posta adresi ile kayıt oluşturulamaz.';
    }

    // ── Demo mod ──────────────────────────────────────────────────────────
    if (!_firebaseAvailable) {
      print('⚠️  Firebase kullanılamıyor! Demo mode\'da çalışılıyor.');
      throw 'Firebase bağlantısı başarısız. Lütfen İnternet bağlantınızı kontrol edin ve uygulamayı yeniden başlatın.';
    }
    // ── Firebase mod ──────────────────────────────────────────────────────
    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      final user = UserModel(
        uid: cred.user!.uid,
        email: email.trim(),
        role: role,
        displayName: displayName.trim(),
        companyName: companyName.trim(),
        taxNumber: taxNumber.trim(),
        accountBalance: role == 'bayi' ? 10000 : 5000,
        createdAt: DateTime.now(),
      );
      await FirebaseFirestore.instance
          .collection('users')
          .doc(cred.user!.uid)
          .set(user.toMap());
      await FirestoreService.addLog(
        userId: cred.user!.uid,
        action: role == 'bayi' ? 'Yeni bayi kaydı' : 'Yeni kullanıcı kaydı',
        details: role == 'bayi' ? 'Firma: $companyName' : 'Ad: $displayName',
      );
      currentUser = user;
      CartProvider.bindToCurrentUser();
      return user;
    } on FirebaseAuthException catch (e) {
      throw _mapError(e);
    }
  }

  Future<void> signOut() async {
    if (_firebaseAvailable) {
      try {
        await FirestoreService.addLog(
          userId: currentUser?.uid ?? '',
          action: 'Çıkış yapıldı',
          details: '',
        );
      } catch (_) {}
      await FirebaseAuth.instance.signOut();
    }
    currentUser = null;
    CartProvider.clearOnLogout();
  }

  /// Ödeme / sipariş sonrası bakiyeden düşer.
  static void deductBalance(double amount) {
    final u = currentUser;
    if (u == null || amount <= 0) return;
    currentUser = u.copyWith(
      accountBalance: (u.accountBalance - amount).clamp(0, double.infinity),
    );
    FirestoreService.persistUserFinances(currentUser!);
  }

  static void reduceDebt(double amount) {
    final u = currentUser;
    if (u == null || amount <= 0) return;
    currentUser = u.copyWith(
      currentDebt: (u.currentDebt - amount).clamp(0, double.infinity),
    );
    FirestoreService.persistUserFinances(currentUser!);
  }

  static void addDebt(double amount) {
    final u = currentUser;
    if (u == null || amount <= 0) return;
    currentUser = u.copyWith(currentDebt: u.currentDebt + amount);
    FirestoreService.persistUserFinances(currentUser!);
  }

  static void updateCustomPrices(Map<String, double> prices) {
    final u = currentUser;
    if (u == null) return;
    currentUser = u.copyWith(customPrices: prices);
  }

  static bool canAfford(double amount) {
    final u = currentUser;
    if (u == null) return false;
    return u.accountBalance >= amount;
  }

  UserModel _withRole(UserModel u, String role) => u.copyWith(role: role);

  String _mapError(FirebaseAuthException e) {
    const map = {
      'user-not-found': 'Bu e-posta ile kullanıcı bulunamadı.',
      'wrong-password': 'Şifre hatalı.',
      'email-already-in-use': 'Bu e-posta zaten kullanımda.',
      'weak-password': 'Şifre çok zayıf (en az 6 karakter).',
      'invalid-email': 'Geçersiz e-posta formatı.',
      'invalid-credential': 'E-posta veya şifre hatalı.',
    };
    return map[e.code] ?? 'Giriş hatası: ${e.message}';
  }
}
