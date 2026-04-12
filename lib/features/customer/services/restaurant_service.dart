import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datn/core/models/restaurant_model.dart';
import 'package:datn/core/models/menu_item_model.dart';

class RestaurantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<RestaurantModel>> getRestaurants() {
    return _firestore.collection('restaurants').snapshots().map((snapshot) {
      final firestoreRestaurants = snapshot.docs.map((doc) {
        return RestaurantModel.fromMap(doc.data(), doc.id);
      }).toList();
      return [..._virtualRestaurants, ...firestoreRestaurants];
    });
  }

  Stream<List<MenuItemModel>> getMenu(String restaurantId) {
    if (restaurantId.startsWith('vr_')) {
      final menu = _virtualMenus[restaurantId] ?? [];
      return Stream.value(menu);
    }
    return _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return MenuItemModel.fromMap(doc.data(), doc.id);
          }).toList();
        });
  }

  // --- Virtual Data ---
  static final List<RestaurantModel> _virtualRestaurants = [
    RestaurantModel(
      id: 'vr_1',
      name: 'Burger Station',
      rating: 4.8,
      ratingCount: 1240,
      time: '15-25 min',
      deliveryFee: '15,000đ',
      tags: ['Burger', 'Fast Food', 'Western'],
      imageUrl: '0xFFFF9800', // Orange
    ),
    RestaurantModel(
      id: 'vr_2',
      name: 'Pizza Hut & Drinks',
      rating: 4.5,
      ratingCount: 890,
      time: '25-40 min',
      deliveryFee: 'Free',
      tags: ['Pizza', 'Italian', 'Drinks'],
      imageUrl: '0xFFF44336', // Red
    ),
    RestaurantModel(
      id: 'vr_3',
      name: 'Asian Express',
      rating: 4.7,
      ratingCount: 2100,
      time: '10-20 min',
      deliveryFee: '10,000đ',
      tags: ['Asian', 'Rice', 'Noodles'],
      imageUrl: '0xFF4CAF50', // Green
    ),
    RestaurantModel(
      id: 'vr_4',
      name: 'Taco Fiesta',
      rating: 4.3,
      ratingCount: 450,
      time: '20-35 min',
      deliveryFee: '20,000đ',
      tags: ['Mexican', 'Tacos', 'Spicy'],
      imageUrl: '0xFFE91E63', // Pink
    ),
    RestaurantModel(
      id: 'vr_5',
      name: 'Vegan Delights',
      rating: 4.9,
      ratingCount: 320,
      time: '15-30 min',
      deliveryFee: '12,000đ',
      tags: ['Vegan', 'Healthy', 'Salads'],
      imageUrl: '0xFF8BC34A', // Light Green
    ),
    RestaurantModel(
      id: 'vr_6',
      name: 'The Coffee House',
      rating: 4.6,
      ratingCount: 1540,
      time: '10-15 min',
      deliveryFee: '15,000đ',
      tags: ['Drinks', 'Coffee', 'Dessert'],
      imageUrl: '0xFF795548', // Brown
    ),
  ];

  static final Map<String, List<MenuItemModel>> _virtualMenus = {
    'vr_1': [
      MenuItemModel(
        id: 'm1',
        name: 'Classic Burger',
        description: 'Beef patty, cheese, lettuce, tomato',
        price: 65000,
        imageUrl: '0xFFFF9800',
        isAvailable: true,
      ),
      MenuItemModel(
        id: 'm2',
        name: 'Double Cheese Burger',
        description: 'Double beef, double cheese',
        price: 95000,
        imageUrl: '0xFFFF9800',
        isAvailable: true,
      ),
      MenuItemModel(
        id: 'm3',
        name: 'French Fries',
        description: 'Crispy golden fries',
        price: 35000,
        imageUrl: '0xFFFF9800',
        isAvailable: true,
      ),
    ],
    'vr_2': [
      MenuItemModel(
        id: 'm4',
        name: 'Pepperoni Pizza',
        description: 'Large pizza with pepperoni and cheese',
        price: 155000,
        imageUrl: '0xFFF44336',
        isAvailable: true,
      ),
      MenuItemModel(
        id: 'm5',
        name: 'Hawaiian Pizza',
        description: 'Ham and pineapple',
        price: 145000,
        imageUrl: '0xFFF44336',
        isAvailable: true,
      ),
      MenuItemModel(
        id: 'm6',
        name: 'Coca Cola',
        description: 'Chilled can 330ml',
        price: 20000,
        imageUrl: '0xFF000000',
        isAvailable: true,
      ),
    ],
    'vr_3': [
      MenuItemModel(
        id: 'm7',
        name: 'Pho Bo',
        description: 'Traditional Vietnamese beef noodle soup',
        price: 55000,
        imageUrl: '0xFF4CAF50',
        isAvailable: true,
      ),
      MenuItemModel(
        id: 'm8',
        name: 'Com Tam',
        description: 'Broken rice with grilled pork rib',
        price: 60000,
        imageUrl: '0xFF4CAF50',
        isAvailable: true,
      ),
    ],
    'vr_4': [
      MenuItemModel(
        id: 'm9',
        name: 'Beef Tacos',
        description: '3 crunchy shell tacos',
        price: 85000,
        imageUrl: '0xFFE91E63',
        isAvailable: true,
      ),
      MenuItemModel(
        id: 'm10',
        name: 'Chicken Burrito',
        description: 'Large burrito with chicken and beans',
        price: 95000,
        imageUrl: '0xFFE91E63',
        isAvailable: true,
      ),
    ],
    'vr_5': [
      MenuItemModel(
        id: 'm11',
        name: 'Avocado Salad',
        description: 'Fresh mixed greens with avocado',
        price: 75000,
        imageUrl: '0xFF8BC34A',
        isAvailable: true,
      ),
      MenuItemModel(
        id: 'm12',
        name: 'Vegan Bowl',
        description: 'Quinoa, tofu, roasted veggies',
        price: 90000,
        imageUrl: '0xFF8BC34A',
        isAvailable: true,
      ),
    ],
    'vr_6': [
      MenuItemModel(
        id: 'm13',
        name: 'Iced Milk Coffee',
        description: 'Traditional Vietnamese iced coffee',
        price: 35000,
        imageUrl: '0xFF795548',
        isAvailable: true,
      ),
      MenuItemModel(
        id: 'm14',
        name: 'Matcha Latte',
        description: 'Hot matcha with milk',
        price: 45000,
        imageUrl: '0xFF4CAF50',
        isAvailable: true,
      ),
      MenuItemModel(
        id: 'm15',
        name: 'Cheesecake',
        description: 'Slice of classic NY cheesecake',
        price: 55000,
        imageUrl: '0xFFFFEB3B',
        isAvailable: true,
      ),
    ],
  };
}
