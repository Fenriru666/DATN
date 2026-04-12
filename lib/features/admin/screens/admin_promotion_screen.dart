import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datn/core/models/promotion_model.dart';
import 'package:datn/core/utils/ui_helpers.dart';
import 'package:intl/intl.dart';

class AdminPromotionScreen extends StatefulWidget {
  const AdminPromotionScreen({super.key});

  @override
  State<AdminPromotionScreen> createState() => _AdminPromotionScreenState();
}

class _AdminPromotionScreenState extends State<AdminPromotionScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Khuyến Mãi'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.grey[100],
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('promotions')
            .orderBy('expiryDate', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'Chưa có mã khuyến mãi nào.',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            );
          }

          final promos = snapshot.data!.docs.map((doc) {
            return PromotionModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: promos.length,
            itemBuilder: (context, index) {
              return _buildPromoCard(promos[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddPromoDialog(),
        backgroundColor: Colors.pink,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tạo Mã Mới', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  Widget _buildPromoCard(PromotionModel promo) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '₫',
    );
    final isExpired = promo.expirationDate.isBefore(DateTime.now());

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.pink.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.pink.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    promo.code,
                    style: const TextStyle(
                      color: Colors.pink,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: isExpired
                        ? Colors.red.withValues(alpha: 0.1)
                        : Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    isExpired ? 'Hết hạn' : 'Đang chạy',
                    style: TextStyle(
                      color: isExpired ? Colors.red : Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mức giảm',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      '${(promo.discountPercentage * 100).toInt()}%',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Đơn tối thiểu',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      currencyFormatter.format(promo.minOrderValue),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Giảm tối đa',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    Text(
                      currencyFormatter.format(promo.maxDiscount),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Hết hạn: ${formatter.format(promo.expirationDate)}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isExpired ? Colors.red : Colors.grey[700],
                    fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deletePromo(promo.id),
                  tooltip: 'Xóa mã này',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deletePromo(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text(
          'Bạn có chắc chắn muốn xóa mã khuyến mãi này không?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _firestore.collection('promotions').doc(id).delete();
        if (mounted) UIHelpers.showSnackBar(context, 'Xóa mã thành công!');
      } catch (e) {
        if (mounted) UIHelpers.showErrorDialog(context, 'Lỗi', e.toString());
      }
    }
  }

  void _showAddPromoDialog() {
    final formKey = GlobalKey<FormState>();
    final codeCtrl = TextEditingController();
    final percentCtrl = TextEditingController();
    final maxAmountCtrl = TextEditingController();
    final minAmountCtrl = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Tạo Mã Khuyến Mãi'),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: codeCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Mã Code (VD: TET2026)',
                        ),
                        textCapitalization: TextCapitalization.characters,
                        validator: (v) =>
                            v!.isEmpty ? 'Vui lòng nhập mã' : null,
                      ),
                      TextFormField(
                        controller: percentCtrl,
                        decoration: const InputDecoration(
                          labelText: '% Giảm (VD: 0.2 cho 20%)',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) {
                          if (v!.isEmpty) return 'Bắt buộc';
                          final val = double.tryParse(v);
                          if (val == null || val <= 0 || val > 1) {
                            return 'Nhập từ 0.01 đến 1.0';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: maxAmountCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Giảm tối đa (VNĐ)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v!.isEmpty) return 'Bắt buộc';
                          if (double.tryParse(v) == null) {
                            return 'Phải là số hợp lệ';
                          }
                          return null;
                        },
                      ),
                      TextFormField(
                        controller: minAmountCtrl,
                        decoration: const InputDecoration(
                          labelText: 'Đơn Tối Thiểu (VNĐ)',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (v) {
                          if (v!.isEmpty) return 'Bắt buộc';
                          if (double.tryParse(v) == null) {
                            return 'Phải là số hợp lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              selectedDate == null
                                  ? 'Chưa chọn ngày hết hạn'
                                  : 'Hết hạn: ${DateFormat('dd/MM/yyyy').format(selectedDate!)}',
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              final date = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now().add(
                                  const Duration(days: 7),
                                ),
                                firstDate: DateTime.now(),
                                lastDate: DateTime.now().add(
                                  const Duration(days: 365),
                                ),
                              );
                              if (date != null) {
                                setDialogState(() => selectedDate = date);
                              }
                            },
                            child: const Text('Chọn Ngày'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      if (selectedDate == null) {
                        UIHelpers.showSnackBar(
                          ctx,
                          'Vui lòng chọn ngày hết hạn!',
                        );
                        return;
                      }

                      try {
                        final newPromo = PromotionModel(
                          id: '',
                          code: codeCtrl.text.trim().toUpperCase(),
                          discountPercentage: double.parse(
                            percentCtrl.text.trim(),
                          ),
                          maxDiscount: double.parse(maxAmountCtrl.text.trim()),
                          minOrderValue: double.parse(
                            minAmountCtrl.text.trim(),
                          ),
                          expirationDate: selectedDate!,
                          isActive: true,
                        );

                        await _firestore
                            .collection('promotions')
                            .add(newPromo.toMap());
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          UIHelpers.showSnackBar(context, 'Tạo mã thành công!');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          UIHelpers.showErrorDialog(
                            context,
                            'Lỗi',
                            e.toString(),
                          );
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
                  child: const Text(
                    'Lưu',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
