import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/features/auth/screens/auth_screen.dart';
import 'package:s_gizi/providers/auth_provider.dart';
import 'package:s_gizi/providers/profile_provider.dart';
import 'package:s_gizi/widgets/loading_skeleton.dart';
import 'package:s_gizi/widgets/nutritionist_bottom_nav_bar.dart';
import 'package:s_gizi/widgets/profile_info_tile.dart';

class NutritionistProfileScreen extends StatefulWidget {
  const NutritionistProfileScreen({super.key, this.showBottomNav = true});

  final bool showBottomNav;

  @override
  State<NutritionistProfileScreen> createState() =>
      _NutritionistProfileScreenState();
}

class _NutritionistProfileScreenState extends State<NutritionistProfileScreen> {
  late final ProfileProvider _profile;
  late final AuthProvider _auth;

  @override
  void initState() {
    super.initState();
    _profile = ProfileProvider()..fetchProfile();
    _auth = AuthProvider();
  }

  @override
  void dispose() {
    _profile.dispose();
    _auth.dispose();
    super.dispose();
  }

  Future<void> _logout() async {
    await _auth.logout();
    if (!mounted) return;
    Navigator.of(
      context,
    ).pushAndRemoveUntil(fadeRoute(const AuthScreen()), (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      appBar: widget.showBottomNav ? AppBar(title: const Text('Profil')) : null,
      bottomNavigationBar: widget.showBottomNav
          ? NutritionistBottomNavBar(
              currentIndex: 3,
              onTap: (_) => Navigator.of(context).maybePop(),
            )
          : null,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _profile,
          builder: (context, _) {
            if (_profile.isLoading) return const LoadingSkeleton();
            if (_profile.errorMessage != null) {
              return ErrorState(
                message: _profile.errorMessage!,
                onRetry: _profile.fetchProfile,
              );
            }
            final profile = _profile.profile;
            if (profile == null) {
              return const EmptyState(
                title: 'Profil belum tersedia',
                message: 'Silakan coba lagi.',
              );
            }
            return ListView(
              padding: EdgeInsets.fromLTRB(
                20,
                widget.showBottomNav ? 14 : 8,
                20,
                120,
              ),
              children: [
                if (!widget.showBottomNav) ...[
                  Text(
                    'Profil',
                    style: AppTypography.h1.copyWith(fontSize: 28),
                  ),
                  const SizedBox(height: 10),
                ],
                HealthCard(
                  dense: true,
                  child: Row(
                    children: [
                      SgAvatar(name: profile.name, radius: 34),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(profile.name, style: AppTypography.h2),
                            Text(profile.profession, style: AppTypography.body),
                            const SizedBox(height: 6),
                            SwitchListTile(
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              title: const Text('Aktif menerima konsultasi'),
                              value: profile.isActive,
                              onChanged: _profile.updateStatus,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                ProfileInfoTile(
                  icon: LucideIcons.phone,
                  label: 'Nomor HP',
                  value: profile.phone,
                ),
                const SizedBox(height: 10),
                ProfileInfoTile(
                  icon: LucideIcons.mail,
                  label: 'Email',
                  value: profile.email,
                ),
                const SizedBox(height: 10),
                ProfileInfoTile(
                  icon: LucideIcons.building2,
                  label: 'Tempat Kerja',
                  value: profile.workplace,
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: _auth.isLoading ? 'Keluar...' : 'Logout',
                  icon: LucideIcons.logOut,
                  isOutlined: true,
                  onPressed: _auth.isLoading ? null : _logout,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
