import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class FamilyDashboardSkeleton extends StatelessWidget {
  const FamilyDashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8EEEC),
      highlightColor: const Color(0xFFF8FAFA),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
        children: [
          _Box(height: 48, width: double.infinity),
          const SizedBox(height: 14),
          _Box(height: 28, width: 220),
          const SizedBox(height: 8),
          _Box(height: 16, width: 180),
          const SizedBox(height: 16),
          _Box(height: 20, width: 120),
          const SizedBox(height: 10),
          for (var i = 0; i < 2; i++) ...[
            _Box(height: 168, width: double.infinity, radius: 18),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

class _Box extends StatelessWidget {
  const _Box({required this.height, required this.width, this.radius = 12});

  final double height;
  final double width;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
