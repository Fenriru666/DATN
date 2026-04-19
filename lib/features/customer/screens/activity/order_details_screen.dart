import 'package:flutter/material.dart';
import 'package:datn/core/models/order_model.dart';
import 'package:datn/l10n/app_localizations.dart';
import 'package:datn/features/customer/screens/activity/widgets/review_dialog.dart';

class OrderDetailsScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailsScreen({super.key, required this.order});

  @override
  State<OrderDetailsScreen> createState() => _OrderDetailsScreenState();
}

class _OrderDetailsScreenState extends State<OrderDetailsScreen> {
  late OrderModel _currentOrder;

  @override
  void initState() {
    super.initState();
    _currentOrder = widget.order;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Status color
    Color statusColor = Colors.orange;
    if (_currentOrder.status == 'Delivered' ||
        _currentOrder.status == 'Completed') {
      statusColor = Colors.green;
    } else if (_currentOrder.status == 'Cancelled') {
      statusColor = Colors.red;
    }

    // Is Eligible For Review
    final isEligibleForReview =
        (_currentOrder.status == 'Delivered' ||
            _currentOrder.status == 'Completed') &&
        _currentOrder.rating == null;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          l10n.orderDetails,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Status Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
              color: statusColor.withValues(alpha: 0.1),
              child: Row(
                children: [
                  Icon(
                    _currentOrder.status == 'Delivered' ||
                            _currentOrder.status == 'Completed'
                        ? Icons.check_circle
                        : (_currentOrder.status == 'Cancelled'
                              ? Icons.cancel
                              : Icons.info),
                    color: statusColor,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _currentOrder.status,
                      style: TextStyle(
                        color: statusColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  if (isEligibleForReview)
                    ElevatedButton.icon(
                      onPressed: () async {
                        final didReview = await showDialog<bool>(
                          context: context,
                          builder: (context) =>
                              ReviewDialog(orderId: _currentOrder.id),
                        );
                        if (didReview == true && mounted) {
                          // Update locally immediately to reflect change
                          setState(() {
                            _currentOrder = OrderModel(
                              id: _currentOrder.id,
                              userId: _currentOrder.userId,
                              merchantName: _currentOrder.merchantName,
                              merchantImage: _currentOrder.merchantImage,
                              itemsSummary: _currentOrder.itemsSummary,
                              totalPrice: _currentOrder.totalPrice,
                              status: _currentOrder.status,
                              createdAt: _currentOrder.createdAt,
                              serviceType: _currentOrder.serviceType,
                              address: _currentOrder.address,
                              driverId: _currentOrder.driverId,
                              pickupLat: _currentOrder.pickupLat,
                              pickupLng: _currentOrder.pickupLng,
                              dropoffLat: _currentOrder.dropoffLat,
                              dropoffLng: _currentOrder.dropoffLng,
                              distance: _currentOrder.distance,
                              paymentMethod: _currentOrder.paymentMethod,
                              rating:
                                  5, // Just visual placeholder till stream updates
                              reviewNote: "Reviewed",
                            );
                          });
                        }
                      },
                      icon: const Icon(Icons.star, size: 16),
                      label: const Text('Review'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: statusColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Merchant / Driver Info
                  Text(
                    l10n.driverInfo,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCard(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Color(
                              int.tryParse(_currentOrder.merchantImage) ??
                                  0xFFFE724C,
                            ).withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _currentOrder.serviceType == 'Ride'
                                ? Icons.directions_car
                                : (_currentOrder.serviceType == 'Mart'
                                      ? Icons.local_grocery_store
                                      : Icons.fastfood),
                            color: Color(
                              int.tryParse(_currentOrder.merchantImage) ??
                                  0xFFFE724C,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentOrder.merchantName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                _currentOrder.serviceType,
                                style: const TextStyle(color: Colors.grey),
                              ),
                              if (_currentOrder.rating != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4.0),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        color: Colors.orange,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${_currentOrder.rating} rating',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.orange,
                                        ),
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

                  const SizedBox(height: 24),

                  // Delivery/Dropoff Address
                  if (_currentOrder.address.isNotEmpty) ...[
                    Text(
                      l10n.deliveryAddress,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildCard(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Color(0xFFFE724C),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _currentOrder.address,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Order Summary
                  Text(
                    l10n.orderSummary,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentOrder.itemsSummary,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        const Divider(),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              l10n.total,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${_currentOrder.totalPrice.toStringAsFixed(0)}đ',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFE724C),
                              ),
                            ),
                          ],
                        ),
                        if (_currentOrder.paymentMethod != null) ...[
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Payment Method',
                                style: TextStyle(color: Colors.grey),
                              ),
                              Text(
                                _currentOrder.paymentMethod!,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Order Metadata
                  _buildCard(
                    child: Column(
                      children: [
                        _buildMetaRow(l10n.orderId, _currentOrder.id),
                        const SizedBox(height: 12),
                        _buildMetaRow(
                          l10n.orderTime,
                          _currentOrder.createdAt.toString().substring(0, 16),
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
    );
  }

  Widget _buildCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildMetaRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    );
  }
}
