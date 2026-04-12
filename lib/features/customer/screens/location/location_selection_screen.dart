import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:datn/features/customer/services/goong_service.dart';

class LocationSelectionScreen extends StatefulWidget {
  final LatLng? initialPosition;

  const LocationSelectionScreen({super.key, this.initialPosition});

  @override
  State<LocationSelectionScreen> createState() =>
      _LocationSelectionScreenState();
}

class _LocationSelectionScreenState extends State<LocationSelectionScreen> {
  final MapController _mapController = MapController();
  final GoongService _goongService = GoongService();
  final TextEditingController _searchController = TextEditingController();

  LatLng _currentCenter = const LatLng(10.7769, 106.7009); // HCMC Default
  String _address = "Moving camera...";
  bool _isMoving = false;
  Timer? _debounce;
  List<GoongPlace> _predictions = [];

  @override
  void initState() {
    super.initState();
    if (widget.initialPosition != null) {
      _currentCenter = widget.initialPosition!;
    }
    _initLocation();
  }

  Future<void> _initLocation() async {
    if (widget.initialPosition != null) return; // Already set

    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    if (permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();
    if (mounted) {
      setState(() {
        _currentCenter = LatLng(pos.latitude, pos.longitude);
      });
      _mapController.move(_currentCenter, 15);
      _lookupAddress(_currentCenter);
    }
  }

  Future<void> _lookupAddress(LatLng point) async {
    try {
      final address = await _goongService.reverseGeocode(point);
      if (mounted) {
        setState(() => _address = address);
      }
    } catch (e) {
      if (mounted) setState(() => _address = "Unknown Location");
    }
  }

  void _onMapMoveEnd(dynamic event) {
    // MapEvent
    setState(() => _isMoving = false);
    _currentCenter = _mapController.camera.center;

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _lookupAddress(_currentCenter);
    });
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.length > 2) {
      final results = await _goongService.searchPlaces(query);
      setState(() {
        _predictions = results;
      });
    } else {
      setState(() => _predictions = []);
    }
  }

  Future<void> _selectPrediction(GoongPlace place) async {
    final latLng = await _goongService.getPlaceDetail(place.placeId);
    if (!mounted) return;
    if (latLng != null) {
      setState(() {
        _currentCenter = latLng;
        _predictions = [];
        _searchController.clear();
        _address = place.description;
      });
      _mapController.move(latLng, 16);
      FocusScope.of(context).unfocus();
    }
  }

  void _confirmLocation() {
    Navigator.pop(context, {'address': _address, 'latlng': _currentCenter});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentCenter,
              initialZoom: 15,
              onMapEvent: (event) {
                if (event is MapEventMoveStart) {
                  setState(() {
                    _isMoving = true;
                    _address = "Locating...";
                  });
                } else if (event is MapEventMoveEnd) {
                  _onMapMoveEnd(event);
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
                userAgentPackageName: 'com.datn.app',
                tileProvider: NetworkTileProvider(),
                errorImage: const NetworkImage(
                  'https://upload.wikimedia.org/wikipedia/commons/thumb/a/ac/No_image_available.svg/1024px-No_image_available.svg.png',
                ), // PNG Fallback
              ),
            ],
          ),

          // Center Pin
          const Center(
            child: Padding(
              padding: EdgeInsets.only(bottom: 40), // Adjust for pin tip
              child: Icon(
                Icons.location_on,
                size: 50,
                color: Color(0xFFFE724C),
              ),
            ),
          ),

          // Search Bar
          Positioned(
            top: 50, // SafeArea
            left: 16,
            right: 16,
            child: Column(
              children: [
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                        child: const Icon(
                          Icons.arrow_back,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: const [
                            BoxShadow(color: Colors.black12, blurRadius: 4),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          decoration: const InputDecoration(
                            hintText: "Search location...",
                            prefixIcon: Icon(Icons.search),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          onChanged: _onSearchChanged,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_predictions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(
                      top: 8,
                      left: 52,
                    ), // Align with search bar
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    constraints: const BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      itemCount: _predictions.length,
                      itemBuilder: (context, index) {
                        final place = _predictions[index];
                        return ListTile(
                          title: Text(
                            place.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          leading: const Icon(
                            Icons.place,
                            size: 20,
                            color: Colors.grey,
                          ),
                          onTap: () => _selectPrediction(place),
                          visualDensity: VisualDensity.compact,
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Bottom Address Card & Confirm Button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
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
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    "Delivery Location",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFFFE724C),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _address,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isMoving ? null : _confirmLocation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFE724C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(_isMoving ? "Locating..." : "Confirm Location"),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
