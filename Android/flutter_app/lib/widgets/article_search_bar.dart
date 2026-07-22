import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';

/// Search bar modern untuk artikel edukasi.
class ArticleSearchBar extends StatelessWidget {
  const ArticleSearchBar({
    super.key,
    required this.query,
    required this.onChanged,
    this.hintText = 'Cari artikel edukasi...',
    this.categories = const ['Semua', 'Gizi', 'Tumbuh Kembang', 'MPASI'],
    this.selectedCategory = 'Semua',
    this.onCategoryChanged,
  });

  final String query;
  final ValueChanged<String> onChanged;
  final String hintText;
  final List<String> categories;
  final String selectedCategory;
  final ValueChanged<String>? onCategoryChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onChanged: onChanged,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: AppTypography.body.copyWith(fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, size: 22),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: SgColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: SgColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: SgColors.primary, width: 1.4),
            ),
          ),
        ),
        if (onCategoryChanged != null && categories.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 32,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final cat = categories[index];
                final active = cat == selectedCategory;
                return ChoiceChip(
                  label: Text(cat),
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
                  onSelected: (_) => onCategoryChanged!(cat),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}
