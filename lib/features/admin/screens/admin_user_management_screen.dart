import 'package:flutter/material.dart';
import 'package:datn/features/admin/services/admin_service.dart';
import 'package:datn/core/models/user_model.dart';
import 'package:datn/core/utils/ui_helpers.dart';
import 'package:intl/intl.dart';
import 'package:datn/features/admin/screens/admin_layout.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() => _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();

  late final Stream<List<UserModel>> _pendingUsersStream;
  late final Stream<List<UserModel>> _activePartnersStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _pendingUsersStream = _adminService.streamPendingUsers();
    _activePartnersStream = _adminService.streamActivePartners();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: 'users',
      title: 'Quản Lý Người Dùng',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderActions(),
          const SizedBox(height: 24),
          _buildTabs(),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 2)),
                ],
              ),
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(), // Disabling swipe on web to avoid conflicts
                children: [_buildPendingUsersTab(), _buildActiveUsersTab()],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActions() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Danh sách Đối Tác',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Kiểm duyệt và quản lý tài khoản Đối Tác trên hệ thống',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: const Color(0xFF4F46E5),
        unselectedLabelColor: const Color(0xFF64748B),
        indicatorColor: const Color(0xFF4F46E5),
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15),
        tabs: const [
          Tab(text: 'Chờ Duyệt (Pending)'),
          Tab(text: 'Đã Duyệt (Active)'),
        ],
      ),
    );
  }

  Widget _buildPendingUsersTab() {
    return StreamBuilder<List<UserModel>>(
      stream: _pendingUsersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.indigo));
        }

        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return _buildEmptyState('Không có tài khoản nào đang chờ duyệt');
        }

        return _buildDataTable(users, isPending: true);
      },
    );
  }

  Widget _buildActiveUsersTab() {
    return StreamBuilder<List<UserModel>>(
      stream: _activePartnersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.indigo));
        }

        final allUsers = snapshot.data ?? [];
        final activePartners = allUsers
            .where((u) => !u.roles.contains(UserRole.customer) && !u.roles.contains(UserRole.admin))
            .toList();

        if (activePartners.isEmpty) {
          return _buildEmptyState('Không có đối tác nào hoạt động');
        }

        return _buildDataTable(activePartners, isPending: false);
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_rounded, size: 64, color: const Color(0xFFCBD5E1)),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(fontSize: 16, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTable(List<UserModel> users, {required bool isPending}) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          dataRowMinHeight: 64,
          dataRowMaxHeight: 64,
          horizontalMargin: 24,
          columnSpacing: 40,
          columns: const [
            DataColumn(label: Text('ĐỐI TÁC', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
            DataColumn(label: Text('VAI TRÒ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
            DataColumn(label: Text('NGÀY ĐĂNG KÝ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
            DataColumn(label: Text('TRẠNG THÁI', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
            DataColumn(label: Text('THAO TÁC', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
          ],
          rows: users.map((user) {
            final roleNames = user.roles.map((e) => e.toString().split('.').last.toUpperCase()).join(', ');
            final isDriver = user.roles.contains(UserRole.driver);
            
            return DataRow(
              cells: [
                DataCell(
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: isDriver ? const Color(0xFFFEF3C7) : const Color(0xFFD1FAE5),
                        child: Icon(
                          isDriver ? Icons.motorcycle_rounded : Icons.restaurant_rounded,
                          color: isDriver ? const Color(0xFFD97706) : const Color(0xFF059669),
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            user.email,
                            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                          ),
                          Text(
                            user.uid,
                            style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      roleNames,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569)),
                    ),
                  ),
                ),
                DataCell(
                  Text(
                    formatter.format(user.createdAt),
                    style: const TextStyle(color: Color(0xFF64748B)),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isPending ? const Color(0xFFFEF2F2) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isPending ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isPending ? 'Pending' : 'Active',
                          style: TextStyle(
                            color: isPending ? const Color(0xFFDC2626) : const Color(0xFF16A34A),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: isPending
                        ? [
                            IconButton(
                              icon: const Icon(Icons.check_circle_rounded, color: Color(0xFF16A34A)),
                              tooltip: 'Duyệt',
                              onPressed: () => _approveUser(user.uid),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cancel_rounded, color: Color(0xFFDC2626)),
                              tooltip: 'Từ chối',
                              onPressed: () => _banUser(user.uid),
                            ),
                          ]
                        : [
                            IconButton(
                              icon: const Icon(Icons.block_rounded, color: Color(0xFFDC2626)),
                              tooltip: 'Đình chỉ (Ban)',
                              onPressed: () => _banUser(user.uid),
                            ),
                          ],
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _approveUser(String uid) async {
    try {
      await _adminService.approveUser(uid);
      if (mounted) {
        UIHelpers.showSnackBar(context, 'Đã phê duyệt đối tác thành công!');
      }
    } catch (e) {
      if (mounted) UIHelpers.showErrorDialog(context, 'Lỗi', e.toString());
    }
  }

  Future<void> _banUser(String uid) async {
    try {
      await _adminService.banUser(uid);
      if (mounted) {
        UIHelpers.showSnackBar(context, 'Tài khoản đã bị đình chỉ/Từ chối.');
      }
    } catch (e) {
      if (mounted) UIHelpers.showErrorDialog(context, 'Lỗi', e.toString());
    }
  }
}
