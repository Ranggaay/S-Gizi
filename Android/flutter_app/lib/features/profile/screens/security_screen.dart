import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/app_state.dart';
import 'package:s_gizi/services/api_service.dart';
import 'package:s_gizi/features/auth/screens/auth_screen.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _api = ApiService();
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _hideOld = true;
  bool _hideNew = true;
  bool _hideConfirm = true;
  bool _savingPassword = false;
  bool _loggingOutAll = false;
  bool _deletingAccount = false;

  @override
  void dispose() {
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
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
    setState(() => _savingPassword = true);
    try {
      await _api.updatePassword(
        oldPassword: _oldPassword.text,
        newPassword: _newPassword.text,
        newPasswordConfirmation: _confirmPassword.text,
      );
      if (!mounted) return;
      _oldPassword.clear();
      _newPassword.clear();
      _confirmPassword.clear();
      await showDialog<void>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Password Berhasil Diubah'),
          content: const Text(
            'Akun Anda tetap aman. Gunakan password baru saat login berikutnya.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Mengerti'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _savingPassword = false);
    }
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<bool> _confirmDanger(String title, String message) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) =>
          AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                icon: const Icon(
                  Icons.warning_amber_rounded,
                  color: SgColors.danger,
                ),
                title: Text(title),
                content: Text(message),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Batal'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: SgColors.danger,
                    ),
                    onPressed: () => Navigator.of(context).pop(true),
                    child: const Text('Lanjutkan'),
                  ),
                ],
              )
              .animate()
              .fadeIn(duration: 180.ms)
              .scale(
                begin: const Offset(0.96, 0.96),
                end: const Offset(1, 1),
                duration: 180.ms,
              ),
    );
    return confirmed == true;
  }

  Future<void> _logoutAllDevices() async {
    final ok = await _confirmDanger(
      'Logout Semua Perangkat?',
      'Anda perlu login ulang di semua perangkat setelah tindakan ini.',
    );
    if (!ok || _loggingOutAll) return;

    setState(() => _loggingOutAll = true);
    try {
      await _api.logoutAllDevices();
      await SgiziAppState.instance.logout();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Berhasil logout dari semua perangkat.')),
      );
      Navigator.of(
        context,
      ).pushAndRemoveUntil(fadeRoute(const AuthScreen()), (_) => false);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loggingOutAll = false);
    }
  }

  Future<void> _deleteAccount() async {
    final ok = await _confirmDanger(
      'Hapus Akun?',
      'Tindakan ini bersifat permanen dan akan menghapus akun beserta data anak yang terhubung.',
    );
    if (!ok || _deletingAccount) return;

    setState(() => _deletingAccount = true);
    try {
      await _api.deleteAccount();
      await SgiziAppState.instance.logout();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Akun berhasil dihapus.')));
      Navigator.of(
        context,
      ).pushAndRemoveUntil(fadeRoute(const AuthScreen()), (_) => false);
    } catch (e) {
      if (!mounted) return;
      _snack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _deletingAccount = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: const Text('Privasi & Keamanan'),
        backgroundColor: const Color(0xFFF5F7F6),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SecurityActionCard(
                icon: LucideIcons.lock,
                title: 'Ubah Password',
                subtitle: 'Perbarui password akun orang tua',
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
                      onChanged: (_) => setState(() {}),
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
                      onToggle: () =>
                          setState(() => _hideConfirm = !_hideConfirm),
                    ),
                    const SizedBox(height: 14),
                    PrimaryButton(
                      label: _savingPassword
                          ? 'Menyimpan...'
                          : 'Simpan Password',
                      icon: LucideIcons.check,
                      onPressed: _savingPassword ? null : _savePassword,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              _SimpleSecurityTile(
                icon: LucideIcons.logOut,
                title: 'Logout Semua Perangkat',
                subtitle: _loggingOutAll
                    ? 'Memproses logout semua sesi...'
                    : 'Keluar dari semua sesi aktif',
                loading: _loggingOutAll,
                onTap: _loggingOutAll ? null : _logoutAllDevices,
              ),
              const SizedBox(height: 10),
              _SimpleSecurityTile(
                icon: LucideIcons.trash2,
                danger: true,
                title: 'Hapus Akun',
                subtitle: _deletingAccount
                    ? 'Menghapus akun...'
                    : 'Hapus akun dan data yang terhubung',
                loading: _deletingAccount,
                onTap: _deletingAccount ? null : _deleteAccount,
              ),
              const SizedBox(height: 10),
              const _PrivacyPolicyCard(),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.02, end: 0);
  }
}

class _SecurityActionCard extends StatelessWidget {
  const _SecurityActionCard({
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
              _SecurityIcon(icon: icon),
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

class _SimpleSecurityTile extends StatelessWidget {
  const _SimpleSecurityTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
    this.loading = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool danger;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final color = danger ? SgColors.danger : SgColors.primary;
    return HealthCard(
      dense: true,
      onTap: onTap,
      child: Row(
        children: [
          _SecurityIcon(icon: icon, color: color),
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
          if (loading)
            SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: color),
            )
          else
            const Icon(LucideIcons.chevronRight, color: SgColors.textSecondary),
        ],
      ),
    );
  }
}

class _PrivacyPolicyCard extends StatelessWidget {
  const _PrivacyPolicyCard();

  @override
  Widget build(BuildContext context) {
    return const HealthCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SecurityIcon(icon: LucideIcons.shieldCheck),
              SizedBox(width: 12),
              Expanded(
                child: Text('Kebijakan Privasi', style: AppTypography.h3),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            'Data pengguna S-Gizi digunakan untuk layanan monitoring, rekomendasi, dan edukasi gizi. Password dikelola oleh server secara aman dan tidak disimpan sebagai teks biasa di aplikasi.',
            style: AppTypography.body,
          ),
        ],
      ),
    );
  }
}

class _SecurityIcon extends StatelessWidget {
  const _SecurityIcon({required this.icon, this.color = SgColors.primary});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 22,
      backgroundColor: color.withValues(alpha: 0.12),
      child: Icon(icon, color: color, size: 20),
    );
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
    required this.controller,
    required this.label,
    required this.hidden,
    required this.onToggle,
    this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool hidden;
  final VoidCallback onToggle;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: hidden,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: const Icon(LucideIcons.shield, color: SgColors.primary),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(hidden ? LucideIcons.eye : LucideIcons.eyeOff),
        ),
      ),
    );
  }
}
