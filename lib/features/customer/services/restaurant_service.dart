import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datn/core/models/restaurant_model.dart';
import 'package:datn/core/models/menu_item_model.dart';

class RestaurantService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<List<RestaurantModel>> getRestaurants() {
    return _firestore.collection('restaurants').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return RestaurantModel.fromMap(doc.data(), doc.id);
      }).toList();
    });
  }

  Stream<List<MenuItemModel>> getMenu(String restaurantId) {
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
}
