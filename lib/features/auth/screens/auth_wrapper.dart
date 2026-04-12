import 'package:datn/core/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:datn/features/admin/screens/admin_dashboard_screen.dart';
import 'package:datn/features/auth/screens/login_screen.dart';
import 'package:datn/features/auth/services/auth_service.dart';
import 'package:datn/features/customer/screens/customer_home_screen.dart';
import 'package:datn/features/driver/screens/driver_dashboard_screen.dart';
import 'package:datn/features/merchant/screens/merchant_dashboard_screen.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final session = snapshot.data?.session;

        // Ensure user is logged in
        if (session != null) {
          // User is logged in, now fetch their role
          return FutureBuilder<UserModel?>(
            future: _authService.getCurrentUser(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }

              if (userSnapshot.hasError) {
                return Scaffold(
                  body: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            size: 48,
                            color: Colors.red,
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            "Login Error",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            userSnapshot.error.toString(),
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: () => _authService.signOut(),
                            child: const Text("Logout & Try Again"),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }

              if (userSnapshot.hasData) {
                final user = userSnapshot.data!;
                switch (user.roles.first) {
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
                      return Scaffold(
                        body: Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.block,
                                  size: 64,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "Admin Portal Restricted",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "The Admin Portal is only accessible via the Web interface. Please log in from a browser.",
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: () => _authService.signOut(),
                                  child: const Text("Logout"),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                }
              }

              // Fallback if user data not found (or error)
              // Fallback if user data not found (or error)
              return Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Error loading user profile or user not found in database.",
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => _authService.signOut(),
                        child: const Text("Logout & Try Again"),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}
