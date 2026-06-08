import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datn/features/admin/screens/admin_layout.dart';

class AdminNotificationScreen extends StatefulWidget {
  const AdminNotificationScreen({super.key});

  @override
  State<AdminNotificationScreen> createState() => _AdminNotificationScreenState();
}

class _AdminNotificationScreenState extends State<AdminNotificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  
  String _selectedType = 'system';
  String _selectedTarget = 'all'; // 'all', 'customer', 'driver', 'merchant'
  bool _isSending = false;

  final SupabaseClient _supabase = Supabase.instance.client;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _sendNotification() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSending = true;
    });

    try {
      final title = _titleController.text.trim();
      final body = _bodyController.text.trim();

      // 1. Fetch target users from Supabase
      var query = _supabase.from('users').select('id, role');
      if (_selectedTarget != 'all') {
        query = query.eq('role', _selectedTarget);
      }

      final List<dynamic> users = await query;

      if (users.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không tìm thấy người dùng nào thuộc phân loại này.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          _isSending = false;
        });
        return;
      }

      // 2. Write in-app notifications to Firestore in chunks (batch max size is 500)
      int successCount = 0;
      final chunks = _chunkList(users, 400);

      for (var chunk in chunks) {
        final batch = _firestore.batch();
        for (var user in chunk) {
          final userId = user['id'] as String;
          final notificationDoc = _firestore
              .collection('users')
              .doc(userId)
              .collection('notifications')
              .doc();

          batch.set(notificationDoc, {
            'title': title,
            'body': body,
            'type': _selectedType,
            'isRead': false,
            'createdAt': FieldValue.serverTimestamp(),
            'relatedId': null,
          });
        }
        await batch.commit();
        successCount += chunk.length;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã gửi thông báo thành công tới $successCount người dùng!'),
            backgroundColor: Colors.green,
          ),
        );
        _titleController.clear();
        _bodyController.clear();
        setState(() {
          _selectedType = 'system';
          _selectedTarget = 'all';
        });
      }
    } catch (e) {
      debugPrint("Lỗi gửi thông báo: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xảy ra lỗi khi gửi: $e'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  List<List<T>> _chunkList<T>(List<T> list, int chunkSize) {
    List<List<T>> chunks = [];
    for (var i = 0; i < list.length; i += chunkSize) {
      chunks.add(list.sublist(i, i + chunkSize > list.length ? list.length : i + chunkSize));
    }
    return chunks;
  }

  @override
  Widget build(BuildContext context) {
    return AdminLayout(
      currentRoute: 'notifications',
      title: 'Thông Báo Hệ Thống',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Panel: Form
                Expanded(
                  flex: 3,
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x05000000),
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Form(
                      key: _formKey,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Soạn Thông Điệp Mới',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 20),
                            
                            // Target Dropdown
                            const Text(
                              'Đối tượng nhận tin',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedTarget,
                              decoration: _inputDecoration(prefixIcon: Icons.group_outlined),
                              items: const [
                                DropdownMenuItem(value: 'all', child: Text('Tất cả người dùng')),
                                DropdownMenuItem(value: 'customer', child: Text('Chỉ Khách hàng (Customer)')),
                                DropdownMenuItem(value: 'driver', child: Text('Chỉ Tài xế (Driver)')),
                                DropdownMenuItem(value: 'merchant', child: Text('Chỉ Cửa hàng (Merchant)')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedTarget = val);
                              },
                            ),
                            const SizedBox(height: 20),

                            // Type Dropdown
                            const Text(
                              'Phân loại tin nhắn',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                            ),
                            const SizedBox(height: 8),
                            DropdownButtonFormField<String>(
                              initialValue: _selectedType,
                              decoration: _inputDecoration(prefixIcon: Icons.label_important_outline),
                              items: const [
                                DropdownMenuItem(value: 'system', child: Text('Hệ thống / Tin tức (System)')),
                                DropdownMenuItem(value: 'promo', child: Text('Mã khuyến mãi / Ưu đãi (Promo)')),
                                DropdownMenuItem(value: 'wallet', child: Text('Ví / Khuyến khích nạp (Wallet)')),
                                DropdownMenuItem(value: 'order', child: Text('Chuyến đi / Cập nhật (Order)')),
                              ],
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedType = val);
                              },
                            ),
                            const SizedBox(height: 20),

                            // Title Field
                            const Text(
                              'Tiêu đề thông báo',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _titleController,
                              decoration: _inputDecoration(
                                hint: 'Nhập tiêu đề ngắn gọn (ví dụ: Bảo trì hệ thống)',
                                prefixIcon: Icons.title_rounded,
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập tiêu đề';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Body Field
                            const Text(
                              'Nội dung thông báo',
                              style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF475569)),
                            ),
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _bodyController,
                              maxLines: 5,
                              decoration: _inputDecoration(
                                hint: 'Soạn thảo nội dung chi tiết gửi tới người dùng...',
                              ),
                              validator: (value) {
                                if (value == null || value.trim().isEmpty) {
                                  return 'Vui lòng nhập nội dung thông báo';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 32),

                            // Submit Button
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton.icon(
                                onPressed: _isSending ? null : _sendNotification,
                                icon: _isSending 
                                    ? const SizedBox(
                                        width: 20, 
                                        height: 20, 
                                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                      )
                                    : const Icon(Icons.send_rounded, size: 20),
                                label: Text(_isSending ? 'Đang gửi...' : 'Gửi Thông Báo Ngay'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6366F1), // Indigo 600
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 24),
                // Right Panel: Tips/Preview
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildPreviewCard(),
                      const SizedBox(height: 24),
                      _buildTipsCard(),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gửi Thông Báo Người Dùng',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Phát sóng thông báo hoặc ưu đãi tới từng nhóm đối tượng người dùng cụ thể',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 15),
        ),
      ],
    );
  }

  Widget _buildPreviewCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark Navy
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bản xem trước trên Điện thoại',
            style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 1),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(20),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _getPreviewIconColor().withAlpha(40),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_getPreviewIcon(), color: _getPreviewIconColor(), size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _titleController.text.isEmpty ? 'Tiêu đề thông báo' : _titleController.text,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _bodyController.text.isEmpty 
                            ? 'Nội dung thông điệp sẽ hiển thị ở đây khi bạn nhập văn bản...' 
                            : _bodyController.text,
                        style: const TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Vừa xong',
                        style: TextStyle(color: Colors.white38, fontSize: 11),
                      ),
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildTipsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2F6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Colors.orangeAccent),
              SizedBox(width: 8),
              Text(
                'Lưu ý hướng dẫn',
                style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '• Hệ thống sẽ tự động gửi thông báo trực tiếp vào mục "Thông báo" trên ứng dụng di động của người dùng.\n\n'
            '• Hỗ trợ chia nhóm tự động (Khách hàng, Tài xế, Đối tác/Merchant) dựa trên cơ sở dữ liệu để gửi tin chính xác.\n\n'
            '• Đảm bảo nội dung thông báo ngắn gọn, rõ ràng để có tỷ lệ xem tốt nhất.',
            style: TextStyle(color: Color(0xFF475569), fontSize: 13, height: 1.5),
          )
        ],
      ),
    );
  }

  InputDecoration _inputDecoration({String? hint, IconData? prefixIcon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: const Color(0xFF94A3B8), size: 20) : null,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6366F1), width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.redAccent, width: 2),
      ),
    );
  }

  IconData _getPreviewIcon() {
    switch (_selectedType) {
      case 'promo': return Icons.local_offer_rounded;
      case 'wallet': return Icons.account_balance_wallet_rounded;
      case 'order': return Icons.receipt_long_rounded;
      case 'system':
      default:
        return Icons.notifications_rounded;
    }
  }

  Color _getPreviewIconColor() {
    switch (_selectedType) {
      case 'promo': return Colors.greenAccent;
      case 'wallet': return Colors.blueAccent;
      case 'order': return Colors.orangeAccent;
      case 'system':
      default:
        return const Color(0xFFFE724C);
    }
  }
}
