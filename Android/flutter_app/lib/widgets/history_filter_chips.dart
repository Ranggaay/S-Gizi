import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';

/// Filter chip horizontal untuk riwayat pengukuran.
class HistoryFilterChips extends StatelessWidget {
  const HistoryFilterChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  static const options = ['Semua', 'Bulan Ini', 'Stunting', 'Gizi Baik'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: options.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final label = options[index];
          final active = label == selected;
          return FilterChip(
            label: Text(label),
            selected: active,
            showCheckmark: false,
            labelStyle: AppTypography.caption.copyWith(
              fontWeight: FontWeight.w700,
              color: active ? Colors.white : SgColors.textSecondary,
            ),
            selectedColor: const Color(0xFF0B7A86),
            backgroundColor: Colors.white,
            side: BorderSide(
              color: active ? const Color(0xFF0B7A86) : SgColors.border,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            onSelected: (_) => onSelected(label),
          );
        },
      ),
    );
  }
}
