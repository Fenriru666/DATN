import 'package:flutter/material.dart';
import 'package:datn/features/customer/services/restaurant_service.dart';
import 'package:datn/features/customer/services/cart_service.dart';
import 'package:datn/core/models/restaurant_model.dart';
import 'package:datn/core/models/menu_item_model.dart';
import 'package:datn/features/customer/screens/cart/cart_screen.dart';

class RestaurantDetailScreen extends StatelessWidget {
  final RestaurantModel restaurant;
  final Color imageColor;

  const RestaurantDetailScreen({
    super.key,
    required this.restaurant,
    required this.imageColor,
  });

  @override
  Widget build(BuildContext context) {
    final cartService = CartService();

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200.0,
            floating: false,
            pinned: true,
            backgroundColor: imageColor,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const BackButton(color: Colors.black),
            ),
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                restaurant.name,
                style: const TextStyle(
                  color: Colors.white,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                ),
              ),
              background: Container(
                color: imageColor,
                child: const Center(
                  child: Icon(Icons.fastfood, size: 80, color: Colors.white54),
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${restaurant.name} Special',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.rating.toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '(${restaurant.ratingCount} ratings)',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: Colors.grey,
                      ),
                      Text(
                        ' ${restaurant.time}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Menu',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),

          // Real Menu List
          StreamBuilder<List<MenuItemModel>>(
            stream: RestaurantService().getMenu(restaurant.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              if (snapshot.hasError) {
                return SliverToBoxAdapter(
                  child: Center(child: Text('Error: ${snapshot.error}')),
                );
              }

              final menu = snapshot.data ?? [];
              if (menu.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Center(child: Text('No menu available')),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  return _MenuItem(
                    item: menu[index],
                    merchantId: restaurant.id,
                    merchantName: restaurant.name,
                  );
                }, childCount: menu.length),
              );
            },
          ),

          // Bottom padding for cart button
          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
      floatingActionButton: AnimatedBuilder(
        animation: cartService,
        builder: (context, _) {
          if (cartService.items.isEmpty) return const SizedBox.shrink();

          return SizedBox(
            width: MediaQuery.of(context).size.width * 0.9,
            child: FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CartScreen()),
                );
              },
              backgroundColor: const Color(0xFFFE724C),
              label: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${cartService.itemCount} Món',
                    style: const TextStyle(color: Colors.white),
                  ),
                  const SizedBox(width: 20),
                  const Text(
                    'Xem Giỏ Hàng',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    '${cartService.totalAmount.toInt()} ₫',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class _MenuItem extends StatelessWidget {
  final MenuItemModel item;
  final String merchantId;
  final String merchantName;

  const _MenuItem({
    required this.item,
    required this.merchantId,
    required this.merchantName,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child:
                item
                    .imageUrl
                    .isNotEmpty // assuming if not empty it's a color hex or url
                ? Icon(Icons.fastfood, color: Colors.orange) // simplified
                : Icon(Icons.fastfood, color: Colors.grey[400]),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.description,
                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  '${item.price.toInt()} ₫',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Color(0xFFFE724C),
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: () {
                  CartService().addToCart(item, merchantId, merchantName);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added ${item.name} to cart'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFE724C),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
