import 'package:flutter/material.dart';
import 'package:datn/features/admin/screens/admin_dashboard_screen.dart';
import 'package:datn/features/admin/screens/admin_user_management_screen.dart';
import 'package:datn/features/admin/screens/admin_promotion_screen.dart';

class AdminSideMenu extends StatelessWidget {
  final String currentRoute;

  const AdminSideMenu({super.key, required this.currentRoute});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      elevation: 0,
      backgroundColor: const Color(0xFF0F172A), // Tailwind Slate 900 - Dark Premium
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      child: Column(
        children: [
          _buildLogoHeader(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildSectionHeader('MAIN MENU'),
                _DrawerListTile(
                  title: "Tổng Quan",
                  icon: Icons.grid_view_rounded,
                  isSelected: currentRoute == 'dashboard',
                  onTap: () {
                    if (currentRoute != 'dashboard') {
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const AdminDashboardScreen(),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    }
                  },
                ),
                _DrawerListTile(
                  title: "Người Dùng",
                  icon: Icons.people_alt_rounded,
                  isSelected: currentRoute == 'users',
                  onTap: () {
                    if (currentRoute != 'users') {
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const AdminUserManagementScreen(),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    }
                  },
                ),
                _DrawerListTile(
                  title: "Khuyến Mãi",
                  icon: Icons.local_offer_rounded,
                  isSelected: currentRoute == 'promotions',
                  onTap: () {
                    if (currentRoute != 'promotions') {
                      Navigator.of(context).pushReplacement(
                        PageRouteBuilder(
                          pageBuilder: (context, animation, secondaryAnimation) => const AdminPromotionScreen(),
                          transitionDuration: Duration.zero,
                          reverseTransitionDuration: Duration.zero,
                        ),
                      );
                    }
                  },
                ),
                
                const SizedBox(height: 24),
                _buildSectionHeader('HỆ THỐNG'),
                _DrawerListTile(
                  title: "Cài Đặt",
                  icon: Icons.settings_rounded,
                  isSelected: false,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Tính năng đang phát triển')),
                    );
                  },
                ),
                _DrawerListTile(
                  title: "Quay lại ứng dụng",
                  icon: Icons.exit_to_app_rounded,
                  isSelected: false,
                  onTap: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
              ],
            ),
          ),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildLogoHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1120), // Darker shade for header
        border: Border(bottom: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], // Indigo to Purple
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Color(0x666366F1),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                )
              ],
            ),
            child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          const Text(
            'DATN Admin',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 24, right: 24, bottom: 8, top: 16),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: Color(0xFF64748B),
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Color(0xFF1E293B))),
      ),
      child: const Row(
        children: [
          CircleAvatar(
            backgroundColor: Color(0xFF334155),
            radius: 16,
            child: Icon(Icons.person, size: 20, color: Colors.white),
          ),
          SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Super Admin',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              Text(
                'admin@datn.vn',
                style: TextStyle(
                  color: Color(0xFF94A3B8),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DrawerListTile extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _DrawerListTile({
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_DrawerListTile> createState() => _DrawerListTileState();
}

class _DrawerListTileState extends State<_DrawerListTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? const Color(0xFF1E293B)
                : (_isHovered ? const Color(0xFF1E293B).withAlpha(128) : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: widget.isSelected
                  ? const Color(0xFF334155)
                  : Colors.transparent,
            ),
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: widget.isSelected ? const Color(0xFF818CF8) : const Color(0xFF94A3B8),
                size: 22,
              ),
              const SizedBox(width: 16),
              Text(
                widget.title,
                style: TextStyle(
                  fontWeight: widget.isSelected ? FontWeight.bold : FontWeight.w500,
                  color: widget.isSelected ? Colors.white : const Color(0xFFCBD5E1),
                  fontSize: 15,
                ),
              ),
              const Spacer(),
              if (widget.isSelected)
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFF818CF8),
                    shape: BoxShape.circle,
                  ),
                )
            ],
          ),
        ),
      ),
    );
  }
}
