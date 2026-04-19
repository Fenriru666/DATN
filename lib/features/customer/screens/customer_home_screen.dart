import 'package:datn/features/customer/screens/food/food_screen.dart';
import 'package:datn/features/customer/screens/ride/ride_screen.dart';
import 'package:datn/features/customer/screens/activity/activity_screen.dart';
import 'package:datn/features/customer/screens/wallet/wallet_screen.dart';
import 'package:datn/features/customer/screens/account/account_screen.dart';
import 'package:datn/features/customer/screens/mart/mart_screen.dart';
import 'package:datn/features/customer/screens/courier/courier_screen.dart';
import 'package:datn/features/customer/services/order_service.dart';
import 'package:datn/core/models/order_model.dart';
import 'package:datn/features/customer/screens/search/global_search_screen.dart';
import 'package:datn/features/chatbot/screens/ai_history_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:datn/l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:datn/core/widgets/pulsing_fab.dart';
import 'package:datn/features/customer/screens/activity/order_details_screen.dart';
import 'package:datn/features/shared/screens/notification_screen.dart';
import 'package:datn/core/services/notification_service.dart';
import 'package:datn/features/customer/screens/account/address_book_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:datn/features/customer/services/user_address_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:datn/features/customer/services/goong_service.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  final List<Widget> _screens = [
    const _HomeDashboard(),
    const ActivityScreen(),
    const AiHistoryScreen(),
    const WalletScreen(),
    const AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: _screens),
      ),
      floatingActionButton: PulsingFAB(
        isActive: _currentIndex == 2,
        onPressed: () {
          setState(() {
            _currentIndex = 2;
          });
        },
      ),
      floatingActionButtonLocation: const CustomFloatingActionButtonLocation(),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          border: Border(
            top: BorderSide(
              color: Colors.grey.withValues(alpha: 0.2),
              width: 1.0,
            ),
          ),
        ),
        child: BottomAppBar(
          shape: const CircularNotchedRectangle(),
          notchMargin: 8.0,
          color: Theme.of(context).cardColor,
          elevation: 0,
          surfaceTintColor: Colors.transparent,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavBarItem(
                0,
                Icons.home_outlined,
                Icons.home,
                AppLocalizations.of(context)!.navHome,
              ),
              _buildNavBarItem(
                1,
                Icons.history_outlined,
                Icons.history,
                AppLocalizations.of(context)!.navActivity,
              ),
              const SizedBox(width: 48), // Gap for FAB
              _buildNavBarItem(
                3,
                Icons.account_balance_wallet_outlined,
                Icons.account_balance_wallet,
                AppLocalizations.of(context)!.navWallet,
              ),
              _buildNavBarItem(
                4,
                Icons.person_outline,
                Icons.person,
                AppLocalizations.of(context)!.navAccount,
              ),
            ],
          ),
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
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedScale(
            scale: isSelected ? 1.2 : 1.0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            child: Icon(
              isSelected ? selectedIcon : icon,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 200),
            style: TextStyle(
              fontSize: 12,
              color: isSelected
                  ? Theme.of(context).colorScheme.primary
                  : Colors.grey,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
            child: Text(label),
          ),
        ],
      ),
    );
  }
}

class _HomeDashboard extends StatefulWidget {
  const _HomeDashboard();

  @override
  State<_HomeDashboard> createState() => _HomeDashboardState();
}

class _HomeDashboardState extends State<_HomeDashboard> {
  String _currentAddress = '';

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
  }

  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      try {
        final pos = await Geolocator.getCurrentPosition();
        final address = await GoongService().reverseGeocode(
          LatLng(pos.latitude, pos.longitude),
        );
        if (mounted) {
          setState(() {
            _currentAddress = address;
          });
        }
      } catch (e) {
        // Fallback handled silently on start
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_currentAddress.isEmpty) {
      _currentAddress = AppLocalizations.of(context)!.currentLocation;
    }
  }

  void _showLocationPicker() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  AppLocalizations.of(context)!.selectLocationTitle,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.my_location, color: Colors.blue),
                title: Text(
                  AppLocalizations.of(context)!.currentLocation,
                  style: TextStyle(color: isDark ? Colors.white : Colors.black),
                ),
                onTap: () async {
                  Navigator.pop(sheetContext);

                  if (mounted) {
                    setState(() {
                      _currentAddress = AppLocalizations.of(
                        context,
                      )!.gettingLocation;
                    });
                  }

                  bool serviceEnabled =
                      await Geolocator.isLocationServiceEnabled();
                  if (!serviceEnabled) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Vui lòng bật dịch vụ định vị (GPS) trong cài đặt thiết bị.',
                          ),
                        ),
                      );
                      setState(() {
                        _currentAddress = AppLocalizations.of(
                          context,
                        )!.currentLocation;
                      });
                    }
                    return;
                  }

                  LocationPermission permission =
                      await Geolocator.checkPermission();
                  if (permission == LocationPermission.denied) {
                    permission = await Geolocator.requestPermission();
                    if (permission == LocationPermission.denied ||
                        permission == LocationPermission.deniedForever) {
                      if (mounted) {
                        setState(() {
                          _currentAddress = AppLocalizations.of(
                            context,
                          )!.currentLocation;
                        });
                      }
                      return;
                    }
                  }

                  try {
                    final pos = await Geolocator.getCurrentPosition();
                    final address = await GoongService().reverseGeocode(
                      LatLng(pos.latitude, pos.longitude),
                    );
                    if (mounted) {
                      setState(() {
                        _currentAddress = address;
                      });
                    }
                  } catch (e) {
                    if (mounted) {
                      setState(() {
                        _currentAddress = AppLocalizations.of(
                          context,
                        )!.currentLocation; // Fallback
                      });
                    }
                  }
                },
              ),
              const Divider(),
              Expanded(
                child: StreamBuilder<List<AddressModel>>(
                  stream: UserAddressService().getAddresses(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final addresses = snapshot.data ?? [];

                    return ListView.builder(
                      itemCount:
                          addresses.length + 1, // +1 for "Add New Address"
                      itemBuilder: (context, index) {
                        if (index == addresses.length) {
                          return ListTile(
                            leading: const Icon(
                              Icons.add_location_alt_outlined,
                              color: Colors.grey,
                            ),
                            title: Text(
                              AppLocalizations.of(context)!.addNewAddress,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            onTap: () {
                              Navigator.pop(sheetContext);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const AddressBookScreen(),
                                ),
                              );
                            },
                          );
                        }

                        final address = addresses[index];
                        return ListTile(
                          leading: Icon(
                            address.name.toLowerCase() == 'nhà riêng' ||
                                    address.name.toLowerCase() == 'home'
                                ? Icons.home
                                : (address.name.toLowerCase() == 'công ty' ||
                                          address.name.toLowerCase() == 'work'
                                      ? Icons.work
                                      : Icons.location_on),
                            color: const Color(0xFFFE724C),
                          ),
                          title: Text(
                            address.name,
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          subtitle: Text(
                            address.fullAddress,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[600],
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              _currentAddress = address
                                  .name; // Use the name or address as you prefer
                            });
                            Navigator.pop(sheetContext);
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.currentLocation,
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                      GestureDetector(
                        onTap: _showLocationPicker,
                        child: Row(
                          children: [
                            Flexible(
                              child: Text(
                                _currentAddress,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: Color(0xFFFE724C),
                              size: 16,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    Stack(
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.notifications_none,
                            color: Theme.of(context).textTheme.bodyLarge?.color,
                            size: 28,
                          ),
                          onPressed: () {
                            final user =
                                Supabase.instance.client.auth.currentUser;
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
                              Supabase.instance.client.auth.currentUser?.id ??
                                  '',
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
                    CircleAvatar(
                      backgroundColor: Colors.grey[200],
                      child: const Icon(Icons.person, color: Colors.grey),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Bar
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const GlobalSearchScreen()),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search, color: Color(0xFFFE724C)),
                    SizedBox(width: 12),
                    Text(
                      AppLocalizations.of(context)!.searchPlaceholder,
                      style: const TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Service Row (Horizontal Scroll)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: Clip.none, // Allow shadow/hero to overflow
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ServiceItem(
                    icon: Icons.directions_car,
                    color: const Color(0xFFFE724C),
                    label: AppLocalizations.of(context)!.serviceRide,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            RideScreen(initialPickup: _currentAddress),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  _ServiceItem(
                    icon: Icons.fastfood,
                    color: const Color(0xFF2CC179),
                    label: AppLocalizations.of(context)!.serviceFood,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            FoodScreen(initialLocation: _currentAddress),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  _ServiceItem(
                    icon: Icons.local_grocery_store,
                    color: Colors.blue,
                    label: AppLocalizations.of(context)!.serviceMart,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            MartScreen(initialLocation: _currentAddress),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  _ServiceItem(
                    icon: Icons.local_shipping,
                    color: Colors.purple,
                    label: AppLocalizations.of(context)!.serviceCourier,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            CourierScreen(initialLocation: _currentAddress),
                      ),
                    ),
                  ),
                  const SizedBox(width: 20),
                  _ServiceItem(
                    icon: Icons.card_giftcard,
                    color: Colors.red,
                    label: AppLocalizations.of(context)!.serviceGift,
                    onTap: () => _showComingSoon(context),
                  ),
                  const SizedBox(width: 20),
                  _ServiceItem(
                    icon: Icons.confirmation_number,
                    color: Colors.amber,
                    label: AppLocalizations.of(context)!.serviceTickets,
                    onTap: () => _showComingSoon(context),
                  ),
                  const SizedBox(width: 20),
                  _ServiceItem(
                    icon: Icons.more_horiz,
                    color: Colors.grey,
                    label: AppLocalizations.of(context)!.serviceMore,
                    onTap: () => _showComingSoon(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Promo Banner
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  AppLocalizations.of(context)!.specialOffers,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.seeAll,
                  style: const TextStyle(color: Color(0xFFFE724C)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 140,
              child: PageView(
                controller: PageController(viewportFraction: 0.9),
                padEnds: false,
                children: [
                  _PromoCard(
                    color: Colors.blue.withValues(alpha: 0.1),
                    title: AppLocalizations.of(context)!.promo1,
                  ),
                  _PromoCard(
                    color: Colors.orange.withValues(alpha: 0.1),
                    title: AppLocalizations.of(context)!.promo2,
                  ),
                  _PromoCard(
                    color: Colors.green.withValues(alpha: 0.1),
                    title: AppLocalizations.of(context)!.promo3,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Recent Activity
            Text(
              AppLocalizations.of(context)!.recentActivity,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            StreamBuilder<OrderModel?>(
              stream: OrderService().getLatestOrder(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        AppLocalizations.of(context)!.noRecentActivity,
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ),
                  );
                }

                final order = snapshot.data!;
                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => OrderDetailsScreen(order: order),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.1),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Color(
                              int.parse(order.merchantImage),
                            ).withValues(alpha: 0.2), // Use actual color
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            order.serviceType == 'Ride'
                                ? Icons.directions_car
                                : order.serviceType == 'Mart'
                                ? Icons.local_grocery_store
                                : Icons.fastfood,
                            color: Color(int.parse(order.merchantImage)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.merchantName,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              Text(
                                order.itemsSummary,
                                style: TextStyle(
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${order.totalPrice.toStringAsFixed(0)}đ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: isDark ? Colors.white : Colors.black,
                              ),
                            ),
                            Text(
                              order.status,
                              style: TextStyle(
                                color: order.status == 'Delivered'
                                    ? Colors.green
                                    : (isDark
                                          ? Colors.grey[400]
                                          : Colors.grey[600]),
                                fontSize: 12,
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
            // Bottom padding
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Theme.of(context).cardColor,
        title: Text(
          AppLocalizations.of(context)!.comingSoonTitle,
          style: TextStyle(
            color: Theme.of(context).textTheme.titleLarge?.color,
          ),
        ),
        content: Text(
          AppLocalizations.of(context)!.comingSoonMessage,
          style: TextStyle(color: Theme.of(context).textTheme.bodyLarge?.color),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              AppLocalizations.of(context)!.ok,
              style: const TextStyle(color: Color(0xFFFE724C)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _ServiceItem({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Width calculation for 4 items approach or just fixed width
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Hero(
            tag: 'service_$label',
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(
                  20,
                ), // Soft rounded square/circle
              ),
              child: Icon(icon, color: color, size: 28),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromoCard extends StatelessWidget {
  final Color color;
  final String title;
  const _PromoCard({required this.color, required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }
}
