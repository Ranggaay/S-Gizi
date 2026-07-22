import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/providers/nutritionist_dashboard_provider.dart';
import 'package:s_gizi/screens/nutritionist/consultation_chat_screen.dart';
import 'package:s_gizi/screens/nutritionist/consultation_list_screen.dart';
import 'package:s_gizi/screens/nutritionist/notification_screen.dart';
import 'package:s_gizi/screens/nutritionist/nutritionist_profile_screen.dart';
import 'package:s_gizi/widgets/consultation_card.dart';
import 'package:s_gizi/widgets/loading_skeleton.dart';
import 'package:s_gizi/widgets/notification_card.dart';
import 'package:s_gizi/widgets/nutritionist_bottom_nav_bar.dart';
import 'package:s_gizi/widgets/summary_card.dart';

class NutritionistDashboardScreen extends StatefulWidget {
  const NutritionistDashboardScreen({super.key});

  @override
  State<NutritionistDashboardScreen> createState() =>
      _NutritionistDashboardScreenState();
}

class _NutritionistDashboardScreenState
    extends State<NutritionistDashboardScreen> {
  int _index = 0;

  late final _pages = [
    _NutritionistDashboardHome(
      onChangeTab: (value) => setState(() => _index = value),
    ),
    const ConsultationListScreen(showBottomNav: false),
    const NotificationScreen(showBottomNav: false),
    const NutritionistProfileScreen(showBottomNav: false),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      body: IndexedStack(index: _index, children: _pages),
      bottomNavigationBar: NutritionistBottomNavBar(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
      ),
    );
  }
}

class _NutritionistDashboardHome extends StatefulWidget {
  const _NutritionistDashboardHome({required this.onChangeTab});

  final ValueChanged<int> onChangeTab;

  @override
  State<_NutritionistDashboardHome> createState() =>
      _NutritionistDashboardHomeState();
}

class _NutritionistDashboardHomeState
    extends State<_NutritionistDashboardHome> {
  late final NutritionistDashboardProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = NutritionistDashboardProvider()..fetchDashboard();
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: AnimatedBuilder(
        animation: _provider,
        builder: (context, _) {
          if (_provider.isLoading) return const LoadingSkeleton();
          if (_provider.errorMessage != null) {
            return ErrorState(
              message: _provider.errorMessage!,
              onRetry: _provider.fetchDashboard,
            );
          }
          final data = _provider.dashboardData;
          if (data == null) {
            return const EmptyState(
              title: 'Belum ada konsultasi hari ini',
              message: 'Ringkasan konsultasi akan tampil di sini.',
            );
          }
          final profile = data.nutritionist;
          final hour = DateTime.now().hour;
          final greeting = hour < 11
              ? 'Selamat pagi'
              : hour < 15
              ? 'Selamat siang'
              : hour < 18
              ? 'Selamat sore'
              : 'Selamat malam';
          return RefreshIndicator(
            color: SgColors.primary,
            onRefresh: _provider.refreshDashboard,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                Row(
                  children: [
                    Text(
                      'S-Gizi',
                      style: AppTypography.h2.copyWith(fontSize: 21),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => widget.onChangeTab(2),
                      icon: const Icon(LucideIcons.bell),
                    ),
                    SgAvatar(name: profile.name, radius: 21),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  '$greeting, ${profile.name}',
                  style: AppTypography.h1.copyWith(fontSize: 25),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pantau konsultasi gizi hari ini.',
                  style: AppTypography.body,
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.45,
                  children: [
                    SummaryCard(
                      title: 'Konsultasi Aktif',
                      value: data.summary.activeConsultations,
                      icon: LucideIcons.messageCircle,
                      color: SgColors.primary,
                      onTap: () => widget.onChangeTab(1),
                    ),
                    SummaryCard(
                      title: 'Belum Dibalas',
                      value: data.summary.unrepliedMessages,
                      icon: LucideIcons.reply,
                      color: const Color(0xFF3B82F6),
                      onTap: () => widget.onChangeTab(1),
                    ),
                    SummaryCard(
                      title: 'Risiko Tinggi',
                      value: data.summary.highRiskConsultations,
                      icon: Icons.warning_amber_rounded,
                      color: const Color(0xFFC62828),
                      onTap: () => widget.onChangeTab(2),
                    ),
                    SummaryCard(
                      title: 'Data Perlu Dicek',
                      value: data.summary.needReviewData,
                      icon: LucideIcons.activity,
                      color: const Color(0xFFEF6C00),
                      onTap: () => widget.onChangeTab(2),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _SectionTitle(
                  title: 'Konsultasi Terbaru',
                  onTap: () => widget.onChangeTab(1),
                ),
                const SizedBox(height: 10),
                if (data.latestConsultations.isEmpty)
                  const EmptyState(
                    title: 'Belum ada konsultasi hari ini',
                    message:
                        'Konsultasi akan muncul jika orang tua mengirim pesan.',
                    icon: LucideIcons.messageCircle,
                  )
                else
                  ...data.latestConsultations
                      .take(2)
                      .map(
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
                const SizedBox(height: 8),
                _SectionTitle(
                  title: 'Notifikasi Terbaru',
                  onTap: () => widget.onChangeTab(2),
                ),
                const SizedBox(height: 10),
                ...data.latestNotifications
                    .take(2)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: NotificationCard(notification: item),
                      ),
                    ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTypography.h2)),
        TextButton(onPressed: onTap, child: const Text('Lihat Semua')),
      ],
    );
  }
}
