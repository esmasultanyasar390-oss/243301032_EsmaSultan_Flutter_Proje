import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../models/product_model.dart';
import '../services/cart_provider.dart';
import '../services/firestore_service.dart';

/// Sepete eklemeden önce adet seçtirir.
Future<void> showAddToCartDialog(BuildContext context, ProductModel product) async {
  int quantity = 1;
  final maxQty = FirestoreService.getStock(product.id);

  final added = await showDialog<bool>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx2, setS) => AlertDialog(
        title: Text(
          product.name,
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${product.brand} · ${product.wholesalePrice.toStringAsFixed(2)} ₺',
              style: const TextStyle(color: AppColors.textGrey, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              'Stok: $maxQty adet',
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey),
            ),
            const SizedBox(height: 20),
            const Text(
              'Kaç adet eklemek istiyorsunuz?',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  onPressed: quantity > 1
                      ? () => setS(() => quantity--)
                      : null,
                  icon: const Icon(Icons.remove_circle_outline),
                  color: AppColors.primary,
                ),
                Container(
                  width: 56,
                  alignment: Alignment.center,
                  child: Text(
                    '$quantity',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: quantity < maxQty
                      ? () => setS(() => quantity++)
                      : null,
                  icon: const Icon(Icons.add_circle_outline),
                  color: AppColors.primary,
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx2, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx2, true),
            child: const Text('Sepete Ekle', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    ),
  );

  if (added == true && context.mounted) {
    final ok = await context.read<CartProvider>().addItem(
      product,
      quantity: quantity,
    );
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? '$quantity adet ${product.name} siparişlere eklendi.'
              : 'Yeterli stok yok.',
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: ok ? AppColors.success : AppColors.danger,
      ),
    );
  }
}
