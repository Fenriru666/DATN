import 'package:flutter/material.dart';

class CancelReasonDialog extends StatefulWidget {
  final List<String> availableReasons;

  const CancelReasonDialog({super.key, required this.availableReasons});

  @override
  State<CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<CancelReasonDialog> {
  String? _selectedReason;
  final TextEditingController _otherReasonController = TextEditingController();

  @override
  void dispose() {
    _otherReasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Lý do hủy đơn',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Vui lòng chọn lý do để chúng tôi cải thiện dịch vụ tốt hơn:',
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 16),
            ...widget.availableReasons.map((reason) {
              return RadioListTile<String>(
                title: Text(reason),
                value: reason,
                // ignore: deprecated_member_use
                groupValue: _selectedReason,
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFFFE724C),
                // ignore: deprecated_member_use
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _selectedReason = value;
                    });
                  }
                },
              );
            }),
            RadioListTile<String>(
              title: const Text('Lý do khác'),
              value: 'Khác',
              // ignore: deprecated_member_use
              groupValue: _selectedReason,
              contentPadding: EdgeInsets.zero,
              activeColor: const Color(0xFFFE724C),
              // ignore: deprecated_member_use
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _selectedReason = value;
                  });
                }
              },
            ),
            if (_selectedReason == 'Khác') ...[
              const SizedBox(height: 8),
              TextField(
                controller: _otherReasonController,
                decoration: InputDecoration(
                  hintText: 'Nhập lý do của bạn...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                ),
                maxLines: 2,
              ),
            ],
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Quay lại',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _selectedReason == null
                        ? null
                        : () {
                            if (_selectedReason == 'Khác' &&
                                _otherReasonController.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Vui lòng nhập lý do cụ thể'),
                                ),
                              );
                              return;
                            }

                            final finalReason = _selectedReason == 'Khác'
                                ? _otherReasonController.text.trim()
                                : _selectedReason!;

                            Navigator.pop(context, finalReason);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Hủy Đơn',
                      style: TextStyle(fontWeight: FontWeight.bold),
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
