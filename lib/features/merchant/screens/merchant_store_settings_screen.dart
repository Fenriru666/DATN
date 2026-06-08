import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:latlong2/latlong.dart';
import 'package:datn/features/customer/screens/location/location_selection_screen.dart';

class MerchantStoreSettingsScreen extends StatefulWidget {
  const MerchantStoreSettingsScreen({super.key});

  @override
  State<MerchantStoreSettingsScreen> createState() =>
      _MerchantStoreSettingsScreenState();
}

class _MerchantStoreSettingsScreenState
    extends State<MerchantStoreSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;

  // Form fields
  late TextEditingController _nameCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _deliveryFeeCtrl;
  late TextEditingController _timeCtrl;
  late TextEditingController _imageUrlCtrl;
  late TextEditingController _tagsCtrl;

  LatLng? _location;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController();
    _addressCtrl = TextEditingController();
    _deliveryFeeCtrl = TextEditingController(text: '15000');
    _timeCtrl = TextEditingController(text: '15-25 min');
    _imageUrlCtrl = TextEditingController();
    _tagsCtrl = TextEditingController();
    _loadCurrentData();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _addressCtrl.dispose();
    _deliveryFeeCtrl.dispose();
    _timeCtrl.dispose();
    _imageUrlCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentData() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(user.id)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _nameCtrl.text = data['name'] ?? '';
        _addressCtrl.text = data['address'] ?? '';
        _deliveryFeeCtrl.text =
            (data['deliveryFeeNum'] ?? data['deliveryFee'] ?? '15000')
                .toString()
                .replaceAll(RegExp(r'[^\d]'), '');
        _timeCtrl.text = data['time'] ?? '15-25 min';
        _imageUrlCtrl.text =
            (data['imageUrl'] ?? '').toString().startsWith('http')
                ? data['imageUrl']
                : '';
        final tags = data['tags'] as List?;
        _tagsCtrl.text = tags?.join(', ') ?? '';
        final lat = data['latitude'];
        final lng = data['longitude'];
        if (lat != null && lng != null) {
          _location =
              LatLng((lat as num).toDouble(), (lng as num).toDouble());
        }
      }
    } catch (e) {
      debugPrint('Load store settings error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickLocation() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            LocationSelectionScreen(initialPosition: _location),
      ),
    );
    if (result != null && result is Map) {
      setState(() {
        _location = result['latlng'] as LatLng;
        _addressCtrl.text = result['address'] as String? ?? _addressCtrl.text;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_location == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng chọn vị trí cửa hàng trên bản đồ'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;

      final fee = double.tryParse(_deliveryFeeCtrl.text.trim()) ?? 15000.0;
      final tags = _tagsCtrl.text
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();

      await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(user.id)
          .set({
        'name': _nameCtrl.text.trim(),
        'address': _addressCtrl.text.trim(),
        'latitude': _location!.latitude,
        'longitude': _location!.longitude,
        'deliveryFeeNum': fee,
        'deliveryFee':
            '${fee.toInt()}đ',
        'time': _timeCtrl.text.trim(),
        'imageUrl': _imageUrlCtrl.text.trim().isNotEmpty
            ? _imageUrlCtrl.text.trim()
            : '0xFFFE724C',
        'tags': tags,
        'isOnline': true,
        'rating': 5.0,
        'ratingCount': 1,
      }, SetOptions(merge: true));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Đã lưu thông tin cửa hàng!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text(
          'Thông Tin Cửa Hàng',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFFE724C),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Header banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFE724C), Color(0xFFFF9A7A)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.store, color: Colors.white, size: 32),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Cài Đặt Cửa Hàng',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                'Thông tin này hiển thị với khách hàng',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Thông tin cơ bản'),
                  const SizedBox(height: 12),

                  _buildTextField(
                    controller: _nameCtrl,
                    label: 'Tên cửa hàng *',
                    icon: Icons.storefront,
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Nhập tên cửa hàng' : null,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _imageUrlCtrl,
                    label: 'URL ảnh cửa hàng',
                    icon: Icons.image_outlined,
                    hint: 'https://example.com/image.jpg',
                    keyboardType: TextInputType.url,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _tagsCtrl,
                    label: 'Danh mục (cách nhau bằng dấu phẩy)',
                    icon: Icons.label_outline,
                    hint: 'Cơm, Phở, Món Việt',
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Địa chỉ & Vị trí'),
                  const SizedBox(height: 12),

                  // Location picker button
                  GestureDetector(
                    onTap: _pickLocation,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _location != null
                              ? Colors.green
                              : const Color(0xFFFE724C),
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: _location != null
                            ? Colors.green.withValues(alpha: 0.05)
                            : const Color(0xFFFE724C).withValues(alpha: 0.05),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _location != null
                                ? Icons.check_circle
                                : Icons.map_outlined,
                            color: _location != null
                                ? Colors.green
                                : const Color(0xFFFE724C),
                            size: 28,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _location != null
                                      ? 'Vị trí đã chọn ✓'
                                      : 'Chọn vị trí trên bản đồ *',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: _location != null
                                        ? Colors.green
                                        : const Color(0xFFFE724C),
                                  ),
                                ),
                                if (_location != null)
                                  Text(
                                    '${_location!.latitude.toStringAsFixed(5)}, ${_location!.longitude.toStringAsFixed(5)}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  )
                                else
                                  const Text(
                                    'Bấm để mở bản đồ và ghim vị trí',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _addressCtrl,
                    label: 'Địa chỉ hiển thị *',
                    icon: Icons.location_on_outlined,
                    hint: '123 Nguyễn Huệ, Q1, TP.HCM',
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Nhập địa chỉ' : null,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Cài đặt giao hàng'),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _deliveryFeeCtrl,
                          label: 'Phí giao hàng (VNĐ)',
                          icon: Icons.delivery_dining,
                          keyboardType: TextInputType.number,
                          hint: '15000',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _timeCtrl,
                          label: 'Thời gian giao',
                          icon: Icons.access_time,
                          hint: '15-25 min',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFE724C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        shadowColor:
                            const Color(0xFFFE724C).withValues(alpha: 0.4),
                      ),
                      child: _isSaving
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.save_alt),
                                SizedBox(width: 8),
                                Text(
                                  'LƯU THÔNG TIN CỬA HÀNG',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFFFE724C),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFFFE724C)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFFE724C), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
