import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../app_design.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _oldPassword = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _otpController = TextEditingController();

  bool _hideOld = true;
  bool _hideNew = true;
  bool _hideConfirm = true;
  bool _savingPassword = false;

  @override
  void dispose() {
    _oldPassword.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    _otpController.dispose();
    super.dispose();
  }

  String get _strength {
    final value = _newPassword.text;
    if (value.length >= 10 && RegExp(r'[A-Z]').hasMatch(value) && RegExp(r'[0-9]').hasMatch(value)) {
      return 'Kuat';
    }
    if (value.length >= 7) return 'Sedang';
    return 'Lemah';
  }

  Color get _strengthColor {
    if (_strength == 'Kuat') return const Color(0xFF34A853);
    if (_strength == 'Sedang') return const Color(0xFFF59E0B);
    return const Color(0xFFE53935);
  }

  Future<void> _savePassword() async {
    if (_newPassword.text.trim().isEmpty || _newPassword.text != _confirmPassword.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Konfirmasi password tidak sesuai.')),
      );
      return;
    }
    setState(() => _savingPassword = true);
    await Future<void>.delayed(const Duration(milliseconds: 900));
    if (!mounted) return;
    setState(() => _savingPassword = false);
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Berhasil'),
        content: const Text('Password berhasil diperbarui.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
              Text('Ubah Password', style: AppTypography.h2.copyWith(color: SgColors.textPrimary)),
              const SizedBox(height: 10),
              HealthCard(
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
                    Row(
                      children: [
                        Text('Kekuatan password: ', style: AppTypography.caption),
                        Text(
                          _strength,
                          style: AppTypography.caption.copyWith(color: _strengthColor, fontWeight: FontWeight.w800),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _PasswordField(
                      controller: _confirmPassword,
                      label: 'Konfirmasi Password',
                      hidden: _hideConfirm,
                      onToggle: () => setState(() => _hideConfirm = !_hideConfirm),
                    ),
                    const SizedBox(height: 14),
                    PrimaryButton(
                      label: _savingPassword ? 'Menyimpan...' : 'Simpan Password',
                      icon: LucideIcons.arrowRight,
                      onPressed: _savingPassword ? null : _savePassword,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Verifikasi Nomor Telepon', style: AppTypography.h2),
              const SizedBox(height: 10),
              HealthCard(
                child: Column(
                  children: [
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Kode OTP',
                        prefixIcon: const Icon(LucideIcons.shield, color: Color(0xFF0B7A86)),
                        filled: true,
                        fillColor: const Color(0xFFF7FAF9),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Color(0xFFE3EAE8)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => _snack(context, 'OTP berhasil dikirim ulang.'),
                            child: const Text('Resend OTP'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton(
                            onPressed: () => _snack(context, 'Nomor berhasil diverifikasi.'),
                            child: const Text('Verifikasi'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text('Kebijakan Privasi', style: AppTypography.h2),
              const SizedBox(height: 10),
              const HealthCard(
                child: Text(
                  'Privasi data pengguna S-Gizi dilindungi dan hanya digunakan untuk kebutuhan layanan monitoring dan edukasi gizi.',
                  style: AppTypography.body,
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.02, end: 0);
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
        prefixIcon: const Icon(LucideIcons.shield, color: Color(0xFF0B7A86)),
        suffixIcon: IconButton(
          onPressed: onToggle,
          icon: Icon(hidden ? LucideIcons.eye : LucideIcons.eyeOff),
        ),
        filled: true,
        fillColor: const Color(0xFFF7FAF9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE3EAE8)),
        ),
      ),
    );
  }
}

void _snack(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
}

