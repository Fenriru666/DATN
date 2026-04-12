import 'package:flutter/material.dart';
import 'package:datn/features/customer/screens/food/restaurant_detail_screen.dart';
import 'package:datn/features/customer/services/restaurant_service.dart';
import 'package:datn/core/models/restaurant_model.dart';
import 'package:datn/features/customer/screens/location/location_selection_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:datn/l10n/generated/app_localizations.dart';

class FoodScreen extends StatefulWidget {
  final String? initialLocation;
  const FoodScreen({super.key, this.initialLocation});

  @override
  State<FoodScreen> createState() => _FoodScreenState();
}

class _FoodScreenState extends State<FoodScreen> {
  late String _address;
  LatLng? _currentLatLng;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _address = widget.initialLocation ?? "Home 1";
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LocationSelectionScreen(initialPosition: _currentLatLng),
      ),
    );

    if (result != null && result is Map) {
      setState(() {
        _address = result['address'];
        _currentLatLng = result['latlng'];
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final RestaurantService restaurantService = RestaurantService();
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        leading: BackButton(color: Theme.of(context).iconTheme.color),
        title: GestureDetector(
          onTap: _pickLocation,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.currentLocation,
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _address,
                      style: const TextStyle(
                        color: Color(0xFFFE724C),
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: Color(0xFFFE724C),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
        elevation: 0,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              // Dynamic Search Bar
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchPlaceholder,
                    hintStyle: TextStyle(color: Colors.grey[400]),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: Color(0xFFFE724C),
                    ),
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFE724C),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.tune,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Promotional Banner
              SizedBox(
                height: 150,
                child: PageView(
                  controller: PageController(viewportFraction: 0.95),
                  padEnds: false,
                  children: [
                    _buildPromoBanner(
                      title: l10n.promoFreeDeliveryTitle,
                      subtitle: l10n.promoFreeDeliverySubtitle,
                      color1: const Color(0xFFFE724C),
                      color2: const Color.fromARGB(255, 255, 148, 118),
                      icon: Icons.delivery_dining,
                    ),
                    _buildPromoBanner(
                      title: l10n.promoPizzaTitle,
                      subtitle: l10n.promoPizzaSubtitle,
                      color1: const Color(0xFF4C72FE),
                      color2: const Color.fromARGB(255, 127, 155, 255),
                      icon: Icons.local_pizza,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Categories Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.categories,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    l10n.seeAll,
                    style: TextStyle(
                      color: const Color(0xFFFE724C),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Categories Carousel
              SizedBox(
                height: 110,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  children: [
                    _CategoryItem(
                      label: l10n.foodCategoryBurger,
                      icon: Icons.lunch_dining,
                      isSelected: true,
                    ),
                    _CategoryItem(
                      label: l10n.foodCategoryPizza,
                      icon: Icons.local_pizza,
                      isSelected: false,
                    ),
                    _CategoryItem(
                      label: l10n.foodCategoryAsian,
                      icon: Icons.rice_bowl,
                      isSelected: false,
                    ),
                    _CategoryItem(
                      label: l10n.foodCategoryMexican,
                      icon: Icons.local_dining,
                      isSelected: false,
                    ),
                    _CategoryItem(
                      label: l10n.foodCategoryDrinks,
                      icon: Icons.local_drink,
                      isSelected: false,
                    ),
                    _CategoryItem(
                      label: l10n.foodCategoryVegan,
                      icon: Icons.eco,
                      isSelected: false,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Popular Restaurants Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.popularRestaurants,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    l10n.seeAll,
                    style: TextStyle(
                      color: const Color(0xFFFE724C),
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Restaurant List (StreamBuilder)
              StreamBuilder<List<RestaurantModel>>(
                stream: restaurantService.getRestaurants(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error.'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFFE724C),
                      ),
                    );
                  }

                  final restaurants = snapshot.data ?? [];

                  if (restaurants.isEmpty) {
                    return Center(
                      child: Text(
                        'No restaurants found.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    );
                  }

                  return Column(
                    children: restaurants.map((restaurant) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24.0),
                        child: _RestaurantCard(
                          restaurant: restaurant,
                          l10n: l10n,
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              // Bottom padding for FAB
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: const Color(0xFFFE724C),
        elevation: 4,
        child: const Icon(Icons.shopping_bag_outlined, color: Colors.white),
      ),
    );
  }

  Widget _buildPromoBanner({
    required String title,
    required String subtitle,
    required Color color1,
    required Color color2,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color1.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
          Icon(icon, size: 60, color: Colors.white.withValues(alpha: 0.8)),
        ],
      ),
    );
  }
}

class _CategoryItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;

  const _CategoryItem({
    required this.label,
    required this.icon,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(right: 20),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFFFE724C) : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.transparent : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
                width: 1.5,
              ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFE724C).withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
            ),
            child: Icon(
              icon,
              size: 28,
              color: isSelected ? Colors.white : (isDark ? Colors.white : Colors.black87),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? const Color(0xFFFE724C) : (isDark ? Colors.grey[400] : Colors.black54),
            ),
          ),
        ],
      ),
    );
  }
}

class _RestaurantCard extends StatelessWidget {
  final RestaurantModel restaurant;
  final AppLocalizations l10n;

  const _RestaurantCard({required this.restaurant, required this.l10n});

  @override
  Widget build(BuildContext context) {
    // Parse color safely
    Color imageColor = Colors.grey;
    try {
      if (restaurant.imageUrl.startsWith('0x')) {
        imageColor = Color(int.parse(restaurant.imageUrl));
      } else {
        imageColor = Colors.orange; // Default
      }
    } catch (e) {
      // ignore
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RestaurantDetailScreen(
              restaurant: restaurant,
              imageColor: imageColor,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Gradient Overlay
            Hero(
              tag: 'restaurant_${restaurant.id}',
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: imageColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Stack(
                  children: [
                    // Gradient overlay for premium feel
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(24),
                        ),
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.4),
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.1),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                      ),
                    ),
                    const Center(
                      child: Icon(
                        Icons.fastfood,
                        size: 60,
                        color: Colors.white60,
                      ),
                    ),
                    Positioned(
                      top: 16,
                      left: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Text(
                              l10n.promo,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFE724C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor.withValues(alpha: 0.9),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite_border,
                          size: 20,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        restaurant.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.star,
                              size: 16,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${restaurant.rating}',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              ' (${restaurant.ratingCount})',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ...restaurant.tags.map(
                        (tag) => Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[800] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              tag,
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.grey[300] : Colors.grey[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.delivery_dining,
                        size: 20,
                        color: const Color(0xFFFE724C),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        restaurant.deliveryFee,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.access_time,
                        size: 18,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        restaurant.time,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
