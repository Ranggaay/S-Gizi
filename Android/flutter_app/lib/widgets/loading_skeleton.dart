import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8EEEC),
      highlightColor: const Color(0xFFF7FAF9),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 120),
        children: [
          Container(height: 46, decoration: _box()),
          const SizedBox(height: 12),
          Container(height: 48, decoration: _box()),
          const SizedBox(height: 12),
          Container(height: 72, decoration: _box()),
          const SizedBox(height: 14),
          for (var i = 0; i < 4; i++) ...[
            Container(height: 156, decoration: _box()),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }

  BoxDecoration _box() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
  );
}
