import 'package:datn/features/auth/services/auth_service.dart';
import 'package:datn/features/auth/screens/register_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:datn/l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    // 1. Reset state
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // 2. Local Validation
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      if (mounted) {
        setState(() {
          _errorMessage = "Please enter both email and password.";
          _isLoading = false;
        });
      }
      return;
    }

    try {
      await _authService.signIn(email, password);
      // Success: RootDispatcher will redirect
    } catch (e) {
      // 3. User Friendly Errors
      String msg = "An error occurred. Please try again.";
      final errorStr = e.toString().toLowerCase();

      if (errorStr.contains('invalid login credentials')) {
        msg = "Sai email hoặc mật khẩu (Hoặc User chưa tồn tại).";
      } else if (errorStr.contains('email not confirmed')) {
        msg =
            "Tài khoản chưa được xác thực Email. Vui lòng tắt tính năng Confirm Email trên Supabase.";
      } else {
        msg = "Lỗi Supabase: ${e.toString()}"; // Show raw error for debugging
      }

      if (mounted) {
        setState(() {
          _errorMessage = msg;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 24.0,
              vertical: 40.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Branding
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFE724C).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hub,
                    size: 60,
                    color: Color(0xFFFE724C),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  AppLocalizations.of(context)!.welcomeBack,
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  AppLocalizations.of(context)!.signInToContinue,
                  style: const TextStyle(color: Colors.grey, fontSize: 16),
                ),
                const SizedBox(height: 40),

                if (_errorMessage != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],

                // Inputs
                TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.email,
                    prefixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF2A2C38)
                        : Colors.grey[100],
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: AppLocalizations.of(context)!.password,
                    prefixIcon: const Icon(Icons.lock_outline),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: isDark
                        ? const Color(0xFF2A2C38)
                        : Colors.grey[100],
                  ),
                  obscureText: true,
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () {},
                    child: Text(
                      AppLocalizations.of(context)!.forgotPassword,
                      style: const TextStyle(color: Color(0xFFFE724C)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Login Button
                _isLoading
                    ? const CircularProgressIndicator()
                    : SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFE724C),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 5,
                            shadowColor: const Color(
                              0xFFFE724C,
                            ).withValues(alpha: 0.4),
                          ),
                          child: Text(
                            AppLocalizations.of(context)!.login,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                const SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(child: Divider()),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        AppLocalizations.of(context)!.or,
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    Expanded(child: Divider()),
                  ],
                ),
                const SizedBox(height: 30),

                // Socials
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _SocialButton(
                      icon: Icons.facebook,
                      color: Colors.blue[800]!,
                    ),
                    const SizedBox(width: 20),
                    const _SocialButton(
                      icon: Icons.g_mobiledata,
                      color: Colors.red,
                    ), // Placeholder for Google
                  ],
                ),
                const SizedBox(height: 40),

                // Test Accounts (Styled)
                Text(
                  AppLocalizations.of(context)!.quickLogin,
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8.0,
                  alignment: WrapAlignment.center,
                  children: [
                    _TestAccountChip(
                      label: AppLocalizations.of(context)!.roleCustomer,
                      onTap: () {
                        _emailController.text = 'test1@gmail.com';
                        _passwordController.text = '123456';
                      },
                    ),
                    _TestAccountChip(
                      label: AppLocalizations.of(context)!.roleMerchant,
                      onTap: () {
                        _emailController.text = 'test2@gmail.com';
                        _passwordController.text = '123456';
                      },
                    ),
                    _TestAccountChip(
                      label: AppLocalizations.of(context)!.roleDriver,
                      onTap: () {
                        _emailController.text = 'test3@gmail.com';
                        _passwordController.text = '123456';
                      },
                    ),
                    if (kIsWeb)
                      _TestAccountChip(
                        label: AppLocalizations.of(context)!.roleAdmin,
                        onTap: () {
                          _emailController.text = 'admin@gmail.com';
                          _passwordController.text = '123456';
                        },
                      ),
                  ],
                ),
                const SizedBox(height: 20),

                // Register Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Chưa có tài khoản?",
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: const Text(
                        "Đăng ký ngay",
                        style: TextStyle(
                          color: Color(0xFFFE724C),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  const _SocialButton({required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).cardColor,
      ),
      child: Icon(icon, color: color, size: 30),
    );
  }
}

class _TestAccountChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TestAccountChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: Theme.of(context).textTheme.bodyMedium?.color,
        ),
      ),
      backgroundColor: Theme.of(context).cardColor,
      side: BorderSide(color: Colors.grey.withValues(alpha: 0.3)),
      onPressed: onTap,
    );
  }
}
