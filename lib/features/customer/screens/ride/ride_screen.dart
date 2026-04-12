import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:datn/features/customer/services/wallet_service.dart';
import 'package:datn/features/customer/services/promotion_service.dart';
import 'package:datn/core/models/promotion_model.dart';
import 'package:datn/core/utils/ui_helpers.dart';
import 'package:datn/features/customer/services/local_driver_database.dart';
// import 'package:geocoding/geocoding.dart' as geo;
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:datn/features/customer/services/ride_service.dart';
import 'package:datn/features/customer/services/order_service.dart';
import 'package:datn/core/models/order_model.dart';
import 'package:datn/features/customer/screens/ride/tracking_screen.dart';
import 'package:datn/features/customer/services/goong_service.dart';
import 'package:datn/features/customer/screens/account/saved_places_screen.dart';
import 'package:datn/core/models/user_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datn/l10n/generated/app_localizations.dart';

class RideScreen extends StatefulWidget {
  final String? initialDestination;
  final String? initialPickup;

  const RideScreen({super.key, this.initialDestination, this.initialPickup});

  @override
  State<RideScreen> createState() => _RideScreenState();
}

class _RideScreenState extends State<RideScreen> {
  final MapController _mapController = MapController();
  final WalletService _walletService = WalletService();
  final PromotionService _promotionService = PromotionService();

  final TextEditingController _promoController = TextEditingController();
  PromotionModel? _appliedPromo;

  final RideService _rideService = RideService();
  final GoongService _goongService = GoongService();

  // State
  int _selectedOptionIndex = -1; // -1 means none selected
  String _selectedPaymentMethod = 'Cash'; // Default payment
  bool _isSearching = false;
  double _searchRadius = 5.0; // Searching radius in km
  List<String> _favoriteDrivers = []; // ID of favorite drivers

  // Loyalty Points (Priority 17)
  int _loyaltyPoints = 0;
  bool _useLoyaltyPoints = false;

  // Scheduled Rides (Priority 18)
  DateTime? _scheduledTime;

  // Location Data
  String _pickupLocation = "";
  String _dropoffLocation = "";
  LatLng? _pickupLatLng;
  LatLng? _dropoffLatLng;
  double _distanceKm = 0.0;
  UserModel? _currentUserData;

  // Map Data
  final List<Marker> _markers = [];
  final List<Polyline> _polylines = [];

  // Computed Ride Options
  List<RideOption> _rideOptions = [];

  static const LatLng _kInitialPosition = LatLng(
    10.7769,
    106.7009,
  ); // HCMC default

  @override
  void initState() {
    super.initState();
    _initLocation();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.id)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        setState(() {
          if (data.containsKey('favoriteDrivers')) {
            _favoriteDrivers = List<String>.from(data['favoriteDrivers']);
          }
          if (data.containsKey('loyaltyPoints')) {
            _loyaltyPoints = data['loyaltyPoints'] as int;
          }
          _currentUserData = UserModel.fromMap(data, user.id);
        });
      }
    }
  }

  Future<void> _toggleFavoriteDriver(String driverId) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    setState(() {
      if (_favoriteDrivers.contains(driverId)) {
        _favoriteDrivers.remove(driverId);
      } else {
        _favoriteDrivers.add(driverId);
      }
    });

    await FirebaseFirestore.instance.collection('users').doc(user.id).update({
      'favoriteDrivers': _favoriteDrivers,
    });
  }

  Future<void> _initLocation() async {
    // Check permissions
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        setState(() => _pickupLocation = "Location Services Disabled");
      }
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) setState(() => _pickupLocation = "Permission Denied");
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        setState(() => _pickupLocation = "Permission Denied Forever");
      }
      return;
    }

    // Get current position
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );

    _pickupLatLng = LatLng(pos.latitude, pos.longitude);

    // Reverse Geocoding (Goong) for current GPS
    try {
      final address = await _goongService.reverseGeocode(_pickupLatLng!);
      _pickupLocation = address;
    } catch (e) {
      debugPrint("Geocoding Error: $e");
      _pickupLocation = "Unknown Location";
    }

    // [PRIORITY 45 Upgrade] - Override with initialPickup if provided by AI
    if (widget.initialPickup != null && widget.initialPickup!.isNotEmpty) {
      if (mounted) {
        setState(() => _isSearching = true);
      }
      try {
        final pickupResults = await _goongService.searchPlaces(widget.initialPickup!);
        if (pickupResults.isNotEmpty) {
          final firstResult = pickupResults.first;
          final latLng = await _goongService.getPlaceDetail(firstResult.placeId);
          if (latLng != null) {
            _pickupLatLng = latLng;
            _pickupLocation = firstResult.description;
          }
        }
      } catch (e) {
        debugPrint("Error auto-routing initial pickup: $e");
      } finally {
        if (mounted) {
          setState(() => _isSearching = false);
        }
      }
    }

    if (mounted) {
      setState(() {
        _updateMarkers();
      });

      _mapController.move(_pickupLatLng!, 15);
    }

    // [PRIORITY 45] - Auto-route if initialDestination is provided from AI
    if (widget.initialDestination != null && widget.initialDestination!.isNotEmpty) {
      if (mounted) {
        setState(() {
          _isSearching = true; 
        });
      }
      
      try {
        final results = await _goongService.searchPlaces(widget.initialDestination!);
        if (results.isNotEmpty) {
          final firstResult = results.first;
          final destLatLng = await _goongService.getPlaceDetail(firstResult.placeId);
          
          if (destLatLng != null) {
            final route = await _goongService.getRoute(_pickupLatLng!, destLatLng);
            
            if (mounted) {
              setState(() {
                _dropoffLocation = firstResult.description;
                _dropoffLatLng = destLatLng;
                _selectedOptionIndex = -1;
                
                if (route != null) {
                  _distanceKm = route.distanceValue / 1000.0;
                  _rideOptions = _rideService.calculateRidePrices(_distanceKm);
                  
                  _polylines.clear();
                  _polylines.add(
                    Polyline(
                      points: PolylinePoints()
                          .decodePolyline(route.overviewPolyline)
                          .map((e) => LatLng(e.latitude, e.longitude))
                          .toList(),
                      strokeWidth: 5,
                      color: Colors.blue,
                    ),
                  );
                } else {
                  // Fallback distance calculation
                  final distanceInMeters = const Distance().as(
                    LengthUnit.Meter,
                    _pickupLatLng!,
                    destLatLng,
                  );
                  _distanceKm = distanceInMeters / 1000.0;
                  _rideOptions = _rideService.calculateRidePrices(_distanceKm);
                }
                
                _updateMarkers();
              });
            }
          }
        }
      } catch (e) {
        debugPrint("Error auto-routing initial destination: $e");
      } finally {
        if (mounted) {
          setState(() {
            _isSearching = false;
          });
        }
      }
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_pickupLocation.isEmpty) {
      _pickupLocation = AppLocalizations.of(context)!.gettingLocation;
    }
    if (_dropoffLocation.isEmpty) {
      _dropoffLocation = AppLocalizations.of(context)!.whereTo;
    }
  }

  void _updateMarkers() {
    _markers.clear();
    if (_pickupLatLng != null) {
      _markers.add(
        Marker(
          point: _pickupLatLng!,
          width: 80,
          height: 80,
          child: const Icon(Icons.location_on, size: 40, color: Colors.blue),
        ),
      );
    }
    if (_dropoffLatLng != null) {
      _markers.add(
        Marker(
          point: _dropoffLatLng!,
          width: 80,
          height: 80,
          child: const Icon(Icons.location_on, size: 40, color: Colors.red),
        ),
      );
    }
  }

  Future<void> _pickPickupLocation() async {
    final searchController = TextEditingController();
    List<GoongPlace> predictions = [];

    final result = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.enterPickupLocation,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Use Current Location Button
                    ListTile(
                      leading: const Icon(
                        Icons.my_location,
                        color: Colors.blue,
                      ),
                      title: Text(
                        AppLocalizations.of(context)!.useCurrentLocation,
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onTap: () {
                        Navigator.pop(context, "CURRENT_LOCATION");
                      },
                    ),
                    const Divider(),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(
                          context,
                        )!.enterPickupAddress,
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) async {
                        if (value.length > 2) {
                          final results = await _goongService.searchPlaces(
                            value,
                          );
                          setModalState(() {
                            predictions = results;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: predictions.length,
                        itemBuilder: (context, index) {
                          final place = predictions[index];
                          return ListTile(
                            title: Text(place.description),
                            leading: const Icon(Icons.location_on_outlined),
                            onTap: () {
                              Navigator.pop(context, place);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result == "CURRENT_LOCATION") {
      setState(() {
        _pickupLocation = AppLocalizations.of(context)!.gettingLocation;
      });
      await _initLocation(); // Refresh GPS

      // Clear routes if any
      setState(() {
        _polylines.clear();
        _dropoffLocation = AppLocalizations.of(context)!.whereTo;
        _dropoffLatLng = null;
        _rideOptions.clear();
        _selectedOptionIndex = -1;
      });
    } else if (result is GoongPlace) {
      final destLatLng = await _goongService.getPlaceDetail(result.placeId);
      if (destLatLng != null) {
        setState(() {
          _pickupLocation = result.description;
          _pickupLatLng = destLatLng;
          _updateMarkers();
          _mapController.move(_pickupLatLng!, 15);

          // Clear routes
          _polylines.clear();
          _dropoffLocation = AppLocalizations.of(context)!.whereTo;
          _dropoffLatLng = null;
          _rideOptions.clear();
          _selectedOptionIndex = -1;
        });
      }
    }
  }

  Future<void> _pickLocation() async {
    final searchController = TextEditingController();
    List<GoongPlace> predictions = [];

    // Custom Bottom Sheet for Goong Search
    final result = await showModalBottomSheet<GoongPlace>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.7,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      AppLocalizations.of(context)!.enterDestination,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: AppLocalizations.of(
                          context,
                        )!.enterPickupAddress,
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onChanged: (value) async {
                        if (value.length > 2) {
                          final results = await _goongService.searchPlaces(
                            value,
                          );
                          setModalState(() {
                            predictions = results;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        itemCount: predictions.length,
                        itemBuilder: (context, index) {
                          final place = predictions[index];
                          return ListTile(
                            title: Text(place.description),
                            leading: const Icon(Icons.location_on_outlined),
                            onTap: () {
                              Navigator.pop(context, place);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (result != null && _pickupLatLng != null) {
      // Get Details from Goong
      final destLatLng = await _goongService.getPlaceDetail(result.placeId);

      if (destLatLng == null) return;

      // Calculate Route from Goong
      final route = await _goongService.getRoute(_pickupLatLng!, destLatLng);

      if (route != null) {
        setState(() {
          _dropoffLocation = result.description;
          _dropoffLatLng = destLatLng;
          _distanceKm = route.distanceValue / 1000.0;
          _selectedOptionIndex = -1; // Reset selection
          _rideOptions = _rideService.calculateRidePrices(_distanceKm);
          _updateMarkers();

          // Draw Polyline from Goong overview_polyline
          _polylines.clear();
          _polylines.add(
            Polyline(
              points: PolylinePoints()
                  .decodePolyline(route.overviewPolyline)
                  .map((e) => LatLng(e.latitude, e.longitude))
                  .toList(),
              strokeWidth: 5,
              color: Colors.blue,
            ),
          );
        });
      } else {
        // Fallback if route fails but we have latlng
        setState(() {
          _dropoffLocation = result.description;
          _dropoffLatLng = destLatLng;
          _distanceKm =
              Geolocator.distanceBetween(
                _pickupLatLng!.latitude,
                _pickupLatLng!.longitude,
                destLatLng.latitude,
                destLatLng.longitude,
              ) /
              1000;
          _rideOptions = _rideService.calculateRidePrices(_distanceKm);
          _updateMarkers();
        });
      }

      // Fit bounds
      _fitBounds();
    }
  }

  void _fitBounds() {
    if (_pickupLatLng == null || _dropoffLatLng == null) return;

    var bounds = LatLngBounds(_pickupLatLng!, _dropoffLatLng!);

    // Expand bounds slightly for better view
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
    );
  }

  Future<void> _handleSavedPlaceSelection(String label) async {
    if (_currentUserData == null) return;
    
    final savedPlaces = _currentUserData!.savedPlaces;
    if (savedPlaces == null || !savedPlaces.containsKey(label)) {
      // Navigate to setup
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SavedPlacesScreen()),
      ).then((_) => _fetchUserData()); // Refresh data when back
      return;
    }

    final placeData = savedPlaces[label];
    if (placeData != null) {
      if (_pickupLatLng == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Vui lòng đợi lấy vị trí hiện tại')),
          );
        }
        return;
      }

      final destLatLng = LatLng(placeData['lat'], placeData['lng']);
      final route = await _goongService.getRoute(_pickupLatLng!, destLatLng);

      if (route != null) {
        setState(() {
          _dropoffLocation = placeData['address'];
          _dropoffLatLng = destLatLng;
          _distanceKm = route.distanceValue / 1000.0;
          _selectedOptionIndex = -1;
          _rideOptions = _rideService.calculateRidePrices(_distanceKm);
          _updateMarkers();

          _polylines.clear();
          _polylines.add(
            Polyline(
              points: PolylinePoints()
                  .decodePolyline(route.overviewPolyline)
                  .map((e) => LatLng(e.latitude, e.longitude))
                  .toList(),
              strokeWidth: 5,
              color: Colors.blue,
            ),
          );
        });
        _fitBounds();
      }
    }
  }

  Future<void> _startBooking() async {
    final l10n = AppLocalizations.of(context)!;
    if (_selectedOptionIndex == -1) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.pleaseSelectRideOption)));
      return;
    }

    setState(() => _isSearching = true);

    try {
      final option = _rideOptions[_selectedOptionIndex];

      // Query Local Database for drivers matching type and provider
      final allDrivers = LocalDriverDatabase.drivers
          .where(
            (d) =>
                d['type'] == option.type.name &&
                d['providerName'] == option.providerName,
          )
          .toList();

      List<Map<String, dynamic>> nearbyDrivers = [];

      for (var data in allDrivers) {
        final driverData = Map<String, dynamic>.from(data);
        final driverLat = driverData['latitude'] as double;
        final driverLng = driverData['longitude'] as double;

        final distance =
            Geolocator.distanceBetween(
              _pickupLatLng!.latitude,
              _pickupLatLng!.longitude,
              driverLat,
              driverLng,
            ) /
            1000; // in km

        if (distance <= _searchRadius) {
          // driverData['id'] is already set in the local db
          driverData['distanceKm'] = distance;
          nearbyDrivers.add(driverData);
        }
      }

      setState(() => _isSearching = false);

      if (nearbyDrivers.isEmpty) {
        if (mounted) {
          _showNoDriversBottomSheet(option);
        }
        return;
      }

      // Sort by distance ascending
      nearbyDrivers.sort((a, b) {
        // Priority 1: Favorites
        final aFav = _favoriteDrivers.contains(a['id']) ? 0 : 1;
        final bFav = _favoriteDrivers.contains(b['id']) ? 0 : 1;
        if (aFav != bFav) return aFav.compareTo(bFav);

        // Priority 2: Distance
        return (a['distanceKm'] as double).compareTo(b['distanceKm'] as double);
      });

      // Show Bottom Sheet to select a driver
      if (mounted) {
        _showDriversBottomSheet(nearbyDrivers, option);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isSearching = false);
      }
    }
  }

  void _showNoDriversBottomSheet(RideOption option) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.search_off, size: 60, color: Colors.grey),
                  const SizedBox(height: 16),
                  Text(
                    l10n.noDriversFound(_searchRadius.toStringAsFixed(0)),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(l10n.expandRadiusPrompt),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Text('${l10n.radius}:'),
                      Expanded(
                        child: Slider(
                          value: _searchRadius,
                          min: 5.0,
                          max: 30.0,
                          divisions: 5,
                          label: '${_searchRadius.toStringAsFixed(0)}km',
                          activeColor: const Color(0xFFFE724C),
                          onChanged: (value) {
                            setModalState(() {
                              _searchRadius = value;
                            });
                            setState(() {
                              _searchRadius = value;
                            });
                          },
                        ),
                      ),
                      Text('${_searchRadius.toStringAsFixed(0)}km'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _startBooking(); // Try searching again with new radius
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFE724C),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        l10n.searchAgain,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showDriversBottomSheet(
    List<Map<String, dynamic>> drivers,
    RideOption option,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        l10n.nearbyDrivers,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _showNoDriversBottomSheet(
                            option,
                          ); // Open radius settings
                        },
                        icon: const Icon(
                          Icons.settings,
                          size: 16,
                          color: Colors.grey,
                        ),
                        label: Text(
                          '${l10n.radius}: ${_searchRadius.toStringAsFixed(0)}km',
                          style: const TextStyle(color: Colors.grey),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: drivers.length,
                      itemBuilder: (context, index) {
                        final driver = drivers[index];
                        final isFavorite = _favoriteDrivers.contains(
                          driver['id'],
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          decoration: BoxDecoration(
                            color: isFavorite
                                ? Colors.orange.withValues(alpha: 0.05)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isFavorite
                                  ? Colors.orange
                                  : Colors.transparent,
                            ),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.person,
                                color: isFavorite
                                    ? Colors.orange
                                    : Colors.grey[700],
                              ),
                            ),
                            title: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${driver['name']}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    if (isFavorite) ...[
                                      const SizedBox(width: 4),
                                      const Icon(
                                        Icons.star,
                                        color: Colors.orange,
                                        size: 14,
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  '${driver['rating'].toStringAsFixed(1)} ★ (${driver['ratingCount']} đánh giá) • ${(driver['distanceKm'] as double).toStringAsFixed(1)} km',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(
                                    isFavorite
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    color: isFavorite
                                        ? Colors.red
                                        : Colors.grey,
                                  ),
                                  onPressed: () async {
                                    await _toggleFavoriteDriver(driver['id']);
                                    setModalState(
                                      () {},
                                    ); // rebuild bottom sheet
                                  },
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    Navigator.pop(
                                      context,
                                    ); // close bottom sheet
                                    _confirmBookingWithDriver(driver, option);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFFE724C),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                  ),
                                  child: const Text('Chọn'),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _pickScheduledTime() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(
        const Duration(days: 7),
      ), // Can schedule up to 7 days in advance
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFFE724C)),
          ),
          child: child!,
        );
      },
    );

    if (selectedDate == null) return;

    if (!mounted) return;

    final selectedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFFE724C)),
          ),
          child: child!,
        );
      },
    );

    if (selectedTime == null) return;

    final scheduled = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );

    if (scheduled.isBefore(now.add(const Duration(minutes: 15)))) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Thời gian hẹn phải cách hiện tại ít nhất 15 phút."),
          ),
        );
      }
      return;
    }

    setState(() {
      _scheduledTime = scheduled;
    });
  }

  Future<void> _confirmBookingWithDriver(
    Map<String, dynamic> driver,
    RideOption option,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _isSearching = true);

    try {
      double discountAmount = 0.0;
      if (_appliedPromo != null) {
        discountAmount = option.price * _appliedPromo!.discountPercentage;
        if (discountAmount > _appliedPromo!.maxDiscount) {
          discountAmount = _appliedPromo!.maxDiscount;
        }
      }

      int pointsToUse = 0;
      if (_useLoyaltyPoints && _loyaltyPoints > 0) {
        pointsToUse = _loyaltyPoints;
      }

      double finalPrice = option.price - discountAmount - pointsToUse;
      if (finalPrice < 0) {
        // Adjust points to use if it exceeds the remaining price
        pointsToUse = (option.price - discountAmount).toInt();
        finalPrice = 0;
      }

      // Create Order
      final newOrder = OrderModel(
        id: '',
        userId: '',
        merchantName: '${driver['name']} (${option.providerName})',
        merchantImage: option.type == RideType.bike
            ? '0xFFFE724C'
            : '0xFF4C72FE',
        itemsSummary: 'Trip to $_dropoffLocation (${option.estimatedTime})',
        totalPrice: finalPrice,
        status: 'Pending',
        createdAt: DateTime.now(),
        serviceType: 'Ride',
        address: _dropoffLocation,
        driverId: driver['id'],
        pickupLat: _pickupLatLng?.latitude,
        pickupLng: _pickupLatLng?.longitude,
        dropoffLat: _dropoffLatLng?.latitude,
        dropoffLng: _dropoffLatLng?.longitude,
        distance: _distanceKm,
        paymentMethod: _selectedPaymentMethod,
        usedPoints: pointsToUse,
        scheduledTime: _scheduledTime,
      );

      // Simulating a short delay if payment is an e-wallet
      if (_selectedPaymentMethod == 'MoMo' ||
          _selectedPaymentMethod == 'ZaloPay') {
        await Future.delayed(const Duration(seconds: 2));
      } else if (_selectedPaymentMethod == 'My Wallet') {
        await _walletService.deductBalance(
          finalPrice,
          'ride_payment',
          'Ride to $_dropoffLocation',
        );
      }

      final orderId = await OrderService().createOrder(newOrder);

      if (mounted) {
        if (_scheduledTime != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Đã lên lịch chuyến đi thành công!"),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context); // Màn hình chính
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.driverApproaching(driver['name'].toString())),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => TrackingScreen(orderId: orderId)),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
        setState(() => _isSearching = false);
      }
    }
  }

  Widget _buildRideOptionTile(int index, RideOption option) {
    final isSelected = _selectedOptionIndex == index;
    final isBike = option.type == RideType.bike;

    return GestureDetector(
      onTap: () => setState(() => _selectedOptionIndex = index),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFFE724C).withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFFFE724C) : Colors.grey[200]!,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isBike ? Icons.two_wheeler : Icons.directions_car,
                color: isBike ? Colors.orange : Colors.blue,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.providerName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    '${option.estimatedTime} • ${_distanceKm.toStringAsFixed(1)} km',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if ((_appliedPromo != null || _useLoyaltyPoints) && isSelected)
                  Text(
                    '${option.price.toStringAsFixed(0)}đ',
                    style: const TextStyle(
                      fontSize: 12,
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey,
                    ),
                  ),
                Builder(
                  builder: (context) {
                    double finalDisplayPrice = option.price;
                    if (isSelected) {
                      if (_appliedPromo != null) {
                        finalDisplayPrice -=
                            (option.price * _appliedPromo!.discountPercentage)
                                .clamp(0, _appliedPromo!.maxDiscount);
                      }
                      if (_useLoyaltyPoints && _loyaltyPoints > 0) {
                        finalDisplayPrice -= _loyaltyPoints;
                      }
                      if (finalDisplayPrice < 0) finalDisplayPrice = 0;
                    }
                    return Text(
                      '${finalDisplayPrice.toStringAsFixed(0)}đ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Color(0xFFFE724C),
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. Flutter Map (Goong)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _kInitialPosition,
              initialZoom: 15,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
              ),
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
                userAgentPackageName: 'com.datn.app',
                tileProvider: NetworkTileProvider(),
                errorImage: const NetworkImage(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ac/No_image_available.svg/1024px-No_image_available.svg.png',
                ), // Fallback image (PNG)
              ),
              PolylineLayer(polylines: _polylines),
              MarkerLayer(markers: _markers),
            ],
          ),

          // 2. Back Button
          Positioned(
            top: 50,
            left: 16,
            child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                ),
                child: const Icon(Icons.arrow_back, size: 20),
              ),
            ),
          ),

          // 3. Floating Address Card
          if (!_isSearching)
            Positioned(
              top: 100,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickPickupLocation,
                      child: _LocationInputRow(
                        icon: Icons.my_location,
                        color: Colors.green,
                        text: _pickupLocation,
                        isDest: false,
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Divider(height: 1, indent: 30),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickLocation,
                      child: _LocationInputRow(
                        icon: Icons.location_on,
                        color: const Color(0xFFFE724C),
                        text: _dropoffLocation,
                        isDest: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSavedPlaceButton(
                            icon: Icons.home,
                            label: 'Nhà riêng',
                            color: Colors.blue,
                            onTap: () => _handleSavedPlaceSelection('home'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildSavedPlaceButton(
                            icon: Icons.work,
                            label: 'Công ty',
                            color: Colors.orange,
                            onTap: () => _handleSavedPlaceSelection('work'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

          // 4. Bottom Sheet for Vehicle Selection
          if (!_isSearching && _rideOptions.isNotEmpty)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, -5),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "Choose a ride",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),

                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: _rideOptions.length,
                        itemBuilder: (context, index) {
                          // Allow selection
                          return _buildRideOptionTile(
                            index,
                            _rideOptions[index],
                          );
                        },
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Payment Method Selector
                    SizedBox(
                      height: 60,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildPaymentOption(
                            'Cash',
                            Icons.money,
                            Colors.green,
                          ),
                          const SizedBox(width: 8),
                          _buildPaymentOption(
                            'MoMo',
                            Icons.account_balance_wallet,
                            Colors.pink,
                          ),
                          const SizedBox(width: 8),
                          const SizedBox(width: 8),
                          _buildPaymentOption(
                            'My Wallet',
                            Icons.account_balance_wallet,
                            Colors.purple,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Promo Code Input
                    if (_selectedOptionIndex != -1)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _promoController,
                              decoration: InputDecoration(
                                hintText: 'Promo Code',
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              final code = _promoController.text.trim();
                              if (code.isEmpty) return;

                              setState(() => _isSearching = true);
                              try {
                                final option =
                                    _rideOptions[_selectedOptionIndex];
                                final promo = await _promotionService
                                    .validatePromoCode(code, option.price);
                                if (!context.mounted) return;
                                setModalState(() {
                                  _appliedPromo = promo;
                                });
                                setState(() {
                                  _appliedPromo = promo;
                                });
                                UIHelpers.showSnackBar(
                                  context,
                                  'Promo applied successfully!',
                                );
                              } catch (e) {
                                if (!context.mounted) return;
                                UIHelpers.showErrorDialog(
                                  context,
                                  'Invalid Promo',
                                  e.toString(),
                                );
                                setModalState(() {
                                  _appliedPromo = null;
                                  _promoController.clear();
                                });
                                setState(() {
                                  _appliedPromo = null;
                                  _promoController.clear();
                                });
                              } finally {
                                if (mounted) {
                                  setState(() => _isSearching = false);
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Apply'),
                          ),
                        ],
                      ),

                    if (_selectedOptionIndex != -1) const SizedBox(height: 10),

                    // Scheduled Time Selection
                    if (_selectedOptionIndex != -1)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        child: InkWell(
                          onTap: () async {
                            if (_scheduledTime == null) {
                              await _pickScheduledTime();
                              setModalState(() {});
                            } else {
                              setModalState(() {
                                _scheduledTime = null;
                              });
                              setState(() {
                                _scheduledTime = null;
                              });
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: _scheduledTime != null
                                  ? Colors.blue.withValues(alpha: 0.1)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _scheduledTime != null
                                    ? Colors.blue
                                    : Colors.grey[300]!,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.access_time_filled,
                                  color: _scheduledTime != null
                                      ? Colors.blue
                                      : Colors.grey,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _scheduledTime != null
                                        ? "Hẹn lúc: ${_scheduledTime!.hour.toString().padLeft(2, '0')}:${_scheduledTime!.minute.toString().padLeft(2, '0')} ngày ${_scheduledTime!.day}/${_scheduledTime!.month}"
                                        : "Hẹn giờ đón",
                                    style: TextStyle(
                                      fontWeight: _scheduledTime != null
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: _scheduledTime != null
                                          ? Colors.blue
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                                if (_scheduledTime != null)
                                  const Icon(
                                    Icons.close,
                                    size: 18,
                                    color: Colors.blue,
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Loyalty Points Toggle
                    if (_selectedOptionIndex != -1 && _loyaltyPoints > 0)
                      Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.amber.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.stars, color: Colors.amber),
                                const SizedBox(width: 8),
                                Text(
                                  "Dùng Xu (-$_loyaltyPoints đ)",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Switch(
                              value: _useLoyaltyPoints,
                              activeThumbColor: Colors.amber,
                              onChanged: (val) {
                                setModalState(() {
                                  _useLoyaltyPoints = val;
                                });
                                setState(() {
                                  _useLoyaltyPoints = val;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _startBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFE724C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          _selectedOptionIndex != -1
                              ? (_scheduledTime != null
                                    ? 'Lên lịch chở bằng ${_rideOptions[_selectedOptionIndex].providerName}'
                                    : 'Book ${_rideOptions[_selectedOptionIndex].providerName}')
                              : 'Select a Ride',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // 5. Searching Overlay
          if (_isSearching)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      "Finding your driver...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPaymentOption(String title, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        setModalState(() {
          _selectedPaymentMethod = title;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedPaymentMethod == title
                ? const Color(0xFFFE724C)
                : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(12),
          color: _selectedPaymentMethod == title
              ? const Color(0xFFFE724C).withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  void setModalState(VoidCallback fn) {
    if (mounted) setState(fn);
  }

  Widget _buildSavedPlaceButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationInputRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  final bool isDest;

  const _LocationInputRow({
    required this.icon,
    required this.color,
    required this.text,
    required this.isDest,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isDest && text == "Where to?"
                  ? FontWeight.normal
                  : FontWeight.bold,
              color: isDest && text == "Where to?" ? Colors.grey : (isDark ? Colors.white : Colors.black),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ],
    );
  }
}
