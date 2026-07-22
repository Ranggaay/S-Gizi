import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/features/children/screens/add_child_screen.dart';

class ChildEmptyStateScreen extends StatelessWidget {
  const ChildEmptyStateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(SgSpacing.pageH + 4),
          child: Column(
            children: [
              const Spacer(),
              ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/image/onboarding_monitoring.png',
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F7F1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          LucideIcons.baby,
                          size: 56,
                          color: Color(0xFF0B7A86),
                        ),
                      ),
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 320.ms)
                  .scale(begin: const Offset(0.92, 0.92)),
              const SizedBox(height: 20),
              Text(
                'Belum ada data anak',
                textAlign: TextAlign.center,
                style: AppTypography.h1.copyWith(fontSize: 24),
              ).animate().fadeIn(delay: 80.ms),
              const SizedBox(height: 8),
              const Text(
                'Tambahkan data si kecil untuk mulai memantau pertumbuhan dan status gizinya.',
                textAlign: TextAlign.center,
                style: AppTypography.body,
              ).animate().fadeIn(delay: 140.ms),
              const Spacer(),
              PrimaryButton(
                label: 'Tambah Data Anak',
                icon: Icons.add_rounded,
                onPressed: () {
                  Navigator.of(context).pushReplacement(
                    fadeRoute(const AddChildScreen(isFirstSetup: true)),
                  );
                },
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}
