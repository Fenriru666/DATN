import 'package:flutter/material.dart';
import 'package:datn/features/customer/screens/location/location_selection_screen.dart';
import 'package:latlong2/latlong.dart';
import 'package:datn/l10n/generated/app_localizations.dart';
import 'package:flutter_map/flutter_map.dart';

class CourierScreen extends StatefulWidget {
  final String? initialLocation;
  const CourierScreen({super.key, this.initialLocation});

  @override
  State<CourierScreen> createState() => _CourierScreenState();
}

class _CourierScreenState extends State<CourierScreen> {
  final MapController _mapController = MapController();
  int _selectedSize = 0;
  String? _senderAddress;
  LatLng? _senderLatLng;
  String? _receiverAddress;
  LatLng? _receiverLatLng;
  double? _distanceKm;
  double? _shippingFee;

  @override
  void initState() {
    super.initState();
    _senderAddress = widget.initialLocation;

  }

  void _calculateDistanceAndFee() {
    if (_senderLatLng != null && _receiverLatLng != null) {
      final distanceInMeters = const Distance().as(LengthUnit.Meter, _senderLatLng!, _receiverLatLng!);
      _distanceKm = distanceInMeters / 1000;
      
      double baseFee = 15000; // Base fee 15,000 VND
      double perKmFee = 5000; // 5,000 VND per km per app mechanics setup
      double totalFee = baseFee + (_distanceKm! * perKmFee);
      
      // Add fee based on package size
      if (_selectedSize == 1) totalFee += 5000; // Medium
      if (_selectedSize == 2) totalFee += 10000; // Large
      
      if (mounted) {
        setState(() {
          _shippingFee = totalFee;
        });
        
        // Adjust map bounds to show both points
        try {
          final bounds = LatLngBounds.fromPoints([_senderLatLng!, _receiverLatLng!]);
          _mapController.fitCamera(CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(50)));
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
        builder: (context) =>
            LocationSelectionScreen(initialPosition: isSender ? _senderLatLng : _receiverLatLng),
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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final List<String> _sizes = [l10n.sizeSmall, l10n.sizeMedium, l10n.sizeLarge, l10n.sizeDocument];

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
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
          ),
          child: BackButton(color: Colors.black),
        ),
      ),
      body: Stack(
        children: [
          // 1. Background Map
          FlutterMap(
             mapController: _mapController,
             options: MapOptions(
               initialCenter: _senderLatLng ?? const LatLng(10.762622, 106.660172), // Center of HCM
               initialZoom: 13.0,
             ),
             children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
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
                           child: const Icon(Icons.location_on, color: Colors.blue, size: 40),
                        ),
                      if (_receiverLatLng != null)
                        Marker(
                           point: _receiverLatLng!,
                           width: 40,
                           height: 40,
                           child: const Icon(Icons.location_on, color: Color(0xFFFE724C), size: 40),
                        ),
                   ],
                ),
             ],
          ),
          
          // 2. Floating Info Card at Bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.only(top: 100),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                boxShadow: const [
                  BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, -2))
                ]
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Sender & Receiver Inputs (Grab Style)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Theme.of(context).dividerColor),
                        ),
                        child: Row(
                          children: [
                            Column(
                              children: [
                                const Icon(Icons.my_location, color: Colors.blue, size: 20),
                                Container(
                                  height: 35,
                                  width: 2,
                                  color: Colors.grey[300],
                                  margin: const EdgeInsets.symmetric(vertical: 4),
                                ),
                                const Icon(Icons.location_on, color: Color(0xFFFE724C), size: 20),
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
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(l10n.senderDetails, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                              Text(
                                                _senderAddress?.isNotEmpty == true ? _senderAddress! : l10n.addSenderInfo,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight: _senderAddress?.isNotEmpty == true ? FontWeight.bold : FontWeight.normal,
                                                  color: _senderAddress?.isNotEmpty == true ? Theme.of(context).textTheme.bodyLarge?.color : Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
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
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(l10n.receiverDetails, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                              Text(
                                                _receiverAddress?.isNotEmpty == true ? _receiverAddress! : l10n.addReceiverInfo,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontWeight: _receiverAddress?.isNotEmpty == true ? FontWeight.bold : FontWeight.normal,
                                                  color: _receiverAddress?.isNotEmpty == true ? Theme.of(context).textTheme.bodyLarge?.color : Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
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

                      // Package Size
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          l10n.packageSize,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(_sizes.length, (index) {
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
                                    color: isSelected ? Colors.white : Colors.grey,
                                    size: 28,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    _sizes[index],
                                    style: TextStyle(
                                      color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
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
                            border: Border.all(color: Theme.of(context).dividerColor),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.two_wheeler,
                                size: 40,
                                color: Colors.black54,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.instantDelivery,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${l10n.distance}: ${_distanceKm!.toStringAsFixed(1)} km',
                                      style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                          onPressed: (_senderAddress != null && _receiverAddress != null && _senderAddress!.isNotEmpty && _receiverAddress!.isNotEmpty) ? () {
                              showDialog(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: Text(l10n.orderSuccess),
                                  content: Text(l10n.orderSuccessMessage),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                        Navigator.pop(context);
                                      },
                                      child: Text(l10n.ok),
                                    ),
                                  ],
                                ),
                              );
                          } : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFE724C),
                            disabledBackgroundColor: Colors.grey[400],
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Text(
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
          )
        ],
      )
    );
  }
}

// _UserInfoRow removed as it was replaced by inline layout
