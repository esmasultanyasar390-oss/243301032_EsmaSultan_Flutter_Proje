import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_home_screen.dart';
import 'services/auth_service.dart';
import 'services/cart_provider.dart';
import 'constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (_) {}
  runApp(const KosmeticApp());
}

class KosmeticApp extends StatelessWidget {
  const KosmeticApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CartProvider(),
      child: MaterialApp(
        title: AppStrings.appName,
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
          ),
          useMaterial3: true,
          scaffoldBackgroundColor: AppColors.background,
        ),
        home: const _AuthGate(),
      ),
    );
  }
}

class _AuthGate extends StatefulWidget {
  const _AuthGate();

  @override
  State<_AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<_AuthGate> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkAuth());
  }

  Future<void> _checkAuth() async {
    // Demo mod (Firebase bağlı değil)
    if (Firebase.apps.isEmpty) {
      final existing = AuthService.currentUser;
      if (existing != null) {
        _navigate(existing.role == 'admin'
            ? const AdminHomeScreen()
            : const HomeScreen());
      } else {
        _navigate(const LoginScreen());
      }
      return;
    }

    // Firebase mod
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      _navigate(const LoginScreen());
      return;
    }

    final user = await AuthService.loadCurrentUser(firebaseUser.uid);
    if (!mounted) return;

    if (user == null) {
      _navigate(const LoginScreen());
    } else {
      _navigate(user.role == 'admin'
          ? const AdminHomeScreen()
          : const HomeScreen());
    }
  }

  void _navigate(Widget screen) {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Kosmetic',
              style: TextStyle(
                fontSize: 42,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
                color: Color(0xFF692662),
              ),
            ),
            SizedBox(height: 28),
            CircularProgressIndicator(color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}
