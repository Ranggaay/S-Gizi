import 'package:flutter/material.dart';

import '../app_design.dart';
import '../app_state.dart';
import '../services/api_service.dart';
import 'check_child_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _api = ApiService();
  final _phoneController = TextEditingController(text: '+62');
  final _otpController = TextEditingController();
  bool _otpSent = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    await _guard(() async {
      await _api.sendOtp(_phoneController.text);
      setState(() => _otpSent = true);
    });
  }

  Future<void> _verifyOtp() async {
    await _guard(() async {
      final token = await _api.verifyOtp(
        _phoneController.text,
        _otpController.text,
      );
      SgiziAppState.instance.setToken(token);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(fadeRoute(const CheckChildScreen()));
    });
  }

  Future<void> _guard(Future<void> Function() action) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SgColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const SizedBox(height: 24),
            const AppLogo(size: 68, showLabel: true),
            const SizedBox(height: 40),
            const Text('Masuk dengan Nomor HP', style: AppTypography.h1),
            const SizedBox(height: 8),
            const Text(
              'Kami akan mengirim kode OTP untuk menjaga data si Kecil tetap aman.',
              style: AppTypography.body,
            ),
            const SizedBox(height: 28),
            HealthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Nomor HP',
                      hintText: '+6281234567890',
                      prefixIcon: Icon(Icons.phone_iphone_rounded),
                    ),
                  ),
                  if (_otpSent) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _otpController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      decoration: const InputDecoration(
                        labelText: 'Kode OTP',
                        hintText: '123456',
                        prefixIcon: Icon(Icons.lock_outline_rounded),
                        counterText: '',
                      ),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: AppTypography.caption.copyWith(
                        color: SgColors.danger,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  PrimaryButton(
                    label: _loading
                        ? 'Memproses...'
                        : (_otpSent ? 'Verifikasi OTP' : 'Kirim OTP'),
                    icon: _otpSent
                        ? Icons.verified_user_outlined
                        : Icons.sms_outlined,
                    onPressed: _loading
                        ? null
                        : (_otpSent ? _verifyOtp : _sendOtp),
                  ),
                  if (_otpSent) ...[
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Kirim Ulang OTP',
                      isOutlined: true,
                      onPressed: _loading ? null : _sendOtp,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
