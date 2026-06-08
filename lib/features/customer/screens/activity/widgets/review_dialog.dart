import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:datn/features/customer/services/order_service.dart';

class ReviewDialog extends StatefulWidget {
  final String orderId;

  const ReviewDialog({super.key, required this.orderId});

  @override
  State<ReviewDialog> createState() => _ReviewDialogState();
}

class _ReviewDialogState extends State<ReviewDialog> {
  int _driverRating = 5;
  int _merchantRating = 5;
  bool _hasDriver = false;
  bool _hasMerchant = false;
  bool _isLoading = true;
  final TextEditingController _noteController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadOrderInfo();
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _loadOrderInfo() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('orders')
          .doc(widget.orderId)
          .get();
      if (doc.exists && mounted) {
        final data = doc.data()!;
        setState(() {
          _hasDriver = data['driverId'] != null;
          _hasMerchant = data['merchantId'] != null;
          // If neither exists, default to driver/provider
          if (!_hasDriver && !_hasMerchant) {
            _hasDriver = true;
          }
          _isLoading = false;
        });
      } else {
        if (mounted) {
          setState(() {
            _hasDriver = true;
            _isLoading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _hasDriver = true;
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _submitReview() async {
    setState(() => _isSaving = true);

    try {
      await OrderService().updateOrderReview(
        widget.orderId,
        driverRating: _hasDriver ? _driverRating.toDouble() : null,
        merchantRating: _hasMerchant ? _merchantRating.toDouble() : null,
        note: _noteController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context, true); // Return true when successful
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Không thể gửi đánh giá: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildStarSelector({
    required String title,
    required int rating,
    required Function(int) onRatingChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          alignment: Alignment.center,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return InkWell(
                  onTap: () => onRatingChanged(index + 1),
                  borderRadius: BorderRadius.circular(20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
                    child: Icon(
                      index < rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 32,
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: _isLoading
            ? const SizedBox(
                height: 150,
                child: Center(child: CircularProgressIndicator()),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Đánh giá chuyến đi',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),

                  // Driver Rating Section
                  if (_hasDriver)
                    _buildStarSelector(
                      title: 'Đánh giá Tài xế (Vận chuyển)',
                      rating: _driverRating,
                      onRatingChanged: (val) {
                        setState(() => _driverRating = val);
                      },
                    ),

                  // Merchant Rating Section
                  if (_hasMerchant)
                    _buildStarSelector(
                      title: 'Đánh giá Cửa hàng / Món ăn',
                      rating: _merchantRating,
                      onRatingChanged: (val) {
                        setState(() => _merchantRating = val);
                      },
                    ),

                  // Note TextField
                  TextField(
                    controller: _noteController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Nhận xét của bạn (Không bắt buộc)',
                      hintStyle: const TextStyle(fontSize: 14, color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Actions
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isSaving ? null : () => Navigator.pop(context),
                          child: const Text(
                            'Hủy',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _submitReview,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFE724C),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  'Gửi',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
