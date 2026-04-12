import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:datn/core/models/user_model.dart';
import 'package:datn/core/utils/tier_calculator.dart';
import 'package:datn/core/services/notification_service.dart';
import 'package:datn/features/customer/screens/rewards/lucky_wheel_screen.dart';
import 'package:datn/features/customer/screens/rewards/my_vouchers_screen.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<UserModel?> _streamCurrentUser() {
    final user = _auth.currentUser;
    if (user == null) return const Stream.empty();
    return _firestore.collection('users').doc(user.uid).snapshots().map((doc) {
      if (doc.exists) return UserModel.fromMap(doc.data()!, doc.id);
      return null;
    });
  }

  void _redeemReward(UserModel user, Map<String, dynamic> reward) {
    int pointCost = reward['cost'];

    if (user.loyaltyPoints < pointCost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Rất tiếc, bạn không đủ điểm thưởng để đổi vé này."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Xác nhận đổi thưởng?"),
        content: Text(
          "Bạn sẽ dùng $pointCost điểm để đổi lấy ${reward['title']}.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Hủy", style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _processRedemption(user, reward);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFE724C),
            ),
            child: const Text(
              "Đổi Ngay",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _processRedemption(
    UserModel user,
    Map<String, dynamic> reward,
  ) async {
    try {
      // Deduct Points
      await _firestore.collection('users').doc(user.uid).update({
        'loyaltyPoints': FieldValue.increment(-reward['cost']),
      });

      // Send In-App Notification with the Promo Code
      await NotificationService().sendInAppNotification(
        userId: user.uid,
        title: "Đổi thưởng thành công!",
        body:
            "Bạn đã đổi ${reward['cost']} điểm lấy ${reward['title']}. Mã Khuyến Mãi của bạn là: ${reward['code']}",
        type: "promo",
      );

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text("Hoan hô! 🎉"),
            content: Text(
              "Đổi quà thành công! Mã Code của bạn là: ${reward['code']}\n(Mã đã được tự động lưu vào Trung tâm thông báo)",
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Tuyệt vời!",
                  style: TextStyle(color: Color(0xFFFE724C)),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Lỗi: $e")));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Cửa Hàng Đổi Thưởng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).textTheme.bodyLarge?.color,
        elevation: 0,
      ),
      body: StreamBuilder<UserModel?>(
        stream: _streamCurrentUser(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text("Không lấy được dữ liệu."));
          }

          final user = snapshot.data!;
          int nextTierRides =
              TierCalculator.getRidesToNextTier(user.completedRides) ?? 0;
          double progress = 1.0;
          String nextTierName = "Max";
          int targetRides = user.completedRides;

          if (user.completedRides < 50) {
            targetRides = 50;
            nextTierName = "Silver";
          } else if (user.completedRides < 100) {
            targetRides = 100;
            nextTierName = "Gold";
          } else if (user.completedRides < 500) {
            targetRides = 500;
            nextTierName = "Platinum";
          }

          if (targetRides > user.completedRides) {
            final startRides = targetRides == 50
                ? 0
                : targetRides == 100
                ? 50
                : 100;
            progress =
                (user.completedRides - startRides) / (targetRides - startRides);
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Map
                Container(
                  color: Theme.of(context).cardColor,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.stars,
                        size: 60,
                        color: Color(0xFFFE724C),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        "Điểm Tích Lũy",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      Text(
                        "${user.loyaltyPoints}",
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFE724C),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Hạng: ${user.tier}",
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            nextTierRides > 0
                                ? "Còn $nextTierRides chuyến -> $nextTierName"
                                : "Bạn đã đạt đỉnh!",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: progress,
                        backgroundColor: Colors.grey[200],
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFFFE724C),
                        ),
                        minHeight: 10,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Text(
                    "Minigame & Giải Trí",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                
                // Lucky Wheel Banner
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LuckyWheelScreen(),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFE724C), Color(0xFFFFB74D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFE724C).withValues(alpha: 0.3),
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
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.casino,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Vòng Quay Giàu Sang",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Thử vận may - Trúng ngay tiền mặt!",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),

                // My Vouchers Banner
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const MyVouchersScreen(),
                      ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 0),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4DB6AC), Color(0xFF26A69A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF26A69A).withValues(alpha: 0.3),
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
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.card_giftcard,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Kho Voucher Của Tôi",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "Mã giảm giá và Ưu đãi đặc quyền",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios,
                          color: Colors.white,
                          size: 20,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                const Padding(
                  padding: EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Text(
                    "Phiếu Quà Tặng Đặc Quyền",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),

                // Mock Rewards Catalog
                _buildRewardCard(
                  user: user,
                  title: "Giảm 30% Cuốc Xe",
                  description: "Tối đa 30K cho dịch vụ chở khách.",
                  cost: 5000,
                  icon: Icons.directions_car,
                  iconColor: Colors.blue,
                  code: "RIDE30X",
                ),
                _buildRewardCard(
                  user: user,
                  title: "Freeship Đồ Ăn",
                  description: "Miễn phí giao hàng tối đa 15K.",
                  cost: 3000,
                  icon: Icons.fastfood,
                  iconColor: Colors.green,
                  code: "FREESHIP3K",
                ),
                _buildRewardCard(
                  user: user,
                  title: "Giảm 50K Mọi Dịch Vụ",
                  description: "Mã giảm giá khủng cho người giàu điểm.",
                  cost: 15000,
                  icon: Icons.star,
                  iconColor: Colors.amber,
                  code: "SUPER50K",
                ),
                const SizedBox(height: 40),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRewardCard({
    required UserModel user,
    required String title,
    required String description,
    required int cost,
    required IconData icon,
    required Color iconColor,
    required String code,
  }) {
    final canAfford = user.loyaltyPoints >= cost;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              description,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.stars, size: 16, color: Color(0xFFFE724C)),
                const SizedBox(width: 4),
                Text(
                  "$cost điểm",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: canAfford ? const Color(0xFFFE724C) : Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: ElevatedButton(
          onPressed: () =>
              _redeemReward(user, {'title': title, 'cost': cost, 'code': code}),
          style: ElevatedButton.styleFrom(
            backgroundColor: canAfford
                ? const Color(0xFFFE724C)
                : Colors.grey[300],
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
          child: Text(
            "Đổi",
            style: TextStyle(
              color: canAfford ? Colors.white : Colors.grey[600],
            ),
          ),
        ),
      ),
    );
  }
}
