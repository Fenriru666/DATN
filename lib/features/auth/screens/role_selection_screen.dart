import 'package:flutter/material.dart';
import 'package:datn/core/models/user_model.dart';
import 'package:datn/features/customer/screens/customer_home_screen.dart';
import 'package:datn/features/driver/screens/driver_dashboard_screen.dart';
import 'package:datn/features/merchant/screens/merchant_dashboard_screen.dart';
import 'package:datn/features/admin/screens/admin_dashboard_screen.dart';
import 'package:flutter/foundation.dart';

class RoleSelectionScreen extends StatelessWidget {
  final List<UserRole> roles;

  const RoleSelectionScreen({super.key, required this.roles});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose Profile'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'You have multiple roles.\nPlease select how you want to continue:',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 32),
              ...roles.map(
                (role) => Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: const TextStyle(fontSize: 18),
                    ),
                    onPressed: () => _navigateToRole(context, role),
                    child: Text(_getRoleName(role)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getRoleName(UserRole role) {
    switch (role) {
      case UserRole.customer:
        return 'Continue as Customer';
      case UserRole.driver:
        return 'Continue as Driver';
      case UserRole.merchant:
        return 'Continue as Merchant';
      case UserRole.admin:
        return 'Continue as Admin';
    }
  }

  void _navigateToRole(BuildContext context, UserRole role) {
    Widget screen;
    switch (role) {
      case UserRole.customer:
        screen = const CustomerHomeScreen();
        break;
      case UserRole.driver:
        screen = const DriverDashboardScreen();
        break;
      case UserRole.merchant:
        screen = const MerchantDashboardScreen();
        break;
      case UserRole.admin:
        if (kIsWeb) {
          screen = const AdminDashboardScreen();
        } else {
          // Reuse the logic for blocking admin on mobile if needed,
          // or just show a dialog. For now, let's just show a concise error/snack
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Admin panel is web-only.')),
          );
          return;
        }
        break;
    }

    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}
