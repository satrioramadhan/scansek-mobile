import 'dart:async';
import 'package:flutter/material.dart';

/// Animated FAB that toggles between Scanner and Add icons
class AnimatedToggleFAB extends StatefulWidget {
  final VoidCallback onScannerPressed;
  final VoidCallback onAddPressed;
  final Color backgroundColor;

  const AnimatedToggleFAB({
    super.key,
    required this.onScannerPressed,
    required this.onAddPressed,
    required this.backgroundColor,
  });

  @override
  State<AnimatedToggleFAB> createState() => _AnimatedToggleFABState();
}

class _AnimatedToggleFABState extends State<AnimatedToggleFAB> {
  bool _showScanner = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Toggle every 1.5 seconds
    _timer = Timer.periodic(const Duration(milliseconds: 1500), (timer) {
      if (mounted) {
        setState(() {
          _showScanner = !_showScanner;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      backgroundColor: widget.backgroundColor,
      elevation: 4,
      onPressed: _showScanner ? widget.onScannerPressed : widget.onAddPressed,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        transitionBuilder: (Widget child, Animation<double> animation) {
          // Slide up transition
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.3),
              end: Offset.zero,
            ).animate(animation),
            child: FadeTransition(
              opacity: animation,
              child: child,
            ),
          );
        },
        child: _showScanner
            ? const Icon(
                Icons.qr_code_scanner_rounded,
                key: ValueKey('scanner'),
                color: Colors.white,
                size: 28,
              )
            : const Icon(
                Icons.add,
                key: ValueKey('add'),
                color: Colors.white,
                size: 28,
              ),
      ),
    );
  }
}
