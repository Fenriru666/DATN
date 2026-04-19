import 'package:datn/core/models/user_model.dart';
void main() {
  Map<String, dynamic> data = {
    'email': 'test@example.com',
    'created_at': '2023-01-01T00:00:00.000Z',
    'role': 'customer',
    'tier': 'Bronze',
    'loyalty_points': 100,
    'favorite_drivers': null,
    'wallet_balance': 100.0, // double
    'rating': 5, // int
    'rating_count': 10.0, // double causing crash on int?
    'completed_rides': 50,
    'is_approved': true,
  };
  try {
    UserModel user = UserModel.fromMap(data, '123');
    print("Success: ${user.toMap()}");
  } catch (e, st) {
    print("Error: $e");
    print(st);
  }
}
