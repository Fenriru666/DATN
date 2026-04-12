class RestaurantModel {
  final String id;
  final String name;
  final double rating;
  final String time;
  final String deliveryFee;
  final List<String> tags;
  final String imageUrl; // For now we might store a color hex or a URL
  final int ratingCount;
  final bool isOnline; // Defines if the merchant is currently accepting orders

  RestaurantModel({
    required this.id,
    required this.name,
    required this.rating,
    required this.time,
    required this.deliveryFee,
    required this.tags,
    required this.imageUrl,
    this.ratingCount = 0,
    this.isOnline = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rating': rating,
      'time': time,
      'deliveryFee': deliveryFee,
      'tags': tags,
      'imageUrl': imageUrl,
      'ratingCount': ratingCount,
      'isOnline': isOnline,
    };
  }

  factory RestaurantModel.fromMap(Map<String, dynamic> map, String id) {
    return RestaurantModel(
      id: id,
      name: map['name'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      time: map['time'] ?? '',
      deliveryFee: map['deliveryFee'] ?? '',
      tags: List<String>.from(map['tags'] ?? []),
      imageUrl: map['imageUrl'] ?? '',
      ratingCount: map['ratingCount'] ?? 0,
      isOnline: map['isOnline'] ?? true,
    );
  }
}
