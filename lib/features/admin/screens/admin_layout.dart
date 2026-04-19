import 'package:flutter/material.dart';
import 'package:datn/features/admin/screens/widgets/admin_side_menu.dart';
import 'package:datn/features/auth/services/auth_service.dart';

class AdminLayout extends StatelessWidget {
  final Widget child;
  final String currentRoute;
  final String title;

  const AdminLayout({
    super.key,
    required this.child,
    required this.currentRoute,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FA), // Light premium gray
      appBar: MediaQuery.of(context).size.width < 900
          ? AppBar(
              title: Text(
                title,
                style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              backgroundColor: Colors.white,
              iconTheme: const IconThemeData(color: Colors.black87),
              elevation: 1,
              actions: [_buildUserAvatar(context)],
            )
          : null,
      drawer: MediaQuery.of(context).size.width < 900
          ? AdminSideMenu(currentRoute: currentRoute)
          : null,
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isLargeScreen = constraints.maxWidth >= 900;
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (isLargeScreen)
                SizedBox(
                  width: 260,
                  child: AdminSideMenu(currentRoute: currentRoute),
                ),
              Expanded(
                child: Column(
                  children: [
                    if (isLargeScreen) _buildTopBar(context),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: child,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E9F2))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          Row(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                width: 250,
                height: 40,
                child: const Row(
                  children: [
                    Icon(Icons.search, color: Color(0xFF94A3B8), size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          border: InputBorder.none,
                          hintText: 'Tìm kiếm...',
                          hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                          contentPadding: EdgeInsets.only(bottom: 12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 24),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: Color(0xFF64748B)),
                    onPressed: () {},
                  ),
                  Positioned(
                    right: 12,
                    top: 12,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  )
                ],
              ),
              const SizedBox(width: 16),
              _buildUserAvatar(context),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildUserAvatar(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'Tài khoản',
      offset: const Offset(0, 50),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: const CircleAvatar(
        radius: 18,
        backgroundColor: Colors.indigo,
        child: Text(
          'AD',
          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
        ),
      ),
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'profile',
          child: Row(
            children: [
              Icon(Icons.person_outline, size: 20),
              SizedBox(width: 12),
              Text('Hồ sơ'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'settings',
          child: Row(
            children: [
              Icon(Icons.settings_outlined, size: 20),
              SizedBox(width: 12),
              Text('Cài đặt'),
            ],
          ),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(
          value: 'logout',
          child: Row(
            children: [
              Icon(Icons.logout, size: 20, color: Colors.redAccent),
              SizedBox(width: 12),
              Text('Đăng xuất', style: TextStyle(color: Colors.redAccent)),
            ],
          ),
        ),
      ],
      onSelected: (value) {
        if (value == 'logout') {
          AuthService().signOut();
        }
      },
    );
  }
}
