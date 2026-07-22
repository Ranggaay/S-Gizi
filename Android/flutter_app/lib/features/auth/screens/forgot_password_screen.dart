import 'dart:async';

import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/app_state.dart';
import 'package:s_gizi/services/api_service.dart';
import 'package:s_gizi/features/auth/widgets/auth_loading_widgets.dart';
import 'package:s_gizi/features/auth/widgets/auth_input_widgets.dart';
import 'package:s_gizi/features/dashboard/screens/child_empty_state_screen.dart';
import 'package:s_gizi/features/navigation/screens/app_shell.dart';
import 'package:s_gizi/features/nutritionist/screens/nutritionist_dashboard_screen.dart';

enum _ForgotStep { phone, otp, newPassword }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _api = ApiService();

  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  _ForgotStep _step = _ForgotStep.phone;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _loading = false;
  String _loadingMessage = '';
  String? _error;

  Timer? _timer;
  int _secondsLeft = 300;
  String _otpCode = '';
  int _otpResetTick = 0;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    _secondsLeft = 300;
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_secondsLeft <= 0) {
        t.cancel();
        if (mounted) setState(() {});
      } else {
        if (mounted) setState(() => _secondsLeft--);
      }
    });
  }

  String get _timerLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _sendOtp() async {
    if (!isValidIndonesiaPhone(_phoneController.text)) {
      const message = 'Nomor telepon tidak valid';
      setState(() => _error = message);
      _showSnack(message);
      return;
    }

    setState(() {
      _loading = true;
      _loadingMessage = 'Mengirim kode OTP...';
      _error = null;
    });

    try {
      await _api.forgotPassword(
        phone: fullIndonesiaPhone(_phoneController.text),
      );
      if (!mounted) return;
      setState(() => _step = _ForgotStep.otp);
      _startTimer();
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _error = msg);
      if (mounted) _showSnack(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resendOtp() async {
    setState(() {
      _loading = true;
      _loadingMessage = 'Mengirim ulang kode OTP...';
      _error = null;
      _otpCode = '';
      _otpResetTick++;
    });
    try {
      await _api.forgotPassword(
        phone: fullIndonesiaPhone(_phoneController.text),
      );
      if (!mounted) return;
      _startTimer();
      _showSnack('OTP baru telah dikirim ke WhatsApp.');
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _error = msg);
      if (mounted) _showSnack(msg);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCode.trim();
    if (otp.length < 6) {
      const message = 'OTP kurang dari 6 digit';
      setState(() => _error = message);
      _showSnack(message);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _loadingMessage = 'Memverifikasi akun...';
      _error = null;
    });

    try {
      await _api.verifyForgotPasswordOtp(
        phone: fullIndonesiaPhone(_phoneController.text),
        otp: otp,
      );
      if (!mounted) return;
      _timer?.cancel();
      setState(() {
        _step = _ForgotStep.newPassword;
        _error = null;
      });
      _showSnack('OTP berhasil diverifikasi.');
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (!mounted) return;
      setState(() => _error = _friendlyOtpError(msg));
      _showSnack(_friendlyOtpError(msg));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text;
    final confirm = _confirmPasswordController.text;

    String? message;
    if (password.isEmpty || confirm.isEmpty) {
      message = 'Password baru dan konfirmasi wajib diisi.';
    } else if (password.length < 8) {
      message = 'Password minimal 8 karakter.';
    } else if (password != confirm) {
      message = 'Konfirmasi password tidak sama.';
    }

    if (message != null) {
      setState(() => _error = message);
      _showSnack(message);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _loadingMessage = 'Menyimpan password baru...';
      _error = null;
    });

    try {
      await _api.resetPassword(
        phone: fullIndonesiaPhone(_phoneController.text),
        otp: _otpCode.trim(),
        password: password,
        passwordConfirmation: confirm,
      );
      if (!mounted) return;
      setState(() => _loadingMessage = 'Mengecek data anak...');
      await _routeAfterPasswordChanged();
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (!mounted) return;
      final message = _friendlyOtpError(msg);
      setState(() => _error = message);
      _showSnack(message.isEmpty ? 'Gagal update password.' : message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _routeAfterPasswordChanged() async {
    try {
      final role = (SgiziAppState.instance.role ?? '').trim().toLowerCase();
      final isNutritionist =
          role == 'nutritionist' || role == 'ahli_gizi' || role == 'ahli gizi';

      if (isNutritionist) {
        if (!mounted) return;
        _showSnack('Password berhasil diubah.');
        Navigator.of(context).pushAndRemoveUntil(
          fadeRoute(const NutritionistDashboardScreen()),
          (_) => false,
        );
        return;
      }

      try {
        final profile = await _api.getProfile();
        SgiziAppState.instance.setProfileData(profile);
      } catch (_) {}

      final children = await _api.getChildren();
      final state = SgiziAppState.instance;
      state.setChildren(children);
      if (children.length == 1) {
        state.setActiveChild(children.first.id);
      } else if (children.length > 1) {
        state.resetActiveChild();
      }

      if (!mounted) return;
      _showSnack('Password berhasil diubah.');
      Navigator.of(context).pushAndRemoveUntil(
        fadeRoute(
          children.isEmpty ? const ChildEmptyStateScreen() : const AppShell(),
        ),
        (_) => false,
      );
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      throw Exception(msg.isEmpty ? 'Gagal mengecek data anak.' : msg);
    }
  }

  void _back() {
    setState(() {
      _error = null;
      if (_step == _ForgotStep.otp) {
        _step = _ForgotStep.phone;
        _timer?.cancel();
        _otpCode = '';
        _otpResetTick++;
      } else if (_step == _ForgotStep.newPassword) {
        _step = _ForgotStep.otp;
        _passwordController.clear();
        _confirmPasswordController.clear();
      }
    });
  }

  SnackBar _snack(String message) {
    return SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(_snack(message));
  }

  String _friendlyOtpError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('expired') ||
        lower.contains('expire') ||
        lower.contains('kadaluarsa') ||
        lower.contains('kedaluwarsa')) {
      return 'OTP telah kedaluwarsa';
    }
    if (lower.contains('otp') || lower.contains('kode')) {
      return 'OTP yang dimasukkan salah';
    }
    return message;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SgColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: SgColors.background,
        title: const Text('Lupa Password'),
        leading: _step == _ForgotStep.phone
            ? null
            : IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _loading ? null : _back,
              ),
      ),
      body: SafeArea(
        child: AuthLoadingOverlay(
          visible: _loading,
          message: _loadingMessage,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            switchInCurve: Curves.easeOut,
            transitionBuilder: (child, animation) {
              final offset = Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(animation);
              return FadeTransition(
                opacity: animation,
                child: SlideTransition(position: offset, child: child),
              );
            },
            child: switch (_step) {
              _ForgotStep.phone => _buildPhoneStep(),
              _ForgotStep.otp => _buildOtpStep(),
              _ForgotStep.newPassword => _buildNewPasswordStep(),
            },
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneStep() {
    return ListView(
      key: const ValueKey('forgot-phone'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        const Icon(Icons.lock_reset_rounded, size: 48, color: SgColors.primary),
        const SizedBox(height: 16),
        const Text('Reset Password', style: AppTypography.h1),
        const SizedBox(height: 8),
        const Text(
          'Masukkan nomor telepon terdaftar. Kami akan kirim kode OTP ke WhatsApp.',
          style: AppTypography.body,
        ),
        const SizedBox(height: 24),
        HealthCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IndonesiaPhoneField(
                controller: _phoneController,
                enabled: !_loading,
                onChanged: (_) => setState(() => _error = null),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: AppTypography.caption.copyWith(color: SgColors.danger),
                ),
              ],
              if (_loading) ...[
                const SizedBox(height: 14),
                InlineAuthLoading(message: _loadingMessage),
              ],
              const SizedBox(height: 20),
              PrimaryButton(
                label: _loading ? 'Mengirim OTP...' : 'Kirim OTP',
                icon: Icons.send_rounded,
                onPressed: _loading ? null : _sendOtp,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOtpStep() {
    final phone = fullIndonesiaPhone(_phoneController.text);
    return ListView(
      key: const ValueKey('forgot-otp'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        const Icon(
          Icons.chat_bubble_outline_rounded,
          size: 48,
          color: SgColors.primary,
        ),
        const SizedBox(height: 16),
        const Text('Masukkan Kode OTP', style: AppTypography.h1),
        const SizedBox(height: 8),
        Text(
          'Kode 6 digit telah dikirim ke WhatsApp $phone. Berlaku 5 menit.',
          style: AppTypography.body,
        ),
        const SizedBox(height: 24),
        HealthCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              OtpCodeInput(
                key: ValueKey(_otpResetTick),
                enabled: !_loading,
                onChanged: (value) => setState(() {
                  _otpCode = value;
                  _error = null;
                }),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: AppTypography.caption.copyWith(color: SgColors.danger),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_secondsLeft > 0)
                    Text(
                      'Kirim ulang dalam $_timerLabel',
                      style: AppTypography.caption.copyWith(
                        color: SgColors.textSecondary,
                      ),
                    )
                  else
                    TextButton.icon(
                      onPressed: _loading ? null : _resendOtp,
                      icon: const Icon(Icons.refresh_rounded, size: 16),
                      label: const Text('Kirim Ulang OTP'),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              PrimaryButton(
                label: _loading ? 'Memverifikasi...' : 'Verifikasi OTP',
                icon: Icons.arrow_forward_rounded,
                onPressed: _loading ? null : _verifyOtp,
              ),
              if (_loading) ...[
                const SizedBox(height: 14),
                InlineAuthLoading(message: _loadingMessage),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNewPasswordStep() {
    return ListView(
      key: const ValueKey('forgot-new-password'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      children: [
        const Icon(
          Icons.lock_outline_rounded,
          size: 48,
          color: SgColors.primary,
        ),
        const SizedBox(height: 16),
        const Text('Buat Password Baru', style: AppTypography.h1),
        const SizedBox(height: 8),
        const Text(
          'Masukkan password baru untuk melanjutkan akses aplikasi.',
          style: AppTypography.body,
        ),
        const SizedBox(height: 24),
        HealthCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _passwordController,
                enabled: !_loading,
                onChanged: (_) => setState(() => _error = null),
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.next,
                decoration: InputDecoration(
                  labelText: 'Password Baru',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: _loading
                        ? null
                        : () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _confirmPasswordController,
                enabled: !_loading,
                onChanged: (_) => setState(() => _error = null),
                obscureText: _obscureConfirm,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _loading ? null : _resetPassword(),
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password',
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  suffixIcon: IconButton(
                    onPressed: _loading
                        ? null
                        : () => setState(
                            () => _obscureConfirm = !_obscureConfirm,
                          ),
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                    ),
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: AppTypography.caption.copyWith(color: SgColors.danger),
                ),
              ],
              if (_passwordController.text.isNotEmpty &&
                  _passwordController.text.length < 8) ...[
                const SizedBox(height: 8),
                Text(
                  'Password minimal 8 karakter.',
                  style: AppTypography.caption.copyWith(
                    color: SgColors.warning,
                  ),
                ),
              ],
              if (_confirmPasswordController.text.isNotEmpty &&
                  _passwordController.text !=
                      _confirmPasswordController.text) ...[
                const SizedBox(height: 8),
                Text(
                  'Konfirmasi password belum cocok.',
                  style: AppTypography.caption.copyWith(
                    color: SgColors.warning,
                  ),
                ),
              ],
              if (_loading) ...[
                const SizedBox(height: 14),
                InlineAuthLoading(message: _loadingMessage),
              ],
              const SizedBox(height: 20),
              PrimaryButton(
                label: _loading ? 'Menyimpan...' : 'Simpan Password Baru',
                icon: Icons.check_circle_outline_rounded,
                onPressed: _loading ? null : _resetPassword,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
