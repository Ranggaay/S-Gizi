import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/models/child_detail_model.dart';
import 'package:s_gizi/providers/child_detail_provider.dart';
import 'package:s_gizi/screens/nutritionist/consultation_chat_screen.dart';
import 'package:s_gizi/screens/nutritionist/nutritionist_note_screen.dart';
import 'package:s_gizi/screens/nutritionist/quick_validation_screen.dart';
import 'package:s_gizi/widgets/action_button_card.dart';
import 'package:s_gizi/widgets/history_measurement_card.dart';
import 'package:s_gizi/widgets/loading_skeleton.dart';
import 'package:s_gizi/widgets/measurement_info_row.dart';
import 'package:s_gizi/widgets/risk_badge.dart';
import 'package:s_gizi/widgets/zscore_card.dart';

class ChildDetailScreen extends StatefulWidget {
  const ChildDetailScreen({super.key, required this.childId});

  final int childId;

  @override
  State<ChildDetailScreen> createState() => _ChildDetailScreenState();
}

class _ChildDetailScreenState extends State<ChildDetailScreen> {
  late final ChildDetailProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ChildDetailProvider()..fetchChildDetail(widget.childId);
  }

  @override
  void dispose() {
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      appBar: AppBar(title: const Text('Detail Anak')),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _provider,
          builder: (context, _) {
            if (_provider.isLoading) return const LoadingSkeleton();
            if (_provider.errorMessage != null) {
              return ErrorState(
                message: _provider.errorMessage!,
                onRetry: () => _provider.fetchChildDetail(widget.childId),
              );
            }
            final child = _provider.childDetail;
            if (child == null) {
              return const EmptyState(
                title: 'Detail anak tidak tersedia',
                message: 'Silakan coba lagi beberapa saat.',
              );
            }
            return RefreshIndicator(
              color: SgColors.primary,
              onRefresh: () => _provider.fetchChildDetail(widget.childId),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
                physics: const AlwaysScrollableScrollPhysics(),
                children: [
                  _ProfileCard(child: child),
                  const SizedBox(height: 12),
                  _MeasurementCard(measurement: child.latestMeasurement),
                  const SizedBox(height: 16),
                  Text('Hasil Z-score WHO', style: AppTypography.h2),
                  const SizedBox(height: 10),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final compact = constraints.maxWidth < 380;
                      return GridView.count(
                        crossAxisCount: compact ? 1 : 3,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: compact ? 2.35 : 0.95,
                        children: [
                          ZScoreCard(
                            title: 'BB/U',
                            score: child.zscoreResult.bbuScore,
                            status: child.zscoreResult.bbuStatus,
                          ),
                          ZScoreCard(
                            title: 'TB/U',
                            score: child.zscoreResult.tbuScore,
                            status: child.zscoreResult.tbuStatus,
                          ),
                          ZScoreCard(
                            title: 'BB/TB',
                            score: child.zscoreResult.bbtbScore,
                            status: child.zscoreResult.bbtbStatus,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  _InterpretationCard(text: child.interpretation),
                  const SizedBox(height: 16),
                  Text('Riwayat Pengukuran Singkat', style: AppTypography.h2),
                  const SizedBox(height: 10),
                  ...child.shortHistories
                      .take(5)
                      .map(
                        (history) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: HistoryMeasurementCard(history: history),
                        ),
                      ),
                  const SizedBox(height: 10),
                  _ActionArea(child: child),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.child});

  final ChildDetailModel child;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      dense: true,
      child: Row(
        children: [
          SgAvatar(name: child.name, radius: 30, icon: LucideIcons.baby),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(child.name, style: AppTypography.h2),
                const SizedBox(height: 3),
                Text(
                  '${child.ageText} • ${child.gender}',
                  style: AppTypography.caption,
                ),
                Text(
                  'Orang tua: ${child.parentName}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption,
                ),
                Text(
                  child.parentPhone,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          RiskBadge(status: child.riskStatus),
        ],
      ),
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  const _MeasurementCard({required this.measurement});

  final LatestMeasurementModel measurement;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      dense: true,
      child: Column(
        children: [
          MeasurementInfoRow(
            label: 'Tanggal',
            value: measurement.measurementDate,
            icon: LucideIcons.calendar,
          ),
          const SizedBox(height: 8),
          MeasurementInfoRow(
            label: 'Umur saat ukur',
            value: measurement.ageAtMeasurement,
            icon: LucideIcons.clock,
          ),
          const SizedBox(height: 8),
          MeasurementInfoRow(
            label: 'Berat badan',
            value: '${measurement.weightKg.toStringAsFixed(1)} kg',
            icon: LucideIcons.scale,
          ),
          const SizedBox(height: 8),
          MeasurementInfoRow(
            label: 'Tinggi badan',
            value: '${measurement.heightCm.toStringAsFixed(0)} cm',
            icon: LucideIcons.ruler,
          ),
          const SizedBox(height: 8),
          MeasurementInfoRow(
            label: 'Posisi ukur',
            value: measurement.position,
            icon: LucideIcons.accessibility,
          ),
        ],
      ),
    );
  }
}

class _InterpretationCard extends StatelessWidget {
  const _InterpretationCard({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return HealthCard(
      dense: true,
      color: const Color(0xFFFFF8E8),
      borderColor: const Color(0xFFFFE2A8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFEF6C00)),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppTypography.body)),
        ],
      ),
    );
  }
}

class _ActionArea extends StatelessWidget {
  const _ActionArea({required this.child});

  final ChildDetailModel child;

  @override
  Widget build(BuildContext context) {
    final canChat = child.hasConsultation && child.consultationId != null;
    return Column(
      children: [
        ActionButtonCard(
          label: canChat ? 'Chat Orang Tua' : 'Chat Belum Tersedia',
          icon: LucideIcons.messageCircle,
          enabled: canChat,
          onTap: () {
            if (!canChat) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Chat belum tersedia. Orang tua belum memulai konsultasi.',
                  ),
                ),
              );
              return;
            }
            Navigator.of(context).push(
              fadeRoute(
                NutritionistConsultationChatScreen(
                  consultationId: child.consultationId!,
                  title: child.parentName,
                ),
              ),
            );
          },
        ),
        if (!canChat) ...[
          const SizedBox(height: 6),
          Text(
            'Chat belum tersedia. Orang tua belum memulai konsultasi.',
            style: AppTypography.caption,
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 10),
        ActionButtonCard(
          label: 'Tambah Catatan',
          icon: LucideIcons.fileEdit,
          onTap: () => Navigator.of(
            context,
          ).push(fadeRoute(NutritionistNoteScreen(childId: child.id))),
        ),
        const SizedBox(height: 10),
        ActionButtonCard(
          label: 'Validasi Data',
          icon: LucideIcons.badgeCheck,
          onTap: () => Navigator.of(context).push(
            fadeRoute(
              QuickValidationScreen(
                measurementId: child.latestMeasurement.measurementId,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
