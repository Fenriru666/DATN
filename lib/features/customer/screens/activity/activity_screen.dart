import 'package:flutter/material.dart';
import 'package:datn/features/customer/services/order_service.dart';
import 'package:datn/core/models/order_model.dart';
import 'package:datn/features/customer/screens/activity/order_details_screen.dart';

class ActivityScreen extends StatelessWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          title: Text(
            'Activity',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleLarge?.color,
            ),
          ),
          centerTitle: false,
          elevation: 0,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          iconTheme: Theme.of(context).iconTheme,
          bottom: const TabBar(
            labelColor: Color(0xFFFE724C),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFFFE724C),
            tabs: [
              Tab(text: 'Ongoing'),
              Tab(text: 'History'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Ongoing Tab
            _buildOrderList(
              context,
              OrderService().getOngoingOrders(),
              isOngoing: true,
            ),

            // History Tab
            _buildOrderList(
              context,
              OrderService().getOrderHistory(),
              isOngoing: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderList(
    BuildContext context,
    Stream<List<OrderModel>> stream, {
    required bool isOngoing,
  }) {
    return StreamBuilder<List<OrderModel>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data ?? [];
        if (orders.isEmpty) {
          return Center(
            child: Text(
              isOngoing
                  ? "No ongoing particular activities"
                  : "No history found",
              style: const TextStyle(color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _ActivityItem(
                title: order.merchantName,
                subtitle: order.itemsSummary,
                time: order.createdAt.toString().substring(0, 16),
                address: order.address,
                icon: order.serviceType == 'Ride'
                    ? Icons.directions_car
                    : (order.serviceType == 'Mart'
                          ? Icons.local_grocery_store
                          : Icons.fastfood),
                iconColor: Color(
                  int.tryParse(order.merchantImage) ?? 0xFFFE724C,
                ),
                status: order.status,
                statusColor:
                    order.status == 'Delivered' || order.status == 'Completed'
                    ? Colors.green
                    : (order.status == 'Cancelled'
                          ? Colors.red
                          : Colors.orange),
                price: '${order.totalPrice.toStringAsFixed(0)}đ',
                onLongPress: isOngoing
                    ? () => _showSimulateDialog(context, order.id)
                    : null,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OrderDetailsScreen(order: order),
                    ),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showSimulateDialog(BuildContext context, String orderId) async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Simulate Order"),
        content: const Text("Advance order status?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, "Delivered"),
            child: const Text("Mark Delivered"),
          ),
        ],
      ),
    );

    if (result != null) {
      await OrderService().updateOrderStatus(orderId, result);
    }
  }
}

class _ActivityItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String time;
  final String price;
  final IconData icon;
  final Color iconColor;
  final String status;
  final Color statusColor;
  final String address;
  final VoidCallback? onLongPress;
  final VoidCallback? onTap;

  const _ActivityItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.price,
    required this.icon,
    required this.iconColor,
    required this.status,
    required this.statusColor,
    this.address = '',
    this.onLongPress,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onLongPress: onLongPress,
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (address.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      address,
                      style: TextStyle(
                        color: isDark ? Colors.grey[500] : Colors.grey[500],
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        time,
                        style: TextStyle(
                          color: isDark ? Colors.grey[400] : Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  price,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 20),
                if (status == 'Completed' || status == 'Delivered')
                  Icon(
                    Icons.refresh,
                    color: isDark ? Colors.grey[400] : Colors.grey,
                    size: 20,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
