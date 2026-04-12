import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:datn/features/merchant/services/merchant_service.dart';
import 'package:datn/features/merchant/screens/edit_menu_item_screen.dart';
import 'package:intl/intl.dart';

class MerchantMenuScreen extends StatefulWidget {
  const MerchantMenuScreen({super.key});

  @override
  State<MerchantMenuScreen> createState() => _MerchantMenuScreenState();
}

class _MerchantMenuScreenState extends State<MerchantMenuScreen> {
  final MerchantService _merchantService = MerchantService();
  String? _merchantId;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

  @override
  void initState() {
    super.initState();
    _merchantId = Supabase.instance.client.auth.currentUser?.id;
  }

  void _toggleAvailability(String itemId, bool isAvailable) async {
    if (_merchantId == null) return;
    try {
      await _merchantService.toggleMenuItemAvailability(
        _merchantId!,
        itemId,
        isAvailable,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  void _showAddDialog() {
    if (_merchantId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditMenuItemScreen(
          onSave: (data) async {
            await _merchantService.addMenuItem(_merchantId!, data);
          },
        ),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> itemData) {
    if (_merchantId == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => EditMenuItemScreen(
          initialItem: itemData,
          onSave: (data) async {
            await _merchantService.updateMenuItem(
              _merchantId!,
              itemData['id'],
              data,
            );
          },
        ),
      ),
    );
  }

  void _confirmDelete(String itemId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa Món Ăn'),
        content: const Text('Bạn có chắc chắn muốn xóa món này khỏi thực đơn?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              if (_merchantId != null) {
                await _merchantService.deleteMenuItem(_merchantId!, itemId);
              }
            },
            child: const Text('Xóa', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_merchantId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Thực Đơn Của Quán')),
        body: const Center(child: Text("Yêu cầu đăng nhập")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Thực Đơn'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 1,
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFFFE724C),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _merchantService.streamMenuItems(_merchantId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Lỗi tải thực đơn: ${snapshot.error}'));
          }

          final items = snapshot.data ?? [];

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.restaurant_menu,
                    size: 80,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Thực đơn đang trống.",
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final isAvailable = item['isAvailable'] ?? true;
              final itemId = item['id'];

              return InkWell(
                onTap: () => _showEditDialog(item),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[200],
                        child:
                            item['imageUrl'] != null &&
                                item['imageUrl'].isNotEmpty
                            ? Image.network(
                                item['imageUrl'],
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(
                                      Icons.fastfood,
                                      color: Colors.grey,
                                    ),
                              )
                            : const Icon(Icons.fastfood, color: Colors.grey),
                      ),
                    ),
                    title: Text(
                      item['name'] ?? 'Món ăn',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        decoration: isAvailable
                            ? TextDecoration.none
                            : TextDecoration.lineThrough,
                        color: isAvailable
                            ? Theme.of(context).textTheme.bodyLarge?.color
                            : Colors.grey,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          currencyFormatter.format(item['price'] ?? 0),
                          style: const TextStyle(
                            color: Color(0xFFFE724C),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (item['description'] != null &&
                            item['description'].toString().isNotEmpty)
                          Text(
                            item['description'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Switch(
                          value: isAvailable,
                          activeThumbColor: Colors.green,
                          activeTrackColor: Colors.green[200],
                          inactiveThumbColor: Colors.red,
                          inactiveTrackColor: Colors.red[200],
                          onChanged: (val) => _toggleAvailability(itemId, val),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.red,
                          ),
                          onPressed: () => _confirmDelete(itemId),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
