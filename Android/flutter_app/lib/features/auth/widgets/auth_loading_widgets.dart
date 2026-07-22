import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';

class AuthLoadingOverlay extends StatelessWidget {
  const AuthLoadingOverlay({
    super.key,
    required this.visible,
    required this.message,
    required this.child,
  });

  final bool visible;
  final String message;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AbsorbPointer(absorbing: visible, child: child),
        Positioned.fill(
          child: IgnorePointer(
            ignoring: !visible,
            child: AnimatedOpacity(
              opacity: visible ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
                  return Container(
                    color: SgColors.background.withValues(alpha: 0.62),
                    child: SafeArea(
                      child: SingleChildScrollView(
                        keyboardDismissBehavior:
                            ScrollViewKeyboardDismissBehavior.onDrag,
                        padding: EdgeInsets.fromLTRB(
                          20,
                          20,
                          20,
                          20 + bottomInset,
                        ),
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight:
                                (constraints.maxHeight -
                                        MediaQuery.paddingOf(context).vertical)
                                    .clamp(0, double.infinity)
                                    .toDouble(),
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 360),
                              child: AuthProgressCard(message: message),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class AuthProgressCard extends StatelessWidget {
  const AuthProgressCard({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 10 * (1 - value)),
          child: Opacity(opacity: value, child: child),
        );
      },
      child: HealthCard(
        dense: true,
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: SgColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.health_and_safety_outlined,
                color: SgColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTypography.h3.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            const _SoftProgressBars(),
          ],
        ),
      ),
    );
  }
}

class InlineAuthLoading extends StatelessWidget {
  const InlineAuthLoading({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF8F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SgColors.primary.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 56, child: _SoftProgressBars(compact: true)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.caption.copyWith(
                color: SgColors.primaryDark,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SoftProgressBars extends StatefulWidget {
  const _SoftProgressBars({this.compact = false});

  final bool compact;

  @override
  State<_SoftProgressBars> createState() => _SoftProgressBarsState();
}

class _SoftProgressBarsState extends State<_SoftProgressBars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final height = widget.compact ? 5.0 : 7.0;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final maxWidth = constraints.maxWidth.isFinite
                ? constraints.maxWidth
                : (widget.compact ? 56.0 : 128.0);
            final gap = widget.compact ? 4.0 : 5.0;
            final available = (maxWidth - (gap * 2)).clamp(24.0, maxWidth);
            final base = available / (widget.compact ? 5.2 : 4.6);
            final extra = available / (widget.compact ? 13.5 : 10.0);

            return Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                final delay = index * 0.18;
                final value = ((_controller.value + delay) % 1.0);
                final width = base + (value * extra);
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 120),
                  margin: EdgeInsets.only(right: index == 2 ? 0 : gap),
                  width: width,
                  height: height,
                  decoration: BoxDecoration(
                    color: SgColors.primary.withValues(
                      alpha: 0.35 + value * 0.45,
                    ),
                    borderRadius: BorderRadius.circular(99),
                  ),
                );
              }),
            );
          },
        );
      },
    );
  }
}
