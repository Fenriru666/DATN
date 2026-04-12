import 'package:flutter_dotenv/flutter_dotenv.dart';

class MapConstants {
  // Map Key: Used for Map Tiles (Client-side)
  static String get goongMapKey => dotenv.env['GOONG_MAPTILES_KEY'] ?? '';

  // Service Key: Used for Places, Directions, Geocoding APIs (Server/Client-side)
  static String get goongServiceKey => dotenv.env['GOONG_API_KEY'] ?? '';
}
