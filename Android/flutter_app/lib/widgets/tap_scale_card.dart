import 'package:flutter/material.dart';

/// Feedback tap ringan (scale) untuk kartu interaktif.
class TapScaleCard extends StatefulWidget {
  const TapScaleCard({
    super.key,
    required this.child,
    required this.onTap,
    this.borderRadius = 16,
  });

  final Widget child;
  final VoidCallback onTap;
  final double borderRadius;

  @override
  State<TapScaleCard> createState() => _TapScaleCardState();
}

class _TapScaleCardState extends State<TapScaleCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      onTap: widget.onTap,
      child: AnimatedScale(
        scale: _pressed ? 0.98 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}
