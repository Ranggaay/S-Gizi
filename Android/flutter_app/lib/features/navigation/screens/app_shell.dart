import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/app_state.dart';
import 'package:s_gizi/services/api_service.dart';
import 'package:s_gizi/features/consultation/screens/consultation_chat_screen.dart';
import 'package:s_gizi/features/dashboard/screens/home_screen.dart';
import 'package:s_gizi/features/nutrition/screens/nutrition_screen.dart';
import 'package:s_gizi/features/profile/screens/profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _api = ApiService();
  int _index = 0;
  bool _homeShowsFamilyOverview = false;
  int _consultationUnread = 0;
  Timer? _badgeTimer;

  late final List<Widget> _screens = [
    HomeScreen(
      onChangeTab: _setTab,
      onOverviewChanged: _setHomeOverviewVisible,
    ),
    const NutritionScreen(),
    const ConsultationChatScreen(showAppBar: false),
    const ProfileScreen(),
  ];

  void _setTab(int index) {
    setState(() => _index = index);
    _loadConsultationUnread();
  }

  @override
  void initState() {
    super.initState();
    SgiziAppState.instance.addListener(_loadConsultationUnread);
    _loadConsultationUnread();
    _badgeTimer = Timer.periodic(
      const Duration(seconds: 8),
      (_) => _loadConsultationUnread(),
    );
  }

  @override
  void dispose() {
    _badgeTimer?.cancel();
    SgiziAppState.instance.removeListener(_loadConsultationUnread);
    super.dispose();
  }

  Future<void> _loadConsultationUnread() async {
    final child = SgiziAppState.instance.activeChild;
    if (child == null) {
      if (mounted) setState(() => _consultationUnread = 0);
      return;
    }
    try {
      final rows = await _api.getConsultationRooms(childId: child.id);
      final total = rows.fold<int>(
        0,
        (sum, row) => sum + ((row['unread_count'] as num?)?.toInt() ?? 0),
      );
      if (mounted) setState(() => _consultationUnread = total);
    } catch (_) {
      if (mounted) setState(() => _consultationUnread = 0);
    }
  }

  void _setHomeOverviewVisible(bool visible) {
    if (_homeShowsFamilyOverview == visible) return;
    setState(() => _homeShowsFamilyOverview = visible);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        child: KeyedSubtree(key: ValueKey(_index), child: _screens[_index]),
      ),
      bottomNavigationBar: _index == 0 && _homeShowsFamilyOverview
          ? null
          : Container(
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
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 380;
                    return Row(
                      children: [
                        _NavItem(
                          label: 'Home',
                          active: _index == 0,
                          icon: PhosphorIconsRegular.house,
                          compact: compact,
                          onTap: () => _setTab(0),
                        ),
                        _NavItem(
                          label: 'Nutrisi',
                          active: _index == 1,
                          icon: LucideIcons.apple,
                          compact: compact,
                          onTap: () => _setTab(1),
                        ),
                        _NavItem(
                          label: 'Konsultasi',
                          active: _index == 2,
                          icon: PhosphorIconsRegular.chatCircleDots,
                          badge: _consultationUnread,
                          compact: compact,
                          onTap: () => _setTab(2),
                        ),
                        _NavItem(
                          label: 'Profil',
                          active: _index == 3,
                          icon: PhosphorIconsRegular.user,
                          compact: compact,
                          onTap: () => _setTab(3),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.label,
    required this.active,
    required this.icon,
    required this.compact,
    required this.onTap,
    this.badge = 0,
  });

  final String label;
  final bool active;
  final IconData icon;
  final bool compact;
  final VoidCallback onTap;
  final int badge;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child:
            AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: EdgeInsets.symmetric(vertical: compact ? 6 : 8),
                  decoration: BoxDecoration(
                    color: active
                        ? const Color(0xFFEAF8F7)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          AnimatedScale(
                            scale: active ? 1.08 : 1,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              icon,
                              size: compact ? 21 : 24,
                              color: active
                                  ? const Color(0xFF0B7A86)
                                  : const Color(0xFF8B959C),
                            ),
                          ),
                          if (badge > 0)
                            Positioned(
                              right: -10,
                              top: -7,
                              child: _NavBadge(count: badge),
                            ),
                        ],
                      ),
                      if (badge > 0 && !compact) ...[
                        const SizedBox(height: 2),
                        Text(
                          badge > 99 ? '99+' : '$badge',
                          style: AppTypography.caption.copyWith(
                            fontSize: 9,
                            color: SgColors.danger,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ],
                      const SizedBox(height: 3),
                      Text(
                        label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.caption.copyWith(
                          fontSize: compact ? 10 : null,
                          color: active
                              ? const Color(0xFF0B7A86)
                              : const Color(0xFF8B959C),
                          fontWeight: active
                              ? FontWeight.w800
                              : FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        height: 3,
                        width: active ? 20 : 0,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0B7A86),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ],
                  ),
                )
                .animate(target: active ? 1 : 0)
                .scale(
                  begin: const Offset(0.98, 0.98),
                  end: const Offset(1, 1),
                  duration: 220.ms,
                ),
      ),
    );
  }
}

class _NavBadge extends StatelessWidget {
  const _NavBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
      padding: const EdgeInsets.symmetric(horizontal: 4),
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
          fontSize: 9,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
