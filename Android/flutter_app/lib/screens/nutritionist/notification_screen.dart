import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/providers/notification_provider.dart';
import 'package:s_gizi/widgets/loading_skeleton.dart';
import 'package:s_gizi/widgets/notification_card.dart';
import 'package:s_gizi/widgets/nutritionist_bottom_nav_bar.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  late final NotificationProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = NotificationProvider()..fetchNotifications();
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
          ? AppBar(title: const Text('Notifikasi'))
          : null,
      bottomNavigationBar: widget.showBottomNav
          ? NutritionistBottomNavBar(
              currentIndex: 3,
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
                onRetry: _provider.fetchNotifications,
              );
            }
            return RefreshIndicator(
              color: SgColors.primary,
              onRefresh: _provider.fetchNotifications,
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
                      'Notifikasi',
                      style: AppTypography.h1.copyWith(fontSize: 28),
                    ),
                    const SizedBox(height: 10),
                  ],
                  _FilterRow(provider: _provider),
                  const SizedBox(height: 14),
                  if (_provider.notifications.isEmpty)
                    const EmptyState(
                      title: 'Belum ada notifikasi baru',
                      message: 'Notifikasi penting akan muncul di sini.',
                    )
                  else
                    ..._provider.notifications.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: NotificationCard(
                          notification: item,
                          onTap: () => _provider.markRead(item.id),
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

  final NotificationProvider provider;

  @override
  Widget build(BuildContext context) {
    const filters = [
      ('Semua', 'all'),
      ('Belum Dibaca', 'unread'),
      ('Risiko Tinggi', 'high_risk'),
      ('Pesan Baru', 'message'),
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
