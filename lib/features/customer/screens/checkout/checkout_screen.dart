import 'package:flutter/material.dart';
import 'package:datn/features/customer/services/cart_service.dart';
import 'package:datn/features/customer/services/order_service.dart';
import 'package:datn/features/customer/services/promotion_service.dart';
import 'package:datn/core/models/order_model.dart';
import 'package:datn/core/models/promotion_model.dart';
import 'package:datn/core/utils/ui_helpers.dart';
import 'package:datn/features/customer/screens/checkout/order_success_screen.dart';
import 'package:datn/features/customer/screens/location/location_selection_screen.dart';
import 'package:latlong2/latlong.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final CartService _cartService = CartService();
  final PromotionService _promotionService = PromotionService();

  final TextEditingController _promoController = TextEditingController();
  PromotionModel? _appliedPromo;

  bool _isLoading = false;

  // Default to a central location (e.g. HCMC) if simpler, or just a string
  String _address = "Quận 1, TP. Hồ Chí Minh";
  LatLng? _userLocation;
  double _deliveryFee = 15000.0;
  String _selectedPaymentMethod = 'Cash'; // Default payment method

  // Mock Restaurant Location (In a real app, this comes from the CartItem's restaurant)
  final LatLng _restaurantLocation = const LatLng(10.7769, 106.7009);

  @override
  Widget build(BuildContext context) {
    // Basic validation: user should have items
    if (_cartService.items.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: const Center(child: Text("Cart is empty")),
      );
    }

    final subtotal = _cartService.totalAmount;

    // Calculate Discount
    double discountAmount = 0.0;
    if (_appliedPromo != null) {
      discountAmount = subtotal * _appliedPromo!.discountPercentage;
      if (discountAmount > _appliedPromo!.maxDiscount) {
        discountAmount = _appliedPromo!.maxDiscount;
      }
    }

    final totalAmount = subtotal + _deliveryFee - discountAmount;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Checkout', style: TextStyle(color: Theme.of(context).textTheme.titleLarge?.color)),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        elevation: 0,
        leading: BackButton(color: Theme.of(context).iconTheme.color),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Delivery Address',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.location_on, color: Colors.orange),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Home',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          _address,
                          style: const TextStyle(color: Colors.grey),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.orange),
                    onPressed: _editAddress,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Text(
              'Order Summary',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            ..._cartService.items.map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.fastfood, color: Colors.grey[400]),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${item.quantity}x',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.orange,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(item.name)),
                    Text(
                      '${(item.price * item.quantity).toInt()} ₫',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
            const Divider(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tạm tính', style: TextStyle(color: Colors.grey)),
                Text(
                  '${subtotal.toInt()} ₫',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            if (_appliedPromo != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Khuyến mãi',
                    style: TextStyle(color: Colors.green),
                  ),
                  Text(
                    '-${discountAmount.toInt()} ₫',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Phí giao hàng',
                  style: TextStyle(color: Colors.grey),
                ),
                Text(
                  '${_deliveryFee.toInt()} ₫',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Tổng cộng',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${totalAmount.toInt()} ₫',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            const Text(
              'Payment Method',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            _buildPaymentOption('Cash', Icons.money, Colors.green),
            _buildPaymentOption(
              'MoMo',
              Icons.account_balance_wallet,
              Colors.pink,
            ),
            _buildPaymentOption(
              'My Wallet',
              Icons.account_balance_wallet,
              Colors.purple,
            ),
            const SizedBox(height: 20),

            // Promo Code Section
            const Text(
              'Add Promo Code',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _promoController,
                    decoration: InputDecoration(
                      hintText: 'Enter code here...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: _applyPromoCode,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 20,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _placeOrder,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFE724C),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'ĐẶT ĐƠN',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Future<void> _placeOrder() async {
    setState(() => _isLoading = true);

    try {
      // Create Items Summary string
      final summary = _cartService.items
          .map((i) => '${i.quantity}x ${i.name}')
          .join(', ');

      // Assume first item's merchant for now
      final firstItem = _cartService.items.first;

      final newOrder = OrderModel(
        id: '', // Generated by server
        userId: '', // Set by service
        merchantId: firstItem.merchantId,
        merchantName: firstItem.merchantName,
        merchantImage: firstItem.image.startsWith('0x')
            ? firstItem.image
            : '0xFFFE724C',
        itemsSummary: summary,
        totalPrice: _cartService.totalAmount + _deliveryFee,
        status: 'Pending',
        createdAt: DateTime.now(),
        serviceType: 'Food',
        address: _address,
        paymentMethod: _selectedPaymentMethod,
      );

      // Simulating a short delay if payment is an e-wallet
      if (_selectedPaymentMethod == 'MoMo' ||
          _selectedPaymentMethod == 'ZaloPay') {
        await Future.delayed(const Duration(seconds: 2));
      }
      // Note: My Wallet deduction is handled inside OrderService().createOrder()

      await OrderService().createOrder(newOrder);
      _cartService.clearCart();

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OrderSuccessScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _editAddress() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            LocationSelectionScreen(initialPosition: _userLocation),
      ),
    );

    if (result != null && result is Map) {
      setState(() {
        _address = result['address'];
        _userLocation = result['latlng'];
      });
      _calculateDeliveryFee();
    }
  }

  void _calculateDeliveryFee() {
    if (_userLocation == null) return;

    // Simple calculation: Base 15000 + 5000 per km
    // Distance using latlong2
    final Distance distance = const Distance();
    final double km = distance.as(
      LengthUnit.Kilometer,
      _userLocation!,
      _restaurantLocation,
    );

    setState(() {
      _deliveryFee = 15000.0 + (km * 5000.0);
    });
  }

  Future<void> _applyPromoCode() async {
    final code = _promoController.text.trim();
    if (code.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      final promo = await _promotionService.validatePromoCode(
        code,
        _cartService.totalAmount,
      );
      setState(() {
        _appliedPromo = promo;
      });
      if (mounted) {
        UIHelpers.showSnackBar(context, 'Promo applied successfully!');
      }
    } catch (e) {
      if (mounted) {
        UIHelpers.showErrorDialog(context, 'Invalid Promo', e.toString());
      }
      setState(() {
        _appliedPromo = null;
        _promoController.clear();
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPaymentOption(String title, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        setState(() {
          _selectedPaymentMethod = title;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(
            color: _selectedPaymentMethod == title
                ? const Color(0xFFFE724C)
                : Colors.grey[300]!,
          ),
          borderRadius: BorderRadius.circular(12),
          color: _selectedPaymentMethod == title
              ? const Color(0xFFFE724C).withValues(alpha: 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            if (_selectedPaymentMethod == title)
              const Icon(Icons.check_circle, color: Color(0xFFFE724C)),
          ],
        ),
      ),
    );
  }
}
