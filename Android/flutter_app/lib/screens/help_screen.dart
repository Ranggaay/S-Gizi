import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../app_design.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      appBar: AppBar(
        title: const Text('Bantuan'),
        backgroundColor: const Color(0xFFF5F7F6),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Pusat bantuan dan informasi aplikasi S-Gizi.',
                style: AppTypography.body.copyWith(color: SgColors.textPrimary),
              ),
              const SizedBox(height: 14),
              const Text('FAQ', style: AppTypography.h2),
              const SizedBox(height: 10),
              const _FaqCard(
                question: 'Bagaimana cara menghitung status gizi anak?',
                answer:
                    'Masuk ke menu Hitung Gizi, isi data berat, tinggi, usia, lalu simpan untuk melihat hasil analisis WHO.',
              ),
              const SizedBox(height: 8),
              const _FaqCard(
                question: 'Bagaimana cara membaca hasil analisis?',
                answer:
                    'Lihat bagian status gabungan, z-score, dan rekomendasi menu untuk memahami kondisi gizi terbaru anak.',
              ),
              const SizedBox(height: 8),
              const _FaqCard(
                question: 'Bagaimana cara konsultasi dengan ahli?',
                answer:
                    'Buka tab Ahli, pilih topik konsultasi, lalu kirim pertanyaan Anda melalui fitur chat.',
              ),
              const SizedBox(height: 16),
              const Text('Hubungi Admin', style: AppTypography.h2),
              const SizedBox(height: 10),
              HealthCard(
                child: Column(
                  children: [
                    _ContactButton(
                      icon: LucideIcons.messageCircle,
                      title: 'WhatsApp Admin',
                      subtitle: '081249583765',
                      onTap: () => _launch(context, 'https://wa.me/6281249583765'),
                    ),
                    const SizedBox(height: 8),
                    _ContactButton(
                      icon: LucideIcons.info,
                      title: 'Email',
                      subtitle: 'smartgiziapp@gmail.com',
                      onTap: () => _launch(context, 'mailto:smartgiziapp@gmail.com'),
                    ),
                    const SizedBox(height: 8),
                    _ContactButton(
                      icon: LucideIcons.user,
                      title: 'Telepon',
                      subtitle: '081249583765',
                      onTap: () => _launch(context, 'tel:081249583765'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 220.ms).slideY(begin: 0.02, end: 0),
      ),
    );
  }
}

class _FaqCard extends StatefulWidget {
  const _FaqCard({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.question,
                    style: AppTypography.h3,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: const Icon(LucideIcons.chevronRight),
                ),
              ],
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Text(widget.answer, style: AppTypography.body),
            ),
            crossFadeState: _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 220),
          ),
        ],
      ),
    );
  }
}

class _ContactButton extends StatelessWidget {
  const _ContactButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFF7FAF9),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2EAE7)),
        ),
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
                  Text(title, style: AppTypography.h3),
                  Text(
                    subtitle,
                    style: AppTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(LucideIcons.chevronRight, color: SgColors.textSecondary),
          ],
        ),
      ),
    );
  }
}

Future<void> _launch(BuildContext context, String url) async {
  final uri = Uri.parse(url);
  final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Tidak dapat membuka tautan.')),
    );
  }
}

