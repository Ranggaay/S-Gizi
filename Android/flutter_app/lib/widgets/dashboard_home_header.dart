import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/app_state.dart';
import 'package:s_gizi/features/profile/screens/profile_screen.dart';

/// Header bersama: logo, notifikasi, avatar profil.
class DashboardHomeHeader extends StatelessWidget {
  const DashboardHomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final profile =
        SgiziAppState.instance.profileData ?? SgiziAppState.instance.userData;
    final name = (profile?['name'] as String?)?.trim() ?? 'Pengguna';

    return Row(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.asset(
            'assets/image/logo_sgizi.png',
            width: 52,
            height: 52,
            fit: BoxFit.cover,
          ),
        ),
        const Spacer(),
        IconButton(
          onPressed: () {},
          icon: const Icon(LucideIcons.bell, color: Color(0xFF5A6875)),
        ),
        InkWell(
          onTap: () => Navigator.of(
            context,
          ).push(fadeRoute(const ProfileScreen())),
          borderRadius: BorderRadius.circular(999),
          child: SgAvatar(name: name, radius: 22, icon: Icons.person),
        ),
      ],
    );
  }
}
