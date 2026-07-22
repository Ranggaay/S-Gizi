import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/providers/consultation_provider.dart';
import 'package:s_gizi/screens/nutritionist/consultation_chat_screen.dart';
import 'package:s_gizi/widgets/consultation_card.dart';
import 'package:s_gizi/widgets/loading_skeleton.dart';
import 'package:s_gizi/widgets/nutritionist_bottom_nav_bar.dart';
import 'package:s_gizi/widgets/search_bar_widget.dart';

class ConsultationListScreen extends StatefulWidget {
  const ConsultationListScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  @override
  State<ConsultationListScreen> createState() => _ConsultationListScreenState();
}

class _ConsultationListScreenState extends State<ConsultationListScreen> {
  late final ConsultationProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ConsultationProvider()..fetchConsultations();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      appBar: widget.showBottomNav
          ? AppBar(title: const Text('Konsultasi'))
          : null,
      bottomNavigationBar: widget.showBottomNav
          ? NutritionistBottomNavBar(
              currentIndex: 2,
              onTap: (_) => Navigator.of(context).maybePop(),
            )
          : null,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _provider,
          builder: (context, _) {
            if (_provider.isLoading) return const LoadingSkeleton();
            if (_provider.errorMessage != null) {
              return ErrorState(
                message: _provider.errorMessage!,
                onRetry: _provider.fetchConsultations,
              );
            }
            return RefreshIndicator(
              color: SgColors.primary,
              onRefresh: _provider.fetchConsultations,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  20,
                  widget.showBottomNav ? 14 : 8,
                  20,
                  120,
                ),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  if (!widget.showBottomNav) ...[
                    Text(
                      'Konsultasi',
                      style: AppTypography.h1.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SearchBarWidget(
                    hintText: 'Cari nama orang tua atau anak',
                    onChanged: _provider.setSearchQuery,
                  ),
                  const SizedBox(height: 12),
                  _FilterRow(provider: _provider),
                  const SizedBox(height: 14),
                  if (_provider.consultations.isEmpty)
                    const EmptyState(
                      title: 'Belum ada konsultasi masuk',
                      message:
                          'Konsultasi akan muncul jika orang tua mengirim pesan.',
                    )
                  else
                    ..._provider.consultations.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: ConsultationCard(
                          consultation: item,
                          onTap: () => Navigator.of(context).push(
                            fadeRoute(
                              ConsultationChatScreen(consultation: item),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FilterRow extends StatelessWidget {
  const _FilterRow({required this.provider});

  final ConsultationProvider provider;

  @override
  Widget build(BuildContext context) {
    const filters = [
      ('Semua', 'all'),
      ('Belum Dibalas', 'unreplied'),
      ('Aktif', 'active'),
      ('Risiko Tinggi', 'high_risk'),
      ('Selesai', 'closed'),
    ];
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final item = filters[index];
          final active = provider.selectedFilter == item.$2;
          return ChoiceChip(
            selected: active,
            showCheckmark: false,
            label: Text(item.$1),
            onSelected: (_) => provider.setFilter(item.$2),
            selectedColor: SgColors.primary,
            labelStyle: AppTypography.caption.copyWith(
              color: active ? Colors.white : SgColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          );
        },
      ),
    );
  }
}
