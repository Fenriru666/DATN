import 'package:supabase_flutter/supabase_flutter.dart';

class AddressModel {
  final String id;
  final String name; // e.g., Home, Work
  final String fullAddress;
  final double? lat;
  final double? lng;
  final bool isDefault;

  AddressModel({
    required this.id,
    required this.name,
    required this.fullAddress,
    this.lat,
    this.lng,
    this.isDefault = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name, 
      'address': fullAddress, 
      'lat': lat,
      'lng': lng,
      'isDefault': isDefault
    };
  }

  factory AddressModel.fromMap(Map<String, dynamic> map, String id) {
    return AddressModel(
      id: id,
      name: map['name'] ?? '',
      fullAddress: map['address'] ?? map['fullAddress'] ?? '',
      lat: map['lat'] != null ? (map['lat'] as num).toDouble() : null,
      lng: map['lng'] != null ? (map['lng'] as num).toDouble() : null,
      isDefault: map['isDefault'] ?? false,
    );
  }
}

class UserAddressService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Stream<List<AddressModel>> getAddresses() {
    final user = _supabase.auth.currentUser;
    if (user == null) return const Stream.empty();

    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .map((snapshot) {
          if (snapshot.isEmpty) return [];
          final data = snapshot.first;
          final Map<String, dynamic>? savedPlaces = data['saved_places'];
          if (savedPlaces == null) return [];
          
          List<AddressModel> addresses = [];
          savedPlaces.forEach((key, value) {
            String addressStr = '';
            double? mLat;
            double? mLng;

            // Handle legacy string saving vs new Map saving
            if (value is Map) {
              addressStr = value['address']?.toString() ?? '';
              mLat = value['lat'] != null ? (value['lat'] as num).toDouble() : null;
              mLng = value['lng'] != null ? (value['lng'] as num).toDouble() : null;
            } else {
              addressStr = value.toString();
            }

            addresses.add(AddressModel(
              id: key, 
              name: key == 'home' ? 'Nhà riêng' : (key == 'work' ? 'Công ty' : key), 
              fullAddress: addressStr,
              lat: mLat,
              lng: mLng,
            ));
          });
          return addresses;
        });
  }

  Future<void> addAddress(String name, String fullAddress, {double? lat, double? lng}) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;
    
    String key = name.toLowerCase() == 'home' || name.toLowerCase() == 'nhà riêng' ? 'home' : (name.toLowerCase() == 'work' || name.toLowerCase() == 'công ty' ? 'work' : name);

    final data = await _supabase.from('users').select('saved_places').eq('id', user.id).single();
    Map<String, dynamic> savedPlaces = data['saved_places'] != null ? Map<String, dynamic>.from(data['saved_places']) : {};
    
    // Store as Map structure with lat/long
    savedPlaces[key] = {
      'address': fullAddress,
      'lat': lat,
      'lng': lng,
    };

    await _supabase.from('users').update({'saved_places': savedPlaces}).eq('id', user.id);
  }

  Future<void> deleteAddress(String addressId) async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final data = await _supabase.from('users').select('saved_places').eq('id', user.id).single();
    if (data['saved_places'] != null) {
      Map<String, dynamic> savedPlaces = Map<String, dynamic>.from(data['saved_places']);
      savedPlaces.remove(addressId);
      await _supabase.from('users').update({'saved_places': savedPlaces}).eq('id', user.id);
    }
  }
}
