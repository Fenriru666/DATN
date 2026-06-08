import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
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
import 'package:url_launcher/url_launcher.dart';
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
  String _customerName = 'Đang tải...';
  String _customerPhone = "";
  double _distanceToTarget = 0.0; // km — cập nhật real-time

  StreamSubscription<Position>? _positionStreamSubscription;
  Timer? _distanceTimer; // Force rebuild khoảng cách mỗi 3 giây

  @override
  void initState() {
    super.initState();
    _orderStatus = widget.order.status == 'Pending'
        ? 'Accepted'
        : widget.order.status;
    _initLocationAndRoute();
    _loadCustomerInfo();

    // ✅ Cập nhật khoảng cách real-time mỗi 3 giây
    _distanceTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (mounted) {
        setState(() {
          _distanceToTarget = _calculateRealTimeDistance();
        });
      }
    });
  }

  Future<void> _loadCustomerInfo() async {
    // Fallback 1: thử load từ Supabase bằng userId
    final uid = widget.order.userId;
    if (uid.isNotEmpty) {
      try {
        final response = await Supabase.instance.client
            .from('users')
            .select('name, phone')
            .eq('id', uid)
            .single();
        if (mounted) {
          setState(() {
            final rawName = response['name']?.toString().trim();
            _customerName = (rawName != null && rawName.isNotEmpty)
                ? rawName
                : _extractNameFromOrder();
            _customerPhone = response['phone'] ?? '';
          });
        }
        return;
      } catch (e) {
        debugPrint('Failed to load customer info from Supabase: $e');
      }
    }
    // Fallback 2: lấy tên từ merchantName trong order
    if (mounted) {
      setState(() {
        _customerName = _extractNameFromOrder();
      });
    }
  }

  /// Trích tên khách từ merchantName (format: "TenTaiXe (Provider)")
  String _extractNameFromOrder() {
    final merchant = widget.order.merchantName;
    if (merchant.isNotEmpty) {
      final parenIdx = merchant.indexOf('(');
      if (parenIdx > 0) return merchant.substring(0, parenIdx).trim();
      return merchant.trim();
    }
    return 'Khách hàng';
  }

  Future<void> _initLocationAndRoute() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (mounted) {
        setState(() {
          _currentDriverLocation = LatLng(position.latitude, position.longitude);
        });
        _driverService.updateOrderLocation(
          widget.order.id,
          _currentDriverLocation!,
        ).catchError((e) => debugPrint("Initial Order Location Update Error: $e"));
        _getRoute();
        _startLocationUpdates();
      }
    } catch (e) {
      debugPrint("Failed to get initial location: $e");
      if (mounted) {
        setState(() {
          _currentDriverLocation = const LatLng(10.7769, 106.7009);
        });
        _driverService.updateOrderLocation(
          widget.order.id,
          _currentDriverLocation!,
        ).catchError((e) => debugPrint("Initial Order Location Update Error: $e"));
        _getRoute();
        _startLocationUpdates();
      }
    }
  }

  void _startLocationUpdates() {
    _positionStreamSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 0,
      ),
    ).listen((Position position) {
      if (!mounted) return;
      setState(() {
        _currentDriverLocation = LatLng(position.latitude, position.longitude);
      });
      // Update DB with error handling to prevent unhandled async exceptions
      _driverService.updateLocation(_currentDriverLocation!).catchError((e) {
        debugPrint("Driver Location Update Error: $e");
      });
      _driverService.updateOrderLocation(
        widget.order.id,
        _currentDriverLocation!,
      ).catchError((e) {
        debugPrint("Order Location Update Error: $e");
      });
    });
  }

  @override
  void dispose() {
    _distanceTimer?.cancel();
    _positionStreamSubscription?.cancel();
    super.dispose();
  }

  Future<void> _getRoute() async {
    setState(() {
      _isLoadingRoute = true;
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
        start = _currentDriverLocation ?? pickup;
        end = pickup;
      } else {
        start = _currentDriverLocation ?? pickup; // Sử dụng tọa độ thật của tài xế thay vì fake về điểm đón
        end = dropoff;
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
    } catch (e) {
      debugPrint("Route error: $e");
    } finally {
      if (mounted) setState(() => _isLoadingRoute = false);
    }
  }

  double _calculateRealTimeDistance() {
    if (_currentDriverLocation == null) return 0.0;
    LatLng destination;
    if (_orderStatus == 'Accepted' || _orderStatus == 'Arrived') {
      destination = widget.order.pickupLat != null && widget.order.pickupLng != null
          ? LatLng(widget.order.pickupLat!.toDouble(), widget.order.pickupLng!.toDouble())
          : const LatLng(10.7800, 106.7020);
    } else {
      destination = widget.order.dropoffLat != null && widget.order.dropoffLng != null
          ? LatLng(widget.order.dropoffLat!.toDouble(), widget.order.dropoffLng!.toDouble())
          : const LatLng(10.7850, 106.7080);
    }

    return Geolocator.distanceBetween(
      _currentDriverLocation!.latitude,
      _currentDriverLocation!.longitude,
      destination.latitude,
      destination.longitude,
    ) / 1000;
  }

  // Utilities to decode polyline from Goong Maps
  List<LatLng> _decodePolyline(String encoded) {
    PolylinePoints polylinePoints = PolylinePoints();
    List<PointLatLng> result = polylinePoints.decodePolyline(encoded);
    return result.map((point) => LatLng(point.latitude, point.longitude)).toList();
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
        title: Text(
          widget.order.serviceType == 'Food'
              ? 'Đồ Ăn - Bản Đồ Giao Hàng'
              : 'Bản Đồ Chuyến Đi',
          style: const TextStyle(fontWeight: FontWeight.bold),
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
              if (_routePoints.isNotEmpty)
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
                  // Pickup Marker (cửa hàng cho Food, điểm đón cho Ride)
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
                      child: Icon(
                        widget.order.serviceType == 'Food'
                            ? Icons.store
                            : Icons.person_pin_circle,
                        color: widget.order.serviceType == 'Food'
                            ? Colors.orange
                            : Colors.blue,
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
                        content: Text("🚨 BÁO ĐỘNG ĐÃ ĐƯỢC PHÁT ĐI!"),
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
                          color: widget.order.serviceType == 'Food'
                              ? Colors.orange[50]
                              : Colors.blue[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.order.serviceType == 'Food'
                              ? Icons.fastfood
                              : Icons.person,
                          color: widget.order.serviceType == 'Food'
                              ? Colors.orange
                              : Colors.blue,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _customerName,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                            Text(
                              _currentDriverLocation == null
                                  ? 'Đang tính khoảng cách...'
                                  : _orderStatus == 'Accepted'
                                      ? widget.order.merchantId == 'courier_service'
                                          ? 'Đến điểm nhận hàng: ${_distanceToTarget.toStringAsFixed(1)} km'
                                          : widget.order.serviceType == 'Food'
                                              ? 'Đến cửa hàng: ${_distanceToTarget.toStringAsFixed(1)} km'
                                              : 'Đến điểm đón: ${_distanceToTarget.toStringAsFixed(1)} km'
                                      : _orderStatus == 'Arrived'
                                          ? widget.order.merchantId == 'courier_service'
                                              ? 'Đã đến điểm nhận. Đang lấy hàng...'
                                              : widget.order.serviceType == 'Food'
                                                  ? 'Đang chờ lấy hàng...'
                                                  : 'Đang chờ khách...'
                                          : widget.order.merchantId == 'courier_service'
                                              ? 'Đang giao đến người nhận: ${_distanceToTarget.toStringAsFixed(1)} km'
                                              : widget.order.serviceType == 'Food'
                                                  ? 'Đến địa chỉ giao: ${_distanceToTarget.toStringAsFixed(1)} km'
                                                  : 'Đến điểm đến: ${_distanceToTarget.toStringAsFixed(1)} km',
                              style: TextStyle(
                                color: _orderStatus == 'InProgress'
                                    ? Colors.blue[700]
                                    : Colors.grey[600],
                                fontWeight: _orderStatus == 'InProgress'
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.phone, color: Colors.green),
                        onPressed: () async {
                          if (_customerPhone.isNotEmpty) {
                            final Uri launchUri = Uri(
                              scheme: 'tel',
                              path: _customerPhone,
                            );
                            if (await canLaunchUrl(launchUri)) {
                              await launchUrl(launchUri);
                            } else {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Không thể thực hiện cuộc gọi')),
                                );
                              }
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Khách hàng không có số điện thoại')),
                            );
                          }
                        },
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
                                peerName: _customerName,
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
                                  await _driverService.updateBusyStatus(false);
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
                                if (_currentDriverLocation != null) {
                                  await _driverService.updateOrderLocation(
                                    widget.order.id,
                                    _currentDriverLocation!,
                                  ).catchError((e) => debugPrint("Error updating order location: $e"));
                                }
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
                            child: Text(
                              widget.order.merchantId == 'courier_service'
                                  ? 'ĐÃ ĐẾN ĐIỂM NHẬN HÀNG'
                                  : widget.order.serviceType == 'Food'
                                      ? 'ĐÃ ĐẾN CỬA HÀNG'
                                      : 'ĐÃ ĐẾN NƠI',
                              style: const TextStyle(
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
                            if (_currentDriverLocation != null) {
                              await _driverService.updateOrderLocation(
                                widget.order.id,
                                _currentDriverLocation!,
                              ).catchError((e) => debugPrint("Error updating order location: $e"));
                            }
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
                        child: Text(
                          widget.order.merchantId == 'courier_service'
                              ? 'ĐÃ NHẬN HÀNG - BẮT ĐẦU GIAO'
                              : widget.order.serviceType == 'Food'
                                  ? 'ĐÃ LẤY HÀNG - BẮT ĐẦU GIAO'
                                  : 'BẮT ĐẦU CHUYỂN ĐI',
                          style: const TextStyle(
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
                            await _driverService.updateBusyStatus(false);
                            await _driverService.goOffline();
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
                        child: Text(
                          widget.order.merchantId == 'courier_service'
                              ? 'ĐÃ GIAO HÀNG ĐẾN NGƯỜI NHẬN'
                              : widget.order.serviceType == 'Food'
                                  ? 'ĐÃ GIAO HÀNG XONG'
                                  : 'HOÀN THÀNH CHUYẾN',
                          style: const TextStyle(
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
