import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../models/product_model.dart';
import '../services/firestore_service.dart';
import '../services/cart_provider.dart';
import '../widgets/product_card.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({super.key});

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  static const _categories = ['', 'Makyaj', 'Cilt Bakımı', 'Saç Bakımı'];
  static const _brands = [
    '',
    "L'Oreal",
    'Maybelline',
    'Nivea',
    'The Body Shop',
    'Rimmel',
    'Garnier',
    'MAC',
    'Clinique',
  ];

  String _selectedCategory = '';
  String _selectedBrand = '';
  late Future<List<ProductModel>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    setState(() {
      _productsFuture = FirestoreService.getProducts(
        category: _selectedCategory,
        brand: _selectedBrand,
      );
    });
  }

  void _showCart(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => const _CartSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text('Ürün Kataloğu',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          Consumer<CartProvider>(
            builder: (context, cart, _) => IconButton(
              icon: Badge(
                isLabelVisible: cart.totalQuantity > 0,
                label: Text('${cart.totalQuantity}'),
                child: const Icon(Icons.shopping_cart, color: Colors.white),
              ),
              onPressed: () => _showCart(context),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Expanded(child: _dropdown('Kategori', _categories, _selectedCategory,
                    (v) => setState(() { _selectedCategory = v ?? ''; _load(); }))),
                const SizedBox(width: 10),
                Expanded(child: _dropdown('Marka', _brands, _selectedBrand,
                    (v) => setState(() { _selectedBrand = v ?? ''; _load(); }))),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ProductModel>>(
              future: _productsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final products = snapshot.data ?? [];
                if (products.isEmpty) {
                  return const Center(
                      child: Text('Ürün bulunamadı.',
                          style: TextStyle(color: AppColors.textGrey)));
                }
                return GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.68,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, i) =>
                      ProductCard(product: products[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _dropdown(String hint, List<String> items, String value,
      ValueChanged<String?> onChanged) {
    return DropdownButtonFormField<String>(
      // ignore: deprecated_member_use
      value: value,
      decoration: InputDecoration(
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      hint: Text(hint),
      items: items
          .map((e) => DropdownMenuItem(
              value: e, child: Text(e.isEmpty ? 'Tümü' : e)))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _CartSheet extends StatelessWidget {
  const _CartSheet();

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, _) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Sepetim',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary)),
            const SizedBox(height: 12),
            if (cart.items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Text('Sepetiniz boş.',
                    style: TextStyle(color: AppColors.textGrey)),
              )
            else
              ConstrainedBox(
                constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: ListView(
                  shrinkWrap: true,
                  children: cart.items.values
                      .map((ci) => ListTile(
                            dense: true,
                            title: Text(ci.product.name,
                                style: const TextStyle(fontSize: 13)),
                            subtitle: Text(
                                '${ci.product.wholesalePrice.toStringAsFixed(2)} ₺ x ${ci.quantity}'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                    '${ci.total.toStringAsFixed(2)} ₺',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary)),
                                const SizedBox(width: 4),
                                GestureDetector(
                                  onTap: () => cart.removeItem(ci.product.id),
                                  child: const Icon(Icons.close,
                                      size: 16, color: AppColors.danger),
                                ),
                              ],
                            ),
                            leading: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, size: 16),
                                  onPressed: () =>
                                      cart.decreaseItem(ci.product.id),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                                Text('${ci.quantity}'),
                                IconButton(
                                  icon: const Icon(Icons.add, size: 16),
                                  onPressed: () =>
                                      cart.addItem(ci.product),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                ),
                              ],
                            ),
                          ))
                      .toList(),
                ),
              ),
            if (cart.items.isNotEmpty) ...[
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Toplam',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  Text('${cart.totalPrice.toStringAsFixed(2)} ₺',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25)),
                  ),
                  onPressed: () async {
                    final ok = await cart.placeOrder();
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                        content: Text(ok
                            ? 'Sipariş başarıyla verildi!'
                            : 'Sipariş verilemedi.'),
                        backgroundColor:
                            ok ? AppColors.success : AppColors.danger,
                      ));
                    }
                  },
                  child: const Text('Sipariş Ver',
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
