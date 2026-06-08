import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datn/features/auth/screens/root_dispatcher.dart';
import 'package:datn/features/auth/services/auth_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:datn/features/chatbot/screens/ai_history_screen.dart';
import 'package:datn/core/widgets/pulsing_fab.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:datn/core/providers/theme_provider.dart';
import 'package:datn/features/driver/services/driver_service.dart';
import 'package:datn/features/driver/screens/driver_map_screen.dart';
import 'package:datn/features/driver/screens/driver_earnings_screen.dart';
import 'package:datn/features/shared/screens/partner_review_screen.dart';
import 'package:datn/features/shared/screens/settings_screen.dart';
import 'package:datn/features/shared/screens/notification_screen.dart';
import 'package:datn/core/services/notification_service.dart';
import 'package:datn/core/models/order_model.dart';
import 'package:datn/core/models/user_model.dart';
import 'package:datn/core/utils/tier_calculator.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> {
  int _currentIndex = 0;
  final DriverService _driverService = DriverService();

  @override
  void initState() {
    super.initState();
    _checkActiveOrder();
  }

  Future<void> _checkActiveOrder() async {
    try {
      final activeOrder = await _driverService.getActiveRideOrder();
      if (activeOrder != null && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => DriverMapScreen(order: activeOrder),
          ),
        );
      }
    } catch (e) {
      debugPrint("Error checking active order: $e");
    }
  }

  List<Widget> get _screens => [
    const _DriverRequestsTab(isScheduled: false),
    const _DriverRequestsTab(isScheduled: true),
    const AiHistoryScreen(role: 'driver'),
    const _DriverActivityTab(),
    _DriverProfileTab(onNavigateToHistory: () => _onTabTapped(3)),
  ];

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      floatingActionButton: PulsingFAB(
        isActive: _currentIndex == 2,
        onPressed: () {
          setState(() {
            _currentIndex = 2;
          });
        },
      ),
      floatingActionButtonLocation: const CustomFloatingActionButtonLocation(),
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavBarItem(
              0,
              Icons.local_taxi_outlined,
              Icons.local_taxi,
              'Nhận Cuốc',
            ),
            _buildNavBarItem(
              1,
              Icons.calendar_month_outlined,
              Icons.calendar_month,
              'Hẹn Giờ',
            ),
            const SizedBox(width: 48), // Gap for FAB
            _buildNavBarItem(
              3,
              Icons.history_outlined,
              Icons.history,
              'Lịch Sử',
            ),
            _buildNavBarItem(4, Icons.person_outline, Icons.person, 'Hồ Sơ'),
          ],
        ),
      ),
    );
  }

  Widget _buildNavBarItem(
    int index,
    IconData icon,
    IconData selectedIcon,
    String label,
  ) {
    final isSelected = _currentIndex == index;
    return InkWell(
      onTap: () => _onTabTapped(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSelected ? selectedIcon : icon,
            color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
          ),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Theme.of(context).primaryColor : Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _DriverRequestsTab extends StatefulWidget {
  final bool isScheduled;
  const _DriverRequestsTab({this.isScheduled = false});

  @override
  State<_DriverRequestsTab> createState() => _DriverRequestsTabState();
}

class _DriverRequestsTabState extends State<_DriverRequestsTab> {
  bool _isOnline = false;
  final DriverService _driverService = DriverService();
  LatLng? _currentLocation;

  @override
  void initState() {
    super.initState();
    _checkOnlineStatus();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _checkOnlineStatus() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('drivers').doc(user.id).get();
      if (doc.exists && mounted) {
        setState(() {
          _isOnline = doc.data()?['isOnline'] ?? false;
        });
      }
    } catch (e) {
      debugPrint("Lỗi khi kiểm tra trạng thái online: \$e");
    }
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Vui lòng bật dịch vụ định vị (GPS).')));
      }
      return false;
    }
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Quyền truy cập vị trí bị từ chối.')));
        }
        return false;
      }
    }
    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Quyền truy cập vị trí bị từ chối vĩnh viễn.')));
      }
      return false;
    }
    return true;
  }

  Future<void> _getCurrentLocation() async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    final pos = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentLocation = LatLng(pos.latitude, pos.longitude);
      });
      // Nếu đang online thì cập nhật vị trí mới lên server
      if (_isOnline) {
        _driverService.updateLocation(_currentLocation!);
      }
    }
  }

  void _toggleOnline(bool val) async {
    if (val && _currentLocation == null) {
      await _getCurrentLocation();
      if (_currentLocation == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Không thể lấy vị trí hiện tại, vui lòng thử lại.')));
        }
        return;
      }
    }

    setState(() => _isOnline = val);

    if (val) {
      await _driverService.goOnline(_currentLocation!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Chế độ trực tuyến BẬT. Đang tìm chuyến..."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } else {
      await _driverService.goOffline();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Bạn đã TẮT chế độ trực tiếp."),
            backgroundColor: Colors.grey,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isScheduled ? 'Chuyến Hẹn Giờ' : 'Nhận Chuyến',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Row(
            children: [
              Text(
                _isOnline ? 'Online' : 'Offline',
                style: TextStyle(
                  color: _isOnline ? Colors.green : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Switch(
                value: _isOnline,
                onChanged: _toggleOnline,
                activeThumbColor: Colors.green,
              ),
            ],
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
                        builder: (_) => NotificationScreen(userId: user.id),
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
      body: !_isOnline
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.directions_car_filled,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Bạn đang Ngoại Tuyến",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text("Bật trực tuyến để nhận các chuyến đi mới."),
                ],
              ),
            )
          : StreamBuilder<List<OrderModel>>(
              stream: _driverService.getPendingRideRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text("Đã xảy ra lỗi: ${snapshot.error}"),
                  );
                }

                var requests = snapshot.data ?? [];

                // Lọc cuốc xe
                requests = requests.where((order) {
                  // Phân luồng hẹn giờ vs Gọi ngay
                  if (widget.isScheduled) {
                    if (order.scheduledTime == null) return false;
                  } else {
                    if (order.scheduledTime != null) return false;
                  }

                  final user = Supabase.instance.client.auth.currentUser;
                  
                  // Lọc bỏ những cuốc xe tài xế này đã từ chối
                  if (order.declinedDrivers != null && order.declinedDrivers!.contains(user?.id)) {
                    return false;
                  }

                  // Nếu cuốc xe đã được gán đích danh cho một tài xế
                  if (order.driverId != null && order.driverId!.isNotEmpty) {
                    return order.driverId == user?.id;
                  }

                  // Nếu cuốc xe broadcast (chưa gán), thì kiểm tra khoảng cách
                  if (order.pickupLat == null || order.pickupLng == null || _currentLocation == null) {
                    return false;
                  }

                  final dist =
                      Geolocator.distanceBetween(
                        _currentLocation!.latitude,
                        _currentLocation!.longitude,
                        order.pickupLat!.toDouble(),
                        order.pickupLng!.toDouble(),
                      ) /
                      1000;
                  return dist <= 5.0; // bán kính 5km
                }).toList();

                if (widget.isScheduled) {
                  requests.sort(
                    (a, b) => a.scheduledTime!.compareTo(b.scheduledTime!),
                  );
                }

                if (requests.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(
                          color: Color(0xFFFE724C),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          widget.isScheduled
                              ? "Chưa có cuốc hẹn giờ tải lên."
                              : "Đang quét tìm khách hàng...",
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final order = requests[index];
                    return Card(
                      elevation: 4,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(bottom: 16),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: order.serviceType == 'Food'
                                        ? Colors.orange[50]
                                        : Colors.blue[50],
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    order.serviceType == 'Food'
                                        ? Icons.fastfood
                                        : Icons.person_pin_circle,
                                    color: order.serviceType == 'Food'
                                        ? Colors.orange
                                        : Colors.blue,
                                    size: 30,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "${order.totalPrice.toInt()} đ",
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22,
                                          color: Color(0xFFFE724C),
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        "Khoảng cách: ~${_currentLocation != null ? (Geolocator.distanceBetween(_currentLocation!.latitude, _currentLocation!.longitude, order.pickupLat!.toDouble(), order.pickupLng!.toDouble()) / 1000).toStringAsFixed(1) : '?'} km",
                                        style: const TextStyle(
                                          color: Colors.grey,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (widget.isScheduled &&
                                        order.scheduledTime != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withValues(
                                            alpha: 0.1,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            4,
                                          ),
                                        ),
                                        child: Text(
                                          "Hẹn lúc: ${order.scheduledTime!.hour.toString().padLeft(2, '0')}:${order.scheduledTime!.minute.toString().padLeft(2, '0')}\n${order.scheduledTime!.day}/${order.scheduledTime!.month}",
                                          textAlign: TextAlign.right,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blue,
                                          ),
                                        ),
                                      )
                                    else
                                      Text(
                                        "${DateTime.now().difference(order.createdAt).inMinutes} phút trước",
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 30),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 12,
                                  color: order.serviceType == 'Food'
                                      ? Colors.orange
                                      : Colors.blue,
                                ),
                                const SizedBox(width: 8),
                                 Expanded(
                                   child: Text(
                                     order.serviceType == 'Food'
                                         ? 'Điểm lấy hàng: ${order.merchantName}'
                                         : 'Điểm đón: Khách hàng',
                                     style: TextStyle(color: Colors.grey[700]),
                                   ),
                                 ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.location_on,
                                  size: 16,
                                  color: Color(0xFFFE724C),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    "Điểm đến: ${order.address}",
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Row(
                              children: [
                                Expanded(
                                  flex: 1,
                                  child: SizedBox(
                                    height: 50,
                                    child: OutlinedButton(
                                      onPressed: () async {
                                        final scaffold = ScaffoldMessenger.of(context);
                                        try {
                                          final user = Supabase.instance.client.auth.currentUser;
                                          final isTargeted = order.driverId == user?.id;
                                          await _driverService.declineRideRequest(
                                            order.id,
                                            isTargeted: isTargeted,
                                          );
                                          scaffold.showSnackBar(
                                            const SnackBar(
                                              content: Text('Đã từ chối chuyến đi này.'),
                                              backgroundColor: Colors.grey,
                                            ),
                                          );
                                        } catch (e) {
                                          scaffold.showSnackBar(
                                            SnackBar(
                                              content: Text('Lỗi: ${e.toString()}'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.red,
                                        side: const BorderSide(color: Colors.red),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text(
                                        "TỪ CHỐI",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 2,
                                  child: SizedBox(
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        final navigator = Navigator.of(context);
                                        final scaffold = ScaffoldMessenger.of(context);
                                        try {
                                          await _driverService.acceptRideRequest(
                                            order.id,
                                          );
                                          scaffold.showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                'Chấp nhận chuyến thành công! Chuyển sang bản đồ...',
                                              ),
                                            ),
                                          );
                                          navigator.push(
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  DriverMapScreen(order: order),
                                            ),
                                          );
                                        } catch (e) {
                                          scaffold.showSnackBar(
                                            SnackBar(
                                              content: Text('Lỗi: ${e.toString()}'),
                                              backgroundColor: Colors.red,
                                            ),
                                          );
                                        }
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: const Color(0xFFFE724C),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text(
                                        "CHẤP NHẬN",
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
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
                );
              },
            ),
    );
  }
}

class _DriverActivityTab extends StatelessWidget {
  const _DriverActivityTab();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lịch Sử Hoạt Động')),
      body: Column(
        children: [
          // Earnings Card
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const DriverEarningsScreen(),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFE724C), Color(0xFFFF9A7A)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFE724C).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: const BoxDecoration(
                        color: Colors.white24,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.bar_chart,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Thu Nhập Của Tôi",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            "Xem thống kê và biểu đồ doanh thu",
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Gần đây",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<OrderModel>>(
              stream: DriverService().getCompletedOrdersStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFFE724C)),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(
                    child: Text("Chưa có chuyến đi nào hoàn thành."),
                  );
                }
                final orders = snapshot.data!;
                return ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    final date = order.createdAt;
                    final dateStr =
                        '${date.day}/${date.month} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';

                    return ListTile(
                      leading: const Icon(
                        Icons.check_circle,
                        color: Colors.green,
                      ),
                      title: Text("Cuốc xe #${order.id.substring(0, 5)}"),
                      subtitle: Text(
                        "Hoàn thành • ${NumberFormat.currency(locale: 'vi_VN', symbol: 'đ').format(order.totalPrice)}",
                      ),
                      trailing: Text(dateStr),
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

class _DriverProfileTab extends StatelessWidget {
  final VoidCallback onNavigateToHistory;

  const _DriverProfileTab({required this.onNavigateToHistory});

  List<Color> _getTierColors(String tier) {
    switch (tier) {
      case TierCalculator.platinum:
        return [const Color(0xFF3E4153), const Color(0xFF191A23)];
      case TierCalculator.gold:
        return [const Color(0xFFFFD700), const Color(0xFFFFA500)];
      case TierCalculator.silver:
        return [const Color(0xFFC0C0C0), const Color(0xFF808080)];
      case TierCalculator.bronze:
      default:
        return [const Color(0xFFCD7F32), const Color(0xFFA0522D)];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Hồ sơ Tài xế',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<UserModel?>(
        future: AuthService().getCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Không thể tải thông tin tài xế"));
          }

          final driver = snapshot.data!;
          final tierColors = _getTierColors(driver.tier);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Avatar
                const CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(
                    'https://ui-avatars.com/api/?name=Driver&background=2CC179&color=fff',
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  driver.uid.length > 5
                      ? "Tài xế ${driver.uid.substring(0, 5)}"
                      : "Thay tên tại đây", // Ideally driver.name
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(driver.email, style: const TextStyle(color: Colors.grey)),
                const SizedBox(height: 24),

                // Tier and Rating Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: tierColors,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: tierColors.first.withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Hạng ${driver.tier}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          const Icon(
                            Icons.workspace_premium,
                            color: Colors.white,
                            size: 28,
                          ),
                        ],
                      ),
                      const Divider(color: Colors.white38, height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            "Chuyến đi",
                            "${driver.completedRides}",
                          ),
                          _buildStatItem(
                            "Đánh giá",
                            "${driver.rating.toStringAsFixed(1)} ★",
                            subtitle: "(${driver.ratingCount} lượt)",
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Logical Settings
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text("Lịch sử chuyến đi"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: onNavigateToHistory,
                ),
                ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: const Text("Ví thu nhập"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DriverEarningsScreen(),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.star_rate_outlined),
                  title: const Text("Đánh giá & Phản hồi"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    final user = Supabase.instance.client.auth.currentUser;
                    if (user != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PartnerReviewScreen(
                            userId: user.id,
                            isDriver: true,
                          ),
                        ),
                      );
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings_outlined),
                  title: const Text("Cài đặt"),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                Consumer(
                  builder: (context, ref, child) {
                    final themeMode = ref.watch(themeProvider);
                    final isDark = themeMode == ThemeMode.dark;
                    return SwitchListTile(
                      value: isDark,
                      onChanged: (val) {
                        ref.read(themeProvider.notifier).toggleTheme(val);
                      },
                      title: const Text("Chế độ tối (Dark Mode)"),
                      secondary: const Icon(Icons.dark_mode_outlined),
                      activeThumbColor: Colors.green,
                    );
                  },
                ),

                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await DriverService().goOffline();
                      await AuthService().signOut();
                      if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (_) => const RootDispatcher(),
                          ),
                          (route) => false,
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "ĐĂNG XUẤT",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(String label, String value, {String? subtitle}) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 14),
        ),
        if (subtitle != null)
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
      ],
    );
  }
}
