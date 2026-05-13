import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:bootstrap_icons/bootstrap_icons.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import '../app_design.dart';
import 'auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _controller = PageController();
  int _index = 0;
  Timer? _autoSlideTimer;

  @override
  void initState() {
    super.initState();
    _autoSlideTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (!mounted || !_controller.hasClients) return;
      final nextIndex = (_index + 1) % 3;
      _controller.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoSlideTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const pages = [
      _OnboardingPage(
        imagePath: 'assets/image/onboarding_monitoring.png',
        title: 'Monitoring Pertumbuhan Si Kecil Secara Akurat',
        subtitle:
            'Pantau perkembangan buah hati Anda dengan standar WHO Z-Score.',
        floatingTags: [
          _FloatingTag(
            label: 'Status Normal',
            icon: BootstrapIcons.heart,
            align: Alignment(0.92, -0.48),
          ),
          _FloatingTag(
            label: 'Pertumbuhan +2.4 cm',
            icon: LucideIcons.lineChart,
            align: Alignment(-0.70, 0.24),
          ),
          _FloatingTag(
            label: 'Anak Aktif',
            icon: PhosphorIconsFill.baby,
            align: Alignment(-0.75, -0.52),
          ),
        ],
        emphasizedWord: 'Akurat',
      ),
      _OnboardingPage(
        imagePath: 'assets/image/onboarding_food.png',
        title: 'Rekomendasi Makanan Personal',
        subtitle:
            'Dapatkan saran menu bergizi sesuai kebutuhan tumbuh kembang si kecil.',
        floatingTags: [
          _FloatingTag(
            label: 'Protein',
            icon: PhosphorIconsFill.barbell,
            align: Alignment(-0.74, -0.36),
          ),
          _FloatingTag(
            label: 'Menu MPASI',
            icon: BootstrapIcons.egg,
            align: Alignment(0.76, -0.70),
          ),
          _FloatingTag(
            label: 'Vitamin',
            icon: LucideIcons.apple,
            align: Alignment(-0.78, 0.28),
          ),
        ],
        emphasizedWord: 'Personal',
      ),
      _OnboardingPage(
        imagePath: 'assets/image/onboarding_consultation.png',
        title: 'Konsultasi Ahli Gizi',
        subtitle:
            'Diskusikan tumbuh kembang anak langsung dengan ahli gizi terpercaya.',
        floatingTags: [
          _FloatingTag(
            label: 'Terverifikasi',
            icon: PhosphorIconsFill.shieldCheck,
            align: Alignment(0.72, 0.28),
          ),
          _FloatingTag(
            label: 'Chat Konsultasi',
            icon: LucideIcons.messageCircle,
            align: Alignment(0.86, -0.42),
          ),
          _FloatingTag(
            label: 'Ahli Gizi',
            icon: PhosphorIconsFill.stethoscope,
            align: Alignment(-0.74, 0.40),
          ),
        ],
        emphasizedWord: 'Ahli Gizi',
      ),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF7FCFB), Color(0xFFF1F7F6), SgColors.background],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
              child: Column(
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.72,
                    child: PageView(
                      controller: _controller,
                      onPageChanged: (value) => setState(() => _index = value),
                      children: pages,
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      pages.length,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 260),
                        width: i == _index ? 32 : 10,
                        height: 10,
                        margin: const EdgeInsets.symmetric(horizontal: 5),
                        decoration: BoxDecoration(
                          gradient: i == _index
                              ? const LinearGradient(
                                  colors: [SgColors.primaryDark, SgColors.primary],
                                )
                              : null,
                          color: i == _index ? null : const Color(0xFFCAE8E2),
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _AnimatedCtaButton(
                    label: 'Mulai Sekarang',
                    onPressed: () => _enterApp(context),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      Text(
                        'Sudah punya akun? ',
                        style: AppTypography.body.copyWith(
                          color: const Color(0xFF62707B),
                        ),
                      ),
                      InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => _enterApp(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(
                            'Masuk di sini',
                            style: AppTypography.body.copyWith(
                              color: SgColors.primary,
                              fontWeight: FontWeight.w700,
                              decoration: TextDecoration.underline,
                              decorationColor: SgColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _enterApp(BuildContext context) {
    Navigator.of(context).pushReplacement(fadeRoute(const AuthScreen()));
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.floatingTags,
    this.emphasizedWord,
  });

  final String imagePath;
  final String title;
  final String subtitle;
  final List<_FloatingTag> floatingTags;
  final String? emphasizedWord;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 20),
          _HeroImageWithBadges(
            imagePath: imagePath,
            floatingTags: const [],
          ),
          const SizedBox(height: 34),
          Text.rich(
            _buildTitleSpan(),
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ).animate().fadeIn(duration: 380.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 14),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.body.copyWith(
              fontSize: 16,
              color: const Color(0xFF5A6875),
              height: 1.5,
            ),
          ).animate().fadeIn(delay: 120.ms, duration: 430.ms),
          const SizedBox(height: 18),
        ],
      ),
    );
  }

  TextSpan _buildTitleSpan() {
    if (emphasizedWord == null || !title.contains(emphasizedWord!)) {
      return TextSpan(
        text: title,
        style: AppTypography.h1.copyWith(fontSize: 44, height: 1.15),
      );
    }

    final word = emphasizedWord!;
    final split = title.split(word);
    return TextSpan(
      style: AppTypography.h1.copyWith(fontSize: 44, height: 1.15),
      children: [
        TextSpan(text: split.first),
        TextSpan(
          text: word,
          style: AppTypography.h1.copyWith(
            fontSize: 44,
            color: SgColors.primaryDark,
            fontStyle: FontStyle.italic,
          ),
        ),
        if (split.length > 1) TextSpan(text: split.last),
      ],
    );
  }
}

class _HeroImageWithBadges extends StatelessWidget {
  const _HeroImageWithBadges({
    required this.imagePath,
    required this.floatingTags,
  });

  final String imagePath;
  final List<_FloatingTag> floatingTags;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.18,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 24,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFE7F4F1),
              alignment: Alignment.center,
              child: const Icon(
                Icons.broken_image_outlined,
                color: SgColors.primary,
                size: 42,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _AnimatedCtaButton extends StatefulWidget {
  const _AnimatedCtaButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  State<_AnimatedCtaButton> createState() => _AnimatedCtaButtonState();
}

class _AnimatedCtaButtonState extends State<_AnimatedCtaButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1,
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        child: Container(
          width: double.infinity,
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF147D89), Color(0xFF2BA6A7)],
            ),
            borderRadius: BorderRadius.circular(999),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF137B87).withValues(alpha: 0.26),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: widget.onPressed,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h2.copyWith(color: Colors.white),
                      ),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.20),
                      ),
                      child: const Icon(
                        LucideIcons.arrowRight,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FloatingTag {
  const _FloatingTag({
    required this.label,
    required this.icon,
    required this.align,
  });

  final String label;
  final IconData icon;
  final Alignment align;
}
