import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datn/features/merchant/services/merchant_service.dart';
import 'package:datn/core/models/order_model.dart';
import 'package:datn/features/merchant/screens/merchant_menu_screen.dart';
import 'package:datn/features/shared/screens/partner_review_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:datn/core/providers/theme_provider.dart';
import 'package:datn/features/shared/screens/notification_screen.dart';
import 'package:datn/core/services/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:datn/features/merchant/screens/merchant_history_screen.dart';

class MerchantDashboardScreen extends StatefulWidget {
  const MerchantDashboardScreen({super.key});

  @override
  State<MerchantDashboardScreen> createState() =>
      _MerchantDashboardScreenState();
}

class _MerchantDashboardScreenState extends State<MerchantDashboardScreen> {
  final MerchantService _merchantService = MerchantService();
  bool _isOnline = true; // Need to fetch initial state from Firestore
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _loadStoreStatus();
  }

  void _loadStoreStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(user.id)
          .get();
      if (doc.exists && mounted) {
        setState(() {
          _isOnline = doc.data()?['isOnline'] ?? true;
        });
      }
    }
  }

  void _toggleOnlineStatus(bool value) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      setState(() => _isOnline = value);
      try {
        await _merchantService.toggleStoreStatus(user.id, value);
      } catch (e) {
        if (mounted) {
          setState(() => _isOnline = !value); // Revert on failure
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi cập nhật trạng thái: $e')),
          );
        }
      }
    }
  }

  void _updateOrderStatus(OrderModel order, String newStatus) async {
    try {
      await _merchantService.updateOrderStatus(order.id, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã cập nhật đơn hàng thành: $newStatus'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  void _showCancelDialog(OrderModel order) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Lý do từ chối'),
          content: const Text(
            'Khách hàng sẽ nhận được thông báo đơn hàng bị hủy. Bạn có chắc chắn không?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _updateOrderStatus(order, 'Cancelled');
              },
              child: const Text(
                'Từ chối Đơn',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: const Text('Quản Trị Cửa Hàng'),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          elevation: 0,
          actions: [
            Row(
              children: [
                Text(
                  _isOnline ? "Mở cửa" : "Đóng cửa",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _isOnline ? Colors.green : Colors.grey,
                  ),
                ),
                Switch(
                  value: _isOnline,
                  activeThumbColor: Colors.green,
                  onChanged: _toggleOnlineStatus,
                ),
                const SizedBox(width: 8),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_none),
                      onPressed: () {
                        final user = Supabase.instance.client.auth.currentUser;
                        if (user != null) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  NotificationScreen(userId: user.id),
                            ),
                          );
                        }
                      },
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: StreamBuilder<int>(
                        stream: NotificationService().streamUnreadCount(
                          Supabase.instance.client.auth.currentUser?.id ?? '',
                        ),
                        builder: (context, snapshot) {
                          final count = snapshot.data ?? 0;
                          if (count == 0) return const SizedBox();
                          return Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              count > 9 ? '9+' : count.toString(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
              ],
            ),
          ],
          bottom: const TabBar(
            labelColor: Color(0xFFFE724C),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFFE724C),
            tabs: [
              Tab(text: "Đơn Mới"),
              Tab(text: "Đang Làm"),
              Tab(text: "Chờ Lấy"),
            ],
          ),
        ),
        drawer: _buildDrawer(),
        body: StreamBuilder<List<OrderModel>>(
          stream: _merchantService.getIncomingOrders(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final orders = snapshot.data ?? [];

            final pendingOrders = orders
                .where((o) => o.status == 'Pending')
                .toList();
            final preparingOrders = orders
                .where((o) => o.status == 'Preparing')
                .toList();
            final readyOrders = orders
                .where((o) => o.status == 'Ready')
                .toList();

            return TabBarView(
              children: [
                _buildOrderList(pendingOrders, 'Pending'),
                _buildOrderList(preparingOrders, 'Preparing'),
                _buildOrderList(readyOrders, 'Ready'),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildDrawer() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          const UserAccountsDrawerHeader(
            decoration: BoxDecoration(color: Color(0xFFFE724C)),
            accountName: Text(
              'Cửa Hàng Của Mình',
              style: TextStyle(color: Colors.white),
            ),
            accountEmail: Text(
              'merchant@superapp.com',
              style: TextStyle(color: Colors.white70),
            ),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.store, color: Color(0xFFFE724C), size: 40),
            ),
          ),
          ListTile(
            leading: Icon(
              Icons.dashboard,
              color: isDark ? Colors.white : Colors.black87,
            ),
            title: Text(
              'Bảng điều khiển',
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: Icon(
              Icons.restaurant_menu,
              color: isDark ? Colors.white : Colors.black87,
            ),
            title: Text(
              'Quản lý Thực Đơn',
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MerchantMenuScreen()),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.history,
              color: isDark ? Colors.white : Colors.black87,
            ),
            title: Text(
              'Lịch sử Đơn Hàng',
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MerchantHistoryScreen(),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(
              Icons.star_rate,
              color: isDark ? Colors.white : Colors.black87,
            ),
            title: Text(
              'Đánh giá & Phản hồi',
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            ),
            onTap: () {
              Navigator.pop(context);
              final user = Supabase.instance.client.auth.currentUser;
              if (user != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) =>
                        PartnerReviewScreen(userId: user.id, isDriver: false),
                  ),
                );
              }
            },
          ),
          Consumer(
            builder: (context, ref, child) {
              final themeMode = ref.watch(themeProvider);
              final isDarkMode = themeMode == ThemeMode.dark;
              return SwitchListTile(
                value: isDarkMode,
                onChanged: (val) {
                  ref.read(themeProvider.notifier).toggleTheme(val);
                },
                title: Text(
                  "Chế độ tối (Dark Mode)",
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                secondary: Icon(
                  Icons.dark_mode_outlined,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                activeThumbColor: const Color(0xFFFE724C),
              );
            },
          ),
          const Spacer(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Đăng xuất',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              await Supabase.instance.client.auth.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/');
            },
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildOrderList(List<OrderModel> orders, String type) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 80, color: Colors.grey[300]),
            const SizedBox(height: 16),
            const Text(
              "Chưa có đơn hàng nào",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.only(bottom: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "#${order.id.substring(0, 8).toUpperCase()}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm - dd/MM').format(order.createdAt),
                      style: const TextStyle(color: Colors.grey, fontSize: 13),
                    ),
                  ],
                ),
                const Divider(),
                // Placeholder for Items
                const Text(
                  "Danh sách món:",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                // Since our OrderModel currently just has "food" generic or we need to map cart items
                // the existing OrderModel stores items dynamically, we might need a general text.
                Text(
                  "Tổng giá trị: ${currencyFormatter.format(order.totalPrice)}",
                  style: const TextStyle(
                    color: Color(0xFFFE724C),
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 12),

                if (type == 'Pending')
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _showCancelDialog(order),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                          ),
                          child: const Text('Từ Chối'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _updateOrderStatus(order, 'Preparing'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                          ),
                          child: const Text(
                            'Chuẩn Bị',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ],
                  ),
                if (type == 'Preparing')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _updateOrderStatus(order, 'Ready'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFE724C),
                      ),
                      child: const Text(
                        'Sẵn Sàng Giao (Xong)',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                if (type == 'Ready')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: null, // Wait for driver to pick up
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[300],
                      ),
                      child: const Text(
                        'Đang chờ Tài xế đến lấy',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
