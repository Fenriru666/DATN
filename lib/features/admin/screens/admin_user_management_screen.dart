import 'package:flutter/material.dart';
import 'package:datn/features/admin/services/admin_service.dart';
import 'package:datn/core/models/user_model.dart';
import 'package:datn/core/utils/ui_helpers.dart';
import 'package:intl/intl.dart';

class AdminUserManagementScreen extends StatefulWidget {
  const AdminUserManagementScreen({super.key});

  @override
  State<AdminUserManagementScreen> createState() =>
      _AdminUserManagementScreenState();
}

class _AdminUserManagementScreenState extends State<AdminUserManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Duyệt Tài Khoản'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.orange,
          tabs: const [
            Tab(text: 'Chờ Duyệt (Pending)'),
            Tab(text: 'Đã Duyệt (Active)'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildPendingUsersTab(), _buildActiveUsersTab()],
      ),
    );
  }

  Widget _buildPendingUsersTab() {
    return StreamBuilder<List<UserModel>>(
      stream: _adminService.streamPendingUsers(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Center(
            child: Text(
              'Không có tài khoản nào đang chờ duyệt',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            return _buildUserCard(user, isPending: true);
          },
        );
      },
    );
  }

  Widget _buildActiveUsersTab() {
    // Only showing drivers and merchants for management context
    return StreamBuilder<List<UserModel>>(
      stream: _adminService
          .streamUsers(), // We'll filter this client-side for simplicity here
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final allUsers = snapshot.data ?? [];
        final activePartners = allUsers
            .where(
              (u) =>
                  u.isApproved &&
                  !u.roles.contains(UserRole.customer) &&
                  !u.roles.contains(UserRole.admin),
            )
            .toList();

        if (activePartners.isEmpty) {
          return const Center(
            child: Text('Không có đối tác (Tài Xế/Nhà Hàng) nào hoạt động'),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activePartners.length,
          itemBuilder: (context, index) {
            return _buildUserCard(activePartners[index], isPending: false);
          },
        );
      },
    );
  }

  Widget _buildUserCard(UserModel user, {required bool isPending}) {
    final roleNames = user.roles
        .map((e) => e.toString().split('.').last)
        .join(', ');
    final formatter = DateFormat('dd/MM/yyyy HH:mm');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: user.roles.contains(UserRole.driver)
                      ? Colors.orange
                      : Colors.green,
                  child: Icon(
                    user.roles.contains(UserRole.driver)
                        ? Icons.motorcycle
                        : Icons.restaurant,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.email,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Role: ${roleNames.toUpperCase()}',
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isPending
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isPending ? 'Pending' : 'Active',
                    style: TextStyle(
                      color: isPending ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 12,
            ), // Added a small space after the header row
            Text(
              'UID: ${user.uid}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(
              'Joined: ${formatter.format(user.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const Divider(height: 24), // Moved the divider here

            if (isPending) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => _banUser(user.uid),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text('Từ chối'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: () => _approveUser(user.uid),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigo,
                    ),
                    child: const Text(
                      'Duyệt',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _banUser(user.uid), // Revoke access
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    icon: const Icon(Icons.block, size: 16),
                    label: const Text('Đình chỉ (Ban)'),
                  ),
                ],
              ),
            ],
          ],
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
