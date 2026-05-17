import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  // Ortak alanlar
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  // Bayi alanları
  final _companyCtrl = TextEditingController();
  final _taxCtrl = TextEditingController();
  // Bireysel alan
  final _nameCtrl = TextEditingController();

  final _auth = AuthService();
  bool _isBayi = true;
  bool _loading = false;
  bool _obscure = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    _companyCtrl.dispose();
    _taxCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text;
    final confirm = _confirmPassCtrl.text;

    if (email.isEmpty || pass.isEmpty) {
      _showError('E-posta ve şifre zorunludur.');
      return;
    }
    if (_isBayi && (_companyCtrl.text.trim().isEmpty || _taxCtrl.text.trim().isEmpty)) {
      _showError('Firma adı ve vergi numarası zorunludur.');
      return;
    }
    if (!_isBayi && _nameCtrl.text.trim().isEmpty) {
      _showError('Ad soyad zorunludur.');
      return;
    }
    if (pass != confirm) {
      _showError('Şifreler eşleşmiyor.');
      return;
    }
    if (pass.length < 6) {
      _showError('Şifre en az 6 karakter olmalıdır.');
      return;
    }

    setState(() => _loading = true);
    try {
      final user = await _auth.register(
        email: email,
        password: pass,
        role: _isBayi ? 'bayi' : 'kullanici',
        displayName: _isBayi ? '' : _nameCtrl.text.trim(),
        companyName: _isBayi ? _companyCtrl.text.trim() : '',
        taxNumber: _isBayi ? _taxCtrl.text.trim() : '',
      );
      if (user != null && mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomeScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Yeni Hesap Oluştur',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          children: [
            const SizedBox(height: 8),
            // Hesap tipi seçici
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(6),
              child: Row(
                children: [
                  _typeBtn(
                    label: 'Bayi Hesabı',
                    icon: Icons.business,
                    selected: _isBayi,
                    onTap: () => setState(() => _isBayi = true),
                  ),
                  _typeBtn(
                    label: 'Bireysel Hesap',
                    icon: Icons.person,
                    selected: !_isBayi,
                    onTap: () => setState(() => _isBayi = false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Açıklama
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Text(
                _isBayi
                    ? 'Toptan alışveriş, cari hesap ve kredi limiti özelliklerine sahip olursunuz.'
                    : 'Ürün kataloğunu görüntüleyebilir ve sipariş verebilirsiniz.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.primary.withValues(alpha: 0.8),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Form kartı
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Bayi alanları
                  if (_isBayi) ...[
                    _field(_companyCtrl, 'Firma Adı', Icons.business_outlined),
                    const SizedBox(height: 14),
                    _field(_taxCtrl, 'Vergi Numarası', Icons.numbers,
                        type: TextInputType.number),
                    const SizedBox(height: 14),
                  ],
                  // Bireysel alan
                  if (!_isBayi) ...[
                    _field(_nameCtrl, 'Ad Soyad', Icons.person_outline),
                    const SizedBox(height: 14),
                  ],
                  // Ortak alanlar
                  _field(_emailCtrl, 'E-posta', Icons.email_outlined,
                      type: TextInputType.emailAddress),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passCtrl,
                    obscureText: _obscure,
                    decoration: _fieldDeco('Şifre', Icons.lock_outline).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscure ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () => setState(() => _obscure = !_obscure),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _confirmPassCtrl,
                    obscureText: _obscureConfirm,
                    decoration:
                        _fieldDeco('Şifre Tekrar', Icons.lock_outline).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                          color: Colors.grey,
                        ),
                        onPressed: () =>
                            setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25)),
                      ),
                      onPressed: _loading ? null : _register,
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text(
                              _isBayi ? 'Bayi Hesabı Oluştur' : 'Hesap Oluştur',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 16),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Zaten hesabım var, giriş yap',
                        style: TextStyle(color: AppColors.primary),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _typeBtn({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  size: 18,
                  color: selected ? Colors.white : AppColors.textGrey),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.textGrey,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController ctrl, String label, IconData icon,
      {TextInputType? type}) {
    return TextField(
      controller: ctrl,
      keyboardType: type,
      decoration: _fieldDeco(label, icon),
    );
  }

  InputDecoration _fieldDeco(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
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
