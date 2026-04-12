import 'package:flutter/material.dart';
import 'package:datn/l10n/generated/app_localizations.dart';
import 'package:datn/features/customer/screens/mart/supermarket_detail_screen.dart';

class MartScreen extends StatefulWidget {
  final String? initialLocation;
  const MartScreen({super.key, this.initialLocation});

  @override
  State<MartScreen> createState() => _MartScreenState();
}

class _MartScreenState extends State<MartScreen> {
  String _searchQuery = '';
  
  final List<Map<String, dynamic>> _allSupermarkets = [
    {
      'name': 'Coopmart Nguyễn Đình Chiểu',
      'imagePath': 'assets/images/pizza.png',
      'distance': '1.2 km',
      'rating': 4.8,
    },
    {
      'name': 'Winmart+ Tuy Lý Vương',
      'imagePath': 'assets/images/burger.png',
      'distance': '0.4 km',
      'rating': 4.5,
    },
    {
      'name': 'Bách Hóa Xanh Quận 8',
      'imagePath': 'assets/images/pizza.png',
      'distance': '0.8 km',
      'rating': 4.6,
    },
    {
      'name': 'Lotte Mart Nam Sài Gòn',
      'imagePath': 'assets/images/burger.png',
      'distance': '4.5 km',
      'rating': 4.9,
    },
    {
      'name': 'Aeon Mall Tân Phú',
      'imagePath': 'assets/images/pizza.png',
      'distance': '12.0 km',
      'rating': 4.9,
    },
    {
      'name': 'Mega Market An Phú',
      'imagePath': 'assets/images/burger.png',
      'distance': '15.5 km',
      'rating': 4.7,
    },
    {
      'name': 'Emart Gò Vấp',
      'imagePath': 'assets/images/pizza.png',
      'distance': '9.2 km',
      'rating': 4.8,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: BackButton(color: Theme.of(context).textTheme.bodyLarge?.color),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.deliveryTo,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            Row(
              children: [
                Flexible(
                  child: Text(
                    widget.initialLocation ?? 'Home 1',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFE724C),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: Color(0xFFFE724C),
                  size: 16,
                ),
              ],
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banners
            SizedBox(
              height: 150,
              child: PageView(
                children: [
                  _MartBanner(
                    color: Colors.green[100]!,
                    title: 'Fresh Veggies\n50% OFF',
                  ),
                  _MartBanner(
                    color: Colors.orange[100]!,
                    title: 'Summer Drinks\nBuy 1 Get 1',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Search Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              height: 50,
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Theme.of(context).dividerColor),
              ),
              child: Row(
                children: [
                   const Icon(Icons.search, color: Colors.grey),
                   const SizedBox(width: 8),
                   Expanded(
                     child: TextField(
                       onChanged: (val) {
                         setState(() {
                           _searchQuery = val;
                         });
                       },
                       decoration: InputDecoration(
                         border: InputBorder.none,
                         hintText: l10n.searchSupermarket,
                         hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                       ),
                     ),
                   ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Categories
            SizedBox(
              height: 100,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  SizedBox(
                    width: 80,
                    child: _MartCategory(
                      icon: Icons.storefront,
                      label: l10n.convenienceStore,
                      color: Colors.green,
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: _MartCategory(
                      icon: Icons.local_grocery_store,
                      label: l10n.grocery,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: _MartCategory(
                      icon: Icons.local_pharmacy,
                      label: l10n.pharmacy,
                      color: Colors.amber,
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: _MartCategory(
                      icon: Icons.set_meal,
                      label: l10n.meat,
                      color: Colors.brown,
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: _MartCategory(
                      icon: Icons.bakery_dining,
                      label: l10n.bakery,
                      color: Colors.blue,
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: _MartCategory(
                      icon: Icons.local_drink,
                      label: l10n.beverage,
                      color: Colors.purple,
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: _MartCategory(
                      icon: Icons.apple,
                      label: l10n.fruits,
                      color: Colors.orange,
                    ),
                  ),
                  SizedBox(
                    width: 80,
                    child: _MartCategory(
                      icon: Icons.menu,
                      label: l10n.seeAll,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nearby Supermarket List
            Text(
              l10n.nearbySupermarkets,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: _allSupermarkets.where((store) {
                if (_searchQuery.isEmpty) {
                  // Only show nearby (< 3.0 km) when not searching
                  double dist = double.tryParse(store['distance'].toString().split(' ')[0]) ?? 0.0;
                  return dist <= 3.0;
                }
                return store['name'].toString().toLowerCase().contains(_searchQuery.toLowerCase());
              }).map((store) {
                return _SupermarketCard(
                  name: store['name'],
                  imagePath: store['imagePath'],
                  distance: store['distance'],
                  rating: store['rating'],
                );
              }).toList(),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFFE724C),
        child: const Icon(Icons.shopping_cart, color: Colors.white),
      ),
    );
  }
}

class _MartBanner extends StatelessWidget {
  final Color color;
  final String title;
  const _MartBanner({required this.color, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          const Icon(Icons.shopping_basket, size: 60, color: Colors.white54),
        ],
      ),
    );
  }
}

class _MartCategory extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MartCategory({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Chức năng "$label" đang được phát triển!'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SupermarketCard extends StatelessWidget {
  final String name;
  final String imagePath;
  final String distance;
  final double rating;

  const _SupermarketCard({
    required this.name,
    required this.imagePath,
    required this.distance,
    required this.rating,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SupermarketDetailScreen(
              supermarketName: name,
              rating: rating,
              distance: distance,
              imagePath: imagePath,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: const BoxDecoration(
              color: Colors.orangeAccent,
              borderRadius: BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
            ),
            child: const Center(
              child: Icon(Icons.store, color: Colors.white, size: 40),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.orange, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        rating.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.location_on, color: Colors.grey, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        distance,
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'Free Delivery',
                      style: TextStyle(color: Colors.green, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }
}
