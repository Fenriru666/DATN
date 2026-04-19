import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:datn/core/constants/map_constants.dart';

class GoongService {
  static const String _baseUrl = 'https://rsapi.goong.io';

  /// Search for places (AutoComplete)
  Future<List<GoongPlace>> searchPlaces(String query) async {
    if (query.isEmpty) return [];

    final encodedQuery = Uri.encodeComponent(query);
    final url =
        '$_baseUrl/Place/AutoComplete?api_key=${MapConstants.goongServiceKey}&input=$encodedQuery';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['predictions'] != null) {
          return (data['predictions'] as List)
              .map((e) => GoongPlace.fromJson(e))
              .toList();
        }
      }
    } catch (e) {
      debugPrint('Goong Search Error: $e');
    }
    return [];
  }

  Future<LatLng?> getPlaceDetail(String placeId) async {
    final encodedPlaceId = Uri.encodeComponent(placeId);
    final url =
        '$_baseUrl/Place/Detail?api_key=${MapConstants.goongServiceKey}&place_id=$encodedPlaceId';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['result'] != null && data['result']['geometry'] != null) {
          final location = data['result']['geometry']['location'];
          return LatLng(location['lat'], location['lng']);
        }
      }
    } catch (e) {
      debugPrint('Goong Detail Error: $e');
    }
    return null;
  }

  /// Get Route (Directions)
  Future<GoongRoute?> getRoute(LatLng origin, LatLng destination) async {
    final url =
        '$_baseUrl/Direction?origin=${origin.latitude},${origin.longitude}'
        '&destination=${destination.latitude},${destination.longitude}'
        '&vehicle=car&api_key=${MapConstants.goongServiceKey}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && (data['routes'] as List).isNotEmpty) {
          final route = data['routes'][0];
          final leg = route['legs'][0];

          return GoongRoute(
            distanceText: leg['distance']['text'],
            durationText: leg['duration']['text'],
            distanceValue: leg['distance']['value'], // meters
            overviewPolyline: route['overview_polyline']['points'],
          );
        }
      }
    } catch (e) {
      debugPrint('Goong Route Error: $e');
    }
    return null;
  }

  /// Reverse Geocoding (LatLng -> Address)
  Future<String> reverseGeocode(LatLng point) async {
    final url =
        '$_baseUrl/Geocode?latlng=${point.latitude},${point.longitude}&api_key=${MapConstants.goongServiceKey}';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['results'] != null && (data['results'] as List).isNotEmpty) {
          return data['results'][0]['formatted_address'] ?? "Unknown Location";
        }
      }
    } catch (e) {
      debugPrint('Goong Reverse Geocode Error: $e');
    }
    return "Unknown Location";
  }
}

class GoongPlace {
  final String placeId;
  final String description;

  GoongPlace({required this.placeId, required this.description});

  factory GoongPlace.fromJson(Map<String, dynamic> json) {
    return GoongPlace(
      placeId: json['place_id'],
      description: json['description'],
    );
  }
}

class GoongRoute {
  final String distanceText;
  final String durationText;
  final int distanceValue;
  final String overviewPolyline;

  GoongRoute({
    required this.distanceText,
    required this.durationText,
    required this.distanceValue,
    required this.overviewPolyline,
  });
}
