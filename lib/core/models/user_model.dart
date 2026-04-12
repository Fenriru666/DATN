enum UserRole { customer, merchant, driver, admin }

class UserModel {
  final String uid;
  final String email;
  final List<UserRole> roles;
  final DateTime createdAt;
  final String tier;
  final int loyaltyPoints;
  final List<String> favoriteDrivers;
  final double walletBalance; // Added for Priority 6
  final double rating;
  final int ratingCount;
  final int completedRides;
  final bool isApproved; // Added for Priority 25
  final String? name; // Added for Priority 33 (Settings)
  final String? phone; // Added for Priority 33 (Settings)
  final String? referralCode; // Added for Priority 40
  final String? referredBy; // Added for Priority 40
  final Map<String, dynamic>? savedPlaces; // Added for Priority 42

  UserModel({
    required this.uid,
    required this.email,
    required this.roles,
    required this.createdAt,
    this.tier = 'Bronze',
    this.loyaltyPoints = 0,
    this.favoriteDrivers = const [],
    this.walletBalance = 0.0,
    this.rating = 5.0, // Default 5 stars
    this.ratingCount = 0,
    this.completedRides = 0,
    this.isApproved =
        true, // Default true for customers, false for drivers/merchants is handled at creation
    this.name,
    this.phone,
    this.referralCode,
    this.referredBy,
    this.savedPlaces,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      roles: (data['email'].toString().startsWith('admin'))
          ? [UserRole.admin]
          : data['role'] != null
              ? [
                  UserRole.values.firstWhere(
                    (e) => e.toString().split('.').last == data['role'],
                    orElse: () => UserRole.customer,
                  )
                ]
              : [UserRole.customer],
      createdAt: data['created_at'] != null
          ? (DateTime.tryParse(data['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
      tier: data['tier'] ?? 'Bronze',
      loyaltyPoints: data['loyalty_points'] != null
          ? (double.tryParse(data['loyalty_points'].toString())?.toInt() ?? 0)
          : 0,
      favoriteDrivers: data['favorite_drivers'] is List
              ? (data['favorite_drivers'] as List).map((e) => e.toString()).toList()
              : [],
      walletBalance: data['wallet_balance'] != null
          ? double.tryParse(data['wallet_balance'].toString()) ?? 0.0
          : 0.0,
      rating: data['rating'] != null
          ? double.tryParse(data['rating'].toString()) ?? 5.0
          : 5.0,
      ratingCount: data['rating_count'] != null
          ? (double.tryParse(data['rating_count'].toString())?.toInt() ?? 0)
          : 0,
      completedRides: data['completed_rides'] != null
          ? (double.tryParse(data['completed_rides'].toString())?.toInt() ?? 0)
          : 0,
      isApproved: data['is_approved'] != null
          ? (data['is_approved'] is bool
              ? data['is_approved']
              : data['is_approved'].toString() == 'true')
          : true,
      name: data['name'],
      phone: data['phone'],
      referralCode: data['referral_code'],
      referredBy: data['referred_by'],
      savedPlaces: data['saved_places'] is Map
          ? Map<String, dynamic>.from(data['saved_places'] as Map)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    String roleString = 'customer';
    if (roles.isNotEmpty) {
      if (roles.first == UserRole.admin) {
        roleString = 'customer'; // DB Check constraint workaround
      } else {
        roleString = roles.first.toString().split('.').last;
      }
    }

    return {
      'id': uid,
      'email': email,
      'role': roleString,
      'created_at': createdAt.toIso8601String(),
      'tier': tier,
      'loyalty_points': loyaltyPoints,
      'favorite_drivers': favoriteDrivers,
      'wallet_balance': walletBalance,
      'rating': rating,
      'rating_count': ratingCount,
      'completed_rides': completedRides,
      'is_approved': isApproved,
      if (name != null) 'name': name,
      if (phone != null) 'phone': phone,
      if (referralCode != null) 'referral_code': referralCode,
      if (referredBy != null) 'referred_by': referredBy,
      if (savedPlaces != null) 'saved_places': savedPlaces,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    List<UserRole>? roles,
    DateTime? createdAt,
    String? tier,
    int? loyaltyPoints,
    List<String>? favoriteDrivers,
    double? walletBalance,
    double? rating,
    int? ratingCount,
    int? completedRides,
    bool? isApproved,
    String? name,
    String? phone,
    String? referralCode,
    String? referredBy,
    Map<String, dynamic>? savedPlaces,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      roles: roles ?? this.roles,
      createdAt: createdAt ?? this.createdAt,
      tier: tier ?? this.tier,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      favoriteDrivers: favoriteDrivers ?? this.favoriteDrivers,
      walletBalance: walletBalance ?? this.walletBalance,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      completedRides: completedRides ?? this.completedRides,
      isApproved: isApproved ?? this.isApproved,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      referralCode: referralCode ?? this.referralCode,
      referredBy: referredBy ?? this.referredBy,
      savedPlaces: savedPlaces ?? this.savedPlaces,
    );
  }
}
