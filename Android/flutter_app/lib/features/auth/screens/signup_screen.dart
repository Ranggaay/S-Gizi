import 'dart:async';

import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/services/api_service.dart';
import 'package:s_gizi/features/auth/widgets/auth_loading_widgets.dart';
import 'package:s_gizi/features/auth/widgets/auth_input_widgets.dart';
import 'package:s_gizi/features/children/screens/add_child_screen.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _api = ApiService();

  // Step 1 form data
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String? _parentGender;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Step 2 OTP
  Timer? _timer;
  int _secondsLeft = 300;
  String _otpCode = '';
  int _otpResetTick = 0;

  bool _onOtpStep = false;
  bool _loading = false;
  String _loadingMessage = '';
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  bool get _isFormValid =>
      _nameController.text.trim().isNotEmpty &&
      isValidIndonesiaPhone(_phoneController.text) &&
      _parentGender != null &&
      _passwordController.text.length >= 8 &&
      _passwordController.text == _confirmPasswordController.text;

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
    if (!_isFormValid) {
      final message = !isValidIndonesiaPhone(_phoneController.text)
          ? 'Nomor telepon tidak valid'
          : 'Lengkapi semua data. Password minimal 8 karakter dan konfirmasi harus cocok.';
      setState(() {
        _error = message;
      });
      _showSnack(message);
      return;
    }

    setState(() {
      _loading = true;
      _loadingMessage = 'Mengirim kode OTP...';
      _error = null;
    });

    try {
      await _api.registerSendOtp(
        name: _nameController.text.trim(),
        phone: fullIndonesiaPhone(_phoneController.text),
        parentGender: _parentGender!,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );
      if (!mounted) return;
      setState(() => _onOtpStep = true);
      _startTimer();
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _error = msg);
      if (mounted) {
        _showSnack(msg);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otp;
    if (otp.length < 6) {
      const message = 'OTP kurang dari 6 digit';
      setState(() => _error = message);
      _showSnack(message);
      return;
    }

    setState(() {
      _loading = true;
      _loadingMessage = 'Memverifikasi akun...';
      _error = null;
    });

    try {
      await _api.registerVerifyOtp(
        phone: fullIndonesiaPhone(_phoneController.text),
        otp: otp,
      );
      if (!mounted) return;
      _timer?.cancel();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(_snack('OTP berhasil diverifikasi. Lengkapi data anak.'));
      Navigator.of(context).pushAndRemoveUntil(
        fadeRoute(const AddChildScreen(isFirstSetup: true)),
        (_) => false,
      );
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      setState(() => _error = msg);
      if (mounted) {
        _showSnack(_friendlyOtpError(msg));
      }
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
      await _api.registerSendOtp(
        name: _nameController.text.trim(),
        phone: fullIndonesiaPhone(_phoneController.text),
        parentGender: _parentGender!,
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
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

  String get _otp => _otpCode.trim();

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
        title: Text(_onOtpStep ? 'Verifikasi OTP' : 'Registrasi Akun'),
        leading: _onOtpStep
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: _loading
                    ? null
                    : () {
                        _timer?.cancel();
                        setState(() {
                          _onOtpStep = false;
                          _error = null;
                          _otpCode = '';
                          _otpResetTick++;
                        });
                      },
              )
            : null,
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
            child: _onOtpStep ? _buildOtpStep() : _buildFormStep(),
          ),
        ),
      ),
    );
  }

  Widget _buildFormStep() {
    return ListView(
      key: const ValueKey('signup-form'),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        const Text('Buat Akun Orang Tua', style: AppTypography.h1),
        const SizedBox(height: 8),
        const Text(
          'Daftar untuk mulai memantau tumbuh kembang si kecil.',
          style: AppTypography.body,
        ),
        const SizedBox(height: 24),
        HealthCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _nameController,
                onChanged: (_) => setState(() => _error = null),
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Nama Lengkap',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
              ),
              const SizedBox(height: 14),
              IndonesiaPhoneField(
                controller: _phoneController,
                enabled: !_loading,
                onChanged: (_) => setState(() => _error = null),
              ),
              const SizedBox(height: 16),
              Text('Gender Orang Tua', style: AppTypography.h3),
              const SizedBox(height: 8),
              _GenderSegment(
                value: _parentGender,
                onChanged: (v) => setState(() {
                  _parentGender = v;
                  _error = null;
                }),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                onChanged: (_) => setState(() => _error = null),
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Password',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
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
                onChanged: (_) => setState(() => _error = null),
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                  labelText: 'Konfirmasi Password',
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  suffixIcon: IconButton(
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
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
      key: const ValueKey('signup-otp'),
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
                label: _loading ? 'Memverifikasi...' : 'Verifikasi & Daftar',
                icon: Icons.how_to_reg_rounded,
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
}

class _GenderSegment extends StatelessWidget {
  const _GenderSegment({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _GenderChip(
            label: 'Ayah',
            selected: value == 'ayah',
            onTap: () => onChanged('ayah'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _GenderChip(
            label: 'Bunda',
            selected: value == 'bunda',
            onTap: () => onChanged('bunda'),
          ),
        ),
      ],
    );
  }
}

class _GenderChip extends StatelessWidget {
  const _GenderChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF0B7A86) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF0B7A86) : const Color(0xFFE1E8E6),
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: AppTypography.body.copyWith(
              color: selected ? Colors.white : SgColors.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
