import 'package:flutter/material.dart';

class PulsingFAB extends StatefulWidget {
  final bool isActive;
  final VoidCallback onPressed;

  const PulsingFAB({
    super.key,
    required this.isActive,
    required this.onPressed,
  });

  @override
  State<PulsingFAB> createState() => _PulsingFABState();
}

class _PulsingFABState extends State<PulsingFAB>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant PulsingFAB oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.reset();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isActive) {
      return FloatingActionButton(
        onPressed: widget.onPressed,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: const CircleBorder(),
        elevation: 4.0,
        child: const Icon(Icons.smart_toy, color: Colors.white, size: 28),
      );
    }
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FloatingActionButton(
        onPressed: widget.onPressed,
        backgroundColor: Theme.of(context).colorScheme.primary,
        shape: const CircleBorder(),
        elevation: 4.0,
        child: const Icon(Icons.smart_toy, color: Colors.white, size: 28),
      ),
    );
  }
}

class CustomFloatingActionButtonLocation extends FloatingActionButtonLocation {
  const CustomFloatingActionButtonLocation();

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final double fabX =
        (scaffoldGeometry.scaffoldSize.width -
            scaffoldGeometry.floatingActionButtonSize.width) /
        2.0;

    final double contentBottom = scaffoldGeometry.contentBottom;
    final double fabHeight = scaffoldGeometry.floatingActionButtonSize.height;

    final double standardY = contentBottom - fabHeight / 2.0;
    final double customY = standardY + 20.0; // Lower it by 20 pixels

    return Offset(fabX, customY);
  }
}
