import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class DataSeeder {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> seed() async {
    try {
      await _seedMockUsersForDashboard();
      await _seedRestaurants();
      await _seedProducts();
      await _seedOrders();
      debugPrint('Data seeding completed successfully.');
    } catch (e) {
      debugPrint('Error seeding data: $e');
    }
  }

  static Future<void> _seedMockUsersForDashboard() async {
    final countSnapshot = await _firestore.collection('users').count().get();
    if ((countSnapshot.count ?? 0) > 20) return; // Already seeded

    debugPrint('Seeding large fake user data for dashboard...');

    Future<void> runBatch(
      List<Map<String, dynamic>> items,
      String prefix,
    ) async {
      int chuckSize = 400; // Firestore batch limit is 500
      for (int i = 0; i < items.length; i += chuckSize) {
        final end = (i + chuckSize < items.length)
            ? i + chuckSize
            : items.length;
        final currentChunk = items.sublist(i, end);
        final batch = _firestore.batch();
        for (int j = 0; j < currentChunk.length; j++) {
          final docRef = _firestore
              .collection('users')
              .doc('mock_${prefix}_${i + j}');
          batch.set(docRef, currentChunk[j]);
        }
        await batch.commit();
      }
    }

    // Generate 1200 Customers
    List<Map<String, dynamic>> customers = List.generate(
      1200,
      (i) => {
        'email': 'customer$i@mock.com',
        'name': 'Khách hàng $i',
        'role': 'customer',
        'roles': ['customer'],
        'isApproved': true,
        'created_at': DateTime.now()
            .subtract(Duration(days: i % 180))
            .toIso8601String(),
      },
    );

    // Generate 350 Drivers (grab, be, xanhsm)
    List<String> types = ['grab', 'be', 'xanhsm'];
    List<Map<String, dynamic>> drivers = List.generate(
      350,
      (i) => {
        'email': 'driver$i@mock.com',
        'name': 'Tài xế $i',
        'role': 'driver',
        'roles': ['driver'],
        'driver_type': types[i % types.length],
        'isApproved': i % 10 != 0, // 10% pending
        'created_at': DateTime.now()
            .subtract(Duration(days: i % 180))
            .toIso8601String(),
      },
    );

    // Generate 150 Merchants
    List<Map<String, dynamic>> merchants = List.generate(
      150,
      (i) => {
        'email': 'merchant$i@mock.com',
        'name': 'Cửa hàng $i',
        'role': 'merchant',
        'roles': ['merchant'],
        'isApproved': i % 10 != 0, // 10% pending
        'created_at': DateTime.now()
            .subtract(Duration(days: i % 180))
            .toIso8601String(),
      },
    );

    try {
      await runBatch(customers, 'cust');
      await runBatch(drivers, 'driver');
      await runBatch(merchants, 'merch');
      debugPrint('Mock Users for Dashboard seeded successfully!');
    } catch (e) {
      debugPrint('Error seeding mock users: $e');
    }
  }

  static Future<void> _seedOrders() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    final snapshot = await _firestore
        .collection('orders')
        .where('userId', isEqualTo: user.id)
        .limit(1)
        .get();

    if (snapshot.docs.isNotEmpty) return;

    // Seed some past orders
    final orders = [
      {
        'userId': user.id,
        'merchantName': 'Burger King',
        'merchantImage': '0xFF8D6E63', // Brown
        'itemsSummary': '1x Whopper, 1x Fries',
        'totalPrice': 8.49,
        'status': 'Delivered',
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 1))
            .toIso8601String(),
        'serviceType': 'Food',
        'address': '123 Seeded Street, NY',
      },
      {
        'userId': user.id,
        'merchantName': 'Fresh Mart',
        'merchantImage': '0xFF4CAF50', // Green
        'itemsSummary': 'Avocados, Milk, Bread',
        'totalPrice': 9.70,
        'status': 'Delivered',
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 3))
            .toIso8601String(),
        'serviceType': 'Mart',
        'address': '456 Mock Avenue, CA',
      },
      {
        'userId': user.id,
        'merchantName': 'GrabRide',
        'merchantImage': '0xFFFE724C', // Orange
        'itemsSummary': 'Trip to Office',
        'totalPrice': 5.00,
        'status': 'Cancelled',
        'createdAt': DateTime.now()
            .subtract(const Duration(days: 5))
            .toIso8601String(),
        'serviceType': 'Ride',
        'address': '789 Fake Blvd, TX',
      },
      // Add a pending one for demo
      {
        'userId': user.id,
        'merchantName': 'Sushi Master',
        'merchantImage': '0xFFE57373', // Red
        'itemsSummary': '2x Salmon Roll',
        'totalPrice': 17.00,
        'status': 'Pending',
        'createdAt': DateTime.now()
            .subtract(const Duration(minutes: 5))
            .toIso8601String(),
        'serviceType': 'Food',
        'address': '101 Demo Lane, FL',
      },
    ];

    for (var order in orders) {
      await _firestore.collection('orders').add(order);
    }
  }

  static Future<void> _seedRestaurants() async {
    final snapshot = await _firestore.collection('restaurants').limit(1).get();
    if (snapshot.docs.isNotEmpty) return; // Already seeded

    final restaurants = [
      {
        'name': 'Burger King',
        'rating': 4.5,
        'time': '15-20 min',
        'deliveryFee': 'Free',
        'tags': ['Burger', 'Fast Food'],
        'imageUrl': '0xFF8D6E63', // Colors.brown[300]
        'ratingCount': 120,
        'menu': [
          {
            'name': 'Whopper',
            'description': 'Flame-grilled beef patty',
            'price': 5.99,
            'imageUrl': '',
          },
          {
            'name': 'Chicken Royale',
            'description': 'Crispy chicken breast',
            'price': 4.99,
            'imageUrl': '',
          },
          {
            'name': 'Fries',
            'description': 'Golden crispy fries',
            'price': 2.50,
            'imageUrl': '',
          },
        ],
      },
      {
        'name': 'Pizza Hut',
        'rating': 4.7,
        'time': '20-30 min',
        'deliveryFee': '\$2.00',
        'tags': ['Pizza', 'Italian'],
        'imageUrl': '0xFFFFCC80', // Colors.orange[300]
        'ratingCount': 85,
        'menu': [
          {
            'name': 'Pepperoni Pizza',
            'description': 'Classic pepperoni',
            'price': 12.99,
            'imageUrl': '',
          },
          {
            'name': 'Margherita',
            'description': 'Cheese and tomato',
            'price': 10.99,
            'imageUrl': '',
          },
        ],
      },
      {
        'name': 'Sushi Master',
        'rating': 4.8,
        'time': '30-40 min',
        'deliveryFee': '\$5.00',
        'tags': ['Japanese', 'Sushi'],
        'imageUrl': '0xFFE57373', // Colors.red[300]
        'ratingCount': 200,
        'menu': [
          {
            'name': 'Salmon Roll',
            'description': 'Fresh salmon maki',
            'price': 8.50,
            'imageUrl': '',
          },
          {
            'name': 'Tuna Sashimi',
            'description': 'Raw tuna slices',
            'price': 14.00,
            'imageUrl': '',
          },
        ],
      },
    ];

    for (var data in restaurants) {
      var menu = data['menu'] as List<Map<String, dynamic>>;
      data.remove('menu');

      DocumentReference docRef = await _firestore
          .collection('restaurants')
          .add(data);
      for (var item in menu) {
        await docRef.collection('menu').add(item);
      }
    }
  }

  static Future<void> _seedProducts() async {
    final snapshot = await _firestore.collection('products').limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final products = [
      {
        'name': 'Fresh Avocados',
        'price': 4.50,
        'category': 'Fruits',
        'imageUrl': '0xFF4CAF50',
      },
      {
        'name': 'Whole Milk',
        'price': 2.00,
        'category': 'Dairy',
        'imageUrl': '0xFF2196F3',
      },
      {
        'name': 'Sliced Bread',
        'price': 3.20,
        'category': 'Bakery',
        'imageUrl': '0xFF795548',
      },
      {
        'name': 'Orange Juice',
        'price': 5.00,
        'category': 'Drinks',
        'imageUrl': '0xFFFF9800',
      },
      {
        'name': 'Bananas',
        'price': 1.50,
        'category': 'Fruits',
        'imageUrl': '0xFFFFEB3B',
      },
    ];

    for (var product in products) {
      await _firestore.collection('products').add(product);
    }
  }
}
