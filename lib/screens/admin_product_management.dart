import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';

/// Admin paneli — ürün ekleme, düzenleme, silme.
class AdminProductManagement extends StatefulWidget {
  const AdminProductManagement({super.key});

  @override
  State<AdminProductManagement> createState() => _AdminProductManagementState();
}

class _AdminProductManagementState extends State<AdminProductManagement> {
  late Future<List<ProductModel>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _future = FirestoreService.getAllProductsAdmin();
    });
  }

  Future<void> _showProductForm({ProductModel? product}) async {
    final isEdit = product != null;
    final nameCtrl = TextEditingController(text: product?.name ?? '');
    final brandCtrl = TextEditingController(text: product?.brand ?? '');
    final categoryCtrl = TextEditingController(text: product?.category ?? 'Makyaj');
    final priceCtrl = TextEditingController(
      text: product?.wholesalePrice.toStringAsFixed(2) ?? '',
    );
    final stockCtrl = TextEditingController(
      text: '${product?.stock ?? 10}',
    );
    final imageCtrl = TextEditingController(text: product?.imageUrl ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          isEdit ? 'Ürün Düzenle' : 'Yeni Ürün Ekle',
          style: const TextStyle(color: AppColors.primary),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _field(nameCtrl, 'Ürün adı'),
              _field(brandCtrl, 'Marka'),
              _field(categoryCtrl, 'Kategori (Makyaj, Cilt Bakımı…)'),
              _field(priceCtrl, 'Toptan fiyat (₺)', isNumber: true),
              _field(stockCtrl, 'Stok adedi', isNumber: true),
              _field(imageCtrl, 'Görsel URL (opsiyonel)'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(isEdit ? 'Kaydet' : 'Ekle',
                style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (saved != true || !mounted) return;

    final price = double.tryParse(priceCtrl.text.replaceAll(',', '.'));
    final stock = int.tryParse(stockCtrl.text);
    if (nameCtrl.text.trim().isEmpty || price == null || stock == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ad, fiyat ve stok zorunludur.')),
      );
      return;
    }

    final model = ProductModel(
      id: product?.id ?? '',
      name: nameCtrl.text.trim(),
      brand: brandCtrl.text.trim(),
      category: categoryCtrl.text.trim(),
      wholesalePrice: price,
      stock: stock,
      imageUrl: imageCtrl.text.trim(),
    );

    if (isEdit) {
      await FirestoreService.updateProduct(model);
    } else {
      await FirestoreService.addProduct(model);
    }
    _reload();
  }

  Future<void> _confirmDelete(ProductModel p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ürünü Sil'),
        content: Text('${p.name} silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true) {
      await FirestoreService.deleteProduct(p.id);
      _reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Ürün Yönetimi',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
              onPressed: () => _showProductForm(),
              icon: const Icon(Icons.add, color: Colors.white, size: 18),
              label: const Text('Ürün Ekle',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Ürün, fiyat, stok ve görsel ekleyin veya silin. '
          'Müşteriler katalogda güncel listeyi görür.',
          style: TextStyle(fontSize: 12, color: AppColors.textGrey),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: FutureBuilder<List<ProductModel>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }
              final products = snap.data ?? [];
              if (products.isEmpty) {
                return const Center(
                  child: Text('Henüz ürün yok. Ürün Ekle ile başlayın.',
                      style: TextStyle(color: AppColors.textGrey)),
                );
              }
              return ListView.separated(
                itemCount: products.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) {
                  final p = products[i];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.cardBg,
                        child: p.imageUrl.isNotEmpty
                            ? ClipOval(
                                child: Image.network(
                                  p.imageUrl,
                                  width: 40,
                                  height: 40,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => const Icon(
                                    Icons.spa_outlined,
                                    color: AppColors.primary,
                                  ),
                                ),
                              )
                            : const Icon(Icons.spa_outlined,
                                color: AppColors.primary),
                      ),
                      title: Text(p.name,
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text(
                        '${p.brand} · ${p.wholesalePrice.toStringAsFixed(2)} ₺ · Stok: ${p.stock}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined,
                                color: AppColors.primary),
                            onPressed: () => _showProductForm(product: p),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline,
                                color: AppColors.danger),
                            onPressed: () => _confirmDelete(p),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _field(TextEditingController c, String label, {bool isNumber = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: c,
        keyboardType:
            isNumber ? const TextInputType.numberWithOptions(decimal: true) : null,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
