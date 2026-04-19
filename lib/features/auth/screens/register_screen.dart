import 'package:datn/features/auth/services/auth_service.dart';
import 'package:datn/core/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:datn/l10n/app_localizations.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralCodeController = TextEditingController();
  UserRole _selectedRole = UserRole.customer;
  String _selectedDriverType = 'grab';

  final AuthService _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();
    final referralCode = _referralCodeController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = "Vui lòng nhập đầy đủ Email và Mật khẩu.";
        _isLoading = false;
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        _errorMessage = "Mật khẩu xác nhận không khớp.";
        _isLoading = false;
      });
      return;
    }

    try {
      await _authService.createUser(
        email: email,
        password: password,
        role: _selectedRole,
        referralCode: referralCode.isNotEmpty ? referralCode : null,
        driverType: _selectedRole == UserRole.driver
            ? _selectedDriverType
            : null,
      );
      // Success, RootDispatcher will handle the auth state change and navigate
      if (mounted) {
        Navigator.pop(context); // Go back to login/root
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Lỗi đăng ký: ${e.toString()}";
      });
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

    // We try to use localizations, fallback to Vietnamese
    final t = AppLocalizations.of(context);
    final emailLabel = t?.email ?? "Email";
    final passwordLabel = t?.password ?? "Mật khẩu";
    final registerLabel =
        "Đăng ký"; // Using hardcoded fallback for simplicity since app_en.arb might not have it yet
    final confirmPasswordLabel = "Xác nhận mật khẩu";
    final roleCustomerLabel = t?.roleCustomer ?? "Khách hàng";
    final roleDriverLabel = t?.roleDriver ?? "Tài xế";
    final roleMerchantLabel = t?.roleMerchant ?? "Cửa hàng";

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(registerLabel),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Tạo Tài Khoản Mới",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Đăng ký để trải nghiệm dịch vụ và nhận ưu đãi!",
                style: const TextStyle(color: Colors.grey, fontSize: 16),
              ),
              const SizedBox(height: 30),

              if (_errorMessage != null) ...[
                Container(
                  width: double.infinity,
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

              // Vai trò
              const Text(
                "Bạn là ai?",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              SegmentedButton<UserRole>(
                segments: [
                  ButtonSegment(
                    value: UserRole.customer,
                    label: Text(
                      roleCustomerLabel,
                      style: const TextStyle(fontSize: 12),
                    ),
                    icon: const Icon(Icons.person),
                  ),
                  ButtonSegment(
                    value: UserRole.driver,
                    label: Text(
                      roleDriverLabel,
                      style: const TextStyle(fontSize: 12),
                    ),
                    icon: const Icon(Icons.motorcycle),
                  ),
                  ButtonSegment(
                    value: UserRole.merchant,
                    label: Text(
                      roleMerchantLabel,
                      style: const TextStyle(fontSize: 12),
                    ),
                    icon: const Icon(Icons.store),
                  ),
                ],
                selected: {_selectedRole},
                onSelectionChanged: (Set<UserRole> newSelection) {
                  setState(() {
                    _selectedRole = newSelection.first;
                  });
                },
                style: ButtonStyle(
                  iconColor: WidgetStateProperty.resolveWith<Color>((states) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.white;
                    }
                    return const Color(0xFFFE724C);
                  }),
                  backgroundColor: WidgetStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return const Color(0xFFFE724C);
                    }
                    return Colors.transparent;
                  }),
                  foregroundColor: WidgetStateProperty.resolveWith<Color>((
                    states,
                  ) {
                    if (states.contains(WidgetState.selected)) {
                      return Colors.white;
                    }
                    return isDark ? Colors.white : Colors.black;
                  }),
                ),
              ),
              if (_selectedRole == UserRole.driver) ...[
                const SizedBox(height: 16),
                const Text(
                  "Hãng xe hoạt động:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 8),
                SegmentedButton<String>(
                  segments: [
                    ButtonSegment(
                      value: 'grab',
                      label: Text('Grab'),
                      icon: Image.asset(
                        'assets/images/grab.png',
                        width: 20,
                        height: 20,
                        errorBuilder: (c, e, s) =>
                            const Icon(Icons.two_wheeler, size: 16),
                      ),
                    ),
                    ButtonSegment(
                      value: 'be',
                      label: Text('Be'),
                      icon: Image.asset(
                        'assets/images/be.png',
                        width: 20,
                        height: 20,
                        errorBuilder: (c, e, s) =>
                            const Icon(Icons.two_wheeler, size: 16),
                      ),
                    ),
                    ButtonSegment(
                      value: 'xanhsm',
                      label: Text('Xanh SM'),
                      icon: Image.asset(
                        'assets/images/xanhsm.png',
                        width: 20,
                        height: 20,
                        errorBuilder: (c, e, s) =>
                            const Icon(Icons.two_wheeler, size: 16),
                      ),
                    ),
                  ],
                  selected: {_selectedDriverType},
                  onSelectionChanged: (Set<String> newSelection) {
                    setState(() {
                      _selectedDriverType = newSelection.first;
                    });
                  },
                  style: ButtonStyle(
                    iconColor: WidgetStateProperty.resolveWith<Color>((states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return const Color(0xFFFE724C);
                    }),
                    backgroundColor: WidgetStateProperty.resolveWith<Color>((
                      states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return const Color(0xFFFE724C);
                      }
                      return Colors.transparent;
                    }),
                    foregroundColor: WidgetStateProperty.resolveWith<Color>((
                      states,
                    ) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.white;
                      }
                      return isDark ? Colors.white : Colors.black;
                    }),
                  ),
                ),
              ],
              const SizedBox(height: 24),

              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: emailLabel,
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
                  labelText: passwordLabel,
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
              const SizedBox(height: 16),

              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: confirmPasswordLabel,
                  prefixIcon: const Icon(Icons.lock_reset),
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
              const SizedBox(height: 16),

              // Referral Code
              TextField(
                controller: _referralCodeController,
                decoration: InputDecoration(
                  labelText: "Mã giới thiệu (Không bắt buộc)",
                  hintText: "Nhập mã để nhận ngay 50.000đ",
                  prefixIcon: const Icon(
                    Icons.card_giftcard,
                    color: Colors.green,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.green.shade200,
                      width: 2,
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: Colors.green.shade200,
                      width: 2,
                    ),
                  ),
                  filled: true,
                  fillColor: isDark
                      ? const Color(0xFF2A2C38)
                      : Colors.green.shade50,
                ),
              ),
              const SizedBox(height: 40),

              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _register,
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
                          registerLabel,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
