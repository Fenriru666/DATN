import 'package:flutter/material.dart';
import 'package:datn/features/admin/services/admin_service.dart';
import 'package:datn/features/admin/screens/admin_user_management_screen.dart';
import 'package:datn/features/admin/screens/admin_promotion_screen.dart';
import 'package:datn/features/admin/screens/admin_layout.dart';
import 'package:datn/features/admin/screens/widgets/admin_dashboard_charts.dart';
import 'package:intl/intl.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _fetchStats();
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoading = true);
    try {
      final stats = await _adminService.getSystemStats();
      setState(() {
        _stats = stats;
      });
    } catch (e) {
      debugPrint("Error fetching stats: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: 'dashboard',
      title: 'Tổng Quan Cửa Hàng',
      child: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.indigo))
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeaderActions(),
                  const SizedBox(height: 32),
                  _buildStatCards(),
                  const SizedBox(height: 32),
                  _buildChartsSection(),
                  const SizedBox(height: 40),
                  _buildQuickAccessSection(),
                ],
              ),
            ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hiệu suất kinh doanh',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Theo dõi chi tiết các chỉ số nền tảng theo thời gian thực',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
            ),
          ],
        ),
        Row(
          children: [
            ElevatedButton.icon(
              onPressed: () async {
                bool confirm = await showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Cảnh báo nguy hiểm'),
                    content: const Text('Hành động này sẽ XÓA VĨNH VIỄN tất cả người dùng, chỉ chừa lại 50 người dùng đầu tiên. Các tài khoản bị xóa sẽ không thể khôi phục. Bạn có chắc chắn không?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Hủy')),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(ctx, true),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                        child: const Text('XÓA DỮ LIỆU', style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                ) ?? false;
                
                if (confirm && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đang xóa dữ liệu...')));
                  await _adminService.keepOnly50Users();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đã dọn dẹp xong!')));
                    _fetchStats();
                  }
                }
              },
              icon: const Icon(Icons.delete_forever_rounded, size: 20),
              label: const Text('Dọn DB còn 50'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48), // Rose 600
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              onPressed: _fetchStats,
              icon: const Icon(Icons.refresh_rounded, size: 20),
              label: const Text('Làm mới dữ liệu'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5), // Indigo 600
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCards() {
    final formatCurrency = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return LayoutBuilder(
      builder: (context, constraints) {
        double width = constraints.maxWidth;
        double itemWidth;
        
        if (width >= 1000) {
          itemWidth = (width - 24 * 3) / 4;
        } else if (width >= 600) {
          itemWidth = (width - 24) / 2;
        } else {
          itemWidth = width;
        }

        itemWidth = itemWidth.floorToDouble();

        return Wrap(
          spacing: 24,
          runSpacing: 24,
          children: [
            SizedBox(
              width: itemWidth,
              child: _buildGradientStatCard(
                title: 'Tổng Khách Hàng',
                value: '${_stats?['totalUsers'] ?? 0}',
                icon: Icons.people_alt_rounded,
                colors: [const Color(0xFF3B82F6), const Color(0xFF2563EB)], // Blue
                trend: '+12% so với tháng trước',
                trendUp: true,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildGradientStatCard(
                title: 'Đơn Hàng Thành Công',
                value: '${_stats?['totalOrders'] ?? 0}',
                icon: Icons.shopping_bag_rounded,
                colors: [const Color(0xFF10B981), const Color(0xFF059669)], // Emerald
                trend: '+5% hôm nay',
                trendUp: true,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildGradientStatCard(
                title: 'Tổng GMV',
                value: formatCurrency.format(_stats?['totalRevenue'] ?? 0),
                icon: Icons.monetization_on_rounded,
                colors: [const Color(0xFFF59E0B), const Color(0xFFD97706)], // Amber
                trend: '+8% tuần này',
                trendUp: true,
              ),
            ),
            SizedBox(
              width: itemWidth,
              child: _buildGradientStatCard(
                title: 'Doanh Thu Nền Tảng (15%)',
                value: formatCurrency.format(_stats?['platformRevenue'] ?? 0),
                icon: Icons.account_balance_wallet_rounded,
                colors: [const Color(0xFF8B5CF6), const Color(0xFF7C3AED)], // Violet
                trend: '+15% tháng này',
                trendUp: true,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGradientStatCard({
    required String title,
    required String value,
    required IconData icon,
    required List<Color> colors,
    required String trend,
    required bool trendUp,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // Very light shadow
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: colors.first.withAlpha(70),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: trendUp ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      trendUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                      color: trendUp ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      trend.split(' ').first, // Just showing the percentage
                      style: TextStyle(
                        color: trendUp ? const Color(0xFF16A34A) : const Color(0xFFDC2626),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            value,
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 15, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isLargeScreen = constraints.maxWidth >= 1000;
        if (isLargeScreen) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: _buildChartCard(
                  title: 'Doanh thu trung bình theo ngày',
                  child: RevenueLineChart(
                    weeklyRevenue: _stats?['weeklyRevenue'] ?? List.filled(7, 0.0),
                    maxRevenue: _stats?['maxDailyRevenue'] ?? 0.0,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                flex: 3,
                child: _buildChartCard(
                  title: 'Tỉ lệ Người Dùng',
                  child: UserDemographicsPieChart(
                    demographics: _stats?['userDemographics'] ?? {},
                    totalUsers: _stats?['totalUsers'] ?? 0,
                  ),
                ),
              ),
            ],
          );
        } else {
          return Column(
            children: [
              _buildChartCard(
                title: 'Doanh thu trung bình theo ngày',
                child: RevenueLineChart(
                  weeklyRevenue: _stats?['weeklyRevenue'] ?? List.filled(7, 0.0),
                  maxRevenue: _stats?['maxDailyRevenue'] ?? 0.0,
                ),
              ),
              const SizedBox(height: 24),
              _buildChartCard(
                title: 'Tỉ lệ Người Dùng',
                child: UserDemographicsPieChart(
                  demographics: _stats?['userDemographics'] ?? {},
                  totalUsers: _stats?['totalUsers'] ?? 0,
                ),
              ),
            ],
          );
        }
      },
    );
  }

  Widget _buildChartCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 20,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E293B),
                ),
              ),
              Icon(Icons.more_horiz, color: Colors.grey[400]),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(height: 300, child: child),
        ],
      ),
    );
  }

  Widget _buildQuickAccessSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Công vụ quản trị',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 20),
        LayoutBuilder(
          builder: (context, constraints) {
            final isLarge = constraints.maxWidth >= 800;
            if (isLarge) {
              return Row(
                children: [
                  Expanded(
                    child: _buildActionCard(
                      title: 'Người Dùng Mới',
                      subtitle: 'Xét duyệt Quán ăn & Tài xế đăng ký',
                      icon: Icons.verified_user_rounded,
                      color: const Color(0xFF14B8A6), // Teal
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const AdminUserManagementScreen(),
                            transitionDuration: Duration.zero,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 24),
                  Expanded(
                    child: _buildActionCard(
                      title: 'Trung Tâm Khuyến Mãi',
                      subtitle: 'Tạo và cấp phát thẻ giảm giá',
                      icon: Icons.stars_rounded,
                      color: const Color(0xFFF43F5E), // Rose
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, secondaryAnimation) => const AdminPromotionScreen(),
                            transitionDuration: Duration.zero,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            } else {
              return Column(
                children: [
                  _buildActionCard(
                    title: 'Người Dùng Mới',
                    subtitle: 'Xét duyệt Quán ăn & Tài xế đăng ký',
                    icon: Icons.verified_user_rounded,
                    color: const Color(0xFF14B8A6),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const AdminUserManagementScreen(),
                          transitionDuration: Duration.zero,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildActionCard(
                    title: 'Trung Tâm Khuyến Mãi',
                    subtitle: 'Tạo và cấp phát thẻ giảm giá',
                    icon: Icons.stars_rounded,
                    color: const Color(0xFFF43F5E),
                    onTap: () {
                      Navigator.pushReplacement(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const AdminPromotionScreen(),
                          transitionDuration: Duration.zero,
                        ),
                      );
                    },
                  ),
                ],
              );
            }
          },
        ),
      ],
    );
  }

  Widget _buildActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        hoverColor: color.withAlpha(10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x05000000),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withAlpha(20),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: const Icon(Icons.arrow_forward_ios_rounded, color: Color(0xFF94A3B8), size: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
