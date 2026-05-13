import 'package:flutter/material.dart';

import '../app_design.dart';
import '../models/riwayat_response_model.dart';
import '../services/api_service.dart';
import '../utils/nutrition_display_utils.dart';
import 'riwayat_detail_screen.dart';

class RiwayatScreen extends StatefulWidget {
  const RiwayatScreen({super.key, required this.childId});

  final int childId;

  @override
  State<RiwayatScreen> createState() => _RiwayatScreenState();
}

class _RiwayatScreenState extends State<RiwayatScreen> {
  final ApiService _apiService = ApiService();
  late Future<RiwayatResponseModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _apiService.getRiwayat(childId: widget.childId);
  }

  void _retry() {
    setState(() {
      _future = _apiService.getRiwayat(childId: widget.childId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SgColors.background,
      appBar: AppBar(title: const Text('Riwayat Gizi')),
      body: FutureBuilder<RiwayatResponseModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _HistorySkeleton();
          }
          if (snapshot.hasError) {
            return ErrorState(
              message:
                  'Riwayat belum dapat dimuat. Pastikan server API aktif dan koneksi tersedia.',
              onRetry: _retry,
            );
          }

          final data = snapshot.data!;
          if (data.riwayat.isEmpty) {
            return EmptyState(
              title: 'Belum Ada Riwayat',
              message:
                  'Input pengukuran pertama untuk mulai melihat timeline pertumbuhan anak.',
              actionLabel: 'Muat Ulang',
              onAction: _retry,
            );
          }

          return ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            children: [
              HealthCard(
                color: const Color(0xFFEAF7F7),
                borderColor: const Color(0xFFCBEAEA),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ChildAvatar(
                      name: data.child.nama,
                      gender: data.child.jenisKelamin,
                      photoUrl: data.child.photoUrl,
                      radius: 28,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data.child.nama,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.h2,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${genderLabel(data.child.jenisKelamin)} | ${formatAgeFromBirthDate(data.child.tanggalLahir)}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.caption,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Timeline pengukuran tersusun dari tanggal ukur terbaru.',
                            style: AppTypography.body,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    StatusBadge(text: '${data.riwayat.length} Entri'),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ...data.riwayat.asMap().entries.map((entry) {
                return _TimelineItem(
                  child: data.child,
                  item: entry.value,
                  isLast: entry.key == data.riwayat.length - 1,
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.child,
    required this.item,
    required this.isLast,
  });

  final ChildInfoModel child;
  final RiwayatItemModel item;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final visual = nutritionStatusVisual(item.statusGabungan);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: visual.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(color: visual.color.withValues(alpha: 0.4)),
                ),
                child: Icon(visual.icon, color: visual.color, size: 12),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: SgColors.border,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 16,
                        color: SgColors.textSecondary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          formatMeasurementDate(item.tanggalUkur),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  HealthCard(
                    onTap: () {
                      Navigator.of(context).push(
                        fadeRoute(
                          RiwayatDetailScreen(child: child, item: item),
                        ),
                      );
                    },
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ChildAvatar(
                              name: child.nama,
                              gender: child.jenisKelamin,
                              photoUrl: child.photoUrl,
                              radius: 22,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    child.nama,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.h3,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Usia ${formatAgeFromMonths(item.umurBulan)}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: AppTypography.caption,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: StatusBadge(
                                text: item.statusGabungan,
                                color: visual.color,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _MeasurementInfo(
                                icon: Icons.monitor_weight_outlined,
                                label: 'Berat badan',
                                value: '${item.berat.toStringAsFixed(1)} kg',
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _MeasurementInfo(
                                icon: Icons.straighten_rounded,
                                label: 'Tinggi badan',
                                value: '${item.tinggi.toStringAsFixed(1)} cm',
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FBFA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: SgColors.border),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                visual.icon,
                                size: 18,
                                color: visual.color,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  visual.summary,
                                  style: AppTypography.body,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: const [
                            Icon(
                              Icons.info_outline_rounded,
                              size: 16,
                              color: SgColors.textSecondary,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Ketuk untuk detail analisis',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption,
                              ),
                            ),
                            Icon(
                              Icons.chevron_right_rounded,
                              color: SgColors.textSecondary,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MeasurementInfo extends StatelessWidget {
  const _MeasurementInfo({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: const Color(0xFFEAF7F7),
          child: Icon(icon, color: SgColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTypography.caption),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.h3,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HistorySkeleton extends StatelessWidget {
  const _HistorySkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        HealthCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 180, height: 18, color: const Color(0xFFE9EEEC)),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                height: 12,
                color: const Color(0xFFE9EEEC),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        for (var i = 0; i < 3; i++) ...[
          HealthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 140,
                  height: 16,
                  color: const Color(0xFFE9EEEC),
                ),
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  height: 12,
                  color: const Color(0xFFE9EEEC),
                ),
                const SizedBox(height: 10),
                Container(
                  width: 180,
                  height: 12,
                  color: const Color(0xFFE9EEEC),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
