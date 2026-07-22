import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/models/child_chat_detail_model.dart';
import 'package:s_gizi/providers/consultation_provider.dart';
import 'package:s_gizi/widgets/history_measurement_card.dart';
import 'package:s_gizi/widgets/loading_skeleton.dart';
import 'package:s_gizi/widgets/measurement_info_row.dart';
import 'package:s_gizi/widgets/risk_badge.dart';
import 'package:s_gizi/widgets/zscore_card.dart';

class ChildDetailFromChatScreen extends StatefulWidget {
  const ChildDetailFromChatScreen({
    super.key,
    required this.consultationId,
    this.initialData,
  });

  final int consultationId;
  final ChildChatDetailModel? initialData;

  @override
  State<ChildDetailFromChatScreen> createState() =>
      _ChildDetailFromChatScreenState();
}

class _ChildDetailFromChatScreenState extends State<ChildDetailFromChatScreen> {
  final _note = TextEditingController();
  String _category = 'Saran pola makan';
  late final ConsultationProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = ConsultationProvider();
    _provider.childDetail = widget.initialData;
    _provider.fetchMessages(widget.consultationId);
  }

  @override
  void dispose() {
    _note.dispose();
    _provider.dispose();
    super.dispose();
  }

  Future<void> _saveNote() async {
    final ok = await _provider.saveNote(
      consultationId: widget.consultationId,
      category: _category,
      note: _note.text,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Catatan disimpan.' : 'Gagal menyimpan catatan.'),
      ),
    );
    if (ok) _note.clear();
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
            final child = _provider.childDetail;
            if (_provider.isLoading && child == null) {
              return const LoadingSkeleton();
            }
            if (_provider.errorMessage != null && child == null) {
              return ErrorState(
                message: _provider.errorMessage!,
                onRetry: () => _provider.fetchMessages(widget.consultationId),
              );
            }
            if (child == null) {
              return const EmptyState(
                title: 'Data anak belum tersedia',
                message: 'Detail anak hanya tampil dari konsultasi yang masuk.',
                icon: LucideIcons.baby,
              );
            }
            final z = child.zscoreResult;
            final m = child.latestMeasurement;
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 120),
              children: [
                HealthCard(
                  dense: true,
                  child: Row(
                    children: [
                      SgAvatar(
                        name: child.name,
                        radius: 30,
                        icon: LucideIcons.baby,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(child.name, style: AppTypography.h2),
                            Text(
                              '${child.ageText} • ${child.gender}',
                              style: AppTypography.caption,
                            ),
                            Text(
                              'Orang tua: ${child.parentName}',
                              style: AppTypography.caption,
                            ),
                          ],
                        ),
                      ),
                      RiskBadge(status: child.riskStatus),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                HealthCard(
                  dense: true,
                  child: Column(
                    children: [
                      MeasurementInfoRow(
                        label: 'Tanggal',
                        value: m.measurementDate,
                        icon: LucideIcons.calendar,
                      ),
                      const SizedBox(height: 8),
                      MeasurementInfoRow(
                        label: 'Umur saat ukur',
                        value: m.ageAtMeasurement,
                        icon: LucideIcons.clock,
                      ),
                      const SizedBox(height: 8),
                      MeasurementInfoRow(
                        label: 'Berat badan',
                        value: '${m.weightKg.toStringAsFixed(1)} kg',
                        icon: LucideIcons.scale,
                      ),
                      const SizedBox(height: 8),
                      MeasurementInfoRow(
                        label: 'Tinggi badan',
                        value: '${m.heightCm.toStringAsFixed(0)} cm',
                        icon: LucideIcons.ruler,
                      ),
                      const SizedBox(height: 8),
                      MeasurementInfoRow(
                        label: 'Posisi ukur',
                        value: m.position,
                        icon: LucideIcons.accessibility,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text('Hasil Z-score WHO', style: AppTypography.h2),
                const SizedBox(height: 10),
                ZScoreCard(
                  title: 'BB/U',
                  score: z.bbuScore,
                  status: z.bbuStatus,
                ),
                const SizedBox(height: 10),
                ZScoreCard(
                  title: 'TB/U',
                  score: z.tbuScore,
                  status: z.tbuStatus,
                ),
                const SizedBox(height: 10),
                ZScoreCard(
                  title: 'BB/TB',
                  score: z.bbtbScore,
                  status: z.bbtbStatus,
                ),
                const SizedBox(height: 12),
                HealthCard(
                  dense: true,
                  color: const Color(0xFFFFF8E8),
                  child: Text(child.interpretation, style: AppTypography.body),
                ),
                const SizedBox(height: 16),
                Text('Riwayat Pengukuran Singkat', style: AppTypography.h2),
                const SizedBox(height: 10),
                ...child.shortHistories
                    .take(3)
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: HistoryMeasurementCard(history: item),
                      ),
                    ),
                const SizedBox(height: 16),
                Text('Catatan Ahli Gizi', style: AppTypography.h2),
                const SizedBox(height: 10),
                ...child.notes.map(
                  (note) => HealthCard(
                    dense: true,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Text(note.note, style: AppTypography.body),
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  items:
                      const [
                            'Saran pola makan',
                            'Saran pengukuran ulang',
                            'Saran konsultasi lanjutan',
                            'Catatan umum',
                          ]
                          .map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          )
                          .toList(),
                  onChanged: (value) =>
                      setState(() => _category = value ?? _category),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _note,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    hintText: 'Tulis catatan...',
                  ),
                ),
                const SizedBox(height: 12),
                PrimaryButton(label: 'Simpan Catatan', onPressed: _saveNote),
              ],
            );
          },
        ),
      ),
    );
  }
}
