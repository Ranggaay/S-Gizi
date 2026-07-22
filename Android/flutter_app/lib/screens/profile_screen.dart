import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:shimmer/shimmer.dart';

import '../app_design.dart';
import '../app_state.dart';
import '../models/mobile_child_model.dart';
import '../services/api_service.dart';
import '../utils/nutrition_display_utils.dart';
import '../widgets/nutrition_status_badges.dart';
import 'add_child_screen.dart';
import 'account_info_screen.dart';
import 'auth_screen.dart';
import 'help_screen.dart';
import 'security_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _api = ApiService();
  final _state = SgiziAppState.instance;

  late Future<void> _future;

  @override
  void initState() {
    super.initState();
    _state.addListener(_onStateChanged);
    _future = _load();
  }

  @override
  void dispose() {
    _state.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _load() async {
    if (!_state.isAuthenticated) return;
    final results = await Future.wait([_api.getChildren(), _api.getProfile()]);
    final children = results[0] as List<MobileChildModel>;
    final profile = results[1] as Map<String, dynamic>;
    _state.setChildren(children);
    _state.setProfileData(profile);
  }

  void _retry() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      body: SafeArea(
        child: FutureBuilder<void>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _ProfileSkeleton();
            }
            if (snapshot.hasError) {
              return _ProfileError(onRetry: _retry);
            }
            final profile = _state.profileData;
            final name = (profile?['name'] as String? ?? 'Siti Aminah').trim();
            final phone = (profile?['phone'] as String? ?? '-').trim();
            final role = (profile?['role'] as String? ?? 'orang_tua').trim();
            return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    SgSpacing.pageH,
                    SgSpacing.pageV,
                    SgSpacing.pageH,
                    20,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ProfileHeaderCard(
                        name: name.isEmpty ? 'Siti Aminah' : name,
                        subtitle: _profileRoleToLabel(role, phone),
                        onEditTap: () async {
                          await Navigator.of(
                            context,
                          ).push(fadeRoute(const AccountInfoScreen()));
                          if (!mounted) return;
                          _retry();
                        },
                      ),
                      const SizedBox(height: 18),
                      _ChildrenSection(
                        children: _state.children,
                        activeChildId: _state.activeChildId,
                        onAdd: () => Navigator.of(
                          context,
                        ).push(fadeRoute(const AddChildScreen())),
                        onSelect: (id) => _state.setActiveChild(id),
                      ),
                      const SizedBox(height: 22),
                      Text(
                        'Pengaturan',
                        style: AppTypography.h2.copyWith(
                          color: SgColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _SettingsCard(
                        onTapAccount: () async {
                          await Navigator.of(
                            context,
                          ).push(fadeRoute(const AccountInfoScreen()));
                          if (!mounted) return;
                          _retry();
                        },
                        onTapPrivacy: () => Navigator.of(
                          context,
                        ).push(fadeRoute(const SecurityScreen())),
                        onTapHelp: () => Navigator.of(
                          context,
                        ).push(fadeRoute(const HelpScreen())),
                      ),
                      const SizedBox(height: 18),
                      _LogoutCard(
                        onLogout: () async {
                          final ok = await _confirmLogout(context);
                          if (ok != true) return;
                          await _state.logout();
                          if (!context.mounted) return;
                          Navigator.of(context).pushAndRemoveUntil(
                            fadeRoute(const AuthScreen()),
                            (_) => false,
                          );
                        },
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'S-GIZI • PREMIUM HEALTHCARE UI',
                        textAlign: TextAlign.center,
                        style: AppTypography.caption.copyWith(
                          letterSpacing: 1,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                )
                .animate()
                .fadeIn(duration: 260.ms, curve: Curves.easeOut)
                .slideY(
                  begin: 0.02,
                  end: 0,
                  duration: 260.ms,
                  curve: Curves.easeOut,
                );
          },
        ),
      ),
    );
  }
}

class _ProfileHeaderCard extends StatelessWidget {
  const _ProfileHeaderCard({
    required this.name,
    required this.subtitle,
    required this.onEditTap,
  });

  final String name;
  final String subtitle;
  final VoidCallback onEditTap;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF085B63), Color(0xFF0B7A86)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 26,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -40,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.08),
                  ),
                ),
              ),
              Positioned(
                left: -50,
                bottom: -50,
                child: Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
                child: Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Container(
                              width: 74,
                              height: 74,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white.withValues(alpha: 0.16),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.22),
                                ),
                              ),
                              child: SgAvatar(
                                name: name,
                                radius: 37,
                                icon: Icons.person_rounded,
                              ),
                            )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .moveY(begin: 0, end: -2, duration: 1800.ms),
                        Positioned(
                          right: 2,
                          bottom: 2,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              color: const Color(0xFF34C759),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: AppTypography.h2.copyWith(
                              color: Colors.white,
                              fontSize: 20,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: AppTypography.body.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.18),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  PhosphorIconsRegular.sealCheck,
                                  color: Colors.white,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  'Akun Terverifikasi',
                                  style: AppTypography.caption.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    _IconPillButton(icon: LucideIcons.pencil, onTap: onEditTap),
                  ],
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 320.ms, curve: Curves.easeOut)
        .slideY(begin: -0.03, end: 0, duration: 320.ms, curve: Curves.easeOut);
  }
}

class _IconPillButton extends StatelessWidget {
  const _IconPillButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(999),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

class _ChildrenSection extends StatelessWidget {
  const _ChildrenSection({
    required this.children,
    required this.activeChildId,
    required this.onAdd,
    required this.onSelect,
  });

  final List<MobileChildModel> children;
  final int? activeChildId;
  final VoidCallback onAdd;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Daftar Anak',
                    style: AppTypography.h2.copyWith(
                      color: SgColors.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(LucideIcons.plus),
                  label: const Text('Tambah'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF0B7A86),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            if (children.isEmpty)
              HealthCard(
                child: Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFF7FD6C2).withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        LucideIcons.baby,
                        color: Color(0xFF0B7A86),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Belum ada data anak. Tambahkan anak untuk mulai memantau status gizi.',
                        style: AppTypography.body,
                      ),
                    ),
                  ],
                ),
              )
            else
              SizedBox(
                height: 88,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: children.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    final c = children[index];
                    final active = c.id == activeChildId;
                    return _ChildCard(
                      child: c,
                      active: active,
                      onTap: () => onSelect(c.id),
                    );
                  },
                ),
              ),
          ],
        )
        .animate()
        .fadeIn(duration: 320.ms, curve: Curves.easeOut)
        .slideY(begin: 0.02, end: 0, duration: 320.ms, curve: Curves.easeOut);
  }
}

class _ChildCard extends StatelessWidget {
  const _ChildCard({
    required this.child,
    required this.active,
    required this.onTap,
  });

  final MobileChildModel child;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final statusRaw = (child.latestStatus ?? '').trim();

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        width: 210,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? const Color(0xFF0B7A86) : const Color(0xFFE2E8E6),
            width: active ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: active ? 0.08 : 0.04),
              blurRadius: active ? 14 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Stack(
              children: [
                ChildAvatar(
                  name: child.nama,
                  gender: child.jenisKelamin,
                  radius: 20,
                ),
                if (active)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B7A86),
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    child.nama,
                    style: AppTypography.h3.copyWith(
                      color: SgColors.textPrimary,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatAgeFromBirthDate(
                      child.tanggalLahir,
                      source: 'profile_child_card',
                    ),
                    style: AppTypography.caption.copyWith(fontSize: 11),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  if (statusRaw.isEmpty)
                    Text(
                      'Belum diukur',
                      style: AppTypography.caption.copyWith(fontSize: 10),
                    )
                  else
                    NutritionStatusBadges(
                      status: statusRaw,
                      compact: true,
                      spacing: 4,
                      runSpacing: 4,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            PopupMenuButton<String>(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 10,
              color: Colors.white,
              onSelected: (value) async {
                if (value == 'edit') {
                  await _showEditChildDialog(context, child);
                }
                if (value == 'delete') {
                  await _showDeleteChildDialog(context, child);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(
                        LucideIcons.edit3,
                        size: 18,
                        color: SgColors.primaryTeal,
                      ),
                      SizedBox(width: 10),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(
                        LucideIcons.trash2,
                        size: 18,
                        color: Color(0xFFE25555),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Hapus',
                        style: AppTypography.body.copyWith(
                          color: const Color(0xFFE25555),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              icon: Icon(
                LucideIcons.moreVertical,
                color: active
                    ? const Color(0xFF0B7A86)
                    : SgColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    ).animate().scale(
      begin: const Offset(0.99, 0.99),
      end: const Offset(1, 1),
      duration: 220.ms,
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.onTapAccount,
    required this.onTapPrivacy,
    required this.onTapHelp,
  });

  final VoidCallback onTapAccount;
  final VoidCallback onTapPrivacy;
  final VoidCallback onTapHelp;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _SettingsTile(
                icon: LucideIcons.user,
                color: const Color(0xFF0B7A86),
                title: 'Informasi Akun',
                subtitle: 'Edit nama, foto, dan nomor telepon',
                onTap: onTapAccount,
              ),
              const Divider(height: 1, color: SgColors.border),
              _SettingsTile(
                icon: LucideIcons.shield,
                color: const Color(0xFF34A853),
                title: 'Privasi & Keamanan',
                subtitle: 'Kebijakan privasi dan keamanan akun',
                onTap: onTapPrivacy,
              ),
              const Divider(height: 1, color: SgColors.border),
              _SettingsTile(
                icon: LucideIcons.messageCircle,
                color: const Color(0xFF3B82F6),
                title: 'Bantuan',
                subtitle: 'FAQ, pusat bantuan, hubungi admin',
                onTap: onTapHelp,
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 280.ms, curve: Curves.easeOut)
        .slideY(begin: 0.02, end: 0, duration: 280.ms, curve: Curves.easeOut);
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            _IconBadge(icon: icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTypography.h3),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: SgColors.textSecondary),
          ],
        ),
      ),
    ).animate().scale(
      begin: const Offset(1, 1),
      end: const Offset(0.99, 0.99),
      duration: 140.ms,
    );
  }
}

class _IconBadge extends StatelessWidget {
  const _IconBadge({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
          color: const Color(0xFFFFF5F5),
          borderColor: const Color(0xFFFFCDD2),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE53935).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(LucideIcons.logOut, color: Color(0xFFE53935)),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Keluar Aplikasi',
                  style: AppTypography.h3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: onLogout,
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE53935),
                ),
                child: const Text('Keluar'),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 240.ms, curve: Curves.easeOut)
        .slideY(begin: 0.02, end: 0, duration: 240.ms, curve: Curves.easeOut);
  }
}

class _ProfileSkeleton extends StatelessWidget {
  const _ProfileSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8EEEC),
      highlightColor: const Color(0xFFF7FAF9),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
        child: Column(
          children: [
            Container(
              height: 124,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              height: 168,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            const SizedBox(height: 22),
            Container(
              height: 260,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
            ),
            const SizedBox(height: 18),
            Container(
              height: 74,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileError extends StatelessWidget {
  const _ProfileError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ErrorState(
      message: 'Profil tidak dapat dimuat. Periksa koneksi lalu coba lagi.',
      onRetry: onRetry,
    );
  }
}

Future<bool?> _confirmLogout(BuildContext context) {
  return showGeneralDialog<bool>(
    context: context,
    barrierLabel: 'logout',
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.38),
    pageBuilder: (context, _, _) {
      return Center(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Material(
              color: Colors.transparent,
              child:
                  Container(
                        width: double.infinity,
                        constraints: const BoxConstraints(maxWidth: 420),
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(22),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.12),
                              blurRadius: 30,
                              offset: const Offset(0, 18),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(
                                  LucideIcons.logOut,
                                  color: Color(0xFFE53935),
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'Konfirmasi Keluar',
                                    style: AppTypography.h2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Apakah Anda yakin ingin keluar?',
                              style: AppTypography.body,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: SizedBox(
                                    height: 52,
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(false),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: SgColors.textPrimary,
                                        side: const BorderSide(
                                          color: SgColors.border,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Batal',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: SizedBox(
                                    height: 52,
                                    child: FilledButton(
                                      onPressed: () =>
                                          Navigator.of(context).pop(true),
                                      style: FilledButton.styleFrom(
                                        backgroundColor: const Color(
                                          0xFFE53935,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Keluar',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 180.ms)
                      .scale(
                        begin: const Offset(0.98, 0.98),
                        end: const Offset(1, 1),
                        duration: 180.ms,
                        curve: Curves.easeOut,
                      ),
            ),
          ),
        ),
      );
    },
    transitionDuration: const Duration(milliseconds: 180),
    transitionBuilder: (context, animation, _, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: child,
      );
    },
  );
}

String _profileRoleToLabel(String role, String fallbackPhone) {
  final v = role.toLowerCase();
  if (v.contains('ortu') || v.contains('orang_tua') || v.contains('parent')) {
    return 'Orang Tua Aktif';
  }
  if (v.contains('admin')) {
    return 'Admin';
  }
  return fallbackPhone.isEmpty ? 'Akun Aktif' : fallbackPhone;
}

Future<void> _showEditChildDialog(
  BuildContext context,
  MobileChildModel child,
) async {
  final api = ApiService();
  final nameController = TextEditingController(text: child.nama);
  String gender = child.jenisKelamin;
  DateTime? birthDate = DateTime.tryParse(child.tanggalLahir);

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            title: const Text('Edit Data Anak'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'Nama Anak'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    initialValue: gender,
                    items: const [
                      DropdownMenuItem(value: 'L', child: Text('Laki-laki')),
                      DropdownMenuItem(value: 'P', child: Text('Perempuan')),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setLocal(() => gender = v);
                    },
                    decoration: const InputDecoration(
                      labelText: 'Jenis Kelamin',
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: birthDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setLocal(() => birthDate = picked);
                      }
                    },
                    child: Text(
                      birthDate == null
                          ? 'Pilih Tanggal Lahir'
                          : 'Tanggal: ${birthDate!.toIso8601String().split('T').first}',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Batal'),
              ),
              FilledButton(
                onPressed: () async {
                  try {
                    await api.updateChild(
                      childId: child.id,
                      data: {
                        'nama': nameController.text.trim(),
                        'tanggal_lahir': (birthDate ?? DateTime.now())
                            .toIso8601String()
                            .split('T')
                            .first,
                        'jenis_kelamin': gender,
                      },
                    );
                    final children = await api.getChildren();
                    SgiziAppState.instance.setChildren(children);
                    if (dialogContext.mounted) {
                      Navigator.of(dialogContext).pop();
                    }
                  } catch (e) {
                    if (!dialogContext.mounted) return;
                    ScaffoldMessenger.of(dialogContext).showSnackBar(
                      SnackBar(content: Text('Gagal edit anak: $e')),
                    );
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _showDeleteChildDialog(
  BuildContext context,
  MobileChildModel child,
) async {
  final api = ApiService();
  final confirm = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: const Text('Hapus Anak'),
      content: Text('Yakin ingin menghapus data ${child.nama}?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFE53935),
          ),
          child: const Text('Hapus'),
        ),
      ],
    ),
  );
  if (confirm != true) return;

  try {
    await api.deleteChild(childId: child.id);
    final children = await api.getChildren();
    SgiziAppState.instance.setChildren(children);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Gagal hapus anak: $e')));
  }
}
