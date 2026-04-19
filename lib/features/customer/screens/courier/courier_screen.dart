import 'package:flutter/material.dart';
import 'package:datn/features/customer/screens/location/location_selection_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:datn/l10n/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:datn/features/customer/services/local_driver_database.dart';
import 'package:datn/features/customer/screens/ride/tracking_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:datn/features/customer/services/order_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:datn/core/models/order_model.dart';

class CourierScreen extends StatefulWidget {
  final String? initialLocation;
  const CourierScreen({super.key, this.initialLocation});

  @override
  State<CourierScreen> createState() => _CourierScreenState();
}

class _CourierScreenState extends State<CourierScreen> {
  final MapController _mapController = MapController();
  final OrderService _orderService = OrderService();
  int _selectedSize = 0;
  String? _senderAddress;
  LatLng? _senderLatLng;
  String? _receiverAddress;
  LatLng? _receiverLatLng;
  double? _distanceKm;
  double? _shippingFee;

  bool _isSearching = false;
  double _searchRadius = 5.0;

  @override
  void initState() {
    super.initState();
    _senderAddress = widget.initialLocation;
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    final pos = await Geolocator.getCurrentPosition();
    setState(() {
      _senderLatLng = LatLng(pos.latitude, pos.longitude);
      _mapController.move(_senderLatLng!, 15);
    });
  }

  void _calculateDistanceAndFee() {
    if (_senderLatLng != null && _receiverLatLng != null) {
      final distanceInMeters = const Distance().as(
        LengthUnit.Meter,
        _senderLatLng!,
        _receiverLatLng!,
      );
      _distanceKm = distanceInMeters / 1000;

      double baseFee = 15000; // Base fee 15,000 VND
      double perKmFee = 5000; // 5,000 VND per km
      double totalFee = baseFee + (_distanceKm! * perKmFee);

      // Add fee based on package size
      if (_selectedSize == 1) totalFee += 5000; // Medium
      if (_selectedSize == 2) totalFee += 10000; // Large
      if (_selectedSize == 3) totalFee += 2000; // Document

      if (mounted) {
        setState(() {
          _shippingFee = totalFee;
        });

        try {
          final bounds = LatLngBounds.fromPoints([
            _senderLatLng!,
            _receiverLatLng!,
          ]);
          _mapController.fitCamera(
            CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)),
          );
        } catch (e) {
          // Ignore state error if map is not ready
        }
      }
    }
  }

  Future<void> _pickLocation(bool isSender) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => LocationSelectionScreen(
          initialPosition: isSender ? _senderLatLng : _receiverLatLng,
        ),
      ),
    );

    if (result != null && result is Map) {
      setState(() {
        if (isSender) {
          _senderAddress = result['address'];
          _senderLatLng = result['latlng'];
        } else {
          _receiverAddress = result['address'];
          _receiverLatLng = result['latlng'];
        }
      });
      _calculateDistanceAndFee();
    }
  }

  Future<void> _startBooking() async {
    if (_senderLatLng == null || _receiverLatLng == null) return;

    setState(() => _isSearching = true);

    try {
      // Find 'bike' drivers for courier
      final allDrivers = LocalDriverDatabase.drivers
          .where((d) => d['type'] == 'bike')
          .toList();

      List<Map<String, dynamic>> nearbyDrivers = [];

      for (var data in allDrivers) {
        final driverData = Map<String, dynamic>.from(data);
        final driverLat = driverData['latitude'] as double;
        final driverLng = driverData['longitude'] as double;

        final distance =
            Geolocator.distanceBetween(
              _senderLatLng!.latitude,
              _senderLatLng!.longitude,
              driverLat,
              driverLng,
            ) /
            1000;

        if (distance <= _searchRadius) {
          driverData['distanceKm'] = distance;
          nearbyDrivers.add(driverData);
        }
      }

      setState(() => _isSearching = false);

      if (nearbyDrivers.isEmpty) {
        if (mounted) _showNoDriversBottomSheet();
        return;
      }

      nearbyDrivers.sort(
        (a, b) =>
            (a['distanceKm'] as double).compareTo(b['distanceKm'] as double),
      );

      if (mounted) _showDriversBottomSheet(nearbyDrivers);
    } catch (e) {
      setState(() => _isSearching = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  void _showNoDriversBottomSheet() {
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
                            setModalState(() => _searchRadius = value);
                            setState(() => _searchRadius = value);
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
                        _startBooking();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFE724C),
                      ),
                      child: Text(
                        l10n.searchAgain,
                        style: const TextStyle(
                          color: Colors.white,
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

  void _showDriversBottomSheet(List<Map<String, dynamic>> drivers) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
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
                  Text(
                    '${l10n.radius}: ${_searchRadius.toStringAsFixed(0)}km',
                    style: const TextStyle(color: Colors.grey),
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
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[200],
                          child: Icon(
                            Icons.two_wheeler,
                            color: Colors.grey[700],
                          ),
                        ),
                        title: Text(
                          '${driver['name']} (${driver['providerName']})',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${(driver['distanceKm'] as double).toStringAsFixed(1)} km away â€¢ â˜… ${driver['rating']}',
                        ),
                        trailing: ElevatedButton(
                          onPressed: () async {
                            Navigator.pop(context); // Close sheet
                            _bookSelectedDriver(driver);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFE724C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: const Text(
                            'Book',
                            style: TextStyle(color: Colors.white),
                          ),
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
  }

  Future<void> _bookSelectedDriver(Map<String, dynamic> driverData) async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Vui lòng đăng nhập!')));
      return;
    }

    try {
      final orderData = OrderModel(
        id: '', // Generated by Supabase
        userId: user.id,
        merchantId: 'courier_service', // Mark as courier
        merchantName: driverData['name'],
        merchantImage: '0xFFFE724C',
        itemsSummary: 'Gói hàng Giao Tốc Hành',
        serviceType: 'Ride',
        address: _senderAddress ?? 'Sender Point',
        status: 'Accepted', // Auto accept for mock
        totalPrice: _shippingFee ?? 0,
        pickupLat: _senderLatLng?.latitude,
        pickupLng: _senderLatLng?.longitude,
        dropoffLat: _receiverLatLng?.latitude,
        dropoffLng: _receiverLatLng?.longitude,
        driverId: driverData['id'],
        driverLat: driverData['latitude'],
        driverLng: driverData['longitude'],
        createdAt: DateTime.now(),
      );

      final orderId = await _orderService.createOrder(orderData);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => TrackingScreen(orderId: orderId)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error booking delivery: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final List<String> sizes = [
      l10n.sizeSmall,
      l10n.sizeMedium,
      l10n.sizeLarge,
      l10n.sizeDocument,
    ];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(l10n.sendPackage),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
        leading: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            shape: BoxShape.circle,
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: BackButton(color: Theme.of(context).iconTheme.color),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  _senderLatLng ?? const LatLng(10.762622, 106.660172),
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.datn.app',
              ),
              if (_senderLatLng != null && _receiverLatLng != null)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: [_senderLatLng!, _receiverLatLng!],
                      strokeWidth: 4.0,
                      color: const Color(0xFFFE724C),
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  if (_senderLatLng != null)
                    Marker(
                      point: _senderLatLng!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.blue,
                        size: 40,
                      ),
                    ),
                  if (_receiverLatLng != null)
                    Marker(
                      point: _receiverLatLng!,
                      width: 40,
                      height: 40,
                      child: const Icon(
                        Icons.location_on,
                        color: Color(0xFFFE724C),
                        size: 40,
                      ),
                    ),
                ],
              ),
            ],
          ),

          // Current Location Button
          Positioned(
            top: 100, // Position it below the top edge
            right: 16,
            child: FloatingActionButton(
              heroTag: 'current_location_courier',
              backgroundColor: Theme.of(context).cardColor,
              mini: true,
              onPressed: _getCurrentLocation,
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),

          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 100),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 10,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Theme.of(context).dividerColor,
                          ),
                        ),
                        child: Row(
                          children: [
                            Column(
                              children: [
                                const Icon(
                                  Icons.my_location,
                                  color: Colors.blue,
                                  size: 20,
                                ),
                                Container(
                                  height: 35,
                                  width: 2,
                                  color: Colors.grey[300],
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                ),
                                const Icon(
                                  Icons.location_on,
                                  color: Color(0xFFFE724C),
                                  size: 20,
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: () => _pickLocation(true),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                l10n.senderDetails,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                _senderAddress?.isNotEmpty ==
                                                        true
                                                    ? _senderAddress!
                                                    : l10n.addSenderInfo,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight:
                                                      _senderAddress
                                                              ?.isNotEmpty ==
                                                          true
                                                      ? FontWeight.bold
                                                      : FontWeight.normal,
                                                  color:
                                                      _senderAddress
                                                              ?.isNotEmpty ==
                                                          true
                                                      ? Theme.of(context)
                                                            .textTheme
                                                            .bodyLarge
                                                            ?.color
                                                      : Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Divider(height: 24),
                                  GestureDetector(
                                    onTap: () => _pickLocation(false),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                l10n.receiverDetails,
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                              Text(
                                                _receiverAddress?.isNotEmpty ==
                                                        true
                                                    ? _receiverAddress!
                                                    : l10n.addReceiverInfo,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight:
                                                      _receiverAddress
                                                              ?.isNotEmpty ==
                                                          true
                                                      ? FontWeight.bold
                                                      : FontWeight.w500,
                                                  color:
                                                      _receiverAddress
                                                              ?.isNotEmpty ==
                                                          true
                                                      ? Theme.of(context)
                                                            .textTheme
                                                            .bodyLarge
                                                            ?.color
                                                      : const Color(0xFFFE724C),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(
                                          Icons.arrow_forward_ios,
                                          size: 14,
                                          color: Colors.grey,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.packageSize,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(sizes.length, (index) {
                          final isSelected = _selectedSize == index;
                          return GestureDetector(
                            onTap: () {
                              setState(() => _selectedSize = index);
                              _calculateDistanceAndFee();
                            },
                            child: Container(
                              width: 75,
                              height: 75,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFFE724C)
                                    : Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isSelected
                                      ? const Color(0xFFFE724C)
                                      : Theme.of(context).dividerColor,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.inventory_2,
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.grey,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    sizes[index],
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : Theme.of(
                                              context,
                                            ).textTheme.bodyLarge?.color,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 20),

                      if (_shippingFee != null && _distanceKm != null)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Theme.of(context).cardColor,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Theme.of(context).dividerColor,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.two_wheeler,
                                size: 40,
                                color: Colors.grey,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.instantDelivery,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${l10n.distance}: ${_distanceKm!.toStringAsFixed(1)} km',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${_shippingFee!.toStringAsFixed(0)} đ',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: Color(0xFFFE724C),
                                ),
                              ),
                            ],
                          ),
                        ),

                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed:
                              (_senderAddress != null &&
                                  _receiverAddress != null &&
                                  _senderAddress!.isNotEmpty &&
                                  _receiverAddress!.isNotEmpty &&
                                  !_isSearching)
                              ? _startBooking
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFE724C),
                            disabledBackgroundColor: Colors.grey[400],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSearching
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  l10n.continueButton,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
