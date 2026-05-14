import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'admin_home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _bayiEmailCtrl = TextEditingController();
  final _bayiPassCtrl = TextEditingController();
  final _adminEmailCtrl = TextEditingController();
  final _adminPassCtrl = TextEditingController();
  final _auth = AuthService();
  bool _bayiLoading = false;
  bool _adminLoading = false;
  bool _bayiObscure = true;
  bool _adminObscure = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bayiEmailCtrl.dispose();
    _bayiPassCtrl.dispose();
    _adminEmailCtrl.dispose();
    _adminPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _loginBayi() async {
    if (_bayiEmailCtrl.text.trim().isEmpty || _bayiPassCtrl.text.isEmpty) {
      _showError('Lütfen tüm alanları doldurun.');
      return;
    }
    setState(() => _bayiLoading = true);
    try {
      final user =
          await _auth.signIn(_bayiEmailCtrl.text.trim(), _bayiPassCtrl.text);
      if (user != null && mounted) {
        if (user.role == 'admin') {
          Navigator.pushReplacement(context,
              MaterialPageRoute(builder: (_) => const AdminHomeScreen()));
        } else {
          Navigator.pushReplacement(
              context, MaterialPageRoute(builder: (_) => const HomeScreen()));
        }
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _bayiLoading = false);
    }
  }

  Future<void> _loginAdmin() async {
    if (_adminEmailCtrl.text.trim().isEmpty || _adminPassCtrl.text.isEmpty) {
      _showError('Lütfen tüm alanları doldurun.');
      return;
    }
    setState(() => _adminLoading = true);
    try {
      final user = await _auth.signIn(
          _adminEmailCtrl.text.trim(), _adminPassCtrl.text);
      if (user != null && mounted) {
        if (user.role != 'admin') {
          _showError('Bu hesap yönetici yetkisine sahip değil.');
          await _auth.signOut();
          return;
        }
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const AdminHomeScreen()));
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _adminLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Kosmetic',
                    style: TextStyle(
                      fontSize: 42,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: Color(0xFF692662),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    AppStrings.tagline,
                    style: TextStyle(
                        fontSize: 14,
                        color: AppColors.primary.withValues(alpha: 0.7)),
                  ),
                ],
              ),
            ),
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    TabBar(
                      controller: _tabController,
                      labelColor: AppColors.primary,
                      unselectedLabelColor: AppColors.textGrey,
                      indicatorColor: AppColors.primary,
                      indicatorWeight: 3,
                      labelStyle: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                      tabs: const [
                        Tab(text: 'Bayi Girişi'),
                        Tab(text: 'Yönetici Girişi'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _BayiTab(
                            emailCtrl: _bayiEmailCtrl,
                            passCtrl: _bayiPassCtrl,
                            loading: _bayiLoading,
                            obscure: _bayiObscure,
                            onObscureToggle: () =>
                                setState(() => _bayiObscure = !_bayiObscure),
                            onLogin: _loginBayi,
                            onRegister: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const RegisterScreen())),
                          ),
                          _AdminTab(
                            emailCtrl: _adminEmailCtrl,
                            passCtrl: _adminPassCtrl,
                            loading: _adminLoading,
                            obscure: _adminObscure,
                            onObscureToggle: () =>
                                setState(() => _adminObscure = !_adminObscure),
                            onLogin: _loginAdmin,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BayiTab extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool loading;
  final bool obscure;
  final VoidCallback onObscureToggle;
  final VoidCallback onLogin;
  final VoidCallback onRegister;

  const _BayiTab({
    required this.emailCtrl,
    required this.passCtrl,
    required this.loading,
    required this.obscure,
    required this.onObscureToggle,
    required this.onLogin,
    required this.onRegister,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          const Text('Vergi No / E-posta',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: _fieldDeco(Icons.person_outline),
          ),
          const SizedBox(height: 20),
          const Text('Şifre',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: passCtrl,
            obscureText: obscure,
            decoration: _fieldDeco(Icons.lock_outline).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey),
                onPressed: onObscureToggle,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Demo: demo@kosmetic.com / 123456',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textGrey.withValues(alpha: 0.8)),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: loading ? null : onLogin,
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Giriş Yap',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: onRegister,
              child: const Text('Yeni Bayi Kaydı',
                  style: TextStyle(fontSize: 16, color: AppColors.primary)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDeco(IconData icon) => InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      );
}

class _AdminTab extends StatelessWidget {
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool loading;
  final bool obscure;
  final VoidCallback onObscureToggle;
  final VoidCallback onLogin;

  const _AdminTab({
    required this.emailCtrl,
    required this.passCtrl,
    required this.loading,
    required this.obscure,
    required this.onObscureToggle,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(10),
              border:
                  Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.admin_panel_settings,
                    color: AppColors.primary),
                const SizedBox(width: 10),
                Text(
                  'Yetkili yönetici girişi',
                  style: TextStyle(
                      color: AppColors.primary.withValues(alpha: 0.8),
                      fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text('E-posta',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: emailCtrl,
            keyboardType: TextInputType.emailAddress,
            decoration: _fieldDeco(Icons.admin_panel_settings_outlined),
          ),
          const SizedBox(height: 20),
          const Text('Şifre',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          const SizedBox(height: 8),
          TextField(
            controller: passCtrl,
            obscureText: obscure,
            decoration: _fieldDeco(Icons.lock_outline).copyWith(
              suffixIcon: IconButton(
                icon: Icon(
                    obscure ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey),
                onPressed: onObscureToggle,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Demo: admin@kosmetic.com / admin123',
              style: TextStyle(
                  fontSize: 11,
                  color: AppColors.textGrey.withValues(alpha: 0.8)),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25)),
              ),
              onPressed: loading ? null : onLogin,
              child: loading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Text('Yönetici Girişi',
                      style: TextStyle(fontSize: 16, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _fieldDeco(IconData icon) => InputDecoration(
        prefixIcon: Icon(icon, color: Colors.grey),
        contentPadding: const EdgeInsets.symmetric(vertical: 15),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary),
        ),
      );
}
