import 'package:datn/features/admin/screens/admin_dashboard_screen.dart';
import 'package:datn/core/models/user_model.dart';
import 'package:datn/features/auth/screens/login_screen.dart';
import 'package:datn/features/auth/screens/role_selection_screen.dart';
import 'package:datn/features/customer/screens/customer_home_screen.dart';
import 'package:datn/features/driver/screens/driver_dashboard_screen.dart';
import 'package:datn/features/merchant/screens/merchant_dashboard_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:datn/features/auth/providers/auth_provider.dart';

class RootDispatcher extends ConsumerWidget {
  const RootDispatcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateChangesProvider);

    return authState.when(
      data: (user) {
        if (user == null) {
          // Not logged in
          return const LoginScreen();
        }

        // Logged in, watch user profile data
        final userProfile = ref.watch(currentUserProvider);

        return userProfile.when(
          data: (model) {
            if (model == null) {
              return _buildErrorScreen("User profile not found.", ref);
            }

            final roles = model.roles;

            if (roles.isEmpty) {
              return _buildErrorScreen("No roles assigned to this user.", ref);
            }

            if (!model.isApproved) {
              return _buildPendingScreen(ref);
            }

            if (roles.length > 1) {
              return RoleSelectionScreen(roles: roles);
            }

            // Single role -> Direct navigation
            final role = roles.first;
            switch (role) {
              case UserRole.customer:
                return const CustomerHomeScreen();
              case UserRole.merchant:
                return const MerchantDashboardScreen();
              case UserRole.driver:
                return const DriverDashboardScreen();
              case UserRole.admin:
                if (kIsWeb) {
                  return const AdminDashboardScreen();
                } else {
                  return _buildRestrictedScreen(ref);
                }
            }
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, stack) => _buildErrorScreen(error.toString(), ref),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stack) => _buildErrorScreen(error.toString(), ref),
    );
  }

  Widget _buildErrorScreen(String error, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                "Login Error",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.read(authServiceProvider).signOut(),
                child: const Text("Logout & Try Again"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRestrictedScreen(WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.block, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                "Admin Portal Restricted",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "The Admin Portal is only accessible via the Web interface. Please log in from a browser.",
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => ref.read(authServiceProvider).signOut(),
                child: const Text("Logout"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingScreen(WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hourglass_empty, size: 64, color: Colors.orange),
              const SizedBox(height: 24),
              const Text(
                "Hồ sơ đang chờ duyệt",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                "Tài khoản Đối Tác của bạn đã được ghi nhận và đang chờ Admin hệ thống phê duyệt. Quá trình này có thể mất một vài ngày làm việc. Vui lòng quay lại sau!",
                style: TextStyle(fontSize: 16, color: Colors.black87),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed: () => ref.read(authServiceProvider).signOut(),
                icon: const Icon(Icons.logout),
                label: const Text("Đăng Xuất"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigo,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
