import 'dart:async';

import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/app_state.dart';
import 'package:s_gizi/features/nutritionist/screens/nutritionist_dashboard_screen.dart';
import 'package:s_gizi/features/auth/screens/onboarding_screen.dart';
import 'package:s_gizi/features/dashboard/screens/parent_dashboard_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _imageScale;
  late final Animation<double> _imageOpacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..forward();
    _imageScale = Tween<double>(
      begin: 1.22,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
    _imageOpacity = Tween<double>(
      begin: 0.2,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    Timer(const Duration(milliseconds: 1500), _openNextScreen);
  }

  Future<void> _openNextScreen() async {
    await SgiziAppState.instance.restoreSession();
    if (!mounted) return;

    final state = SgiziAppState.instance;
    Widget next = const OnboardingScreen();
    if (state.isAuthenticated) {
      final role = (state.role ?? '').trim().toLowerCase();
      final isNutritionist =
          role == 'nutritionist' || role == 'ahli_gizi' || role == 'ahli gizi';
      next = isNutritionist
          ? const NutritionistDashboardScreen()
          : const ParentDashboardScreen();
    }

    Navigator.of(context).pushReplacement(fadeRoute(next));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final shortest = size.shortestSide;
    final imageSize = (shortest * 0.58).clamp(190.0, 320.0);

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFDFEFE), Color(0xFFE8F6F3), Color(0xFFF5F7F6)],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: constraints.maxWidth.clamp(280.0, 520.0),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: (size.width * 0.08).clamp(20.0, 36.0),
                  ),
                  child: Center(
                    child: FadeTransition(
                      opacity: _imageOpacity,
                      child: ScaleTransition(
                        scale: _imageScale,
                        child: Container(
                          width: imageSize,
                          height: imageSize,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(40),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF4B8E96,
                                ).withValues(alpha: 0.24),
                                blurRadius: 42,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(40),
                            child: Image.asset(
                              'assets/image/Logo_SplashScreen.png',
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (_, _, _) => Image.asset(
                                'assets/image/logo_sgizi.png',
                                fit: BoxFit.contain,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
