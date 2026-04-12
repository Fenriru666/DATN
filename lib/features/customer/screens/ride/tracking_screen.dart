import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:datn/core/models/order_model.dart';
import 'package:datn/features/customer/services/order_service.dart';

import 'package:datn/core/widgets/cancel_reason_dialog.dart';
import 'package:datn/core/widgets/sos_button.dart';
import 'package:datn/core/models/emergency_model.dart';
import 'package:datn/core/services/emergency_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:datn/features/chat/screens/in_app_chat_screen.dart';

class TrackingScreen extends StatefulWidget {
  final String orderId;

  const TrackingScreen({super.key, required this.orderId});

  @override
  State<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends State<TrackingScreen> {
  final OrderService _orderService = OrderService();
  final MapController _mapController = MapController();

  // Default to Vietnam's rough center or generic coordinates if nothing loaded yet
  LatLng _lastKnownCameraCenter = const LatLng(10.7769, 106.7009);
  bool _hasCenteredInitially = false;

  String _getFormattedStatus(String status) {
    switch (status) {
      case 'Pending':
        return 'ĐANG TÌM TÀI XẾ';
      case 'Accepted':
        return 'TÀI XẾ ĐÃ NHẬN CHUYẾN';
      case 'Arrived':
        return 'TÀI XẾ ĐÃ ĐẾN ĐIỂM ĐÓN';
      case 'InProgress':
        return 'ĐANG TRÊN ĐƯỜNG';
      case 'Completed':
        return 'HOÀN THÀNH';
      case 'Cancelled':
        return 'ĐÃ HỦY';
      default:
        return status.toUpperCase();
    }
  }

  @override
  void initState() {
    super.initState();
    _hasCenteredInitially = false;
  }

  @override
  void dispose() {
    super.dispose();
  }

  void _recenterCamera(OrderModel order) {
    if (order.driverLat == null || order.driverLng == null) return;

    final driverPos = LatLng(order.driverLat!, order.driverLng!);

    // Fit Bounds between Customer Pickup and Driver
    if (order.pickupLat != null && order.pickupLng != null) {
      final pickupPos = LatLng(
        order.pickupLat!.toDouble(),
        order.pickupLng!.toDouble(),
      );
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([driverPos, pickupPos]),
          padding: const EdgeInsets.all(50.0),
        ),
      );
    } else {
      _mapController.move(driverPos, 16.0);
    }
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
                              "🚨 CẢNH BÁO ĐÃ ĐƯỢC GỬI ĐẾN TRUNG TÂM!",
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
                        _getFormattedStatus(order.status),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFE724C),
                        ),
                      ),
                      const SizedBox(height: 16),
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
                          order.merchantName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          order.distance != null
                              ? '${order.distance!.toStringAsFixed(1)} km'
                              : 'Calculating...',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chat, color: Colors.blue),
                              onPressed: () {
                                if (order.driverId != null) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => InAppChatScreen(
                                        orderId: widget.orderId,
                                        peerId: order.driverId!,
                                        peerName: order.merchantName,
                                      ),
                                    ),
                                  );
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đang tìm tài xế...'),
                                    ),
                                  );
                                }
                              },
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.phone,
                                color: Colors.green,
                              ),
                              onPressed: () {},
                            ),
                          ],
                        ),
                      ),
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
