import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/models/api_result_model.dart';
import 'package:s_gizi/utils/nutrition_display_utils.dart';
import 'package:s_gizi/features/consultation/screens/consultation_chat_screen.dart';
import 'package:s_gizi/features/nutrition/screens/recommendation_screen.dart';

class ResultScreen extends StatefulWidget {
  const ResultScreen({super.key, required this.result});

  final ApiResultModel result;

  @override
  State<ResultScreen> createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    )..forward();
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final result = widget.result;
    final measurement = result.measurement;
    final visual = nutritionStatusVisual(result.statusGabungan);
    final isNormal = normalizeStatus(result.statusGabungan).isNormal;
    final hasExtremeZScore =
        _isExtremeZScore(result.zScore.bbu) ||
        _isExtremeZScore(result.zScore.tbu) ||
        _isExtremeZScore(result.zScore.bbtb);
    final monitoringLabel = _monitoringStatusLabel(measurement);
    final validationLabel = _validationStatusLabel(measurement);
    final validationNote = _validationNote(
      measurement: measurement,
      hasExtremeZScore: hasExtremeZScore,
    );

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _backToDashboard();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFEFF8F7),
        appBar: AppBar(
          title: const Text('Hasil Analisis'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: _backToDashboard,
          ),
        ),
        body: FadeTransition(
          opacity: _fade,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 180),
            children: [
              HealthCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 32,
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: visual.color.withValues(alpha: 0.14),
                      child: Icon(visual.icon, color: visual.color, size: 38),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'STATUS GIZI',
                      style: AppTypography.caption.copyWith(
                        letterSpacing: 4,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      result.statusGabungan,
                      style: AppTypography.h1.copyWith(fontSize: 32),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    StatusBadge(text: visual.badgeLabel, color: visual.color),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              HealthCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 25,
                      backgroundColor: Color(0xFFEAF7F7),
                      child: Icon(
                        Icons.child_care_rounded,
                        color: SgColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            measurement?.childName ?? 'Data Anak',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.h3,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${_ageLabel(result.identitas)} | ${_genderLabel(result.identitas.jenisKelamin)}',
                            style: AppTypography.caption,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'TERAKHIR UKUR',
                          style: AppTypography.caption,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          measurement == null
                              ? 'Hari ini'
                              : formatMeasurementDate(measurement.tanggalUkur),
                          style: AppTypography.h3,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (validationLabel != 'Valid' ||
                  monitoringLabel != 'Normal' ||
                  hasExtremeZScore) ...[
                const SizedBox(height: 16),
                HealthCard(
                  dense: true,
                  color: monitoringLabel == 'Perlu Dipantau'
                      ? const Color(0xFFFFF3E0)
                      : const Color(0xFFFFFBEB),
                  borderColor: monitoringLabel == 'Perlu Dipantau'
                      ? const Color(0xFFFFCC80)
                      : const Color(0xFFF4D58A),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: SgColors.warning,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              monitoringLabel == 'Perlu Dipantau'
                                  ? 'Perlu Dipantau'
                                  : validationLabel,
                              style: AppTypography.h3.copyWith(
                                color: const Color(0xFF8A5A00),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              validationNote,
                              style: AppTypography.body.copyWith(
                                color: const Color(0xFF6F5200),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  const Icon(
                    Icons.trending_up_rounded,
                    color: SgColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text('Detail Indikator Gizi', style: AppTypography.h2),
                ],
              ),
              const SizedBox(height: 16),
              MetricProgress(
                label: 'Berat Badan / Umur (BB/U)',
                description: 'Mengukur berat terhadap usia',
                status: result.kategori.bbu,
                value: _scoreToProgress(result.zScore.bbu),
                icon: Icons.monitor_weight_outlined,
              ),
              MetricProgress(
                label: 'Tinggi Badan / Umur (TB/U)',
                description: 'Mengukur tinggi terhadap usia',
                status: result.kategori.tbu,
                value: _scoreToProgress(result.zScore.tbu),
                icon: Icons.straighten_rounded,
              ),
              MetricProgress(
                label: 'Berat / Tinggi (${result.identitas.standarBbtb})',
                description: 'Proporsi tubuh ideal',
                status: result.kategori.bbtb,
                value: _scoreToProgress(result.zScore.bbtb),
                icon: Icons.verified_outlined,
              ),
              const SizedBox(height: 8),
              HealthCard(
                color: const Color(0xFFF5FBFA),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      color: SgColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Catatan Nutrisi',
                            style: AppTypography.h3,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            recommendationStatusExplanation(
                              result.statusGabungan,
                            ),
                            style: AppTypography.body,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              HealthCard(
                dense: true,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Status Pemantauan', style: AppTypography.h3),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        StatusBadge(
                          text: monitoringLabel,
                          color: monitoringLabel == 'Perlu Dipantau'
                              ? SgColors.warning
                              : SgColors.success,
                        ),
                        StatusBadge(
                          text: validationLabel,
                          color: validationLabel == 'Perlu Ukur Ulang'
                              ? SgColors.warning
                              : SgColors.success,
                        ),
                      ],
                    ),
                    if (validationNote.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(validationNote, style: AppTypography.body),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        bottomSheet: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.96),
            border: const Border(top: BorderSide(color: SgColors.border)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!isNormal) ...[
                  HealthCard(
                    color: const Color(0xFFFFFBEB),
                    borderColor: const Color(0xFFF7E7C1),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.warning_amber_rounded,
                          color: SgColors.warning,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Status perlu perhatian. Konsultasi ahli gizi menjadi prioritas.',
                            style: AppTypography.body,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (!isNormal)
                  PrimaryButton(
                    label: 'Konsultasi Ahli Gizi',
                    icon: Icons.chat_bubble_outline_rounded,
                    onPressed: _startConsultation,
                  ),
                if (!isNormal) const SizedBox(height: 12),
                PrimaryButton(
                  label: 'Lihat Rekomendasi Menu',
                  icon: Icons.restaurant_menu_rounded,
                  onPressed: () {
                    Navigator.of(context).push(
                      fadeRoute(
                        RecommendationScreen(
                          status: result.statusGabungan,
                          childId: measurement?.childId,
                          riwayatId: measurement?.id,
                          childName: measurement?.childName,
                          measuredAt: measurement?.tanggalUkur,
                        ),
                      ),
                    );
                  },
                ),
                if (isNormal) ...[
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Konsultasi Ahli Gizi',
                    icon: Icons.chat_bubble_outline_rounded,
                    isOutlined: true,
                    onPressed: _startConsultation,
                  ),
                ],
                const SizedBox(height: 12),
                TextButton(
                  onPressed: _saveForLater,
                  child: const Text('Nanti Saja'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _backToDashboard() {
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _startConsultation() {
    final measurement = widget.result.measurement;
    Navigator.of(context).push(
      fadeRoute(
        ConsultationChatScreen(
          confirmBeforeStart: true,
          initialMeasurementId: measurement?.id,
          initialMessage: _initialConsultationMessage(),
        ),
      ),
    );
  }

  void _saveForLater() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Hasil telah disimpan. Anda dapat berkonsultasi kapan saja melalui halaman hasil atau riwayat pengukuran.',
        ),
      ),
    );
    _backToDashboard();
  }

  String _initialConsultationMessage() {
    final result = widget.result;
    final measurement = result.measurement;
    return [
      'Halo, saya ingin berkonsultasi mengenai hasil status gizi anak.',
      if (measurement != null) 'Nama anak: ${measurement.childName}',
      'Status BB/U: ${result.kategori.bbu} (${result.zScore.bbu.toStringAsFixed(2)} SD)',
      'Status TB/U: ${result.kategori.tbu} (${result.zScore.tbu.toStringAsFixed(2)} SD)',
      'Status BB/TB: ${result.kategori.bbtb} (${result.zScore.bbtb.toStringAsFixed(2)} SD)',
      'Status pemantauan: ${_monitoringStatusLabel(measurement)}',
      if (_validationNote(
        measurement: measurement,
        hasExtremeZScore: false,
      ).isNotEmpty)
        'Catatan: ${_validationNote(measurement: measurement, hasExtremeZScore: false)}',
    ].join('\n');
  }

  double _scoreToProgress(double score) {
    if (score.isNaN) return 0.62;
    return ((score + 3) / 6).clamp(0.08, 0.96).toDouble();
  }

  bool _isExtremeZScore(double score) {
    if (score.isNaN) return false;
    return score < -6 || score > 6;
  }

  String _validationStatusLabel(AnalysisMeasurementModel? measurement) {
    final status =
        (measurement?.validationStatus ?? measurement?.dataStatus ?? '')
            .toLowerCase();
    if (status == 'perlu_ukur_ulang' ||
        status == 'anomali' ||
        status == 'perlu_verifikasi' ||
        measurement?.isAnomaly == true) {
      return 'Perlu Ukur Ulang';
    }
    return 'Valid';
  }

  String _monitoringStatusLabel(AnalysisMeasurementModel? measurement) {
    final status = (measurement?.monitoringStatus ?? '').toLowerCase();
    if (status == 'perlu_dipantau') return 'Perlu Dipantau';
    return 'Normal';
  }

  String _validationNote({
    required AnalysisMeasurementModel? measurement,
    required bool hasExtremeZScore,
  }) {
    final note = (measurement?.validationNote ?? '').trim();
    if (note.isNotEmpty) return note;
    if ((measurement?.monitoringStatus ?? '').toLowerCase() ==
        'perlu_dipantau') {
      return 'Berat badan anak turun signifikan dari pengukuran sebelumnya dan sudah dikonfirmasi oleh orang tua.';
    }
    if (hasExtremeZScore || measurement?.isAnomaly == true) {
      return 'Data pengukuran perlu dicek ulang agar hasil status gizi lebih akurat.';
    }
    return '';
  }

  String _ageLabel(IdentitasModel identitas) {
    final days = identitas.umurHari;
    final months = identitas.umurBulan.isNaN
        ? '-'
        : identitas.umurBulan.toStringAsFixed(2);

    if (days == null) return '$months bulan';
    return '$months bulan ($days hari)';
  }

  String _genderLabel(String gender) {
    if (gender.toLowerCase().startsWith('p')) return 'Perempuan';
    return 'Laki-laki';
  }
}
