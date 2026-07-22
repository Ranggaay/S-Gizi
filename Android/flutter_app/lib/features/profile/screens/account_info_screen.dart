import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:shimmer/shimmer.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/app_state.dart';
import 'package:s_gizi/services/api_service.dart';
import 'package:s_gizi/utils/nutrition_display_utils.dart';
import 'package:s_gizi/features/profile/screens/edit_profile_screen.dart';

class AccountInfoScreen extends StatefulWidget {
  const AccountInfoScreen({super.key});

  @override
  State<AccountInfoScreen> createState() => _AccountInfoScreenState();
}

class _AccountInfoScreenState extends State<AccountInfoScreen> {
  final _api = ApiService();
  final _state = SgiziAppState.instance;
  late Future<Map<String, dynamic>> _future;
  Map<String, dynamic>? _profileCache;

  @override
  void initState() {
    super.initState();
    _future = _api.getProfile().then((value) {
      _state.setProfileData(value);
      return value;
    });
  }

  void _retry() => setState(() {
    _future = _api.getProfile().then((value) {
      _state.setProfileData(value);
      return value;
    });
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: const Text('Informasi Akun'),
        backgroundColor: const Color(0xFFF5F7F6),
      ),
      body: SafeArea(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _AccountSkeleton();
            }
            if (snapshot.hasError) {
              return ErrorState(
                message: 'Informasi akun gagal dimuat.',
                onRetry: _retry,
              );
            }
            final profile =
                _profileCache ?? snapshot.data ?? const <String, dynamic>{};
            final name = (profile['name'] as String? ?? '-').trim();
            final phone = (profile['phone'] as String? ?? '-').trim();
            final email = (profile['email'] as String? ?? '-').trim();
            final joinedAtRaw = (profile['joined_at'] as String? ?? '-').trim();
            final joinedAt = joinedAtRaw == '-'
                ? '-'
                : formatMeasurementDate(joinedAtRaw);

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HealthCard(
                    child: Row(
                      children: [
                        SgAvatar(name: name, radius: 39, icon: Icons.person)
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .moveY(begin: 0, end: -2, duration: 1800.ms),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: AppTypography.h2,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                phone,
                                style: AppTypography.body,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              const StatusBadge(
                                text: 'Akun Terverifikasi',
                                color: Color(0xFF0B7A86),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        IconButton(
                          onPressed: () async {
                            final updated = await Navigator.of(context)
                                .push<Map<String, dynamic>>(
                                  fadeRoute(
                                    EditProfileScreen(
                                      initialName: name,
                                      initialPhone: phone,
                                      initialEmail: email == '-' ? '' : email,
                                    ),
                                  ),
                                );
                            if (updated != null && mounted) {
                              setState(() {
                                _profileCache = updated;
                                _future = Future.value(updated);
                              });
                              _state.setProfileData(updated);
                            }
                          },
                          icon: const Icon(
                            LucideIcons.pencil,
                            color: Color(0xFF0B7A86),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Data Akun',
                    style: AppTypography.h2.copyWith(
                      color: SgColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  HealthCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: LucideIcons.user,
                          title: 'Nama Lengkap',
                          value: name,
                        ),
                        const Divider(height: 1, color: SgColors.border),
                        _InfoRow(
                          icon: LucideIcons.messageCircle,
                          title: 'Nomor Telepon',
                          value: phone,
                        ),
                        const Divider(height: 1, color: SgColors.border),
                        _InfoRow(
                          icon: LucideIcons.info,
                          title: 'Email',
                          value: email,
                        ),
                        const Divider(height: 1, color: SgColors.border),
                        _InfoRow(
                          icon: LucideIcons.calendarDays,
                          title: 'Tanggal Bergabung',
                          value: joinedAt,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  PrimaryButton(
                    label: 'Edit Profil',
                    icon: LucideIcons.arrowRight,
                    onPressed: () async {
                      final updated = await Navigator.of(context)
                          .push<Map<String, dynamic>>(
                            fadeRoute(
                              EditProfileScreen(
                                initialName: name,
                                initialPhone: phone,
                                initialEmail: email == '-' ? '' : email,
                              ),
                            ),
                          );
                      if (updated != null && mounted) {
                        setState(() {
                          _profileCache = updated;
                          _future = Future.value(updated);
                        });
                        _state.setProfileData(updated);
                      }
                    },
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.02, end: 0);
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF7FD6C2).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: const Color(0xFF0B7A86), size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.caption),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.h3,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountSkeleton extends StatelessWidget {
  const _AccountSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE8EEEC),
      highlightColor: const Color(0xFFF7FAF9),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
        child: Column(
          children: [
            Container(
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              height: 230,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
