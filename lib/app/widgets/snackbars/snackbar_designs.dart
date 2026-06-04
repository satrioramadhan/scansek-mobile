import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Elegant Minimal - White card dengan soft border
class ElegantSnackbar {
  ElegantSnackbar._();

  static void success(BuildContext? context, String message, {Duration duration = const Duration(seconds: 3)}) {
    // 1. Try context from argument
    OverlayState? overlay;
    
    if (context != null) {
      try {
        overlay = Overlay.of(context);
      } catch (_) {}
    }
    
    // 2. Try Get.overlayContext
    if (overlay == null && Get.overlayContext != null) {
      try {
        overlay = Overlay.of(Get.overlayContext!);
      } catch (_) {}
    }
    
    // 3. Try Get.context
    if (overlay == null && Get.context != null) {
      try {
        overlay = Overlay.of(Get.context!);
      } catch (_) {}
    }

    // 4. Try Direct Navigator Overlay (Most robust for GetX)
    if (overlay == null && Get.key.currentState != null) {
      overlay = Get.key.currentState?.overlay;
    }

    if (overlay == null) {
      print('❌ ElegantSnackbar Error: Overlay not found after all attempts');
      return;
    }

    final GlobalKey<_AnimatedSnackbarState> snackbarKey = GlobalKey();
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: _AnimatedSnackbar(
            key: snackbarKey,
            message: message,
            icon: Icons.check_circle,
            color: const Color(0xFF80CBC4), // Soft Teal
            onDismiss: () => overlayEntry.remove(),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    Future.delayed(duration, () {
      if (overlayEntry.mounted) snackbarKey.currentState?._dismiss();
    });
  }

  static void error(BuildContext? context, String message, {Duration duration = const Duration(seconds: 3)}) {
    // 1. Try context from argument
    OverlayState? overlay;
    
    if (context != null) {
      try {
        overlay = Overlay.of(context);
      } catch (_) {}
    }
    
    // 2. Try Get.overlayContext
    if (overlay == null && Get.overlayContext != null) {
      try {
        overlay = Overlay.of(Get.overlayContext!);
      } catch (_) {}
    }
    
    // 3. Try Get.context
    if (overlay == null && Get.context != null) {
      try {
        overlay = Overlay.of(Get.context!);
      } catch (_) {}
    }

    // 4. Try Direct Navigator Overlay (Most robust for GetX)
    if (overlay == null && Get.key.currentState != null) {
      overlay = Get.key.currentState?.overlay;
    }

    if (overlay == null) {
      print('❌ ElegantSnackbar Error: Overlay not found after all attempts');
      return;
    }

    final GlobalKey<_AnimatedSnackbarState> snackbarKey = GlobalKey();
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: _AnimatedSnackbar(
            key: snackbarKey,
            message: message,
            icon: Icons.error,
            color: const Color(0xFFEF9A9A), // Soft Pink
            onDismiss: () => overlayEntry.remove(),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    Future.delayed(duration, () {
      if (overlayEntry.mounted) snackbarKey.currentState?._dismiss();
    });
  }

  static void warning(BuildContext? context, String message, {Duration duration = const Duration(seconds: 3)}) {
    // 1. Try context from argument
    OverlayState? overlay;
    
    if (context != null) {
      try {
        overlay = Overlay.of(context);
      } catch (_) {}
    }
    
    // 2. Try Get.overlayContext
    if (overlay == null && Get.overlayContext != null) {
      try {
        overlay = Overlay.of(Get.overlayContext!);
      } catch (_) {}
    }
    
    // 3. Try Get.context
    if (overlay == null && Get.context != null) {
      try {
        overlay = Overlay.of(Get.context!);
      } catch (_) {}
    }

    // 4. Try Direct Navigator Overlay (Most robust for GetX)
    if (overlay == null && Get.key.currentState != null) {
      overlay = Get.key.currentState?.overlay;
    }

    if (overlay == null) {
      print('❌ ElegantSnackbar Error: Overlay not found after all attempts');
      return;
    }

    final GlobalKey<_AnimatedSnackbarState> snackbarKey = GlobalKey();
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: _AnimatedSnackbar(
            key: snackbarKey,
            message: message,
            icon: Icons.warning,
            color: const Color(0xFFFFCC80), // Soft Orange
            onDismiss: () => overlayEntry.remove(),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    Future.delayed(duration, () {
      if (overlayEntry.mounted) snackbarKey.currentState?._dismiss();
    });
  }

  static void info(BuildContext? context, String message, {Duration duration = const Duration(seconds: 3)}) {
    // 1. Try context from argument
    OverlayState? overlay;
    
    if (context != null) {
      try {
        overlay = Overlay.of(context);
      } catch (_) {}
    }
    
    // 2. Try Get.overlayContext
    if (overlay == null && Get.overlayContext != null) {
      try {
        overlay = Overlay.of(Get.overlayContext!);
      } catch (_) {}
    }
    
    // 3. Try Get.context
    if (overlay == null && Get.context != null) {
      try {
        overlay = Overlay.of(Get.context!);
      } catch (_) {}
    }

    // 4. Try Direct Navigator Overlay (Most robust for GetX)
    if (overlay == null && Get.key.currentState != null) {
      overlay = Get.key.currentState?.overlay;
    }

    if (overlay == null) {
      print('❌ ElegantSnackbar Error: Overlay not found after all attempts');
      return;
    }

    final GlobalKey<_AnimatedSnackbarState> snackbarKey = GlobalKey();
    late OverlayEntry overlayEntry;
    
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: _AnimatedSnackbar(
            key: snackbarKey,
            message: message,
            icon: Icons.info,
            color: const Color(0xFF90CAF9), // Soft Blue
            onDismiss: () => overlayEntry.remove(),
          ),
        ),
      ),
    );
    
    overlay.insert(overlayEntry);
    Future.delayed(duration, () {
      if (overlayEntry.mounted) snackbarKey.currentState?._dismiss();
    });
  }
}

// ====================================
// ANIMATED SNACKBAR WIDGET
// ====================================

class _AnimatedSnackbar extends StatefulWidget {
  final String message;
  final IconData icon;
  final Color color;
  final VoidCallback onDismiss;

  const _AnimatedSnackbar({
    super.key,
    required this.message,
    required this.icon,
    required this.color,
    required this.onDismiss,
  });

  @override
  State<_AnimatedSnackbar> createState() => _AnimatedSnackbarState();
}

class _AnimatedSnackbarState extends State<_AnimatedSnackbar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    ));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _dismiss() async {
    await _controller.reverse();
    widget.onDismiss();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: GestureDetector(
          onTap: _dismiss,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: widget.color.withOpacity(0.3),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Icon dengan circle background
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: widget.color.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    widget.icon,
                    color: widget.color,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                // Message
                Expanded(
                  child: Text(
                    widget.message,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Close button
                GestureDetector(
                  onTap: _dismiss,
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: Colors.grey[400],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
