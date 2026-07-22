import 'dart:async';
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/app_state.dart';
import 'package:s_gizi/core/helpers/nutrition_status_helper.dart';
import 'package:s_gizi/services/api_service.dart';
import 'package:s_gizi/utils/dashboard_error_utils.dart';
import 'package:s_gizi/features/auth/screens/auth_screen.dart';

class NutritionistDashboardScreen extends StatefulWidget {
  const NutritionistDashboardScreen({super.key});

  @override
  State<NutritionistDashboardScreen> createState() =>
      _NutritionistDashboardScreenState();
}

class _NutritionistDashboardScreenState
    extends State<NutritionistDashboardScreen> {
  final _controller = _NutritionistController();
  int _index = 0;
  Timer? _refreshTimer;

  late final List<Widget> _pages = [
    _NutritionistHomePage(controller: _controller, onChangeTab: _setIndex),
    _ConsultationListPage(controller: _controller),
    _NutritionistNotificationsPage(controller: _controller),
    _NutritionistProfilePage(controller: _controller),
  ];

  @override
  void initState() {
    super.initState();
    _controller.loadDashboard();
    _refreshTimer = Timer.periodic(const Duration(seconds: 20), (_) {
      if (!mounted) return;
      _controller.loadDashboard(showLoading: false);
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _NutritionistProvider(
      controller: _controller,
      child: Scaffold(
        backgroundColor: SgColors.background,
        body: SafeArea(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(key: ValueKey(_index), child: _pages[_index]),
          ),
        ),
        bottomNavigationBar: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) => _NutritionistBottomNav(
            index: _index,
            unreadChatCount: _controller.unreadRooms,
            notificationCount: _controller.notificationCount,
            onChanged: _setIndex,
          ),
        ),
      ),
    );
  }

  void _setIndex(int value) {
    if (value == 2) {
      _controller.markNotificationsSeen();
    }
    setState(() => _index = value);
  }
}

class _NutritionistProvider extends InheritedNotifier<_NutritionistController> {
  const _NutritionistProvider({
    required _NutritionistController controller,
    required super.child,
  }) : super(notifier: controller);
}

class _NutritionistController extends ChangeNotifier {
  _NutritionistController() {
    final user = SgiziAppState.instance.userData ?? const <String, dynamic>{};
    final nutritionist = user['nutritionist'] is Map<String, dynamic>
        ? user['nutritionist'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final name = (user['name'] as String? ?? '').trim();
    final phone = (user['phone'] as String? ?? '').trim();
    final email = (user['email'] as String? ?? '').trim();
    profile = _NutritionistProfile(
      name: name.isEmpty ? 'Ahli Gizi' : name,
      specialization:
          (nutritionist['specialization'] as String? ?? '').trim().isEmpty
          ? 'Spesialis Gizi Anak'
          : (nutritionist['specialization'] as String).trim(),
      experience: (nutritionist['experience'] as String? ?? '').trim().isEmpty
          ? '-'
          : (nutritionist['experience'] as String).trim(),
      phone: phone.isEmpty ? '-' : phone,
      email: email.isEmpty ? '-' : email,
      license: (nutritionist['str_sip'] as String? ?? '').trim().isEmpty
          ? '-'
          : (nutritionist['str_sip'] as String).trim(),
      online: nutritionist['is_online'] == true,
      photoUrl: _pickString(user, const [
        'profile_image',
        'photo',
        'profile_photo',
        'avatar',
        'asset_image',
      ]),
      gender:
          (user['gender'] as String? ?? user['parent_gender'] as String? ?? '')
              .trim(),
    );
  }

  final _api = ApiService();
  late _NutritionistProfile profile;
  bool loading = true;
  Object? error;
  int activeConsultationCount = 0;
  int monitoredChildrenCount = 0;
  int riskChildrenCount = 0;
  int unansweredCount = 0;
  String consultationQuery = '';
  String consultationFilter = 'Semua';

  final rooms = <_NutritionistRoom>[];
  final activities = <_NutritionistActivity>[];
  final Set<String> _seenNotificationKeys = {};

  List<_NutritionistRoom> get filteredRooms {
    return rooms.where((room) {
      final q = consultationQuery.trim().toLowerCase();
      final matchesQuery =
          q.isEmpty ||
          room.parentName.toLowerCase().contains(q) ||
          room.childName.toLowerCase().contains(q) ||
          room.status.toLowerCase().contains(q);
      final matchesFilter =
          consultationFilter == 'Semua' || room.state == consultationFilter;
      return matchesQuery && matchesFilter;
    }).toList();
  }

  int get activeConsultations => activeConsultationCount;
  int get monitoredChildren => monitoredChildrenCount;
  int get riskChildren => riskChildrenCount;
  int get unreadRooms => rooms.where((room) => room.unread > 0).length;
  int get needMonitoringCount =>
      rooms.where((room) => room.monitoringStatus == 'perlu_dipantau').length;
  int get dashboardChatNotificationCount => unreadChatRooms.length;
  int get notificationCount => notificationItems
      .where((item) => !_seenNotificationKeys.contains(item.key))
      .length;
  List<_NutritionistRoom> get unreadChatRooms =>
      rooms.where((room) => room.unread > 0).toList();
  List<_NutritionistNotificationItem> get notificationItems {
    final items = <_NutritionistNotificationItem>[
      for (final room in unreadChatRooms)
        _NutritionistNotificationItem(
          key: 'chat-${room.id}-${room.unread}-${room.time}',
          title: '${room.unread} chat baru',
          description: '${room.parentName} - ${room.childName}',
          time: room.time,
          icon: LucideIcons.messageCircle,
          color: SgColors.primary,
          room: room,
        ),
      for (final room in rooms.where((room) => room.risk == _RiskLevel.high))
        _NutritionistNotificationItem(
          key: 'high-risk-${room.id}-${room.measuredAt}-${room.status}',
          title: 'Risiko Tinggi',
          description:
              '${room.childName} membutuhkan perhatian. Status terakhir: ${room.statusLabel}.',
          time: room.measuredAtLabel == '-' ? room.time : room.measuredAtLabel,
          icon: LucideIcons.siren,
          color: SgColors.danger,
          room: room,
        ),
      for (final room in rooms.where(
        (room) => room.monitoringStatus == 'perlu_dipantau',
      ))
        _NutritionistNotificationItem(
          key:
              'monitoring-${room.id}-${room.measuredAt}-${room.validationNote}',
          title: 'Perlu Dipantau',
          description: room.validationNote.isEmpty
              ? '${room.childName} perlu dipantau melalui konsultasi gizi.'
              : room.validationNote,
          time: room.measuredAtLabel == '-' ? room.time : room.measuredAtLabel,
          icon: LucideIcons.activity,
          color: SgColors.warning,
          room: room,
        ),
      for (final room in rooms.where(
        (room) => room.validationStatus == 'perlu_ukur_ulang',
      ))
        _NutritionistNotificationItem(
          key: 'remeasure-${room.id}-${room.measuredAt}-${room.validationNote}',
          title: 'Perlu Ukur Ulang',
          description: room.validationNote.isEmpty
              ? '${room.childName} memiliki data pengukuran yang perlu dicek ulang.'
              : room.validationNote,
          time: room.measuredAtLabel == '-' ? room.time : room.measuredAtLabel,
          icon: Icons.refresh_rounded,
          color: const Color(0xFFEF6C00),
          room: room,
        ),
      for (final activity in activities)
        _NutritionistNotificationItem(
          key: 'activity-${activity.title}-${activity.time}',
          title: activity.title,
          description: activity.description,
          time: activity.time,
          icon: _activityIcon(activity.title),
          color: _activityColor(activity.title),
        ),
    ];

    final keys = items.map((item) => item.key).toSet();
    _seenNotificationKeys.removeWhere((key) => !keys.contains(key));
    return items;
  }

  Future<void> loadDashboard({bool showLoading = true}) async {
    if (showLoading) {
      loading = true;
    }
    error = null;
    notifyListeners();
    try {
      final json = await _api.getNutritionistDashboard();
      profile = _NutritionistProfile.fromJson(
        json['profile'] is Map<String, dynamic>
            ? json['profile'] as Map<String, dynamic>
            : const <String, dynamic>{},
        fallback: profile,
      );
      final stats = json['stats'] is Map<String, dynamic>
          ? json['stats'] as Map<String, dynamic>
          : const <String, dynamic>{};
      activeConsultationCount =
          (stats['active_consultations'] as num?)?.toInt() ?? 0;
      monitoredChildrenCount =
          (stats['monitored_children'] as num?)?.toInt() ?? 0;
      riskChildrenCount = (stats['risk_children'] as num?)?.toInt() ?? 0;
      unansweredCount = (stats['unanswered'] as num?)?.toInt() ?? 0;
      rooms
        ..clear()
        ..addAll(
          (json['rooms'] is List ? json['rooms'] as List : const [])
              .whereType<Map<String, dynamic>>()
              .map(_NutritionistRoom.fromJson),
        );
      activities
        ..clear()
        ..addAll(
          (json['activities'] is List ? json['activities'] as List : const [])
              .whereType<Map<String, dynamic>>()
              .map(_NutritionistActivity.fromJson),
        );
    } catch (e) {
      error = e;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  void setConsultationQuery(String value) {
    consultationQuery = value;
    notifyListeners();
  }

  void setConsultationFilter(String value) {
    consultationFilter = value;
    notifyListeners();
  }

  void markRoomNotificationRead(int roomId) {
    final index = rooms.indexWhere((room) => room.id == roomId);
    if (index < 0) return;
    if (rooms[index].unread <= 0) return;
    rooms[index] = rooms[index].copyWith(unread: 0);
    unansweredCount = math.max(0, unansweredCount - 1);
    notifyListeners();
  }

  void markNotificationsSeen() {
    _seenNotificationKeys.addAll(notificationItems.map((item) => item.key));
    notifyListeners();
  }

  void toggleOnline() {
    profile = profile.copyWith(online: !profile.online);
    notifyListeners();
  }
}

class _NutritionistHomePage extends StatelessWidget {
  const _NutritionistHomePage({
    required this.controller,
    required this.onChangeTab,
  });

  final _NutritionistController controller;
  final ValueChanged<int> onChangeTab;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.loading) {
          return const _NutritionistSkeleton();
        }
        if (controller.error != null) {
          final info = dashboardErrorInfo(controller.error);
          return ErrorState(
            title: info.title,
            message: info.message,
            icon: info.icon,
            color: info.color,
            onRetry: controller.loadDashboard,
          );
        }
        return RefreshIndicator(
          color: SgColors.primary,
          onRefresh: controller.loadDashboard,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            children: [
              _NutritionistHeader(
                profile: controller.profile,
                notificationCount: controller.dashboardChatNotificationCount,
                onRefresh: controller.loadDashboard,
                onNotification: () {
                  _showNotificationSheet(context, controller);
                },
                onProfile: () => onChangeTab(3),
              ),
              const SizedBox(height: 14),
              _DashboardGreeting(profile: controller.profile),
              const SizedBox(height: 14),
              _StatsGrid(
                controller: controller,
                onConsultation: () => onChangeTab(1),
                onChildren: () => _showNeedMonitoringSheet(context, controller),
                onRisk: () => _showRiskSheet(context, controller),
                onUnanswered: () {
                  controller.setConsultationFilter('Belum Dibalas');
                  onChangeTab(1);
                },
              ),
              const SizedBox(height: 18),
              _SectionHeader(
                title: 'Konsultasi Terbaru',
                action: 'Lihat Semua',
                onTap: () => onChangeTab(1),
              ),
              const SizedBox(height: 10),
              if (controller.rooms.isEmpty)
                EmptyState(
                  title: 'Belum Ada Konsultasi',
                  message:
                      'Belum ada konsultasi aktif yang terhubung dengan akun ahli gizi ini.',
                  icon: LucideIcons.messageCircle,
                  actionLabel: 'Refresh Dashboard',
                  onAction: controller.loadDashboard,
                )
              else
                ...controller.rooms
                    .take(2)
                    .map(
                      (room) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RoomCard(
                          room: room,
                          onTap: () => _openChat(context, room),
                        ),
                      ),
                    ),
            ],
          ),
        );
      },
    );
  }
}

class _NutritionistHeader extends StatelessWidget {
  const _NutritionistHeader({
    required this.profile,
    this.notificationCount = 0,
    this.onRefresh,
    this.onNotification,
    this.onProfile,
  });

  final _NutritionistProfile profile;
  final int notificationCount;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onNotification;
  final VoidCallback? onProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.asset(
            'assets/image/logo_sgizi.png',
            width: 42,
            height: 42,
            fit: BoxFit.cover,
          ),
        ),
        const SizedBox(width: 10),
        Text('S-Gizi', style: AppTypography.h2.copyWith(fontSize: 20)),
        const Spacer(),
        IconButton(
          tooltip: 'Refresh dashboard',
          onPressed: onRefresh == null ? null : () => onRefresh!(),
          icon: const Icon(LucideIcons.refreshCw, size: 18),
          color: SgColors.primary,
        ),
        _NotificationIconButton(
          count: notificationCount,
          onTap: onNotification,
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: 'Profil',
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onProfile,
            child: _ProfileAvatar(profile: profile, radius: 21),
          ),
        ),
      ],
    );
  }
}

class _NotificationIconButton extends StatelessWidget {
  const _NotificationIconButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF8F7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFCFEAE7)),
            ),
            child: const Icon(
              LucideIcons.bell,
              color: SgColors.primary,
              size: 20,
            ),
          ),
          if (count > 0)
            Positioned(
              right: -2,
              top: -4,
              child: Container(
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: SgColors.danger,
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: Text(
                  count > 99 ? '99+' : '$count',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ProfileAvatar extends StatelessWidget {
  const _ProfileAvatar({required this.profile, required this.radius});

  final _NutritionistProfile profile;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final photoUrl = profile.photoUrl.trim();
    if (photoUrl.isNotEmpty) {
      return ClipOval(
        child: Image.network(
          _absoluteImageUrl(photoUrl),
          width: radius * 2,
          height: radius * 2,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => SgAvatar(
            name: profile.name,
            radius: radius,
            icon: LucideIcons.user,
          ),
        ),
      );
    }
    return SgAvatar(name: profile.name, radius: radius, icon: LucideIcons.user);
  }
}

class _DashboardGreeting extends StatelessWidget {
  const _DashboardGreeting({required this.profile});

  final _NutritionistProfile profile;

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final timeLabel = hour < 11
        ? 'pagi'
        : hour < 15
        ? 'siang'
        : hour < 18
        ? 'sore'
        : 'malam';
    final greeting = 'Selamat $timeLabel, ${profile.salutationName}';
    return HealthCard(
      dense: true,
      color: const Color(0xFFF7FCFB),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  greeting,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h2.copyWith(fontSize: 20),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Pantau kondisi anak dan konsultasi hari ini.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body,
                ),
                const SizedBox(height: 8),
                _SoftChip(
                  label: profile.specialization,
                  color: SgColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const CircleAvatar(
            radius: 22,
            backgroundColor: Color(0xFFE0F4F2),
            child: Icon(LucideIcons.stethoscope, color: SgColors.primary),
          ),
        ],
      ),
    );
  }
}

class _NutritionistSkeleton extends StatelessWidget {
  const _NutritionistSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      children: [
        Container(
          height: 126,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(26),
          ),
        ),
        const SizedBox(height: 14),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.55,
          children: [
            for (var i = 0; i < 4; i++)
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        for (var i = 0; i < 4; i++) ...[
          Container(
            height: 96,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.controller,
    required this.onConsultation,
    required this.onChildren,
    required this.onRisk,
    required this.onUnanswered,
  });

  final _NutritionistController controller;
  final VoidCallback onConsultation;
  final VoidCallback onChildren;
  final VoidCallback onRisk;
  final VoidCallback onUnanswered;

  @override
  Widget build(BuildContext context) {
    final stats = [
      _StatVm(
        'Konsultasi Aktif',
        '${controller.activeConsultations}',
        LucideIcons.messageCircle,
        const Color(0xFF4B8E96),
        const Color(0xFFE6F7F8),
        onConsultation,
      ),
      _StatVm(
        'Belum Dibalas',
        '${controller.unansweredCount}',
        LucideIcons.messageCircle,
        const Color(0xFF6D8DBE),
        const Color(0xFFF4F8FC),
        onUnanswered,
      ),
      _StatVm(
        'Risiko Tinggi',
        '${controller.riskChildren}',
        Icons.warning_amber_rounded,
        SgColors.danger,
        const Color(0xFFFFEEF0),
        onRisk,
      ),
      _StatVm(
        'Perlu Dipantau',
        '${controller.needMonitoringCount}',
        Icons.refresh_rounded,
        const Color(0xFFEF6C00),
        const Color(0xFFFFF3E0),
        onChildren,
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final spacing = constraints.maxWidth < 380 ? 10.0 : 12.0;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: stats.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: spacing,
            mainAxisSpacing: spacing,
            childAspectRatio: constraints.maxWidth < 380 ? 1.35 : 1.55,
          ),
          itemBuilder: (context, index) => _StatCard(stat: stats[index]),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat});

  final _StatVm stat;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      dense: true,
      padding: const EdgeInsets.all(12),
      color: stat.background,
      borderColor: stat.color.withValues(alpha: 0.10),
      onTap: stat.onTap,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.86),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Icon(stat.icon, color: stat.color, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.value.padLeft(2, '0'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h1.copyWith(fontSize: 26),
                ),
                Text(
                  stat.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: SgColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_circle_right_outlined,
            size: 20,
            color: stat.color.withValues(alpha: 0.72),
          ),
        ],
      ),
    );
  }
}

// ignore: unused_element
class _NutritionistChildrenPage extends StatelessWidget {
  const _NutritionistChildrenPage({required this.controller});

  final _NutritionistController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.loading) return const _NutritionistSkeleton();
        if (controller.error != null) {
          final info = dashboardErrorInfo(controller.error);
          return ErrorState(
            title: info.title,
            message: info.message,
            icon: info.icon,
            color: info.color,
            onRetry: controller.loadDashboard,
          );
        }
        final riskRooms = controller.rooms
            .where((room) => room.risk != _RiskLevel.normal)
            .toList();
        final rooms = riskRooms.isEmpty ? controller.rooms : riskRooms;
        return RefreshIndicator(
          color: SgColors.primary,
          onRefresh: controller.loadDashboard,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            children: [
              Text('Anak', style: AppTypography.h1.copyWith(fontSize: 28)),
              const SizedBox(height: 6),
              const Text(
                'Pantau anak yang membutuhkan perhatian lebih dahulu.',
                style: AppTypography.body,
              ),
              const SizedBox(height: 14),
              if (rooms.isEmpty)
                const EmptyState(
                  title: 'Belum Ada Anak Dipantau',
                  message:
                      'Anak akan tampil setelah konsultasi atau pengukuran dibuat.',
                  icon: LucideIcons.baby,
                )
              else
                ...rooms.map(
                  (room) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RiskMonitoringCard(
                      room: room,
                      onTap: () => _showGrowthSheet(context, room),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ConsultationListPage extends StatelessWidget {
  const _ConsultationListPage({required this.controller});

  final _NutritionistController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.loading) {
          return const _NutritionistSkeleton();
        }
        if (controller.error != null) {
          final info = dashboardErrorInfo(controller.error);
          return ErrorState(
            title: info.title,
            message: info.message,
            icon: info.icon,
            color: info.color,
            onRetry: controller.loadDashboard,
          );
        }
        final rooms = controller.filteredRooms;
        return ListView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          children: [
            Text('Konsultasi', style: AppTypography.h1.copyWith(fontSize: 28)),
            const SizedBox(height: 6),
            const Text(
              'Pantau chat orang tua dan perkembangan anak secara berkala.',
              style: AppTypography.body,
            ),
            const SizedBox(height: 14),
            _SearchBox(
              hint: 'Cari orang tua, anak, atau status...',
              onChanged: controller.setConsultationQuery,
            ),
            const SizedBox(height: 12),
            _FilterChips(
              values: const ['Semua', 'Belum Dibalas', 'Aktif', 'Selesai'],
              selected: controller.consultationFilter,
              onSelected: controller.setConsultationFilter,
            ),
            const SizedBox(height: 14),
            if (rooms.isEmpty)
              const EmptyState(
                title: 'Belum Ada Konsultasi',
                message: 'Room konsultasi yang sesuai filter belum tersedia.',
                icon: Icons.forum_outlined,
              )
            else
              ...rooms.map(
                (room) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RoomCard(
                    room: room,
                    onTap: () => _openChat(context, room),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _RoomCard extends StatelessWidget {
  const _RoomCard({required this.room, required this.onTap});

  final _NutritionistRoom room;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _riskVisual(room.risk);
    final statusColor = _statusColor(room);
    return HealthCard(
      dense: true,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Stack(
            children: [
              SgAvatar(name: room.parentName, radius: 26),
              if (room.unread > 0)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: SgColors.danger,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${room.unread}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        room.parentName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h3,
                      ),
                    ),
                    const Icon(
                      LucideIcons.clock3,
                      size: 13,
                      color: SgColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(room.time, style: AppTypography.caption),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  '${room.childName} - ${room.age}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _SoftChip(label: room.statusLabel, color: statusColor),
                    if (room.isMeasured)
                      _SoftChip(label: visual.label, color: visual.color),
                    if (room.monitoringStatus == 'perlu_dipantau')
                      const _SoftChip(
                        label: 'Perlu Dipantau',
                        color: SgColors.warning,
                      ),
                    if (room.validationStatus == 'perlu_ukur_ulang')
                      const _SoftChip(
                        label: 'Perlu Ukur Ulang',
                        color: SgColors.warning,
                      ),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  '"${room.lastMessage}"',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                    fontSize: 13,
                    fontStyle: FontStyle.italic,
                    color: SgColors.textPrimary.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            LucideIcons.chevronRight,
            color: SgColors.textSecondary,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _RiskMonitoringCard extends StatelessWidget {
  const _RiskMonitoringCard({required this.room, this.onTap});

  final _NutritionistRoom room;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final visual = _riskVisual(room.risk);
    return HealthCard(
      dense: true,
      padding: const EdgeInsets.all(14),
      color: Colors.white,
      borderColor: visual.color.withValues(alpha: 0.14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.childName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.h3,
                    ),
                    Text(
                      '${room.age} - Orang tua: ${room.parentName}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _SoftChip(label: visual.label, color: visual.color),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'TB/U: ${room.statusLabel}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            'BB/U: ${room.previousStatus.isEmpty ? room.statusLabel : _localizedNutritionStatus(room.previousStatus)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.caption,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'BB ${room.latestWeightLabel} • TB ${room.latestHeightLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: SgColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Ukur terakhir: ${room.measuredAtLabel}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: AppTypography.caption,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AllClearRiskCard extends StatelessWidget {
  const _AllClearRiskCard();

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      dense: true,
      color: const Color(0xFFF0FAF4),
      borderColor: const Color(0xFFD5EFD8),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: SgColors.success.withValues(alpha: 0.14),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              color: SgColors.success,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Belum ada anak yang perlu perhatian khusus dari konsultasi milik akun ini.',
              style: AppTypography.body,
            ),
          ),
        ],
      ),
    );
  }
}

class _NutritionistNotificationsPage extends StatelessWidget {
  const _NutritionistNotificationsPage({required this.controller});

  final _NutritionistController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        if (controller.loading) return const _NutritionistSkeleton();
        if (controller.error != null) {
          final info = dashboardErrorInfo(controller.error);
          return ErrorState(
            title: info.title,
            message: info.message,
            icon: info.icon,
            color: info.color,
            onRetry: controller.loadDashboard,
          );
        }
        final notifications = controller.notificationItems;
        return RefreshIndicator(
          color: SgColors.primary,
          onRefresh: controller.loadDashboard,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            children: [
              Text(
                'Notifikasi',
                style: AppTypography.h1.copyWith(fontSize: 28),
              ),
              const SizedBox(height: 6),
              const Text(
                'Pesan baru, risiko tinggi, perlu dipantau, dan aktivitas penting.',
                style: AppTypography.body,
              ),
              const SizedBox(height: 14),
              if (notifications.isEmpty)
                const EmptyState(
                  title: 'Belum Ada Notifikasi',
                  message:
                      'Notifikasi konsultasi dan pemantauan akan tampil di sini.',
                  icon: LucideIcons.bell,
                )
              else
                ...notifications.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _NotificationTile(
                      title: item.title,
                      description: item.description,
                      time: item.time,
                      icon: item.icon,
                      color: item.color,
                      onTap: item.room == null
                          ? null
                          : () {
                              if (item.room!.unread > 0) {
                                controller.markRoomNotificationRead(
                                  item.room!.id,
                                );
                              }
                              _openChat(context, item.room!);
                            },
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.color,
    this.onTap,
  });

  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      dense: true,
      padding: const EdgeInsets.all(12),
      color: color.withValues(alpha: 0.06),
      borderColor: color.withValues(alpha: 0.18),
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(icon, color: color, size: 17),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h3.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(time, style: AppTypography.caption),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            const Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: SgColors.textSecondary,
            ),
          ],
        ],
      ),
    );
  }
}

class _NutritionistNotificationItem {
  const _NutritionistNotificationItem({
    required this.key,
    required this.title,
    required this.description,
    required this.time,
    required this.icon,
    required this.color,
    this.room,
  });

  final String key;
  final String title;
  final String description;
  final String time;
  final IconData icon;
  final Color color;
  final _NutritionistRoom? room;
}

class _ConsultationChatPage extends StatefulWidget {
  const _ConsultationChatPage({required this.room});

  final _NutritionistRoom room;

  @override
  State<_ConsultationChatPage> createState() => _ConsultationChatPageState();
}

class _ConsultationChatPageState extends State<_ConsultationChatPage> {
  final _api = ApiService();
  final _input = TextEditingController();
  final _scroll = ScrollController();
  final List<_ChatMessage> _messages = [];
  bool _loading = true;
  bool _sending = false;
  bool _initialScrollReady = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _loadMessages() async {
    setState(() {
      _loading = true;
      _initialScrollReady = false;
      _error = null;
    });
    try {
      final json = await _api.getNutritionistRoomMessages(
        roomId: widget.room.id,
      );
      final list = json['data'] is List ? json['data'] as List : const [];
      _messages
        ..clear()
        ..addAll(
          list.whereType<Map<String, dynamic>>().map(_ChatMessage.fromJson),
        );
    } catch (e) {
      _error = e;
    } finally {
      if (mounted) {
        setState(() => _loading = false);
        _jumpBottom(instant: true, revealAfterJump: true);
      }
    }
  }

  void _jumpBottom({bool instant = false, bool revealAfterJump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final target = _scroll.position.maxScrollExtent;
      if (instant) {
        _scroll.jumpTo(target);
        if (revealAfterJump && mounted) {
          setState(() => _initialScrollReady = true);
        }
        return;
      }
      _scroll.animateTo(target, duration: 220.ms, curve: Curves.easeOut);
    });
  }

  Future<void> _sendText([String? quick]) async {
    final text = (quick ?? _input.text).trim();
    if (text.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final json = await _api.sendNutritionistMessage(
        roomId: widget.room.id,
        message: text,
      );
      final data = json['data'];
      if (data is Map<String, dynamic>) {
        _messages.add(_ChatMessage.fromJson(data));
      } else {
        _messages.add(
          _ChatMessage(text: text, fromParent: false, time: 'Baru'),
        );
      }
      _input.clear();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
    _jumpBottom();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    return Scaffold(
      backgroundColor: SgColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            _ChatHeader(
              room: room,
              onClose: () async {
                final messenger = ScaffoldMessenger.of(context);
                final navigator = Navigator.of(context);
                await _api.closeNutritionistConsultation(roomId: room.id);
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('Konsultasi ditandai selesai.')),
                );
                navigator.pop();
              },
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? ErrorState(
                      message: 'Chat konsultasi belum dapat dimuat.',
                      onRetry: _loadMessages,
                    )
                  : AnimatedOpacity(
                      opacity: _initialScrollReady ? 1 : 0,
                      duration: 120.ms,
                      child: ListView(
                        controller: _scroll,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                        children: [
                          _ProgressUpdateCard(room: room),
                          const SizedBox(height: 10),
                          if (room.validationStatus == 'perlu_ukur_ulang') ...[
                            _ChatWarningCard(
                              title: 'Perlu Ukur Ulang',
                              message: room.validationNote.isEmpty
                                  ? 'Data pengukuran perlu dicek ulang. Sarankan orang tua melakukan pengukuran ulang.'
                                  : '${room.validationNote}\nSarankan orang tua melakukan pengukuran ulang.',
                              color: SgColors.warning,
                              icon: Icons.refresh_rounded,
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (room.monitoringStatus == 'perlu_dipantau') ...[
                            _ChatWarningCard(
                              title: 'Perlu Dipantau',
                              message: room.validationNote.isEmpty
                                  ? 'Data sudah dikonfirmasi orang tua dan anak perlu dipantau melalui konsultasi gizi.'
                                  : room.validationNote,
                              color: SgColors.warning,
                              icon: LucideIcons.activity,
                            ),
                            const SizedBox(height: 10),
                          ],
                          if (_messages.isEmpty)
                            const EmptyState(
                              title: 'Belum Ada Pesan',
                              message:
                                  'Pesan konsultasi dari orang tua akan muncul di sini.',
                              icon: LucideIcons.messageCircle,
                            )
                          else
                            ..._messages.map(
                              (message) => _ChatBubble(message: message),
                            ),
                        ],
                      ),
                    ),
            ),
            _ChatInput(
              controller: _input,
              sending: _sending,
              onSend: () => _sendText(),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({required this.room, required this.onClose});

  final _NutritionistRoom room;
  final Future<void> Function() onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: SgColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(LucideIcons.chevronLeft),
          ),
          SgAvatar(name: room.parentName, radius: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  room.parentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h3,
                ),
                Text(
                  '${room.childName} - ${room.age}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Lihat grafik',
            onPressed: () => _showGrowthSheet(context, room),
            icon: const Icon(LucideIcons.lineChart, color: SgColors.primary),
          ),
          PopupMenuButton<String>(
            tooltip: 'Aksi konsultasi',
            onSelected: (value) async {
              if (value == 'close') {
                await onClose();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'close', child: Text('Tandai Selesai')),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProgressUpdateCard extends StatelessWidget {
  const _ProgressUpdateCard({required this.room});

  final _NutritionistRoom room;

  @override
  Widget build(BuildContext context) {
    if (!room.hasGrowthChartData) {
      return HealthCard(
        color: const Color(0xFFF0FAF8),
        borderColor: const Color(0xFFBFE8E1),
        onTap: () => _showGrowthSheet(context, room),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xFFDDF4F0),
              child: Icon(LucideIcons.activity, color: SgColors.primary),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Belum ada pengukuran yang dibagikan untuk ${room.childName}.',
                style: AppTypography.body,
              ),
            ),
          ],
        ),
      );
    }
    final previousWeight = room.weights.length > 1
        ? room.weights[room.weights.length - 2]
        : room.weights.isEmpty
        ? null
        : room.weights.last;
    final previousHeight = room.heights.length > 1
        ? room.heights[room.heights.length - 2]
        : room.heights.isEmpty
        ? null
        : room.heights.last;
    return HealthCard(
      color: const Color(0xFFF0FAF8),
      borderColor: const Color(0xFFBFE8E1),
      onTap: () => _showGrowthSheet(context, room),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFDDF4F0),
                child: Icon(LucideIcons.activity, color: SgColors.primary),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Update Perkembangan Anak',
                  style: AppTypography.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              _SoftChip(label: 'Baru', color: SgColors.primary),
            ],
          ),
          const SizedBox(height: 12),
          _MiniGrowthChart(
            weights: room.weights,
            heights: room.heights,
            zBbuScores: room.zBbuScores,
            zScores: room.zScores,
            zBbtbScores: room.zBbtbScores,
            dates: room.measurementDateLabels,
            statuses: room.measurementStatusLabels,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MeasurePill(
                label: 'BB',
                value: previousWeight == null || room.weights.isEmpty
                    ? '-'
                    : '${previousWeight.toStringAsFixed(1)} -> ${room.weights.last.toStringAsFixed(1)} kg',
              ),
              _MeasurePill(
                label: 'TB',
                value: previousHeight == null || room.heights.isEmpty
                    ? '-'
                    : '${previousHeight.toStringAsFixed(0)} -> ${room.heights.last.toStringAsFixed(0)} cm',
              ),
              _MeasurePill(
                label: 'Status',
                value: room.previousStatus == room.status
                    ? room.status
                    : '${room.previousStatus} -> ${room.status}',
              ),
              _MeasurePill(label: 'Tanggal', value: room.measuredAtLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChatWarningCard extends StatelessWidget {
  const _ChatWarningCard({
    required this.title,
    required this.message,
    required this.color,
    required this.icon,
  });

  final String title;
  final String message;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      dense: true,
      color: color.withValues(alpha: 0.10),
      borderColor: color.withValues(alpha: 0.22),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.h3.copyWith(color: color)),
                const SizedBox(height: 4),
                Text(message, style: AppTypography.body),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatBubble extends StatelessWidget {
  const _ChatBubble({required this.message});

  final _ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final fromParent = message.fromParent;
    return Align(
      alignment: fromParent ? Alignment.centerLeft : Alignment.centerRight,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.78,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: fromParent ? Colors.white : SgColors.primary,
            borderRadius: BorderRadius.circular(18).copyWith(
              bottomLeft: Radius.circular(fromParent ? 4 : 18),
              bottomRight: Radius.circular(fromParent ? 18 : 4),
            ),
            border: Border.all(
              color: fromParent ? SgColors.border : SgColors.primary,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.text,
                style: AppTypography.body.copyWith(
                  color: fromParent ? SgColors.textPrimary : Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                message.time,
                style: AppTypography.caption.copyWith(
                  color: fromParent
                      ? SgColors.textSecondary
                      : Colors.white.withValues(alpha: 0.8),
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      color: Colors.white,
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Tulis balasan...',
                  prefixIcon: Icon(LucideIcons.messageCircle),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 48,
              height: 48,
              child: FilledButton(
                onPressed: sending ? null : onSend,
                style: FilledButton.styleFrom(
                  padding: EdgeInsets.zero,
                  shape: const CircleBorder(),
                ),
                child: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(LucideIcons.send, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NutritionistProfilePage extends StatelessWidget {
  const _NutritionistProfilePage({required this.controller});

  final _NutritionistController controller;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final profile = controller.profile;
        return ListView(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          physics: const BouncingScrollPhysics(),
          children: [
            _NutritionistHeader(
              profile: profile,
              notificationCount: controller.dashboardChatNotificationCount,
              onRefresh: () => controller.loadDashboard(showLoading: false),
              onNotification: () => _showNotificationSheet(context, controller),
            ),
            const SizedBox(height: 16),
            _ProfileHeroCard(profile: profile),
            const SizedBox(height: 14),
            _ProfileInfoCard(profile: profile),
            const SizedBox(height: 14),
            _SettingsTile(
              icon: LucideIcons.edit3,
              title: 'Edit Profil',
              subtitle: 'Perbarui data praktik dan kontak',
              onTap: () async {
                final changed = await Navigator.of(context).push<bool>(
                  fadeRoute(
                    _NutritionistEditProfileScreen(profile: controller.profile),
                  ),
                );
                if (changed == true) {
                  await controller.loadDashboard(showLoading: false);
                }
              },
            ),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: LucideIcons.lock,
              title: 'Ubah Password',
              subtitle: 'Ganti password akun ahli gizi',
              onTap: () => Navigator.of(
                context,
              ).push(fadeRoute(const _NutritionistPasswordScreen())),
            ),
            const SizedBox(height: 10),
            _SettingsTile(
              icon: LucideIcons.logOut,
              title: 'Logout',
              subtitle: 'Keluar dari S-Gizi Ahli Gizi',
              danger: true,
              onTap: () async {
                final confirmed = await _confirmNutritionistLogout(context);
                if (confirmed != true) return;
                await SgiziAppState.instance.logout();
                if (!context.mounted) return;
                Navigator.of(context).pushAndRemoveUntil(
                  fadeRoute(const AuthScreen()),
                  (_) => false,
                );
              },
            ),
          ],
        );
      },
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({required this.profile});

  final _NutritionistProfile profile;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ProfileAvatar(profile: profile, radius: 38),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(profile.name, style: AppTypography.h2),
                const SizedBox(height: 4),
                Text(
                  profile.specialization,
                  style: AppTypography.body.copyWith(
                    color: SgColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _SoftChip(label: profile.email, color: SgColors.primary),
                    _SoftChip(
                      label: profile.phone,
                      color: const Color(0xFF2F80ED),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  const _ProfileInfoCard({required this.profile});

  final _NutritionistProfile profile;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      child: Column(
        children: [
          _InfoRow(
            icon: Icons.medical_services_outlined,
            label: 'Pengalaman',
            value: profile.experience,
          ),
          _InfoRow(
            icon: LucideIcons.phone,
            label: 'Nomor Telepon',
            value: profile.phone,
          ),
          _InfoRow(
            icon: LucideIcons.mail,
            label: 'Email',
            value: profile.email,
          ),
          _InfoRow(
            icon: LucideIcons.badgeCheck,
            label: 'STR/SIP',
            value: profile.license,
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFEAF8F7),
            child: Icon(icon, size: 17, color: SgColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.caption),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.h3,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? SgColors.danger : SgColors.primary;
    return HealthCard(
      dense: true,
      onTap: onTap,
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.12),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.h3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const Icon(LucideIcons.chevronRight, color: SgColors.textSecondary),
        ],
      ),
    );
  }
}

class _NutritionistEditProfileScreen extends StatefulWidget {
  const _NutritionistEditProfileScreen({required this.profile});

  final _NutritionistProfile profile;

  @override
  State<_NutritionistEditProfileScreen> createState() =>
      _NutritionistEditProfileScreenState();
}

class _NutritionistEditProfileScreenState
    extends State<_NutritionistEditProfileScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _specialization;
  late final TextEditingController _experience;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _license;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _name = TextEditingController(text: profile.name);
    _specialization = TextEditingController(text: profile.specialization);
    _experience = TextEditingController(
      text: profile.experience == '-' ? '' : profile.experience,
    );
    _phone = TextEditingController(
      text: profile.phone == '-' ? '' : profile.phone,
    );
    _email = TextEditingController(
      text: profile.email == '-' ? '' : profile.email,
    );
    _license = TextEditingController(
      text: profile.license == '-' ? '' : profile.license,
    );
  }

  @override
  void dispose() {
    _name.dispose();
    _specialization.dispose();
    _experience.dispose();
    _phone.dispose();
    _email.dispose();
    _license.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      final updated = await _api.updateProfile(
        name: _name.text.trim(),
        phone: _phone.text.trim(),
        email: _email.text.trim(),
        specialization: _specialization.text.trim(),
        experience: _experience.text.trim(),
        strSip: _license.text.trim(),
      );
      SgiziAppState.instance.setProfileData(updated);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil diperbarui.'),
          duration: Duration(milliseconds: 900),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SgColors.background,
      appBar: AppBar(
        title: const Text('Edit Profil'),
        backgroundColor: SgColors.background,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                HealthCard(
                  child: Row(
                    children: [
                      SgAvatar(name: _name.text, radius: 34),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Profil Ahli Gizi', style: AppTypography.h2),
                            const SizedBox(height: 2),
                            Text(
                              'Perbarui data praktik dan kontak aktif.',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                _SheetTextField(
                  controller: _name,
                  label: 'Nama Lengkap',
                  icon: LucideIcons.user,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Nama wajib diisi.'
                      : null,
                ),
                const SizedBox(height: 10),
                _SheetTextField(
                  controller: _specialization,
                  label: 'Spesialisasi',
                  icon: LucideIcons.stethoscope,
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? 'Spesialisasi wajib diisi.'
                      : null,
                ),
                const SizedBox(height: 10),
                _SheetTextField(
                  controller: _experience,
                  label: 'Pengalaman',
                  icon: LucideIcons.briefcase,
                ),
                const SizedBox(height: 10),
                _SheetTextField(
                  controller: _phone,
                  label: 'Nomor Telepon',
                  icon: LucideIcons.phone,
                  keyboardType: TextInputType.phone,
                  validator: (value) =>
                      (value == null || value.trim().length < 8)
                      ? 'Nomor telepon tidak valid.'
                      : null,
                ),
                const SizedBox(height: 10),
                _SheetTextField(
                  controller: _email,
                  label: 'Email',
                  icon: LucideIcons.mail,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final email = (value ?? '').trim();
                    if (email.isEmpty) return null;
                    return email.contains('@')
                        ? null
                        : 'Format email tidak valid.';
                  },
                ),
                const SizedBox(height: 10),
                _SheetTextField(
                  controller: _license,
                  label: 'STR/SIP',
                  icon: LucideIcons.badgeCheck,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: _saving ? 'Menyimpan...' : 'Simpan Profil',
                  icon: LucideIcons.check,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NutritionistPasswordScreen extends StatefulWidget {
  const _NutritionistPasswordScreen();

  @override
  State<_NutritionistPasswordScreen> createState() =>
      _NutritionistPasswordScreenState();
}

class _NutritionistPasswordScreenState
    extends State<_NutritionistPasswordScreen> {
  final _api = ApiService();
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  bool _hideOld = true;
  bool _hideNew = true;
  bool _hideConfirm = true;
  bool _saving = false;

  @override
  void dispose() {
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<bool> _confirmSave() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        icon: const Icon(LucideIcons.lock, color: SgColors.primary),
        title: const Text('Ubah Password?'),
        content: const Text(
          'Pastikan password baru sudah benar. Anda akan menggunakan password baru saat login berikutnya.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ubah'),
          ),
        ],
      ),
    );
    return result == true;
  }

  Future<void> _savePassword() async {
    if (_oldPassword.text.isEmpty) {
      _snack('Password lama wajib diisi.');
      return;
    }
    if (_newPassword.text.length < 8) {
      _snack('Password baru minimal 8 karakter.');
      return;
    }
    if (_newPassword.text != _confirmPassword.text) {
      _snack('Konfirmasi password baru belum cocok.');
      return;
    }
    final ok = await _confirmSave();
    if (!ok || _saving) return;

    setState(() => _saving = true);
    try {
      await _api.updatePassword(
        oldPassword: _oldPassword.text,
        newPassword: _newPassword.text,
        newPasswordConfirmation: _confirmPassword.text,
      );
      _oldPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password berhasil diperbarui.'),
          duration: Duration(milliseconds: 900),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SgColors.background,
      appBar: AppBar(
        title: const Text('Ubah Password'),
        backgroundColor: SgColors.background,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          child: _SecurityLikeCard(
            icon: LucideIcons.lock,
            title: 'Ubah Password',
            subtitle: 'Perbarui password akun ahli gizi',
            child: Column(
              children: [
                _PasswordField(
                  controller: _oldPassword,
                  label: 'Password Lama',
                  hidden: _hideOld,
                  onToggle: () => setState(() => _hideOld = !_hideOld),
                ),
                const SizedBox(height: 10),
                _PasswordField(
                  controller: _newPassword,
                  label: 'Password Baru',
                  hidden: _hideNew,
                  onToggle: () => setState(() => _hideNew = !_hideNew),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Minimal 8 karakter. Data password disimpan aman oleh server.',
                    style: AppTypography.caption,
                  ),
                ),
                const SizedBox(height: 10),
                _PasswordField(
                  controller: _confirmPassword,
                  label: 'Konfirmasi Password Baru',
                  hidden: _hideConfirm,
                  onToggle: () => setState(() => _hideConfirm = !_hideConfirm),
                ),
                const SizedBox(height: 14),
                PrimaryButton(
                  label: _saving ? 'Menyimpan...' : 'Simpan Password',
                  icon: LucideIcons.check,
                  onPressed: _saving ? null : _savePassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SecurityLikeCard extends StatelessWidget {
  const _SecurityLikeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFEAF8F7),
                child: Icon(icon, color: SgColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppTypography.h2),
                    Text(subtitle, style: AppTypography.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.hidden,
    required this.onToggle,
  });

  final TextEditingController controller;
  final String label;
  final bool hidden;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: hidden,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(LucideIcons.keyRound),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(hidden ? LucideIcons.eye : LucideIcons.eyeOff),
        ),
      ),
    );
  }
}

class _MiniGrowthChart extends StatelessWidget {
  const _MiniGrowthChart({
    required this.weights,
    required this.heights,
    required this.zBbuScores,
    required this.zScores,
    required this.zBbtbScores,
    required this.dates,
    required this.statuses,
  });

  final List<double> weights;
  final List<double> heights;
  final List<double> zBbuScores;
  final List<double> zScores;
  final List<double> zBbtbScores;
  final List<String> dates;
  final List<String> statuses;

  @override
  Widget build(BuildContext context) {
    if (weights.isEmpty && heights.isEmpty && zScores.isEmpty) {
      return Container(
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: const Color(0xFFF7FBFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: SgColors.border),
        ),
        child: const Text(
          'Grafik muncul setelah pengukuran tersedia.',
          textAlign: TextAlign.center,
          style: AppTypography.caption,
        ),
      );
    }
    return Container(
      height: 230,
      padding: const EdgeInsets.fromLTRB(10, 12, 10, 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FBFA),
        border: Border.all(color: SgColors.border),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 42),
              child: LineChart(
                LineChartData(
                  clipData: const FlClipData.none(),
                  minX: 0,
                  maxX: math.max(1, _chartLength() - 1).toDouble(),
                  minY: -0.08,
                  maxY: 1.08,
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) =>
                        const FlLine(color: Color(0xFFE6EFED), strokeWidth: 1),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 30,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final index = value.round();
                          if (index != value ||
                              index < 0 ||
                              index >= _chartLength()) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              _shortDateAt(index),
                              style: AppTypography.caption.copyWith(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: SgColors.textSecondary,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    enabled: true,
                    handleBuiltInTouches: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => Colors.white,
                      tooltipRoundedRadius: 14,
                      tooltipPadding: const EdgeInsets.all(10),
                      tooltipMargin: 10,
                      maxContentWidth: 220,
                      fitInsideHorizontally: true,
                      fitInsideVertically: true,
                      getTooltipItems: (spots) => spots.map((spot) {
                        final idx = spot.x.toInt().clamp(0, _chartLength() - 1);
                        final metric = _metricLabel(spot.barIndex);
                        final value = _rawValue(spot.barIndex, idx);
                        return LineTooltipItem(
                          '$metric: $value\nTanggal: ${_dateAt(idx)}\nBB/U: ${_bbuAt(idx)}\nTB/U: ${_tbuAt(idx)}\nBB/TB: ${_bbtbAt(idx)}\nStatus: ${_statusAt(idx)}',
                          AppTypography.caption.copyWith(
                            color: SgColors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  lineBarsData: [
                    if (weights.isNotEmpty)
                      _chartLine(weights, SgColors.primary),
                    if (heights.isNotEmpty)
                      _chartLine(heights, const Color(0xFF2F80ED)),
                    if (zScores.isNotEmpty)
                      _chartLine(zScores, const Color(0xFF58B98B)),
                  ],
                ),
                duration: 450.ms,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Wrap(
            spacing: 10,
            runSpacing: 6,
            children: [
              _ChartLegend(label: 'BB', color: SgColors.primary),
              _ChartLegend(label: 'TB', color: Color(0xFF2F80ED)),
              _ChartLegend(label: 'TB/U', color: Color(0xFF58B98B)),
            ],
          ),
        ],
      ),
    );
  }

  LineChartBarData _chartLine(List<double> values, Color color) {
    if (values.isEmpty) {
      return LineChartBarData(spots: const []);
    }
    final min = values.reduce(math.min);
    final max = values.reduce(math.max);
    final range = (max - min).abs() < 0.001 ? 1.0 : max - min;
    return LineChartBarData(
      spots: [
        for (var i = 0; i < values.length; i++)
          FlSpot(i.toDouble(), (values[i] - min) / range),
      ],
      isCurved: values.length > 1,
      curveSmoothness: 0.35,
      color: color,
      barWidth: 2.8,
      isStrokeCapRound: true,
      dotData: FlDotData(
        show: true,
        getDotPainter: (_, _, _, _) => FlDotCirclePainter(
          radius: 4.4,
          color: color,
          strokeWidth: 2,
          strokeColor: Colors.white,
        ),
      ),
      belowBarData: BarAreaData(
        show: values.length > 1,
        color: color.withValues(alpha: 0.08),
      ),
    );
  }
}

class _ChartLegend extends StatelessWidget {
  const _ChartLegend({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            fontSize: 10,
            color: SgColors.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

extension _MiniGrowthChartData on _MiniGrowthChart {
  int _chartLength() {
    return [
      weights.length,
      heights.length,
      zScores.length,
      dates.length,
      statuses.length,
    ].fold<int>(0, math.max);
  }

  String _metricLabel(int barIndex) {
    final hasWeight = weights.isNotEmpty;
    final hasHeight = heights.isNotEmpty;
    if (hasWeight && barIndex == 0) return 'BB';
    if (hasHeight && barIndex == (hasWeight ? 1 : 0)) return 'TB';
    return 'Z-score TB/U';
  }

  String _rawValue(int barIndex, int index) {
    final hasWeight = weights.isNotEmpty;
    final hasHeight = heights.isNotEmpty;
    if (hasWeight && barIndex == 0 && index < weights.length) {
      return '${weights[index].toStringAsFixed(1)} kg';
    }
    if (hasHeight &&
        barIndex == (hasWeight ? 1 : 0) &&
        index < heights.length) {
      return '${heights[index].toStringAsFixed(0)} cm';
    }
    if (index < zScores.length) return zScores[index].toStringAsFixed(1);
    return '-';
  }

  String _dateAt(int index) {
    if (index >= 0 && index < dates.length && dates[index].trim().isNotEmpty) {
      return dates[index];
    }
    return '-';
  }

  String _shortDateAt(int index) {
    final value = _dateAt(index);
    if (value == '-') return '';
    final parts = value.split('/');
    if (parts.length >= 2) return '${parts[0]}/${parts[1]}';
    return value;
  }

  String _statusAt(int index) {
    if (index >= 0 &&
        index < statuses.length &&
        statuses[index].trim().isNotEmpty) {
      return statuses[index];
    }
    return '-';
  }

  String _bbuAt(int index) {
    if (index < zBbuScores.length) {
      return NutritionStatusHelper.bbuFromZ(zBbuScores[index]);
    }
    return '-';
  }

  String _tbuAt(int index) {
    if (index < zScores.length) {
      return NutritionStatusHelper.tbuFromZ(zScores[index]);
    }
    return '-';
  }

  String _bbtbAt(int index) {
    if (index < zBbtbScores.length) {
      return NutritionStatusHelper.bbtbFromZ(zBbtbScores[index]);
    }
    return '-';
  }
}

class _BottomNavItem {
  const _BottomNavItem(this.label, this.icon);
  final String label;
  final IconData icon;
}

class _NavBadge extends StatelessWidget {
  const _NavBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final label = count > 9 ? '9+' : '$count';
    return Container(
      constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: SgColors.danger,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white, width: 1.4),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: Colors.white,
          fontSize: 9,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _NutritionistBottomNav extends StatelessWidget {
  const _NutritionistBottomNav({
    required this.index,
    required this.onChanged,
    this.unreadChatCount = 0,
    this.notificationCount = 0,
  });

  final int index;
  final ValueChanged<int> onChanged;
  final int unreadChatCount;
  final int notificationCount;

  @override
  Widget build(BuildContext context) {
    const items = [
      _BottomNavItem('Dashboard', PhosphorIconsRegular.house),
      _BottomNavItem('Konsultasi', PhosphorIconsRegular.chatCircleDots),
      _BottomNavItem('Notifikasi', LucideIcons.bell),
      _BottomNavItem('Profil', PhosphorIconsRegular.user),
    ];
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(10, 6, 10, 8),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => onChanged(i),
                  child: AnimatedContainer(
                    duration: 220.ms,
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    decoration: BoxDecoration(
                      color: i == index
                          ? const Color(0xFFEAF8F7)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Icon(
                              items[i].icon,
                              size: 21,
                              color: i == index
                                  ? SgColors.primary
                                  : SgColors.textSecondary,
                            ),
                            if (i == 1 && unreadChatCount > 0)
                              Positioned(
                                right: -8,
                                top: -7,
                                child: _NavBadge(count: unreadChatCount),
                              ),
                            if (i == 2 && notificationCount > 0)
                              Positioned(
                                right: -8,
                                top: -7,
                                child: _NavBadge(count: notificationCount),
                              ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          items[i].label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: i == index
                                ? SgColors.primary
                                : SgColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.action, this.onTap});

  final String title;
  final String? action;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTypography.h2)),
        if (action != null) TextButton(onPressed: onTap, child: Text(action!)),
      ],
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.hint, required this.onChanged});

  final String hint;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(LucideIcons.search),
      ),
    );
  }
}

class _FilterChips extends StatelessWidget {
  const _FilterChips({
    required this.values,
    required this.selected,
    required this.onSelected,
  });

  final List<String> values;
  final String selected;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final value = values[index];
          final active = value == selected;
          return ChoiceChip(
            selected: active,
            showCheckmark: false,
            label: Text(value),
            onSelected: (_) => onSelected(value),
            selectedColor: SgColors.primary,
            backgroundColor: Colors.white,
            labelStyle: AppTypography.caption.copyWith(
              color: active ? Colors.white : SgColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
            side: BorderSide(
              color: active ? SgColors.primary : SgColors.border,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(999),
            ),
          );
        },
      ),
    );
  }
}

class _SoftChip extends StatelessWidget {
  const _SoftChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxWidth = math.max(120.0, MediaQuery.sizeOf(context).width - 72);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Text(
          label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppTypography.caption.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _MeasurePill extends StatelessWidget {
  const _MeasurePill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final maxWidth = math.max(150.0, MediaQuery.sizeOf(context).width - 64);
    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: SgColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: AppTypography.caption),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                value,
                softWrap: true,
                style: AppTypography.caption.copyWith(
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _openChat(BuildContext context, _NutritionistRoom room) {
  Navigator.of(context).push(fadeRoute(_ConsultationChatPage(room: room)));
}

void _showGrowthSheet(BuildContext context, _NutritionistRoom room) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.82,
        ),
        child: ListView(
          shrinkWrap: true,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            Text(
              'Grafik Pertumbuhan ${room.childName}',
              style: AppTypography.h2,
            ),
            const SizedBox(height: 6),
            const Text(
              'BB, TB, dan Z-score dari pengukuran terakhir.',
              style: AppTypography.body,
            ),
            const SizedBox(height: 16),
            _GrowthSummaryCard(room: room),
            const SizedBox(height: 14),
            _MiniGrowthChart(
              weights: room.weights,
              heights: room.heights,
              zBbuScores: room.zBbuScores,
              zScores: room.zScores,
              zBbtbScores: room.zBbtbScores,
              dates: room.measurementDateLabels,
              statuses: room.measurementStatusLabels,
            ),
          ],
        ),
      ),
    ),
  );
}

class _GrowthSummaryCard extends StatelessWidget {
  const _GrowthSummaryCard({required this.room});

  final _NutritionistRoom room;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      dense: true,
      color: const Color(0xFFF8FCFB),
      borderColor: SgColors.border,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(room.childName, style: AppTypography.h2),
          const SizedBox(height: 2),
          Text(
            '${room.age} • ${room.genderLabel}',
            style: AppTypography.body.copyWith(color: SgColors.textPrimary),
          ),
          const SizedBox(height: 14),
          Text('Hasil terakhir:', style: AppTypography.h3),
          const SizedBox(height: 8),
          _GrowthResultRow(label: 'BB/U', value: room.bbuStatusLabel),
          _GrowthResultRow(label: 'TB/U', value: room.tbuStatusLabel),
          _GrowthResultRow(label: 'BB/TB', value: room.bbtbStatusLabel),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SoftChip(
                label: 'Status: ${room.statusLabel}',
                color: _statusColor(room),
              ),
              _SoftChip(
                label: 'Tanggal pengukuran: ${room.measuredAtLabel}',
                color: SgColors.primary,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GrowthResultRow extends StatelessWidget {
  const _GrowthResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 54, child: Text(label, style: AppTypography.caption)),
          const Text(':  ', style: AppTypography.caption),
          Expanded(
            child: Text(
              value,
              style: AppTypography.body.copyWith(
                color: SgColors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

void _showNotificationSheet(
  BuildContext context,
  _NutritionistController controller,
) {
  final dismissedRoomIds = <int>{};
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) {
        final unreadRooms = controller.rooms
            .where(
              (room) => room.unread > 0 && !dismissedRoomIds.contains(room.id),
            )
            .toList();
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(sheetContext).height * 0.72,
            ),
            child: ListView(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
              children: [
                Text('Notifikasi', style: AppTypography.h2),
                const SizedBox(height: 12),
                if (unreadRooms.isEmpty)
                  const EmptyState(
                    title: 'Belum Ada Notifikasi',
                    message: 'Chat terbaru dari orang tua akan tampil di sini.',
                    icon: LucideIcons.bell,
                  )
                else ...[
                  ...unreadRooms
                      .take(3)
                      .map(
                        (room) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _NotificationTile(
                            title: '${room.unread} pesan belum dibaca',
                            description:
                                '${room.parentName} - ${room.childName}',
                            time: room.time,
                            icon: LucideIcons.messageCircle,
                            color: SgColors.primary,
                            onTap: () {
                              setSheetState(
                                () => dismissedRoomIds.add(room.id),
                              );
                              controller.markRoomNotificationRead(room.id);
                              Navigator.of(sheetContext).pop();
                              _openChat(context, room);
                            },
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
        );
      },
    ),
  );
}

void _showRiskSheet(BuildContext context, _NutritionistController controller) {
  final riskRooms = controller.rooms
      .where((room) => room.risk != _RiskLevel.normal)
      .toList();
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            Text('Monitoring Risiko', style: AppTypography.h2),
            const SizedBox(height: 12),
            if (riskRooms.isEmpty)
              const _AllClearRiskCard()
            else
              ...riskRooms.map(
                (room) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RiskMonitoringCard(room: room),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

void _showNeedMonitoringSheet(
  BuildContext context,
  _NutritionistController controller,
) {
  final monitoringRooms = controller.rooms
      .where((room) => room.monitoringStatus == 'perlu_dipantau')
      .toList();
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
    ),
    builder: (context) => SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.sizeOf(context).height * 0.78,
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 24),
          children: [
            Text('Perlu Dipantau', style: AppTypography.h2),
            const SizedBox(height: 6),
            const Text(
              'Konsultasi berikut memiliki data yang sudah dikonfirmasi orang tua dan perlu dipantau.',
              style: AppTypography.caption,
            ),
            const SizedBox(height: 12),
            if (monitoringRooms.isEmpty)
              const EmptyState(
                title: 'Tidak ada data yang perlu dipantau',
                message: 'Belum ada konsultasi dengan status Perlu Dipantau.',
                icon: LucideIcons.clipboardCheck,
              )
            else
              ...monitoringRooms.map(
                (room) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _RoomCard(
                    room: room,
                    onTap: () {
                      Navigator.of(context).pop();
                      _openChat(context, room);
                    },
                  ),
                ),
              ),
          ],
        ),
      ),
    ),
  );
}

Future<bool?> _confirmNutritionistLogout(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Keluar dari akun?'),
      content: const Text(
        'Anda akan keluar dari dashboard Ahli Gizi S-Gizi pada perangkat ini.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: FilledButton.styleFrom(backgroundColor: SgColors.danger),
          child: const Text('Logout'),
        ),
      ],
    ),
  );
}

class _SheetTextField extends StatelessWidget {
  const _SheetTextField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.validator,
  });

  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
    );
  }
}

_RiskVisual _riskVisual(_RiskLevel risk) {
  switch (risk) {
    case _RiskLevel.high:
      return const _RiskVisual(
        'Risiko Tinggi',
        SgColors.danger,
        LucideIcons.siren,
      );
    case _RiskLevel.warning:
      return const _RiskVisual(
        'Perhatian',
        SgColors.warning,
        Icons.warning_amber_rounded,
      );
    case _RiskLevel.normal:
      return const _RiskVisual(
        'Normal',
        SgColors.success,
        Icons.check_circle_outline_rounded,
      );
  }
}

Color _statusColor(_NutritionistRoom room) {
  if (!room.isMeasured) return const Color(0xFF9CA3AF);
  switch (room.risk) {
    case _RiskLevel.high:
      return SgColors.danger;
    case _RiskLevel.warning:
      return SgColors.warning;
    case _RiskLevel.normal:
      return SgColors.success;
  }
}

Color _activityColor(String title) {
  final value = title.toLowerCase();
  if (value.contains('anomali') || value.contains('ekstrem')) {
    return const Color(0xFFEF6C00);
  }
  if (value.contains('pesan') || value.contains('konsultasi')) {
    return const Color(0xFF3B82F6);
  }
  if (value.contains('ukur')) return SgColors.primary;
  return SgColors.warning;
}

IconData _activityIcon(String title) {
  final value = title.toLowerCase();
  if (value.contains('pesan') || value.contains('konsultasi')) {
    return LucideIcons.messageCircle;
  }
  if (value.contains('ukur')) return LucideIcons.clipboardList;
  if (value.contains('anomali') || value.contains('ekstrem')) {
    return Icons.warning_amber_rounded;
  }
  return LucideIcons.bell;
}

class _NutritionistProfile {
  const _NutritionistProfile({
    required this.name,
    required this.specialization,
    required this.experience,
    required this.phone,
    required this.email,
    required this.license,
    required this.online,
    required this.photoUrl,
    required this.gender,
  });

  final String name;
  final String specialization;
  final String experience;
  final String phone;
  final String email;
  final String license;
  final bool online;
  final String photoUrl;
  final String gender;

  String get salutationName {
    final prefix = _genderPrefix(gender);
    final clean = name
        .replaceAll(RegExp(r'\bdr\.?\b', caseSensitive: false), '')
        .replaceAll(
          RegExp(r'\b(sp\.?gk|s\.?gz|m\.?gz)\b', caseSensitive: false),
          '',
        )
        .replaceAll(',', ' ')
        .trim();
    final parts = clean.split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
    final first = parts.isEmpty ? 'Ahli Gizi' : parts.first;
    return '$prefix $first';
  }

  _NutritionistProfile copyWith({bool? online}) {
    return _NutritionistProfile(
      name: name,
      specialization: specialization,
      experience: experience,
      phone: phone,
      email: email,
      license: license,
      online: online ?? this.online,
      photoUrl: photoUrl,
      gender: gender,
    );
  }

  factory _NutritionistProfile.fromJson(
    Map<String, dynamic> json, {
    required _NutritionistProfile fallback,
  }) {
    final nutritionist = json['nutritionist'] is Map<String, dynamic>
        ? json['nutritionist'] as Map<String, dynamic>
        : const <String, dynamic>{};
    String pick(Map<String, dynamic> source, String key, String fallbackValue) {
      final value = (source[key] as String? ?? '').trim();
      return value.isEmpty ? fallbackValue : value;
    }

    return _NutritionistProfile(
      name: pick(json, 'name', fallback.name),
      specialization: pick(
        nutritionist,
        'specialization',
        fallback.specialization,
      ),
      experience: pick(nutritionist, 'experience', fallback.experience),
      phone: pick(json, 'phone', fallback.phone),
      email: pick(json, 'email', fallback.email),
      license: pick(nutritionist, 'str_sip', fallback.license),
      online: nutritionist['is_online'] == true,
      photoUrl: _pickString(json, const [
        'profile_image',
        'photo',
        'profile_photo',
        'avatar',
        'asset_image',
      ], fallback.photoUrl),
      gender: pick(
        json,
        'gender',
        pick(json, 'parent_gender', fallback.gender),
      ),
    );
  }
}

class _NutritionistRoom {
  const _NutritionistRoom({
    required this.id,
    required this.parentName,
    required this.childName,
    required this.age,
    required this.childGender,
    required this.status,
    required this.risk,
    required this.lastMessage,
    required this.time,
    required this.unread,
    required this.state,
    required this.weights,
    required this.heights,
    required this.zBbuScores,
    required this.zScores,
    required this.zBbtbScores,
    required this.measurementDates,
    required this.measurementStatuses,
    required this.previousStatus,
    required this.measuredAt,
    required this.zBbu,
    required this.zTbu,
    required this.zBbtb,
    required this.zScore,
    required this.isAnomaly,
    required this.validationStatus,
    required this.validationNote,
    required this.monitoringStatus,
    required this.isConfirmedByParent,
    required this.riskReasons,
  });

  final int id;
  final String parentName;
  final String childName;
  final String age;
  final String childGender;
  final String status;
  final _RiskLevel risk;
  final String lastMessage;
  final String time;
  final int unread;
  final String state;
  final List<double> weights;
  final List<double> heights;
  final List<double> zBbuScores;
  final List<double> zScores;
  final List<double> zBbtbScores;
  final List<String> measurementDates;
  final List<String> measurementStatuses;
  final String previousStatus;
  final String measuredAt;
  final double? zBbu;
  final double? zTbu;
  final double? zBbtb;
  final double? zScore;
  final bool isAnomaly;
  final String validationStatus;
  final String validationNote;
  final String monitoringStatus;
  final bool isConfirmedByParent;
  final List<String> riskReasons;

  _NutritionistRoom copyWith({int? unread}) {
    return _NutritionistRoom(
      id: id,
      parentName: parentName,
      childName: childName,
      age: age,
      childGender: childGender,
      status: status,
      risk: risk,
      lastMessage: lastMessage,
      time: time,
      unread: unread ?? this.unread,
      state: unread == 0 && this.unread > 0 ? 'Aktif' : state,
      weights: weights,
      heights: heights,
      zBbuScores: zBbuScores,
      zScores: zScores,
      zBbtbScores: zBbtbScores,
      measurementDates: measurementDates,
      measurementStatuses: measurementStatuses,
      previousStatus: previousStatus,
      measuredAt: measuredAt,
      zBbu: zBbu,
      zTbu: zTbu,
      zBbtb: zBbtb,
      zScore: zScore,
      isAnomaly: isAnomaly,
      validationStatus: validationStatus,
      validationNote: validationNote,
      monitoringStatus: monitoringStatus,
      isConfirmedByParent: isConfirmedByParent,
      riskReasons: riskReasons,
    );
  }

  bool get isMeasured {
    final value = status.trim().toLowerCase();
    return value.isNotEmpty && !value.contains('belum');
  }

  String get statusLabel =>
      isMeasured ? _localizedNutritionStatus(status) : 'Belum Diukur';

  String get genderLabel => _childGenderLabel(childGender);

  String get bbuStatusLabel => NutritionStatusHelper.bbuFromZ(zBbu);

  String get tbuStatusLabel => NutritionStatusHelper.tbuFromZ(zTbu);

  String get bbtbStatusLabel => NutritionStatusHelper.bbtbFromZ(zBbtb);

  bool get hasGrowthChartData =>
      weights.isNotEmpty || heights.isNotEmpty || zScores.isNotEmpty;

  List<String> get measurementDateLabels {
    if (measurementDates.isEmpty && measuredAtLabel != '-') {
      return [measuredAtLabel];
    }
    return measurementDates.map(_dateLabel).toList();
  }

  List<String> get measurementStatusLabels {
    if (measurementStatuses.isEmpty && statusLabel != 'Belum Diukur') {
      return [statusLabel];
    }
    return measurementStatuses.map(_localizedNutritionStatus).toList();
  }

  String get measuredAtLabel {
    final raw = measuredAt.trim();
    if (raw.isEmpty) return '-';
    final parsed = DateTime.tryParse(raw);
    if (parsed == null) return raw;
    String two(int value) => value.toString().padLeft(2, '0');
    return '${two(parsed.day)}/${two(parsed.month)}/${parsed.year}';
  }

  String get zScoreLabel => zScore == null ? '-' : zScore!.toStringAsFixed(1);

  String get weightChangeLabel {
    if (weights.isEmpty) return '-';
    if (weights.length == 1) return '${weights.last.toStringAsFixed(1)} kg';
    final previous = weights[weights.length - 2];
    return '${previous.toStringAsFixed(1)} -> ${weights.last.toStringAsFixed(1)} kg';
  }

  String get latestWeightLabel =>
      weights.isEmpty ? '-' : '${weights.last.toStringAsFixed(1)} kg';

  String get heightChangeLabel {
    if (heights.isEmpty) return '-';
    if (heights.length == 1) return '${heights.last.toStringAsFixed(0)} cm';
    final previous = heights[heights.length - 2];
    return '${previous.toStringAsFixed(0)} -> ${heights.last.toStringAsFixed(0)} cm';
  }

  String get latestHeightLabel =>
      heights.isEmpty ? '-' : '${heights.last.toStringAsFixed(0)} cm';

  factory _NutritionistRoom.fromJson(Map<String, dynamic> json) {
    final weights = _doubleList(json['weights']);
    final heights = _doubleList(json['heights']);
    final zBbuScores = _doubleList(json['z_bbu_scores']);
    final zScores = _doubleList(json['z_scores']);
    final zBbtbScores = _doubleList(json['z_bbtb_scores']);
    final measurementDates = _stringList(json['measurement_dates']);
    final measurementStatuses = _stringList(json['measurement_statuses']);
    final latest = json['latest_measurement'] is Map<String, dynamic>
        ? json['latest_measurement'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final previous = json['previous_measurement'] is Map<String, dynamic>
        ? json['previous_measurement'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final latestStatus = (json['status'] as String? ?? 'Belum Diukur').trim();
    return _NutritionistRoom(
      id: (json['id'] as num?)?.toInt() ?? 0,
      parentName: (json['parent_name'] as String? ?? 'Orang Tua').trim(),
      childName: (json['child_name'] as String? ?? 'Anak').trim(),
      age: _formatAgeLabel((json['child_age'] as String? ?? '-').trim()),
      childGender:
          (json['child_gender'] as String? ??
                  json['gender'] as String? ??
                  json['jenis_kelamin'] as String? ??
                  '-')
              .trim(),
      status: latestStatus,
      risk: _riskFromString(json['risk'] as String?),
      lastMessage: (json['last_message'] as String? ?? '').trim().isEmpty
          ? 'Belum ada pesan terbaru.'
          : (json['last_message'] as String).trim(),
      time: _shortTime(json['last_message_at'] as String?),
      unread: (json['unread_count'] as num?)?.toInt() ?? 0,
      state: _stateLabel(
        json['room_status'] as String?,
        (json['unread_count'] as num?)?.toInt() ?? 0,
      ),
      weights: weights.isEmpty && _doubleValue(latest['berat']) != null
          ? [_doubleValue(latest['berat'])!]
          : weights,
      heights: heights.isEmpty && _doubleValue(latest['tinggi']) != null
          ? [_doubleValue(latest['tinggi'])!]
          : heights,
      zBbuScores: zBbuScores.isEmpty && _doubleValue(latest['z_bbu']) != null
          ? [_doubleValue(latest['z_bbu'])!]
          : zBbuScores,
      zScores: zScores.isEmpty && _doubleValue(latest['z_tbu']) != null
          ? [_doubleValue(latest['z_tbu'])!]
          : zScores,
      zBbtbScores: zBbtbScores.isEmpty && _doubleValue(latest['z_bbtb']) != null
          ? [_doubleValue(latest['z_bbtb'])!]
          : zBbtbScores,
      measurementDates:
          measurementDates.isEmpty &&
              (latest['tanggal_ukur'] as String? ?? '').trim().isNotEmpty
          ? [(latest['tanggal_ukur'] as String).trim()]
          : measurementDates,
      measurementStatuses:
          measurementStatuses.isEmpty && latestStatus.isNotEmpty
          ? [latestStatus]
          : measurementStatuses,
      previousStatus: (previous['status_gabungan'] as String? ?? latestStatus)
          .trim(),
      measuredAt: (latest['tanggal_ukur'] as String? ?? '').trim(),
      zBbu: _doubleValue(latest['z_bbu']),
      zTbu: _doubleValue(latest['z_tbu']),
      zBbtb: _doubleValue(latest['z_bbtb']),
      zScore: _doubleValue(latest['z_tbu']) ?? _doubleValue(latest['z_bbtb']),
      isAnomaly:
          _readBool(json['is_anomaly']) ||
          _readBool(latest['is_anomaly']) ||
          _readBool(json['has_anomaly']) ||
          _readBool(json['needs_remeasure']),
      validationStatus:
          (json['validation_status'] as String? ??
                  latest['validation_status'] as String? ??
                  'valid')
              .trim(),
      validationNote:
          (json['validation_note'] as String? ??
                  latest['validation_note'] as String? ??
                  '')
              .trim(),
      monitoringStatus:
          (json['monitoring_status'] as String? ??
                  latest['monitoring_status'] as String? ??
                  'normal')
              .trim(),
      isConfirmedByParent:
          _readBool(json['is_confirmed_by_parent']) ||
          _readBool(latest['is_confirmed_by_parent']),
      riskReasons: json['risk_reasons'] is List
          ? (json['risk_reasons'] as List)
                .whereType<String>()
                .map((item) => item.trim())
                .where((item) => item.isNotEmpty)
                .toList()
          : const [],
    );
  }
}

class _ChatMessage {
  const _ChatMessage({
    required this.text,
    required this.fromParent,
    required this.time,
  });

  final String text;
  final bool fromParent;
  final String time;

  factory _ChatMessage.fromJson(Map<String, dynamic> json) {
    final sender = (json['sender_type'] as String? ?? '').toLowerCase();
    return _ChatMessage(
      text: (json['message'] as String? ?? '').trim(),
      fromParent: sender != 'expert',
      time: _shortTime(json['created_at'] as String?),
    );
  }
}

class _NutritionistActivity {
  const _NutritionistActivity({
    required this.title,
    required this.description,
    required this.time,
  });

  final String title;
  final String description;
  final String time;

  factory _NutritionistActivity.fromJson(Map<String, dynamic> json) {
    return _NutritionistActivity(
      title: (json['title'] as String? ?? 'Aktivitas baru').trim(),
      description: (json['description'] as String? ?? '').trim(),
      time: _shortTime(json['time'] as String?),
    );
  }
}

class _StatVm {
  const _StatVm(
    this.label,
    this.value,
    this.icon,
    this.color,
    this.background,
    this.onTap,
  );
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color background;
  final VoidCallback onTap;
}

class _RiskVisual {
  const _RiskVisual(this.label, this.color, this.icon);
  final String label;
  final Color color;
  final IconData icon;
}

String _genderPrefix(String raw) {
  final value = raw.trim().toLowerCase();
  if (value == 'l' ||
      value.contains('laki') ||
      value.contains('pria') ||
      value.contains('male')) {
    return 'Bapak';
  }
  return 'Ibu';
}

String _childGenderLabel(String raw) {
  final value = raw.trim().toLowerCase();
  if (value == 'l' || value.contains('laki') || value.contains('male')) {
    return 'Laki-laki';
  }
  if (value == 'p' || value.contains('perempuan') || value.contains('female')) {
    return 'Perempuan';
  }
  return '-';
}

String _pickString(
  Map<String, dynamic> source,
  List<String> keys, [
  String fallback = '',
]) {
  for (final key in keys) {
    final value = (source[key] as String? ?? '').trim();
    if (value.isNotEmpty) return value;
  }
  return fallback;
}

String _absoluteImageUrl(String raw) {
  final value = raw.trim();
  if (value.startsWith('http://') || value.startsWith('https://')) {
    return value;
  }
  final apiBase = ApiService().baseUrl;
  final root = apiBase.endsWith('/api')
      ? apiBase.substring(0, apiBase.length - 4)
      : apiBase;
  final path = value.startsWith('/') ? value : '/$value';
  return '$root$path';
}

String _localizedNutritionStatus(String raw) {
  return NutritionStatusHelper.localize(raw);
}

String _formatAgeLabel(String raw) {
  final value = raw.trim();
  if (value.isEmpty || value == '-') return '-';
  if (!RegExp(r'\d+\.\d+').hasMatch(value)) return value;
  final number = double.tryParse(
    RegExp(r'\d+\.\d+').firstMatch(value)?.group(0) ?? '',
  );
  if (number == null) return value;
  final totalMonths = (number * 12).round();
  final years = totalMonths ~/ 12;
  final months = totalMonths % 12;
  if (years < 2) return '$totalMonths Bulan';
  if (months == 0) return '$years Tahun';
  return '$years Tahun $months Bulan';
}

List<double> _doubleList(Object? value) {
  if (value is! List) return const [];
  return value.map(_doubleValue).whereType<double>().toList(growable: false);
}

double? _doubleValue(Object? value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.trim());
  return null;
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) => (item?.toString() ?? '').trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

String _dateLabel(String raw) {
  final value = raw.trim();
  if (value.isEmpty) return '-';
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
  String two(int value) => value.toString().padLeft(2, '0');
  return '${two(parsed.day)}/${two(parsed.month)}/${parsed.year}';
}

bool _readBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.trim().toLowerCase();
    return normalized == 'true' || normalized == '1' || normalized == 'yes';
  }
  return false;
}

_RiskLevel _riskFromString(String? value) {
  switch ((value ?? '').toLowerCase()) {
    case 'high':
      return _RiskLevel.high;
    case 'warning':
      return _RiskLevel.warning;
    default:
      return _RiskLevel.normal;
  }
}

String _stateLabel(String? status, int unread) {
  final value = (status ?? '').toLowerCase();
  if (unread > 0) return 'Belum Dibalas';
  if (value == 'closed' || value == 'selesai') return 'Selesai';
  if (value == 'pending') return 'Pending';
  return 'Aktif';
}

String _shortTime(String? raw) {
  if (raw == null || raw.trim().isEmpty) return '-';
  final date = DateTime.tryParse(raw)?.toLocal();
  if (date == null) return raw;
  final now = DateTime.now();
  final sameDay =
      now.year == date.year && now.month == date.month && now.day == date.day;
  String two(int value) => value.toString().padLeft(2, '0');
  if (sameDay) return '${two(date.hour)}:${two(date.minute)}';
  return '${two(date.day)}/${two(date.month)}';
}

enum _RiskLevel { high, warning, normal }
