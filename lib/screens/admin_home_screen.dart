import 'package:flutter/material.dart';
import '../constants.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'login_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: const [
          _DashboardTab(),
          _OrdersTab(),
          _UsersTab(),
          _LogsTab(),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_outlined),
              activeIcon: Icon(Icons.dashboard),
              label: 'Panel'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: 'Siparişler'),
          BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: 'Bayiler'),
          BottomNavigationBarItem(
              icon: Icon(Icons.history_outlined),
              activeIcon: Icon(Icons.history),
              label: 'Loglar'),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  Future<void> _logout(BuildContext context) async {
    await AuthService().signOut();
    if (context.mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final admin = AuthService.currentUser;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Merhaba,',
                          style: TextStyle(
                              fontSize: 14, color: AppColors.textGrey)),
                      Text(
                        admin?.companyName ?? 'Yönetici',
                        style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.admin_panel_settings,
                                size: 16, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text('Admin',
                                style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout, color: AppColors.primary),
                        onPressed: () => _logout(context),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Genel Bakış',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.3,
                children: const [
                  _StatCard(
                      title: 'Toplam Bayi',
                      value: '3',
                      icon: Icons.people,
                      color: AppColors.primary),
                  _StatCard(
                      title: 'Toplam Sipariş',
                      value: '3',
                      icon: Icons.receipt_long,
                      color: AppColors.info),
                  _StatCard(
                      title: 'Bekleyen',
                      value: '1',
                      icon: Icons.pending_actions,
                      color: AppColors.warning),
                  _StatCard(
                      title: 'Tamamlanan',
                      value: '1',
                      icon: Icons.check_circle,
                      color: AppColors.success),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Hızlı İşlemler',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
              const SizedBox(height: 14),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
                children: const [
                  _ActionCard(
                      icon: Icons.people_alt_outlined,
                      title: 'Bayileri Yönet',
                      color: AppColors.primary),
                  _ActionCard(
                      icon: Icons.receipt_outlined,
                      title: 'Siparişleri Yönet',
                      color: AppColors.info),
                  _ActionCard(
                      icon: Icons.inventory_2_outlined,
                      title: 'Ürün Ekle',
                      color: AppColors.warning),
                  _ActionCard(
                      icon: Icons.bar_chart_outlined,
                      title: 'Raporlar',
                      color: AppColors.success),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.title,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark)),
              Text(title,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textGrey)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _ActionCard(
      {required this.icon, required this.title, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 8),
                Text(title,
                    style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                    textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OrdersTab extends StatefulWidget {
  const _OrdersTab();

  @override
  State<_OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<_OrdersTab> {
  late Future<List<OrderModel>> _future;

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
    _future = FirestoreService.getAllOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Tüm Siparişler',
            style: TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<OrderModel>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final orders = snap.data ?? [];
          if (orders.isEmpty) {
            return const Center(child: Text('Sipariş bulunamadı.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: orders.length,
            itemBuilder: (ctx, i) {
              final order = orders[i];
              final color = _statusColor[order.status] ?? Colors.grey;
              final label = _statusLabel[order.status] ?? order.status;
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.id,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              '${order.totalAmount.toStringAsFixed(2)} ₺',
                              style: const TextStyle(
                                  color: AppColors.primary, fontSize: 15),
                            ),
                            Text(
                              '${order.createdAt.day.toString().padLeft(2, '0')}.${order.createdAt.month.toString().padLeft(2, '0')}.${order.createdAt.year}',
                              style: const TextStyle(
                                  color: AppColors.textGrey, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(label,
                            style: TextStyle(
                                color: color,
                                fontWeight: FontWeight.w600,
                                fontSize: 12)),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _UsersTab extends StatefulWidget {
  const _UsersTab();

  @override
  State<_UsersTab> createState() => _UsersTabState();
}

class _UsersTabState extends State<_UsersTab> {
  late Future<List<UserModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = FirestoreService.getAllUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Bayiler',
            style: TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<UserModel>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final users = snap.data ?? [];
          if (users.isEmpty) {
            return const Center(child: Text('Bayi bulunamadı.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            itemBuilder: (ctx, i) {
              final user = users[i];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor:
                        AppColors.primary.withValues(alpha: 0.1),
                    child: Text(
                      user.name.isNotEmpty
                          ? user.name[0].toUpperCase()
                          : 'K',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(
                    user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(user.email,
                          style: const TextStyle(
                              color: AppColors.textGrey, fontSize: 12)),
                      Container(
                        margin: const EdgeInsets.only(top: 3),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: (user.role == 'bayi'
                                  ? AppColors.info
                                  : AppColors.success)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user.role == 'bayi' ? 'Bayi' : 'Bireysel',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: user.role == 'bayi'
                                ? AppColors.info
                                : AppColors.success,
                          ),
                        ),
                      ),
                    ],
                  ),
                  trailing: user.role == 'bayi'
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${user.currentDebt.toStringAsFixed(0)} ₺',
                              style: TextStyle(
                                color: user.currentDebt > 0
                                    ? AppColors.danger
                                    : AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Text('Borç',
                                style: TextStyle(
                                    color: AppColors.textGrey,
                                    fontSize: 11)),
                          ],
                        )
                      : null,
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _LogsTab extends StatefulWidget {
  const _LogsTab();

  @override
  State<_LogsTab> createState() => _LogsTabState();
}

class _LogsTabState extends State<_LogsTab> {
  late Future<List<Map<String, dynamic>>> _future;

  @override
  void initState() {
    super.initState();
    _future = FirestoreService.getAllLogs();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Sistem Logları',
            style: TextStyle(
                color: AppColors.primary, fontWeight: FontWeight.bold)),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: AppColors.primary));
          }
          final logs = snap.data ?? [];
          if (logs.isEmpty) {
            return const Center(child: Text('Log bulunamadı.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (ctx, i) {
              final log = logs[i];
              final ts = log['timestamp'];
              final date = ts is DateTime
                  ? ts
                  : (ts?.toDate?.call() ?? DateTime.now());
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFF3E5F5),
                    child: Icon(Icons.info_outline,
                        color: AppColors.primary, size: 20),
                  ),
                  title: Text(log['action'] ?? '',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(log['details'] ?? '',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textGrey)),
                  trailing: Text(
                    '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}',
                    style: const TextStyle(
                        color: AppColors.textGrey, fontSize: 11),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
