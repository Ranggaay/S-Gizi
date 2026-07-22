import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/widgets/risk_badge.dart';

class FilterChipStatus extends StatelessWidget {
  const FilterChipStatus({
    super.key,
    required this.label,
    required this.value,
    required this.selectedValue,
    required this.onSelected,
  });

  final String label;
  final String value;
  final String selectedValue;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    final selected = value == selectedValue;
    final style = value == 'all'
        ? const RiskStyle(Color(0xFFEAF8F7), SgColors.primary)
        : riskStyle(label);
    return ChoiceChip(
      selected: selected,
      showCheckmark: false,
      label: Text(label),
      onSelected: (_) => onSelected(value),
      selectedColor: SgColors.primary,
      backgroundColor: style.background,
      side: BorderSide(color: selected ? SgColors.primary : style.background),
      labelStyle: AppTypography.caption.copyWith(
        color: selected ? Colors.white : style.foreground,
        fontWeight: FontWeight.w800,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    );
  }
}
