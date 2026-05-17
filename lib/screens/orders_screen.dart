import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  late Future<List<OrderModel>> _future;
  String _search = '';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: const Text(
          'Siparişlerim',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
          Expanded(
            child: FutureBuilder<List<OrderModel>>(
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
                if (orders.isEmpty) {
                  return const Center(
                    child: Text(
                      'Sipariş bulunamadı.',
                      style: TextStyle(color: AppColors.textGrey),
                    ),
                  );
                }
                final total = orders.fold<double>(
                  0,
                  (s, o) => s + o.totalAmount,
                );
                return Column(
                  children: [
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        itemCount: orders.length,
                        itemBuilder: (ctx, i) {
                          final o = orders[i];
                          final color = _statusColor[o.status] ?? Colors.grey;
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
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(
                                            20,
                                          ),
                                          border: Border.all(
                                            color: color.withValues(alpha: 0.4),
                                          ),
                                        ),
                                        child: Text(
                                          _statusLabel[o.status] ?? o.status,
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
                                              MaterialTapTargetSize.shrinkWrap,
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
            ),
          ),
        ],
      ),
    );
  }
}
