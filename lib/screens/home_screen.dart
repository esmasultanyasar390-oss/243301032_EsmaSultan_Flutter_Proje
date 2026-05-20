import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/order_model.dart';
import '../services/cart_provider.dart';
import 'catalog_screen.dart';
import 'orders_screen.dart';
import 'payment_screen.dart';
import 'profile_screen.dart';

/// Bayi ve bireysel kullanıcı için rol bazlı ana kabuk.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  bool get _isBayi => AuthService.isBayi;

  List<Widget> get _screens => _isBayi
      ? const [
          _BayiDashboardTab(),
          CatalogScreen(),
          OrdersScreen(),
          PaymentScreen(),
          ProfileScreen(),
        ]
      : const [
          _KullaniciDashboardTab(),
          CatalogScreen(),
          OrdersScreen(),
          ProfileScreen(),
        ];

  List<BottomNavigationBarItem> _navItems(int cartQty) {
    Widget badgeIcon(IconData outlined, IconData filled) {
      return Badge(
        isLabelVisible: cartQty > 0,
        label: Text('$cartQty'),
        child: Icon(outlined),
      );
    }

    Widget badgeIconActive(IconData outlined, IconData filled) {
      return Badge(
        isLabelVisible: cartQty > 0,
        label: Text('$cartQty'),
        child: Icon(filled),
      );
    }

    if (_isBayi) {
      return [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home_outlined),
          activeIcon: Icon(Icons.home),
          label: 'Ana Sayfa',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.shopping_bag_outlined),
          activeIcon: Icon(Icons.shopping_bag),
          label: 'Ürünler',
        ),
        BottomNavigationBarItem(
          icon: badgeIcon(Icons.receipt_long_outlined, Icons.receipt_long),
          activeIcon: badgeIconActive(Icons.receipt_long_outlined, Icons.receipt_long),
          label: 'Siparişler',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.account_balance_wallet_outlined),
          activeIcon: Icon(Icons.account_balance_wallet),
          label: 'Cari',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          activeIcon: Icon(Icons.person),
          label: 'Profil',
        ),
      ];
    }

    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.home_outlined),
        activeIcon: Icon(Icons.home),
        label: 'Ana Sayfa',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.shopping_bag_outlined),
        activeIcon: Icon(Icons.shopping_bag),
        label: 'Ürünler',
      ),
      BottomNavigationBarItem(
        icon: badgeIcon(Icons.receipt_long_outlined, Icons.receipt_long),
        activeIcon: badgeIconActive(Icons.receipt_long_outlined, Icons.receipt_long),
        label: 'Siparişler',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.person_outline),
        activeIcon: Icon(Icons.person),
        label: 'Profil',
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final screens = _screens;
    return Consumer<CartProvider>(
      builder: (context, cart, _) {
        final maxIndex = screens.length - 1;
        final index = _currentIndex.clamp(0, maxIndex);

        return Scaffold(
          body: IndexedStack(index: index, children: screens),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: index,
            onTap: (i) => setState(() => _currentIndex = i),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: Colors.grey,
            items: _navItems(cart.totalQuantity),
          ),
        );
      },
    );
  }
}

// ── Bayi ana sayfa ─────────────────────────────────────────────────────

class _BayiDashboardTab extends StatefulWidget {
  const _BayiDashboardTab();

  @override
  State<_BayiDashboardTab> createState() => _BayiDashboardTabState();
}

class _BayiDashboardTabState extends State<_BayiDashboardTab> {
  late Future<List<OrderModel>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture =
        FirestoreService.getUserOrders(AuthService.currentUser?.uid ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<List<OrderModel>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            final orders = snapshot.data ?? [];
            final pending =
                orders.where((o) => o.status == 'beklemede').length;
            final preparing =
                orders.where((o) => o.status == 'hazirlaniyor').length;
            final done =
                orders.where((o) => o.status == 'tamamlandi').length;
            final totalSpending =
                orders.fold<double>(0, (s, o) => s + o.totalAmount);
            final pendingAmount = orders
                .where((o) => o.status == 'beklemede')
                .fold<double>(0, (s, o) => s + o.totalAmount);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DashboardHeader(
                    title: user?.companyName ?? 'Bayi',
                    subtitle: user?.email ?? '',
                    badge: 'Bayi Hesabı',
                    badgeColor: AppColors.info,
                  ),
                  const SizedBox(height: 8),
                  _CreditSummaryRow(
                    accountBalance: user?.accountBalance ?? 0,
                    creditLimit: user?.creditLimit ?? 50000,
                    currentDebt: user?.currentDebt ?? 0,
                  ),
                  const SizedBox(height: 20),
                  const _SectionTitle('Sipariş Özeti'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _StatusCard('Beklemede', pending, AppColors.info),
                      const SizedBox(width: 8),
                      _StatusCard('Hazırlanıyor', preparing, AppColors.warning),
                      const SizedBox(width: 8),
                      _StatusCard('Tamamlandı', done, AppColors.success),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoCard(
                          'Toplam Harcama',
                          '${totalSpending.toStringAsFixed(2)} ₺',
                          Icons.payments_outlined,
                          AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InfoCard(
                          'Bekleyen Ödeme',
                          '${pendingAmount.toStringAsFixed(2)} ₺',
                          Icons.pending_actions,
                          AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  if (orders.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const _SectionTitle('Son Siparişler'),
                    const SizedBox(height: 10),
                    ...orders.take(3).map(_RecentOrderTile.new),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Bireysel kullanıcı ana sayfa ───────────────────────────────────────

class _KullaniciDashboardTab extends StatefulWidget {
  const _KullaniciDashboardTab();

  @override
  State<_KullaniciDashboardTab> createState() => _KullaniciDashboardTabState();
}

class _KullaniciDashboardTabState extends State<_KullaniciDashboardTab> {
  late Future<List<OrderModel>> _ordersFuture;

  @override
  void initState() {
    super.initState();
    _ordersFuture =
        FirestoreService.getUserOrders(AuthService.currentUser?.uid ?? '');
  }

  @override
  Widget build(BuildContext context) {
    final user = AuthService.currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: FutureBuilder<List<OrderModel>>(
          future: _ordersFuture,
          builder: (context, snapshot) {
            final orders = snapshot.data ?? [];
            final pending =
                orders.where((o) => o.status == 'beklemede').length;
            final preparing =
                orders.where((o) => o.status == 'hazirlaniyor').length;
            final done =
                orders.where((o) => o.status == 'tamamlandi').length;
            final totalSpending =
                orders.fold<double>(0, (s, o) => s + o.totalAmount);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _DashboardHeader(
                    title: user?.displayName.isNotEmpty == true
                        ? user!.displayName
                        : user?.email ?? 'Kullanıcı',
                    subtitle: user?.email ?? '',
                    badge: 'Bireysel Müşteri',
                    badgeColor: AppColors.success,
                  ),
                  const SizedBox(height: 20),
                  const _SectionTitle('Siparişlerim'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _StatusCard('Beklemede', pending, AppColors.info),
                      const SizedBox(width: 8),
                      _StatusCard('Hazırlanıyor', preparing, AppColors.warning),
                      const SizedBox(width: 8),
                      _StatusCard('Tamamlandı', done, AppColors.success),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _InfoCard(
                    'Toplam Alışveriş',
                    '${totalSpending.toStringAsFixed(2)} ₺',
                    Icons.shopping_bag_outlined,
                    AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.info.withValues(alpha: 0.25),
                      ),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            color: AppColors.info, size: 22),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Perakende fiyatlarla sipariş verebilirsiniz. '
                            'Cari hesap ve toptan fiyat yalnızca bayiler içindir.',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textDark,
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (orders.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    const _SectionTitle('Son Siparişler'),
                    const SizedBox(height: 10),
                    ...orders.take(3).map(_RecentOrderTile.new),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Paylaşılan bileşenler ──────────────────────────────────────────────

class _DashboardHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;

  const _DashboardHeader({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white.withValues(alpha: 0.2),
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    badge,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
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
}

class _CreditSummaryRow extends StatelessWidget {
  final double accountBalance;
  final double creditLimit;
  final double currentDebt;

  const _CreditSummaryRow({
    required this.accountBalance,
    required this.creditLimit,
    required this.currentDebt,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _miniStat(
            'Bakiye',
            '${accountBalance.toStringAsFixed(0)} ₺',
            AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _miniStat(
            'Borç',
            '${currentDebt.toStringAsFixed(0)} ₺',
            currentDebt > 0 ? AppColors.danger : AppColors.success,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _miniStat(
            'Limit',
            '${creditLimit.toStringAsFixed(0)} ₺',
            AppColors.info,
          ),
        ),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 9, color: AppColors.textGrey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: AppColors.textDark,
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusCard(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(
              '$count',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _InfoCard(this.title, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textGrey,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentOrderTile extends StatelessWidget {
  final OrderModel order;
  const _RecentOrderTile(this.order);

  @override
  Widget build(BuildContext context) {
    const statusColors = {
      'beklemede': AppColors.info,
      'hazirlaniyor': AppColors.warning,
      'tamamlandi': AppColors.success,
    };
    const statusLabels = {
      'beklemede': 'Beklemede',
      'hazirlaniyor': 'Hazırlanıyor',
      'tamamlandi': 'Tamamlandı',
    };
    final color = statusColors[order.status] ?? Colors.grey;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sipariş ${order.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${order.createdAt.day}.${order.createdAt.month}.${order.createdAt.year}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textGrey,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${order.totalAmount.toStringAsFixed(2)} ₺',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              statusLabels[order.status] ?? order.status,
              style: TextStyle(fontSize: 11, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
