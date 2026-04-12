import 'package:flutter/material.dart';

class SOSButton extends StatefulWidget {
  final VoidCallback onSOSActived;

  const SOSButton({super.key, required this.onSOSActived});

  @override
  State<SOSButton> createState() => _SOSButtonState();
}

class _SOSButtonState extends State<SOSButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isPressing = false;

  @override
  void initState() {
    super.initState();
    // 3 seconds duration for the SOS to trigger
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );

    _controller.addListener(() {
      setState(() {});
      if (_controller.value == 1.0) {
        // Full 3 seconds hold reached!
        widget.onSOSActived();
        _controller.reset();
        _isPressing = false;
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    setState(() {
      _isPressing = true;
    });
    _controller.forward();
  }

  void _onPointerUp(PointerUpEvent event) {
    setState(() {
      _isPressing = false;
    });
    _controller.reverse(); // If released early, shrink back
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: (_) =>
          _onPointerUp(const PointerUpEvent()), // Typesafe hack
      child: Container(
        width: 70,
        height: 70,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red.withValues(alpha: 0.1),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Internal Red Button
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: const Center(
                child: Text(
                  "SOS",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),

            // Progress Indicator showing the hold duration
            if (_isPressing)
              SizedBox(
                width: 66,
                height: 66,
                child: CircularProgressIndicator(
                  value: _controller.value,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Colors.redAccent,
                  ),
                  strokeWidth: 4,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
