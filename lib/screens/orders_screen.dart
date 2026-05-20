import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart';
import '../services/cart_provider.dart';
import '../services/firestore_service.dart';
import '../widgets/checkout_payment_dialog.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<OrderModel>> _future;
  String _search = '';
  bool _checkingOut = false;
  int _lastOrdersRevision = -1;

  static const _statusColor = {
    'beklemede': AppColors.info,
    'hazirlaniyor': AppColors.warning,
    'tamamlandi': AppColors.success,
  };
  static const _statusLabel = {
    'beklemede': 'Beklemede',
    'hazirlaniyor': 'Hazırlanıyor',
    'tamamlandi': 'Tamamlandı',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    final uid = AuthService.currentUser?.uid ?? '';
    setState(() {
      _future = FirestoreService.getUserOrders(uid);
    });
  }

  Future<void> _checkout(CartProvider cart) async {
    if (cart.items.isEmpty || _checkingOut) return;

    final payment = await showCheckoutPaymentDialog(
      context,
      orderTotal: cart.totalPrice,
    );
    if (payment == null || !mounted) return;

    setState(() => _checkingOut = true);
    final ok = await cart.completeCheckout(
      paidAmount: payment.amount,
      paymentType: payment.paymentType,
    );
    if (!mounted) return;
    setState(() => _checkingOut = false);

    if (ok) {
      _load();
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Siparişiniz oluşturuldu. Kalan bakiye: '
            '${AuthService.currentUser?.accountBalance.toStringAsFixed(2) ?? '0'} ₺',
          ),
          backgroundColor: AppColors.success,
        ),
      );
    } else {
      final msg = !AuthService.canAfford(cart.totalPrice)
          ? 'Yetersiz bakiye. Cari sekmesinden bakiye yükleyin veya tutarı kontrol edin.'
          : 'Sipariş oluşturulamadı.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  void _showDetail(BuildContext ctx, OrderModel order) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: Text('Sipariş ${order.id}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tarih: ${order.createdAt.day}.${order.createdAt.month}.${order.createdAt.year}',
              ),
              Text('Durum: ${_statusLabel[order.status] ?? order.status}'),
              const Divider(),
              const Text(
                'Ürünler:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              ...order.items.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.productName,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                      Text(
                        '${item.quantity} x ${item.unitPrice} ₺',
                        style: const TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Toplam:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${order.totalAmount.toStringAsFixed(2)} ₺',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Kapat'),
          ),
        ],
      ),
    );
  }

  Widget _pendingCartSection(CartProvider cart) {
    if (cart.items.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.warning.withValues(alpha: 0.12),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Row(
              children: [
                const Icon(Icons.shopping_cart_outlined,
                    color: AppColors.warning, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Bekleyen Sepet (${cart.totalQuantity} ürün)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDark,
                  ),
                ),
              ],
            ),
          ),
          ...cart.items.values.map(
            (ci) => ListTile(
              dense: true,
              title: Text(ci.product.name,
                  style: const TextStyle(fontSize: 13)),
              subtitle: Text(
                '${ci.product.wholesalePrice.toStringAsFixed(2)} ₺ x ${ci.quantity}',
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${ci.total.toStringAsFixed(2)} ₺',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline,
                        size: 18, color: AppColors.danger),
                    onPressed: () async {
                      await cart.removeItem(ci.product.id);
                    },
                  ),
                ],
              ),
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove, size: 16),
                    onPressed: () async {
                      await cart.decreaseItem(ci.product.id);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  Text('${ci.quantity}'),
                  IconButton(
                    icon: const Icon(Icons.add, size: 16),
                    onPressed: () async {
                      final fresh =
                          FirestoreService.getProductById(ci.product.id) ??
                              ci.product;
                      await cart.addItem(fresh, quantity: 1);
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance_wallet,
                        size: 16, color: AppColors.textGrey),
                    const SizedBox(width: 6),
                    Text(
                      'Bakiyeniz: ${(AuthService.currentUser?.accountBalance ?? 0).toStringAsFixed(2)} ₺',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textGrey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Sepet Toplamı',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text(
                      '${cart.totalPrice.toStringAsFixed(2)} ₺',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),
                    onPressed:
                        _checkingOut ? null : () => _checkout(cart),
                    icon: _checkingOut
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.payment, color: Colors.white),
                    label: Text(
                      _checkingOut
                          ? 'İşleniyor...'
                          : 'Öde ve Sipariş Ver',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBayi = AuthService.isBayi;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text(
          isBayi ? 'Siparişler & Sepet' : 'Siparişlerim',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _load,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Sipariş Ara...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (v) => setState(() => _search = v.toLowerCase()),
            ),
          ),
          Consumer<CartProvider>(
            builder: (context, cart, _) => _pendingCartSection(cart),
          ),
          Expanded(
            child: Consumer<CartProvider>(
              builder: (context, cart, _) {
                if (cart.ordersRevision != _lastOrdersRevision) {
                  _lastOrdersRevision = cart.ordersRevision;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) _load();
                  });
                }
                return FutureBuilder<List<OrderModel>>(
              key: ValueKey('orders_${cart.ordersRevision}_$_search'),
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                var orders = snap.data ?? [];
                if (_search.isNotEmpty) {
                  orders = orders
                      .where(
                        (o) =>
                            o.id.toLowerCase().contains(_search) ||
                            (_statusLabel[o.status] ?? '')
                                .toLowerCase()
                                .contains(_search),
                      )
                      .toList();
                }

                return Consumer<CartProvider>(
                  builder: (context, cart, _) {
                    if (orders.isEmpty && cart.items.isEmpty) {
                      return const Center(
                        child: Text(
                          'Henüz sipariş yok.\nÜrünler sekmesinden sepete ekleyin.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textGrey),
                        ),
                      );
                    }

                    if (orders.isEmpty) {
                      return Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            cart.items.isEmpty
                                ? 'Henüz sipariş yok.'
                                : 'Sepetiniz yukarıda görünüyor.\n'
                                    '"Öde ve Sipariş Ver" ile onaylayın.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.textGrey),
                          ),
                        ),
                      );
                    }

                    final total = orders.fold<double>(
                      0,
                      (s, o) => s + o.totalAmount,
                    );

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (cart.items.isNotEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'Geçmiş Siparişler',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                        Expanded(
                          child: ListView.builder(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: orders.length,
                            itemBuilder: (ctx, i) {
                              final o = orders[i];
                              final color =
                                  _statusColor[o.status] ?? Colors.grey;
                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.only(bottom: 10),
                                child: Padding(
                                  padding: const EdgeInsets.all(14),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Sipariş ${o.id}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${o.createdAt.day}.${o.createdAt.month}.${o.createdAt.year}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppColors.textGrey,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${o.totalAmount.toStringAsFixed(2)} ₺',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: color.withValues(
                                                alpha: 0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                color: color.withValues(
                                                  alpha: 0.4,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              _statusLabel[o.status] ??
                                                  o.status,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: color,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 8),
                                          TextButton(
                                            style: TextButton.styleFrom(
                                              padding: EdgeInsets.zero,
                                              minimumSize: Size.zero,
                                              tapTargetSize:
                                                  MaterialTapTargetSize
                                                      .shrinkWrap,
                                            ),
                                            onPressed: () =>
                                                _showDetail(context, o),
                                            child: const Text(
                                              'Detay Gör',
                                              style: TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 14,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Toplam Harcama',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              Text(
                                '${total.toStringAsFixed(2)} ₺',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
              },
            ),
          ),
        ],
      ),
    );
  }
}
