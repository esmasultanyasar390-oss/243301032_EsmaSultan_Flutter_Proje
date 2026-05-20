import 'package:flutter/material.dart';
import '../constants.dart';

class CheckoutPaymentResult {
  final double amount;
  final String paymentType;

  const CheckoutPaymentResult({
    required this.amount,
    required this.paymentType,
  });
}

/// Sipariş öncesi ödeme onayı diyaloğu.
Future<CheckoutPaymentResult?> showCheckoutPaymentDialog(
  BuildContext context, {
  required double orderTotal,
}) async {
  final amountCtrl = TextEditingController(text: orderTotal.toStringAsFixed(2));
  String paymentType = 'Kredi Kartı';

  return showDialog<CheckoutPaymentResult>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx2, setS) => AlertDialog(
        title: const Text(
          'Ödeme Onayı',
          style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sipariş tutarı',
                        style: TextStyle(color: AppColors.textGrey)),
                    Text(
                      '${orderTotal.toStringAsFixed(2)} ₺',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Ödenecek tutar (₺)',
                  prefixIcon: const Icon(Icons.payments),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                // ignore: deprecated_member_use
                value: paymentType,
                decoration: InputDecoration(
                  labelText: 'Ödeme yöntemi',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                items: ['Kredi Kartı', 'Havale', 'Nakit']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                    .toList(),
                onChanged: (v) => setS(() => paymentType = v ?? 'Kredi Kartı'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Siparişiniz ödeme onayından sonra oluşturulacaktır.',
                style: TextStyle(fontSize: 12, color: AppColors.textGrey),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx2),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () {
              final amount = double.tryParse(
                amountCtrl.text.replaceAll(',', '.'),
              );
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(ctx2).showSnackBar(
                  const SnackBar(content: Text('Geçerli bir tutar girin.')),
                );
                return;
              }
              if (amount < orderTotal) {
                ScaffoldMessenger.of(ctx2).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Minimum ödeme: ${orderTotal.toStringAsFixed(2)} ₺',
                    ),
                  ),
                );
                return;
              }
              Navigator.pop(
                ctx2,
                CheckoutPaymentResult(
                  amount: amount,
                  paymentType: paymentType,
                ),
              );
            },
            child: const Text('Öde ve Sipariş Ver',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );
}
