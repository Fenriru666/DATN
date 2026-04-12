import 'package:flutter/foundation.dart';
import 'package:datn/core/models/cart_item_model.dart';
import 'package:datn/core/models/menu_item_model.dart';
import 'package:datn/core/models/product_model.dart';

class CartService extends ChangeNotifier {
  static final CartService _instance = CartService._internal();
  factory CartService() => _instance;
  CartService._internal();

  final List<CartItemModel> _items = [];

  List<CartItemModel> get items => List.unmodifiable(_items);

  double get totalAmount =>
      _items.fold(0, (sum, item) => sum + item.totalPrice);
  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  void addToCart(
    dynamic item,
    String merchantId,
    String merchantName, {
    int quantity = 1,
  }) {
    String id;
    String name;
    double price;
    String image;

    if (item is MenuItemModel) {
      id = item.name; // Using name as ID for simplicity in this scope
      name = item.name;
      price = item.price;
      image = item.imageUrl;
    } else if (item is ProductModel) {
      id = item.id;
      name = item.name;
      price = item.price;
      image = item.imageUrl;
    } else {
      debugPrint("Unknown item type added to cart");
      return;
    }

    if (_items.isNotEmpty && _items.first.merchantId != merchantId) {
      _items.clear();
      // Optional: You could show a toast here to inform the user
    }

    // Check if item exists
    final index = _items.indexWhere(
      (i) => i.id == id && i.merchantId == merchantId,
    );
    if (index >= 0) {
      _items[index] = _items[index].copyWith(
        quantity: _items[index].quantity + quantity,
      );
    } else {
      _items.add(
        CartItemModel(
          id: id,
          name: name,
          price: price,
          quantity: quantity,
          image: image,
          merchantId: merchantId,
          merchantName: merchantName,
        ),
      );
    }
    notifyListeners();
  }

  void removeFromCart(String itemId) {
    _items.removeWhere((item) => item.id == itemId);
    notifyListeners();
  }

  void updateQuantity(String itemId, int quantity) {
    final index = _items.indexWhere((item) => item.id == itemId);
    if (index >= 0) {
      if (quantity <= 0) {
        removeFromCart(itemId);
      } else {
        _items[index] = _items[index].copyWith(quantity: quantity);
        notifyListeners();
      }
    }
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
