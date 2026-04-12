import 'package:flutter/material.dart';
import 'package:datn/features/customer/services/restaurant_service.dart';
import 'package:datn/features/customer/services/mart_service.dart';
import 'package:datn/core/models/restaurant_model.dart';
import 'package:datn/core/models/product_model.dart';

import 'package:datn/features/customer/screens/food/restaurant_detail_screen.dart';
import 'package:datn/features/customer/services/cart_service.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'Search for food or products...',
            border: InputBorder.none,
          ),
          onChanged: (value) {
            setState(() {
              _query = value.toLowerCase();
            });
          },
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFFE724C),
          unselectedLabelColor: Colors.grey,
          indicatorColor: const Color(0xFFFE724C),
          tabs: const [
            Tab(text: 'Restaurants'),
            Tab(text: 'Mart Products'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RestaurantSearchResults(query: _query),
          _ProductSearchResults(query: _query),
        ],
      ),
    );
  }
}

class _RestaurantSearchResults extends StatelessWidget {
  final String query;
  const _RestaurantSearchResults({required this.query});

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Type to search restaurants'));
    }

    return StreamBuilder<List<RestaurantModel>>(
      stream: RestaurantService().getRestaurants(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final results = snapshot.data!.where((r) {
          return r.name.toLowerCase().contains(query) ||
              r.tags.any((t) => t.toLowerCase().contains(query));
        }).toList();

        if (results.isEmpty) {
          return const Center(child: Text('No restaurants found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final restaurant = results[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(int.parse(restaurant.imageUrl)),
                child: const Icon(Icons.store, color: Colors.white),
              ),
              title: Text(restaurant.name),
              subtitle: Text(restaurant.tags.join(', ')),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RestaurantDetailScreen(
                      restaurant: restaurant,
                      imageColor: Color(int.parse(restaurant.imageUrl)),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

class _ProductSearchResults extends StatelessWidget {
  final String query;
  const _ProductSearchResults({required this.query});

  @override
  Widget build(BuildContext context) {
    if (query.isEmpty) {
      return const Center(child: Text('Type to search products'));
    }

    return StreamBuilder<List<ProductModel>>(
      stream: MartService().getProducts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final results = snapshot.data!.where((p) {
          return p.name.toLowerCase().contains(query) ||
              p.category.toLowerCase().contains(query);
        }).toList();

        if (results.isEmpty) {
          return const Center(child: Text('No products found'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: results.length,
          itemBuilder: (context, index) {
            final product = results[index];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Color(int.parse(product.imageUrl)),
                child: const Icon(Icons.shopping_bag, color: Colors.white),
              ),
              title: Text(product.name),
              subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
              trailing: IconButton(
                icon: const Icon(Icons.add_circle, color: Color(0xFFFE724C)),
                onPressed: () {
                  CartService().addToCart(
                    product,
                    'Mart',
                    'Fresh Mart',
                  ); // Simplified merchant assignment
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Added ${product.name} to cart'),
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
