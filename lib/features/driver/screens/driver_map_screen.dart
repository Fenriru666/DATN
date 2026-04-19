import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:datn/features/driver/services/driver_service.dart';
import 'package:datn/features/customer/services/order_service.dart';
import 'package:datn/core/models/order_model.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:datn/core/constants/map_constants.dart';
import 'package:datn/core/widgets/cancel_reason_dialog.dart';
import 'package:datn/core/widgets/sos_button.dart';
import 'package:datn/core/models/emergency_model.dart';
import 'package:datn/core/services/emergency_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:datn/features/chat/screens/in_app_chat_screen.dart';

class DriverMapScreen extends StatefulWidget {
  final OrderModel order;
  const DriverMapScreen({super.key, required this.order});

  @override
  State<DriverMapScreen> createState() => _DriverMapScreenState();
}

class _DriverMapScreenState extends State<DriverMapScreen> {
  final MapController _mapController = MapController();
  final DriverService _driverService = DriverService();
  final OrderService _orderService = OrderService();

  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = true;
  LatLng? _currentDriverLocation;

  String _orderStatus = 'Accepted';

  // Fake tracking for demo purposes
  Timer? _simulationTimer;
  int _currentPathIndex = 0;

  @override
  void initState() {
    super.initState();
    _initializeMockLocation();
    _orderStatus = widget.order.status == 'Pending'
        ? 'Accepted'
        : widget.order.status;
    _getRoute();
  }

  void _initializeMockLocation() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null && user.email == 'test3@gmail.com') {
      // Mock start: Tùng Thiện Vương, Phường 11, Quận 8, TPHCM
      _currentDriverLocation = const LatLng(10.741639, 106.660144);
    } else {
      // Mock start: Nhà thờ Đức Bà (default)
      _currentDriverLocation = const LatLng(10.7769, 106.7009);
    }
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    super.dispose();
  }

  Future<void> _getRoute() async {
    _simulationTimer?.cancel();
    setState(() {
      _isLoadingRoute = true;
      _currentPathIndex = 0;
      _routePoints.clear();
    });

    try {
      final pickup =
          widget.order.pickupLat != null && widget.order.pickupLng != null
          ? LatLng(
              widget.order.pickupLat!.toDouble(),
              widget.order.pickupLng!.toDouble(),
            )
          : const LatLng(
              10.7800,
              106.7020,
            ); // Sai Gon Notre Dame Basilica (mock)

      final dropoff =
          widget.order.dropoffLat != null && widget.order.dropoffLng != null
          ? LatLng(
              widget.order.dropoffLat!.toDouble(),
              widget.order.dropoffLng!.toDouble(),
            )
          : const LatLng(10.7850, 106.7080); // fake dropoff if null

      LatLng start;
      LatLng end;

      if (_orderStatus == 'Accepted') {
        start = _currentDriverLocation!;
        end = pickup;
      } else {
        start = pickup;
        end = dropoff;
        _currentDriverLocation = pickup;
      }

      final url = Uri.parse(
        'https://rsapi.goong.io/Direction?origin=${start.latitude},${start.longitude}&destination=${end.latitude},${end.longitude}&vehicle=bike&api_key=${MapConstants.goongServiceKey}',
      );

      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final encodedPolyline =
              data['routes'][0]['overview_polyline']['points'];
          _routePoints = _decodePolyline(encodedPolyline);
        }
      }

      if (_routePoints.isNotEmpty) {
        _mapController.fitCamera(
          CameraFit.bounds(
            bounds: LatLngBounds.fromPoints([start, end]),
            padding: const EdgeInsets.all(50.0),
          ),
        );
      }

      _startDriverSimulation();
    } catch (e) {
      debugPrint("Route error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  void _startDriverSimulation() {
    if (_routePoints.isEmpty) return;

    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_currentPathIndex < _routePoints.length - 1) {
        setState(() {
          _currentPathIndex++;
          _currentDriverLocation = _routePoints[_currentPathIndex];
        });
        // Update DB
        _driverService.updateLocation(_currentDriverLocation!);
        _driverService.updateOrderLocation(
          widget.order.id,
          _currentDriverLocation!,
        );
      } else {
        timer.cancel();
      }
    });
  }

  // Utilities to decode polyline from Goong Maps
  List<LatLng> _decodePolyline(String encoded) {
    List<LatLng> poly = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      poly.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return poly;
  }

  @override
  Widget build(BuildContext context) {
    final pickup =
        widget.order.pickupLat != null && widget.order.pickupLng != null
        ? LatLng(
            widget.order.pickupLat!.toDouble(),
            widget.order.pickupLng!.toDouble(),
          )
        : const LatLng(10.7800, 106.7020);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Bản Đồ Chuyến Đi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter:
                  _currentDriverLocation ?? const LatLng(10.7769, 106.7009),
              initialZoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://a.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}@2x.png',
              ),
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: _routePoints,
                    color: Colors.blue,
                    strokeWidth: 4.0,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Driver Marker
                  if (_currentDriverLocation != null)
                    Marker(
                      point: _currentDriverLocation!,
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(color: Colors.black26, blurRadius: 4),
                          ],
                        ),
                        child: const Icon(
                          Icons.directions_car,
                          color: Color(0xFFFE724C),
                          size: 24,
                        ),
                      ),
                    ),
                  // Pickup Marker
                  Marker(
                    point: pickup,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black26, blurRadius: 4),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Colors.blue,
                        size: 28,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          if (_isLoadingRoute)
            const Center(
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(width: 16),
                      Text("Đang tính toán tuyến đường..."),
                    ],
                  ),
                ),
              ),
            ),

          // Current Location Button
          Positioned(
            bottom: 330,
            right: 16,
            child: FloatingActionButton(
              heroTag: 'current_location_drv',
              backgroundColor: Colors.white,
              mini: true,
              onPressed: () {
                if (_currentDriverLocation != null) {
                  _mapController.move(_currentDriverLocation!, 16);
                }
              },
              child: const Icon(Icons.my_location, color: Colors.blue),
            ),
          ),

          // SOS BUTTON for Driver
          Positioned(
            bottom: 270,
            right: 16,
            child: SOSButton(
              onSOSActived: () async {
                try {
                  final pos = await Geolocator.getCurrentPosition(
                    locationSettings: const LocationSettings(
                      accuracy: LocationAccuracy.high,
                    ),
                  );

                  final user = Supabase.instance.client.auth.currentUser;
                  if (user == null) return;

                  final emergencyData = EmergencyModel(
                    id: '',
                    userId: user.id,
                    userRole: 'Driver',
                    orderId: widget.order.id,
                    lat: pos.latitude,
                    lng: pos.longitude,
                    timestamp: DateTime.now(),
                  );

                  await EmergencyService().triggerSOS(emergencyData);

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("ðŸš¨ BÁO ĐỘNG ĐÃ ĐƯỢC PHÁT ĐI!"),
                        backgroundColor: Colors.red,
                        duration: Duration(seconds: 5),
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
                  }
                }
              },
            ),
          ),

          // Bottom Action Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person, color: Colors.blue),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Khách hàng",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              "Cách bạn ~2.5km",
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone, color: Colors.green),
                        onPressed: () {},
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green[50],
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.chat, color: Colors.blue),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => InAppChatScreen(
                                orderId: widget.order.id,
                                peerId: widget.order.userId,
                                peerName: "Khách hàng",
                              ),
                            ),
                          );
                        },
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue[50],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 30),
                  // BOTTOM ACTION BUTTONS
                  if (_orderStatus == 'Accepted')
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () async {
                              final reason = await showDialog<String>(
                                context: context,
                                builder: (context) => const CancelReasonDialog(
                                  availableReasons: [
                                    'Khách hàng không nghe máy',
                                    'Xe hỏng / Gặp sự cố',
                                    'Kẹt xe / Đường cấm',
                                    'Khách hàng yêu cầu hủy',
                                  ],
                                ),
                              );

                              if (reason != null && context.mounted) {
                                try {
                                  await _orderService.updateOrderStatus(
                                    widget.order.id,
                                    'Cancelled',
                                    cancellationReason: reason,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Đã hủy chuyến'),
                                      ),
                                    );
                                    Navigator.of(context).pop();
                                  }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Lỗi: $e')),
                                    );
                                  }
                                }
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "HỦY",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton(
                            onPressed: () async {
                              try {
                                await _orderService.updateOrderStatus(
                                  widget.order.id,
                                  'Arrived',
                                );
                                if (context.mounted) {
                                  setState(() {
                                    _orderStatus = 'Arrived';
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã đến điểm đón!'),
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Lỗi: $e')),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFE724C),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "ĐÃ ĐẾN NÆ I",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    )
                  else if (_orderStatus == 'Arrived')
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await _orderService.updateOrderStatus(
                              widget.order.id,
                              'InProgress',
                            );
                            if (context.mounted) {
                              setState(() {
                                _orderStatus = 'InProgress';
                              });
                              _getRoute(); // Request route to Destination
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi: $e')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "BẮT ĐẦU CHUYẾN ĐI",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    )
                  else if (_orderStatus == 'InProgress' ||
                      _orderStatus == 'On the way') // Fallback for old status
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          try {
                            await _orderService.updateOrderStatus(
                              widget.order.id,
                              'Completed',
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Chuyến đi Hoàn Thành! Đã cộng tiền vào ví.',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                              Navigator.of(context).pop();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Lỗi: $e')),
                              );
                            }
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          "HOÀN THÀNH CHUYẾN",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
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
}
