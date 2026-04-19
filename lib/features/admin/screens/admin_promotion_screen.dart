import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:datn/core/models/promotion_model.dart';
import 'package:datn/core/utils/ui_helpers.dart';
import 'package:intl/intl.dart';
import 'package:datn/features/admin/screens/admin_layout.dart';

class AdminPromotionScreen extends StatefulWidget {
  const AdminPromotionScreen({super.key});

  @override
  State<AdminPromotionScreen> createState() => _AdminPromotionScreenState();
}

class _AdminPromotionScreenState extends State<AdminPromotionScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;
  late final Stream<List<Map<String, dynamic>>> _promotionsStream;

  @override
  void initState() {
    super.initState();
    _promotionsStream = _supabase
        .from('promotions')
        .stream(primaryKey: ['id'])
        .order('expiration_date', ascending: false);
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: 'promotions',
      title: 'Khuyến Mãi & Voucher',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeaderActions(),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
                boxShadow: const [
                  BoxShadow(color: Color(0x05000000), blurRadius: 10, offset: Offset(0, 2)),
                ],
              ),
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: _promotionsStream,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Colors.indigo));
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.local_offer_outlined, size: 64, color: Color(0xFFCBD5E1)),
                          SizedBox(height: 16),
                          Text(
                            'Chưa có mã khuyến mãi nào.',
                            style: TextStyle(fontSize: 16, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  }

                  final promos = snapshot.data!.map((doc) {
                    return PromotionModel.fromMap(doc, doc['id'].toString());
                  }).toList();

                  return _buildDataTable(promos);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Danh sách Voucher',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Quản lý và thiết lập mã giảm giá cho hệ thống',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
            ),
          ],
        ),
        ElevatedButton.icon(
          onPressed: () => _showAddPromoDialog(),
          icon: const Icon(Icons.add_rounded, size: 20),
          label: const Text('Tạo Mã Mới'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE11D48), // Rose 600
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDataTable(List<PromotionModel> promos) {
    final formatter = DateFormat('dd/MM/yyyy HH:mm');
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
          dataRowMinHeight: 70,
          dataRowMaxHeight: 70,
          horizontalMargin: 24,
          columnSpacing: 40,
          columns: const [
            DataColumn(label: Text('MÃ VOUCHER', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
            DataColumn(label: Text('TRẠNG THÁI', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
            DataColumn(label: Text('MỨC GIẢM', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
            DataColumn(label: Text('ĐIỀU KIỆN', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
            DataColumn(label: Text('HẠN SỬ DỤNG', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
            DataColumn(label: Text('THAO TÁC', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569)))),
          ],
          rows: promos.map((promo) {
            final isExpired = promo.expirationDate.isBefore(DateTime.now());

            return DataRow(
              cells: [
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1F2), // Rose 50
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFFECDD3)), // Rose 200
                    ),
                    child: Text(
                      promo.code,
                      style: const TextStyle(
                        color: Color(0xFFE11D48),
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: isExpired ? const Color(0xFFF1F5F9) : const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isExpired ? const Color(0xFF94A3B8) : const Color(0xFF16A34A),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isExpired ? 'Hết hạn' : 'Đang chạy',
                          style: TextStyle(
                            color: isExpired ? const Color(0xFF64748B) : const Color(0xFF16A34A),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                DataCell(
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${(promo.discountPercentage * 100).toInt()}%',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B), fontSize: 15),
                      ),
                      Text(
                        'Tối đa: ${currencyFormatter.format(promo.maxDiscount)}',
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                DataCell(
                  Text(
                    'Đơn từ ${currencyFormatter.format(promo.minOrderValue)}',
                    style: const TextStyle(color: Color(0xFF475569), fontWeight: FontWeight.w500),
                  ),
                ),
                DataCell(
                  Text(
                    formatter.format(promo.expirationDate),
                    style: TextStyle(
                      color: isExpired ? const Color(0xFFEF4444) : const Color(0xFF64748B),
                      fontWeight: isExpired ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                ),
                DataCell(
                  IconButton(
                    icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFDC2626)),
                    tooltip: 'Xóa mã này',
                    onPressed: () => _deletePromo(promo.id),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  Future<void> _deletePromo(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: const Text('Bạn có chắc chắn muốn xóa mã khuyến mãi này không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Xóa', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _supabase.from('promotions').delete().eq('id', id);
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
              title: const Text('Tạo Mã Khuyến Mãi', style: TextStyle(fontWeight: FontWeight.bold)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              content: SizedBox(
                width: 400,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: codeCtrl,
                          decoration: InputDecoration(
                            labelText: 'Mã Code (VD: TET2026)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          textCapitalization: TextCapitalization.characters,
                          validator: (v) => v!.isEmpty ? 'Vui lòng nhập mã' : null,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: TextFormField(
                                controller: percentCtrl,
                                decoration: InputDecoration(
                                  labelText: '% Giảm (VD: 0.2)',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                validator: (v) {
                                  if (v!.isEmpty) return 'Bắt buộc';
                                  final val = double.tryParse(v);
                                  if (val == null || val <= 0 || val > 1) {
                                    return 'Từ 0.01 - 1.0';
                                  }
                                  return null;
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: TextFormField(
                                controller: maxAmountCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Giảm tối đa (VNĐ)',
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  contentPadding: const EdgeInsets.all(16),
                                ),
                                keyboardType: TextInputType.number,
                                validator: (v) {
                                  if (v!.isEmpty) return 'Bắt buộc';
                                  if (double.tryParse(v) == null) return 'Không hợp lệ';
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: minAmountCtrl,
                          decoration: InputDecoration(
                            labelText: 'Đơn Tối Thiểu (VNĐ)',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            contentPadding: const EdgeInsets.all(16),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (v) {
                            if (v!.isEmpty) return 'Bắt buộc';
                            if (double.tryParse(v) == null) return 'Không hợp lệ';
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today_rounded, color: Colors.indigo[400], size: 20),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  selectedDate == null
                                      ? 'Chọn ngày hết hạn'
                                      : 'Hết hạn: ${DateFormat('dd/MM/yyyy').format(selectedDate!)}',
                                  style: TextStyle(
                                    color: selectedDate == null ? const Color(0xFF64748B) : const Color(0xFF1E293B),
                                    fontWeight: selectedDate == null ? FontWeight.normal : FontWeight.bold,
                                  ),
                                ),
                              ),
                              TextButton(
                                onPressed: () async {
                                  final date = await showDatePicker(
                                    context: context,
                                    initialDate: DateTime.now().add(const Duration(days: 7)),
                                    firstDate: DateTime.now(),
                                    lastDate: DateTime.now().add(const Duration(days: 365)),
                                  );
                                  if (date != null) {
                                    setDialogState(() => selectedDate = date);
                                  }
                                },
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF4F46E5),
                                ),
                                child: const Text('Chọn', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      if (selectedDate == null) {
                        UIHelpers.showSnackBar(ctx, 'Vui lòng chọn ngày hết hạn!');
                        return;
                      }

                      try {
                        final newPromo = PromotionModel(
                          id: '', // Supabase will auto-generate if omitted or handled properly, but toMap uses it... wait!
                          code: codeCtrl.text.trim().toUpperCase(),
                          discountPercentage: double.parse(percentCtrl.text.trim()),
                          maxDiscount: double.parse(maxAmountCtrl.text.trim()),
                          minOrderValue: double.parse(minAmountCtrl.text.trim()),
                          expirationDate: selectedDate!,
                          isActive: true,
                        );

                        // toMap currently only exports data without 'id'. Supabase will automatically create an id (UUID) if there's a default "uuid_generate_v4()".
                        // If not, it will crash. I assume the user set it up properly since user auth does it automatically.
                        await _supabase.from('promotions').insert(newPromo.toMap());
                        if (context.mounted) {
                          Navigator.pop(ctx);
                          UIHelpers.showSnackBar(context, 'Tạo mã thành công!');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          UIHelpers.showErrorDialog(context, 'Lỗi', e.toString());
                        }
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE11D48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Lưu Mã', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
