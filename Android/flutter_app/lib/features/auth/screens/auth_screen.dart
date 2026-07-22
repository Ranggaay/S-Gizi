import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/app_state.dart';
import 'package:s_gizi/services/api_service.dart';
import 'package:s_gizi/features/auth/widgets/auth_loading_widgets.dart';
import 'package:s_gizi/features/auth/widgets/auth_input_widgets.dart';
import 'package:s_gizi/features/nutritionist/screens/nutritionist_dashboard_screen.dart';
import 'package:s_gizi/features/dashboard/screens/parent_dashboard_screen.dart';
import 'package:s_gizi/features/auth/screens/forgot_password_screen.dart';
import 'package:s_gizi/features/auth/screens/signup_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _api = ApiService();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String _loadingMessage = '';
  String? _error;

  bool get _phoneValid => isValidIndonesiaPhone(_phoneController.text);
  bool get _passwordValid => _passwordController.text.length >= 8;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_phoneValid || !_passwordValid) {
      final message = !_phoneValid
          ? (_phoneController.text.trim().isEmpty
                ? 'Nomor telepon wajib diisi'
                : 'Nomor telepon tidak valid')
          : 'Password minimal 8 karakter.';
      setState(() {
        _error = message;
      });
      _showSnack(message);
      return;
    }
    await _guard('Memverifikasi akun...', () async {
      await _api.login(
        phone: fullIndonesiaPhone(_phoneController.text),
        password: _passwordController.text,
      );
      if (!mounted) return;
      final role = (SgiziAppState.instance.role ?? '').trim().toLowerCase();
      final isNutritionist =
          role == 'nutritionist' || role == 'ahli_gizi' || role == 'ahli gizi';
      Navigator.of(context).pushReplacement(
        fadeRoute(
          isNutritionist
              ? const NutritionistDashboardScreen()
              : const ParentDashboardScreen(),
        ),
      );
    });
  }

  Future<void> _guard(String message, Future<void> Function() action) async {
    FocusScope.of(context).unfocus();
    setState(() {
      _loading = true;
      _loadingMessage = message;
      _error = null;
    });
    try {
      await action();
    } catch (error) {
      final message = error.toString().replaceFirst('Exception: ', '');
      setState(() => _error = message);
      if (mounted) {
        _showSnack(message);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SgColors.background,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: AuthLoadingOverlay(
          visible: _loading,
          message: _loadingMessage,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(
              SgSpacing.pageH + 4,
              SgSpacing.pageV,
              SgSpacing.pageH + 4,
              20,
            ),
            children: [
              const SizedBox(height: 12),
              const AppLogo(size: 56, showLabel: true),
              const SizedBox(height: 20),
              const Text('Masuk ke S-Gizi', style: AppTypography.h1),
              const SizedBox(height: 6),
              const Text(
                'Pantau pertumbuhan dan gizi si kecil dengan mudah.',
                style: AppTypography.body,
              ),
              const SizedBox(height: 18),
              HealthCard(
                dense: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IndonesiaPhoneField(
                      controller: _phoneController,
                      enabled: !_loading,
                      onChanged: (_) => setState(() => _error = null),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _passwordController,
                      onChanged: (_) => setState(() => _error = null),
                      obscureText: _obscure,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(
                            _obscure
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
                        style: AppTypography.caption.copyWith(
                          color: SgColors.danger,
                        ),
                      ),
                    ],
                    if (_phoneController.text.trim().isNotEmpty &&
                        !_phoneValid) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Nomor telepon tidak valid.',
                        style: AppTypography.caption.copyWith(
                          color: SgColors.warning,
                        ),
                      ),
                    ],
                    if (_passwordController.text.isNotEmpty &&
                        !_passwordValid) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Password minimal 8 karakter.',
                        style: AppTypography.caption.copyWith(
                          color: SgColors.warning,
                        ),
                      ),
                    ],
                    if (_loading) ...[
                      const SizedBox(height: 12),
                      InlineAuthLoading(message: _loadingMessage),
                    ],
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _loading
                            ? null
                            : () => Navigator.of(
                                context,
                              ).push(fadeRoute(const ForgotPasswordScreen())),
                        child: const Text('Lupa Password?'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    PrimaryButton(
                      label: _loading ? 'Memproses...' : 'Masuk',
                      icon: Icons.login_rounded,
                      onPressed: _loading ? null : _login,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                children: [
                  Text(
                    'Belum punya akun? ',
                    style: AppTypography.body.copyWith(
                      color: const Color(0xFF62707B),
                    ),
                  ),
                  InkWell(
                    onTap: _loading
                        ? null
                        : () => Navigator.of(
                            context,
                          ).push(fadeRoute(const SignupScreen())),
                    child: Text(
                      'Daftar Sekarang',
                      style: AppTypography.body.copyWith(
                        color: SgColors.primary,
                        fontWeight: FontWeight.w700,
                        decoration: TextDecoration.underline,
                        decorationColor: SgColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
