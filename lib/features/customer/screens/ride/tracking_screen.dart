import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:datn/core/models/order_model.dart';
import 'package:datn/features/customer/services/order_service.dart';

import 'package:datn/core/widgets/cancel_reason_dialog.dart';
import 'package:datn/core/widgets/sos_button.dart';
import 'package:datn/core/models/emergency_model.dart';
import 'package:datn/core/services/emergency_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:datn/features/chat/screens/in_app_chat_screen.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:datn/features/customer/services/goong_service.dart';
import 'package:datn/features/customer/screens/activity/widgets/review_dialog.dart';

class TrackingScreen extends StatefulWidget {
  final String orderId;

  const TrackingScreen({super.key, required this.orderId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final OrderService _orderService = OrderService();
  final MapController _mapController = MapController();
  final GoongService _goongService = GoongService();

  // Default to Vietnam's rough center or generic coordinates if nothing loaded yet
  LatLng _lastKnownCameraCenter = const LatLng(10.7769, 106.7009);
  bool _hasCenteredInitially = false;
  String? _lastStatus;
  bool _hasShownReviewDialog = false;

  List<LatLng> _routePoints = [];
  LatLng? _lastRouteDriverPos;
  String? _lastRouteStatus;

  String _getFormattedStatus(OrderModel order) {
    if (order.status == 'Pending') {
      if (order.serviceType == 'Food') {
        return 'ĐANG CHỜ CỬA HÀNG XÁC NHẬN';
      }
      if (order.driverId != null && order.driverId!.isNotEmpty) {
        return 'ĐANG CHỜ TÀI XẾ XÁC NHẬN';
      }
      return 'ĐANG TÌM TÀI XẾ';
    }
    switch (order.status) {
      case 'Preparing':
        return 'CỬA HÀNG ĐANG CHUẨN BỊ MÓN';
      case 'Ready':
        return 'MÓN ĂN ĐÃ SẴN SÀNG - ĐANG CHỜ TÀI XẾ';
      case 'Accepted':
        if (order.merchantId == 'courier_service') {
          return 'TÀI XẾ ĐANG ĐẾN LẤY HÀNG';
        }
        return order.serviceType == 'Food' ? 'TÀI XẾ ĐANG ĐẾN CỬA HÀNG' : 'TÀI XẾ ĐÃ NHẬN CHUYẾN';
      case 'Arrived':
        if (order.merchantId == 'courier_service') {
          return 'TÀI XẾ ĐÃ ĐẾN ĐIỂM LẤY HÀNG';
        }
        return order.serviceType == 'Food' ? 'TÀI XẾ ĐÃ ĐẾN CỬA HÀNG' : 'TÀI XẾ ĐÃ ĐẾN ĐIỂM ĐÓN';
      case 'InProgress':
        if (order.merchantId == 'courier_service') {
          return 'TÀI XẾ ĐANG GIAO HÀNG ĐẾN NGƯỜI NHẬN';
        }
        return order.serviceType == 'Food' ? 'ĐANG GIAO HÀNG' : 'ĐANG TRÊN ĐƯỜNG';
      case 'Completed':
        return 'HOÀN THÀNH';
      case 'Cancelled':
        return 'ĐÃ HỦY';
      default:
        return order.status.toUpperCase();
    }
  }

  @override
  void initState() {
    super.initState();
    _hasCenteredInitially = false;
    _lastStatus = null;
    _hasShownReviewDialog = false;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _recenterCamera(OrderModel order) {
    if (order.driverLat == null || order.driverLng == null) return;

    final driverPos = LatLng(order.driverLat!, order.driverLng!);

    bool useDropoff = order.status == 'InProgress';
    double? targetLat = useDropoff ? order.dropoffLat?.toDouble() : order.pickupLat?.toDouble();
    double? targetLng = useDropoff ? order.dropoffLng?.toDouble() : order.pickupLng?.toDouble();

    if (targetLat != null && targetLng != null) {
      final targetPos = LatLng(targetLat, targetLng);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([driverPos, targetPos]),
          padding: const EdgeInsets.all(50.0),
        ),
      );
    } else {
      _mapController.move(driverPos, 16.0);
    }
  }

  Future<void> _updateRoutePoints(OrderModel order) async {
    if (order.driverLat == null || order.driverLng == null) return;
    final driverPos = LatLng(order.driverLat!, order.driverLng!);

    bool useDropoff = order.status == 'InProgress';
    double? destLat = useDropoff ? order.dropoffLat?.toDouble() : order.pickupLat?.toDouble();
    double? destLng = useDropoff ? order.dropoffLng?.toDouble() : order.pickupLng?.toDouble();

    if (destLat == null || destLng == null) return;
    final destPos = LatLng(destLat, destLng);

    // Only fetch route if driver has moved significantly or status changed
    if (_lastRouteStatus != order.status ||
        _lastRouteDriverPos == null ||
        Geolocator.distanceBetween(
              _lastRouteDriverPos!.latitude,
              _lastRouteDriverPos!.longitude,
              driverPos.latitude,
              driverPos.longitude,
            ) > 100) {
      
      _lastRouteStatus = order.status;
      _lastRouteDriverPos = driverPos;

      try {
        final route = await _goongService.getRoute(driverPos, destPos);
        if (route != null) {
          final points = PolylinePoints()
              .decodePolyline(route.overviewPolyline)
              .map((point) => LatLng(point.latitude, point.longitude))
              .toList();
          if (mounted) {
            setState(() {
              _routePoints = points;
            });
          }
        }
      } catch (e) {
        debugPrint("Error fetching route in TrackingScreen: $e");
      }
    }
  }

  Future<Map<String, String>?> _fetchDriverInfo(String driverId) async {
    try {
      final response = await Supabase.instance.client
          .from('users')
          .select('name, phone')
          .eq('id', driverId)
          .single();
      return {
        'name': response['name'] ?? 'Tài xế',
        'phone': response['phone'] ?? '',
      };
    } catch (e) {
      return null;
    }
  }

  double _calculateCustomerRealTimeDistance(OrderModel order) {
    if (order.driverLat == null || order.driverLng == null) return 0.0;
    double destLat = order.dropoffLat?.toDouble() ?? 10.7769;
    double destLng = order.dropoffLng?.toDouble() ?? 106.7009;

    if (order.status == 'Accepted' || order.status == 'Arrived' || order.status == 'Preparing' || order.status == 'Ready') {
      destLat = order.pickupLat?.toDouble() ?? 10.7769;
      destLng = order.pickupLng?.toDouble() ?? 106.7009;
    }

    return Geolocator.distanceBetween(
      order.driverLat!,
      order.driverLng!,
      destLat,
      destLng,
    ) / 1000;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Theo Dõi Chuyến Đi',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<OrderModel?>(
        stream: _orderService.streamOrder(widget.orderId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final order = snapshot.data;
          if (order == null) {
            return const Center(child: Text('Order not found.'));
          }

          // Detect status change to trigger recenter
          if (_lastStatus != order.status) {
            _lastStatus = order.status;
            _hasCenteredInitially = false;
          }

          // Trigger async route points update
          _updateRoutePoints(order);

          // Auto-trigger Review Dialog if order is Completed and not yet reviewed
          if (order.status == 'Completed' && !_hasShownReviewDialog) {
            _hasShownReviewDialog = true;
            Future.delayed(Duration.zero, () async {
              if (mounted) {
                await showDialog<bool>(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => ReviewDialog(orderId: widget.orderId),
                );
                if (mounted) {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                }
              }
            });
          }

          // Handle Initial Center
          if (!_hasCenteredInitially &&
              order.driverLat != null &&
              order.driverLng != null) {
            Future.delayed(Duration.zero, () {
              if (mounted) {
                _recenterCamera(order);
                setState(() => _hasCenteredInitially = true);
              }
            });
          }

          return Stack(
            children: [
              // 1. Map Layer
              FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: _lastKnownCameraCenter,
                  initialZoom: 15.0,
                  onMapEvent: (event) {
                    if (event is MapEventMoveEnd) {
                      _lastKnownCameraCenter = event.camera.center;
                    }
                  },
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
                          color: const Color(0xFFFE724C),
                          strokeWidth: 4.5,
                        ),
                      ],
                    ),
                  // Markers
                  MarkerLayer(
                    markers: [
                      // Pickup Location
                      if (order.pickupLat != null && order.pickupLng != null)
                        Marker(
                          point: LatLng(
                            order.pickupLat!.toDouble(),
                            order.pickupLng!.toDouble(),
                          ),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.blue,
                            size: 40,
                          ),
                        ),
                      // Dropoff Location
                      if (order.dropoffLat != null && order.dropoffLng != null)
                        Marker(
                          point: LatLng(
                            order.dropoffLat!.toDouble(),
                            order.dropoffLng!.toDouble(),
                          ),
                          width: 40,
                          height: 40,
                          child: const Icon(
                            Icons.location_on,
                            color: Colors.green,
                            size: 40,
                          ),
                        ),
                      // Driver Animated Marker (Real-time Stream)
                      if (order.driverId != null &&
                          order.driverLat != null &&
                          order.driverLng != null)
                        Marker(
                          point: LatLng(order.driverLat!, order.driverLng!),
                          width: 50,
                          height: 50,
                          child: AnimatedContainer(
                            duration: const Duration(seconds: 1),
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
                              size: 28,
                            ),
                          ),
                        )
                      else if (order.driverLat != null &&
                          order.driverLng != null)
                        // Fallback if driverId is somehow null but we have coordinates
                        Marker(
                          point: LatLng(order.driverLat!, order.driverLng!),
                          width: 50,
                          height: 50,
                          child: AnimatedContainer(
                            duration: const Duration(seconds: 1),
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
                              size: 28,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),

              // 2. Refresh / Recenter Button
              Positioned(
                top: 16,
                right: 16,
                child: FloatingActionButton(
                  mini: true,
                  backgroundColor: Colors.white,
                  child: const Icon(Icons.my_location, color: Colors.black),
                  onPressed: () => _recenterCamera(order),
                ),
              ),

              // SOS Button
              Positioned(
                bottom: 270, // Above the info panel
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
                        userRole: 'Customer',
                        orderId: widget.orderId,
                        lat: pos.latitude,
                        lng: pos.longitude,
                        timestamp: DateTime.now(),
                      );

                      await EmergencyService().triggerSOS(emergencyData);

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "ðŸš¨ CẢNH BÁO ĐÃ ĐƯỢC GỬI ĐẾN TRUNG TÂM!",
                            ),
                            backgroundColor: Colors.red,
                            duration: Duration(seconds: 5),
                          ),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text("Lỗi gửi SOS: $e")),
                        );
                      }
                    }
                  },
                ),
              ),

              // 3. Status Info Panel at Bottom
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
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
                      Text(
                        _getFormattedStatus(order),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFE724C),
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (order.driverId != null)
                        FutureBuilder<Map<String, String>?>(
                          future: _fetchDriverInfo(order.driverId!),
                          builder: (context, driverSnapshot) {
                            final driverInfo = driverSnapshot.data;
                            final driverName = driverInfo?['name'] ?? 'Tài xế';
                            final driverPhone = driverInfo?['phone'] ?? '';

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (order.serviceType == 'Food') ...[
                                  ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    leading: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withValues(alpha: 0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.fastfood, color: Colors.orange),
                                    ),
                                    title: Text(
                                      order.merchantName,
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                                    subtitle: const Text('Cửa hàng chuẩn bị đơn hàng'),
                                  ),
                                  const Divider(),
                                ],
                                ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.person),
                                  ),
                                  title: Text(
                                    driverName,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: order.status == 'Pending'
                                      ? const Text(
                                          'Đang chờ xác nhận...',
                                          style: TextStyle(
                                            color: Color(0xFFFE724C),
                                            fontWeight: FontWeight.bold,
                                          ),
                                        )
                                      : Text(
                                          order.driverLat != null && order.driverLng != null
                                              ? 'Khoảng cách: ${_calculateCustomerRealTimeDistance(order).toStringAsFixed(1)} km'
                                              : 'Đang tính khoảng cách...',
                                        ),
                                  trailing: order.status == 'Pending'
                                      ? const Padding(
                                          padding: EdgeInsets.only(right: 16.0),
                                          child: SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: Color(0xFFFE724C),
                                            ),
                                          ),
                                        )
                                      : Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.chat, color: Colors.blue),
                                              onPressed: () {
                                                Navigator.push(
                                                  context,
                                                  MaterialPageRoute(
                                                    builder: (_) => InAppChatScreen(
                                                      orderId: widget.orderId,
                                                      peerId: order.driverId!,
                                                      peerName: driverName,
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.phone,
                                                color: Colors.green,
                                              ),
                                              onPressed: () async {
                                                if (driverPhone.isNotEmpty) {
                                                  final phoneUri = Uri.parse('tel:$driverPhone');
                                                  try {
                                                    if (await canLaunchUrl(phoneUri)) {
                                                      await launchUrl(phoneUri);
                                                    } else {
                                                      if (context.mounted) {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(content: Text('Không thể gọi số điện thoại này')),
                                                        );
                                                      }
                                                    }
                                                  } catch (e) {
                                                    if (context.mounted) {
                                                      ScaffoldMessenger.of(context).showSnackBar(
                                                        SnackBar(content: Text('Lỗi: $e')),
                                                      );
                                                    }
                                                  }
                                                } else {
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    const SnackBar(content: Text('Tài xế chưa cập nhật số điện thoại')),
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        ),
                                ),
                              ],
                            );
                          },
                        )
                      else ...[
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person),
                          ),
                          title: Text(
                            order.serviceType == 'Food' ? order.merchantName : 'Đang tìm tài xế...',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            order.serviceType == 'Food'
                                ? (order.status == 'Pending'
                                    ? 'Đang chờ nhà hàng nhận đơn...'
                                    : 'Đang kết nối tài xế giao hàng...')
                                : 'Hệ thống đang tìm tài xế gần nhất...',
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.chat, color: Colors.grey),
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Đang tìm tài xế...'),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      if (order.status == 'Completed' ||
                          order.status == 'Cancelled')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(
                                context,
                              ).popUntil((route) => route.isFirst);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Về trang chủ',
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        )
                      else if (order.status != 'Completed' &&
                          order.status != 'Cancelled')
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () async {
                              final reason = await showDialog<String>(
                                context: context,
                                builder: (context) => const CancelReasonDialog(
                                  availableReasons: [
                                    'Đợi quá lâu',
                                    'Tài xế yêu cầu hủy',
                                    'Nhầm địa chỉ đón',
                                    'Tôi thay đổi ý định',
                                  ],
                                ),
                              );

                              if (reason != null && context.mounted) {
                                try {
                                  await _orderService.updateOrderStatus(
                                    widget.orderId,
                                    'Cancelled',
                                    cancellationReason: reason,
                                  );
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Đã hủy chuyến'),
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
                              }
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red,
                              side: const BorderSide(color: Colors.red),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'Hủy Chuyến',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
