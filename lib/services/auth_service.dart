import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

class AuthService {
  static UserModel? currentUser;

  bool get _firebaseAvailable => Firebase.apps.isNotEmpty;

  // Bu listedeki e-postalar otomatik olarak yönetici rolü alır.
  static const List<String> adminEmails = [
    'admin@kosmetic.com',
  ];

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
      final docRef =
          FirebaseFirestore.instance.collection('users').doc(uid);
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
      final user = UserModel(
        uid: 'demo_${DateTime.now().millisecondsSinceEpoch}',
        email: email.trim(),
        role: role,
        displayName: displayName.trim(),
        companyName: companyName.trim(),
        taxNumber: taxNumber.trim(),
        createdAt: DateTime.now(),
      );
      currentUser = user;
      return user;
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
  }

  UserModel _withRole(UserModel u, String role) => UserModel(
        uid: u.uid,
        email: u.email,
        role: role,
        displayName: u.displayName,
        companyName: u.companyName,
        taxNumber: u.taxNumber,
        creditLimit: u.creditLimit,
        currentDebt: u.currentDebt,
        createdAt: u.createdAt,
      );

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
