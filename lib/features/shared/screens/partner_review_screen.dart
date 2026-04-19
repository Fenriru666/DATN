import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:datn/core/models/order_model.dart';
import 'package:intl/intl.dart';

class PartnerReviewScreen extends StatelessWidget {
  final String userId;
  final bool isDriver;

  const PartnerReviewScreen({
    super.key,
    required this.userId,
    required this.isDriver,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Đánh giá & Phản hồi (Reviews)'),
        backgroundColor: isDriver ? Colors.green : Colors.orange,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client
            .from('orders')
            .stream(primaryKey: ['id'])
            .eq(isDriver ? 'driver_id' : 'merchant_id', userId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          // Parse and filter locally
          final allOrders = snapshot.data!.map((data) {
            return OrderModel.fromMap(data, data['id']);
          }).toList();

          // Client-side sort by createdAt descending
          allOrders.sort((a, b) => b.createdAt.compareTo(a.createdAt));

          final reviewedOrders = allOrders
              .where((o) => o.rating != null)
              .toList();

          if (reviewedOrders.isEmpty) {
            return _buildEmptyState();
          }

          final formatter = DateFormat('dd/MM/yyyy HH:mm');

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: reviewedOrders.length,
            itemBuilder: (context, index) {
              final order = reviewedOrders[index];
              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 16),
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber),
                              const SizedBox(width: 4),
                              Text(
                                '${order.rating}',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            formatter.format(order.createdAt),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      if (order.reviewNote != null &&
                          order.reviewNote!.isNotEmpty)
                        Text(
                          order.reviewNote!,
                          style: const TextStyle(
                            fontSize: 15,
                            fontStyle: FontStyle.italic,
                          ),
                        )
                      else
                        const Text(
                          'Khách hàng không để lại nhận xét.',
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      const Divider(height: 24),
                      Row(
                        children: [
                          Icon(
                            order.serviceType == 'Ride'
                                ? Icons.directions_car
                                : Icons.fastfood,
                            size: 16,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Chuyến: ${order.id.substring(0, 8)} â€¢ ${order.serviceType}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.rate_review_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 16),
          Text(
            'Chưa có Đánh giá nào',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8),
          Text(
            'Dịch vụ của bạn chưa nhận được phản hồi nào từ khách hàng.',
            style: TextStyle(color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
