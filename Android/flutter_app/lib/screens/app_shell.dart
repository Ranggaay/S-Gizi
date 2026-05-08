import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../app_design.dart';
import 'consultation_chat_screen.dart';
import 'home_screen.dart';
import 'nutrition_screen.dart';
import 'profile_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _index = 0;

  late final List<Widget> _screens = [
    HomeScreen(onChangeTab: _setTab),
    const NutritionScreen(),
    const ConsultationChatScreen(showAppBar: false),
    const ProfileScreen(),
  ];

  void _setTab(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        switchInCurve: Curves.easeOut,
        child: KeyedSubtree(key: ValueKey(_index), child: _screens[_index]),
      ),
      bottomNavigationBar: Container(
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
        padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
        child: SafeArea(
          top: false,
          child: Row(
            children: [
              _NavItem(
                label: 'Home',
                active: _index == 0,
                icon: PhosphorIconsRegular.house,
                onTap: () => _setTab(0),
              ),
              _NavItem(
                label: 'Nutrisi',
                active: _index == 1,
                icon: LucideIcons.apple,
                onTap: () => _setTab(1),
              ),
              _NavItem(
                label: 'Ahli',
                active: _index == 2,
                icon: PhosphorIconsRegular.chatCircleDots,
                onTap: () => _setTab(2),
              ),
              _NavItem(
                label: 'Profil',
                active: _index == 3,
                icon: PhosphorIconsRegular.user,
                onTap: () => _setTab(3),
              ),
            ],
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
    required this.onTap,
  });

  final String label;
  final bool active;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFEAF8F7) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: active ? 1.08 : 1,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  icon,
                  color: active ? const Color(0xFF0B7A86) : const Color(0xFF8B959C),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: AppTypography.caption.copyWith(
                  color: active ? const Color(0xFF0B7A86) : const Color(0xFF8B959C),
                  fontWeight: active ? FontWeight.w800 : FontWeight.w600,
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
        ).animate(target: active ? 1 : 0).scale(
          begin: const Offset(0.98, 0.98),
          end: const Offset(1, 1),
          duration: 220.ms,
        ),
      ),
    );
  }
}
