import 'package:flutter/material.dart';
import 'package:datn/l10n/generated/app_localizations.dart';

class SupermarketDetailScreen extends StatefulWidget {
  final String supermarketName;
  final double rating;
  final String distance;
  final String imagePath;

  const SupermarketDetailScreen({
    super.key,
    required this.supermarketName,
    required this.rating,
    required this.distance,
    required this.imagePath,
  });

  @override
  State<SupermarketDetailScreen> createState() => _SupermarketDetailScreenState();
}

class _SupermarketDetailScreenState extends State<SupermarketDetailScreen> {
  // Biến lưu trữ giỏ hàng: Key là tên sản phẩm, Value là số lượng và giá
  final Map<String, Map<String, dynamic>> _cart = {};

  final List<Map<String, dynamic>> _mockProducts = [
    {
      'name': 'Cải thảo tươi Đà Lạt',
      'price': 15000.0,
      'unit': '1 kg',
      'icon': Icons.grass,
      'color': Colors.green,
    },
    {
      'name': 'Cam sành loại 1',
      'price': 25000.0,
      'unit': '1 kg',
      'icon': Icons.apple,
      'color': Colors.orange,
    },
    {
      'name': 'Thịt bò Úc thái lát',
      'price': 150000.0,
      'unit': '500g',
      'icon': Icons.set_meal,
      'color': Colors.redAccent,
    },
    {
      'name': 'Gà ta nguyên con sạch',
      'price': 120000.0,
      'unit': 'Con',
      'icon': Icons.egg,
      'color': Colors.amber,
    },
    {
      'name': 'Nước giải khát Coca-Cola',
      'price': 10000.0,
      'unit': '1 lon',
      'icon': Icons.local_drink,
      'color': Colors.red,
    },
    {
      'name': 'Bánh mì sandwich',
      'price': 20000.0,
      'unit': '1 bịch',
      'icon': Icons.bakery_dining,
      'color': Colors.brown,
    },
  ];

  int get _totalItems {
    return _cart.values.fold(0, (sum, item) => sum + (item['quantity'] as int));
  }

  double get _totalPrice {
    return _cart.values.fold(0.0, (sum, item) => sum + ((item['quantity'] as int) * (item['price'] as double)));
  }

  void _addToCart(Map<String, dynamic> product) {
    setState(() {
      if (_cart.containsKey(product['name'])) {
        _cart[product['name']]!['quantity'] += 1;
      } else {
        _cart[product['name']] = {
          'price': product['price'],
          'quantity': 1,
          'icon': product['icon'],
          'color': product['color'],
        };
      }
    });

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã thêm ${product['name']} vào giỏ hàng!'),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // Header Banner
              SliverAppBar(
                expandedHeight: 200.0,
                pinned: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(
                    widget.supermarketName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      shadows: [Shadow(color: Colors.black54, blurRadius: 10)],
                    ),
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(color: Colors.orange), // Fallback
                      Image.asset(
                        'assets/images/pizza.png', // Fallback to generic pizza image
                        fit: BoxFit.cover,
                        color: Colors.black.withValues(alpha: 0.3),
                        colorBlendMode: BlendMode.darken,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(color: Colors.orangeAccent),
                      ),
                      Positioned(
                        bottom: 40,
                        left: 16,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.orange, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.rating.toString(),
                                    style: const TextStyle(
                                        color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.location_on, color: Colors.grey, size: 14),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.distance,
                                    style: const TextStyle(
                                        color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
                leading: Container(
                  margin: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.white54,
                    shape: BoxShape.circle,
                  ),
                  child: const BackButton(color: Colors.black),
                ),
              ),

              // Categories Bubble
              SliverToBoxAdapter(
                child: SizedBox(
                  height: 60,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    children: [
                      _buildFilterChip('Tất cả', true),
                      _buildFilterChip('Rau củ', false),
                      _buildFilterChip('Trái cây', false),
                      _buildFilterChip('Thịt cá', false),
                      _buildFilterChip('Đồ uống', false),
                    ],
                  ),
                ),
              ),

              // Products Grid
              SliverPadding(
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 100),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final product = _mockProducts[index];
                      return _buildProductCard(product, isDark);
                    },
                    childCount: _mockProducts.length,
                  ),
                ),
              ),
            ],
          ),

          // Floating Cart Button
          if (_totalItems > 0)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: GestureDetector(
                onTap: _showCheckoutDialog,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFE724C),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFFE724C).withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.shopping_basket, color: Colors.white),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$_totalItems món',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const Text(
                            'Đến trang thanh toán',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        '${_totalPrice.toStringAsFixed(0)} đ',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFFE724C) : Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFFFE724C) : Theme.of(context).dividerColor,
        ),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).textTheme.bodyLarge?.color,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product, bool isDark) {
    Color iconColor = product['color'] as Color;
    
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image / Icon
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Center(
                child: Icon(product['icon'], color: iconColor, size: 60),
              ),
            ),
          ),
          
          // Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['name'],
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  product['unit'],
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${product['price'].toStringAsFixed(0)} đ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFE724C),
                        fontSize: 16,
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _addToCart(product),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFFE724C),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  void _showCheckoutDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Column(
            children: [
              Icon(Icons.check_circle, color: Colors.green, size: 60),
              SizedBox(height: 16),
              Text('Đặt hàng thành công!', textAlign: TextAlign.center),
            ],
          ),
          content: Text(
            'Đơn hàng tại ${widget.supermarketName} với giá ${_totalPrice.toStringAsFixed(0)} đ đã được chuyển tới tài xế. Tụi mình sẽ giao hàng đến bạn sớm nhất nhé!',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            ElevatedButton(
              onPressed: () {
                // Đóng dialog
                Navigator.pop(context);
                // Thoát về trang chủ (hoặc màn hình trước)
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFE724C),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Quay lại trang chủ', style: TextStyle(color: Colors.white)),
            )
          ],
        );
      },
    );
  }
}
