import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where(isDriver ? 'driverId' : 'merchantId', isEqualTo: userId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải dữ liệu: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          // Parse and filter locally
          final allOrders = snapshot.data!.docs.map((doc) {
            return OrderModel.fromMap(doc.data(), doc.id);
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
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 6),
                          CustomerNameText(userId: order.userId),
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
                            'Chuyến: ${order.id.substring(0, 8)} • ${order.serviceType}',
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

  class CustomerNameText extends StatefulWidget {
    final String userId;
    const CustomerNameText({super.key, required this.userId});

    @override
    State<CustomerNameText> createState() => _CustomerNameTextState();
  }

  class _CustomerNameTextState extends State<CustomerNameText> {
    String _name = "Khách hàng";

    @override
    void initState() {
      super.initState();
      _loadName();
    }

    Future<void> _loadName() async {
      try {
        final response = await Supabase.instance.client
            .from('users')
            .select('name')
            .eq('id', widget.userId)
            .single();
        if (mounted) {
          setState(() {
            _name = response['name'] ?? "Khách hàng";
          });
        }
      } catch (_) {}
    }

    @override
    Widget build(BuildContext context) {
      return Text(
        _name,
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Colors.grey,
        ),
      );
    }
  }
