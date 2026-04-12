import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:datn/features/customer/services/goong_service.dart';

class LocationService {
  final GoongService _goongService = GoongService();

  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null; // Location services are disabled.
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return null; // Permissions are denied
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return null;
    }

    return await Geolocator.getCurrentPosition();
  }

  Future<String> getAddressFromCoordinates(double lat, double lng) async {
    try {
      // Use Goong for reverse geocoding
      return await _goongService.reverseGeocode(LatLng(lat, lng));
    } catch (e) {
      // Handle error
    }
    return "Unknown Location";
  }

  Future<double> getDistanceInKm(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) async {
    double distanceInMeters = Geolocator.distanceBetween(
      startLat,
      startLng,
      endLat,
      endLng,
    );
    return distanceInMeters / 1000;
  }

  Future<LatLng?> getCoordinatesFromAddress(String address) async {
    try {
      // Use Goong Search + Detail
      final places = await _goongService.searchPlaces(address);
      if (places.isNotEmpty) {
        return await _goongService.getPlaceDetail(places.first.placeId);
      }
    } catch (e) {
      // Handle error
    }
    return null;
  }
}
