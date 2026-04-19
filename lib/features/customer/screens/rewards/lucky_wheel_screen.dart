import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_fortune_wheel/flutter_fortune_wheel.dart';
import 'package:datn/core/models/user_model.dart';
import 'package:datn/features/auth/services/auth_service.dart';
import 'package:datn/core/services/lucky_wheel_service.dart';

class LuckyWheelScreen extends StatefulWidget {
  const LuckyWheelScreen({super.key});

  @override
  State<LuckyWheelScreen> createState() => _LuckyWheelScreenState();
}

class _LuckyWheelScreenState extends State<LuckyWheelScreen> {
  final StreamController<int> _selectedController = StreamController<int>();
  final LuckyWheelService _wheelService = LuckyWheelService();

  UserModel? _currentUser;
  bool _isSpinning = false;
  String? _errorMessage;
  int _finalIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  void dispose() {
    _selectedController.close();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final user = await AuthService().getCurrentUser();
    if (mounted) {
      setState(() {
        _currentUser = user;
      });
    }
  }

  Future<void> _spinWheel() async {
    if (_isSpinning || _currentUser == null) return;

    if (_currentUser!.loyaltyPoints < LuckyWheelService.pointsPerSpin) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không đủ điểm để quay. Hãy tích điểm thêm nhé!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isSpinning = true;
      _errorMessage = null;
    });

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      // 1. Roll the dice on the server
      final resultIndex = await _wheelService.spinWheel(_currentUser!.uid);

      // 2. Play animation
      _finalIndex = resultIndex;
      _selectedController.add(resultIndex);

      // Temporarily deduct points on UI immediately for feedback
      setState(() {
        _currentUser = _currentUser!.copyWith(
          loyaltyPoints:
              _currentUser!.loyaltyPoints - LuckyWheelService.pointsPerSpin,
        );
      });
    } catch (e) {
      setState(() {
        _isSpinning = false;
        _errorMessage = "Lỗi khi quay: ${e.toString()}";
      });
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
      );
    }
  }

  void _onSpinComplete() async {
    setState(() {
      _isSpinning = false;
    });

    final prize = LuckyWheelService.wheelItems[_finalIndex];

    // Refresh user to get updated wallet/points
    await _loadUser();

    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            prize['type'] == 'WALLET'
                ? 'ðŸŽ‰ Trúng Thưởng! ðŸŽ‰'
                : 'Rất Tiếc! ðŸ˜¢',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                prize['type'] == 'WALLET'
                    ? Icons.monetization_on
                    : Icons.sentiment_dissatisfied,
                color: prize['type'] == 'WALLET' ? Colors.amber : Colors.grey,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                prize['type'] == 'WALLET'
                    ? 'Chúc mừng bạn đã quay trúng\n${prize['label']}'
                    : 'Chúc bạn may mắn lần sau nhé!',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              if (prize['type'] == 'WALLET') ...[
                const SizedBox(height: 8),
                const Text(
                  'Tiền thưởng đã được cộng vào Ví của bạn.',
                  style: TextStyle(color: Colors.green, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFE724C),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 12,
                  ),
                ),
                child: const Text(
                  'Xác nhận',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vòng Quay Giàu Sang'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      backgroundColor: Colors.indigo.shade50,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Points Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Điểm hiện tại:',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${_currentUser!.loyaltyPoints}',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFE724C),
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.star, color: Colors.amber),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),

              // The Wheel
              SizedBox(
                height: 350,
                child: FortuneWheel(
                  selected: _selectedController.stream,
                  animateFirst: false,
                  items: [
                    for (var it in LuckyWheelService.wheelItems)
                      FortuneItem(
                        child: Text(
                          it['label'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: FortuneItemStyle(
                          color: Color(it['color']),
                          borderColor: Colors.white,
                          borderWidth: 2,
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                  onAnimationEnd: _onSpinComplete,
                ),
              ),
              const SizedBox(height: 40),

              // Spin Button
              ElevatedButton(
                onPressed: _isSpinning ? null : _spinWheel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFE724C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 48,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                  elevation: 8,
                ),
                child: _isSpinning
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 3,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.play_arrow, size: 28),
                          SizedBox(width: 8),
                          Text(
                            'QUAY NGAY (-50 ĐIỂM)',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 20),
              const Text(
                'Mẹo: Chăm chỉ đi xe và đặt đồ ăn để tích thêm Điểm Thành viên. Biết đâu bất ngờ!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
