import 'package:flutter/material.dart';
import '../constants.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  late Future<List<Map<String, dynamic>>> _paymentsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final uid = AuthService.currentUser?.uid ?? 'demo_uid';
    setState(() {
      _paymentsFuture = FirestoreService.getUserPayments(uid);
    });
  }

  DateTime _toDate(dynamic v) {
    if (v is DateTime) return v;
    try {
      return (v as dynamic).toDate();
    } catch (e) {
      return DateTime.now();
    }
  }

  void _showPaymentDialog() {
    final amountCtrl = TextEditingController();
    String paymentType = 'Havale';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setS) => AlertDialog(
          title: const Text('Ödeme Yap',
              style: TextStyle(color: AppColors.primary)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'Miktar (₺)',
                  prefixIcon: const Icon(Icons.payments),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: paymentType,
                decoration: InputDecoration(
                  labelText: 'Ödeme Türü',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                items: ['Havale', 'Kredi Kartı', 'Nakit']
                    .map((e) =>
                        DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setS(() => paymentType = v ?? 'Havale'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx2),
                child: const Text('İptal')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary),
              onPressed: () async {
                final amount = double.tryParse(amountCtrl.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(ctx2).showSnackBar(const SnackBar(
                      content: Text('Geçerli bir miktar girin.')));
                  return;
                }
                Navigator.pop(ctx2);
                await FirestoreService.makePayment(
                  userId: AuthService.currentUser?.uid ?? 'demo_uid',
                  amount: amount,
                  paymentType: paymentType,
                );
                if (mounted) {
                  _load();
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                    content: Text('Ödeme kaydedildi!'),
                    backgroundColor: AppColors.success,
                  ));
                }
              },
              child: const Text('Onayla',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    final debt = user?.currentDebt ?? 1575.25;
    final limit = user?.creditLimit ?? 50000.0;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Cari Hesap & Ödeme',
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _balanceCard('Hesap Bakiyesi',
                    '${(limit - debt).toStringAsFixed(2)} ₺',
                    AppColors.success),
                const SizedBox(width: 10),
                _balanceCard('Kredi Limiti',
                    '${limit.toStringAsFixed(2)} ₺', AppColors.info),
                const SizedBox(width: 10),
                _balanceCard('Toplam Borç',
                    '${debt.toStringAsFixed(2)} ₺', AppColors.danger),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25)),
                ),
                onPressed: _showPaymentDialog,
                icon: const Icon(Icons.payment, color: Colors.white),
                label: const Text('Ödeme Yap',
                    style: TextStyle(color: Colors.white, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 20),
            const Text('Son Ödemeler',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark)),
            const SizedBox(height: 10),
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _paymentsFuture,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final payments = snap.data ?? [];
                if (payments.isEmpty) {
                  return const Center(
                      child: Text('Ödeme kaydı bulunamadı.',
                          style: TextStyle(color: AppColors.textGrey)));
                }
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: payments.length,
                  itemBuilder: (context, i) {
                    final p = payments[i];
                    final date = _toDate(p['date']);
                    return Card(
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              AppColors.success.withValues(alpha: 0.1),
                          child: const Icon(Icons.check,
                              color: AppColors.success),
                        ),
                        title: Text(
                            '${(p['amount'] as num).toStringAsFixed(2)} ₺',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                        subtitle: Text(p['paymentType'] ?? '',
                            style:
                                const TextStyle(color: AppColors.textGrey)),
                        trailing: Text(
                            '${date.day}.${date.month}.${date.year}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.textGrey)),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cardBg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.account_balance,
                          color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text('Banka Hesap Bilgileri',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  _bankRow('Banka', 'Ziraat Bankası'),
                  _bankRow('Hesap Adı', 'Kosmetic Kozmetik Ltd. Şti.'),
                  _bankRow('IBAN', 'TR12 0001 0017 4567 8901 2345 67'),
                  _bankRow('Açıklama', 'Vergi No + Firma Adı'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: color),
                textAlign: TextAlign.center),
            const SizedBox(height: 4),
            Text(title,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textGrey),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _bankRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textGrey)),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}
