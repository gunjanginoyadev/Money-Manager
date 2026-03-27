import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_theme.dart';

/// Top banner toasts using [Overlay] with slide + fade animations (not SnackBar).
class AppToast {
  AppToast._();

  static const Duration _visibleDuration = Duration(seconds: 3);
  static const Duration _enterDuration = Duration(milliseconds: 380);
  static const Duration _exitDuration = Duration(milliseconds: 280);

  static OverlayEntry? _activeEntry;

  static void show(
    BuildContext context, {
    required String message,
    required bool isError,
  }) {
    final overlayState = Overlay.maybeOf(context, rootOverlay: true);
    if (overlayState == null) return;

    _activeEntry?.remove();
    _activeEntry = null;

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (ctx) => _TopToastBanner(
        message: message,
        isError: isError,
        onDispose: () {
          entry.remove();
          if (_activeEntry == entry) _activeEntry = null;
        },
      ),
    );
    _activeEntry = entry;
    overlayState.insert(entry);
  }
}

class _TopToastBanner extends StatefulWidget {
  const _TopToastBanner({
    required this.message,
    required this.isError,
    required this.onDispose,
  });

  final String message;
  final bool isError;
  final VoidCallback onDispose;

  @override
  State<_TopToastBanner> createState() => _TopToastBannerState();
}

class _TopToastBannerState extends State<_TopToastBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late Animation<double> _scale;
  bool _removed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppToast._enterDuration,
      reverseDuration: AppToast._exitDuration,
    );

    final enter = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.7, curve: Curves.easeOut),
        reverseCurve: const Interval(0.3, 1, curve: Curves.easeIn),
      ),
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, -1.15),
      end: Offset.zero,
    ).animate(enter);

    _scale = Tween<double>(begin: 0.94, end: 1).animate(enter);

    HapticFeedback.lightImpact();

    _controller.forward();

    Future<void>.delayed(AppToast._visibleDuration, () async {
      if (!mounted || _removed) return;
      await _controller.reverse();
      _safeRemove();
    });
  }

  void _safeRemove() {
    if (_removed) return;
    _removed = true;
    widget.onDispose();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _dismissEarly() async {
    if (_removed) return;
    await _controller.reverse();
    if (mounted) _safeRemove();
  }

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.paddingOf(context).top + 10;
    final bg = widget.isError
        ? AppColors.danger.withValues(alpha: 0.94)
        : AppColors.safe.withValues(alpha: 0.94);
    final icon = widget.isError
        ? Icons.error_outline_rounded
        : Icons.check_circle_rounded;

    return Stack(
      children: [
        Positioned(
          top: top,
          left: 16,
          right: 16,
          child: SlideTransition(
            position: _slide,
            child: FadeTransition(
              opacity: _fade,
              child: ScaleTransition(
                scale: _scale,
                alignment: Alignment.topCenter,
                child: Material(
                  color: Colors.transparent,
                  child: GestureDetector(
                    onVerticalDragEnd: (_) => _dismissEarly(),
                    onTap: _dismissEarly,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        child: Row(
                          children: [
                            Icon(icon, color: Colors.white, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.message,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  height: 1.35,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
