import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/app_state.dart';
import 'package:s_gizi/models/api_result_model.dart';
import 'package:s_gizi/services/api_service.dart';
import 'package:s_gizi/features/children/screens/result_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key, required this.payload});

  final Map<String, dynamic> payload;

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  final ApiService _apiService = ApiService();
  late Future<ApiResultModel> _future;

  @override
  void initState() {
    super.initState();
    _future = _apiService.postHasil(widget.payload);
  }

  void _retry() {
    setState(() => _future = _apiService.postHasil(widget.payload));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<ApiResultModel>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorState(
              message: _friendlyErrorMessage(snapshot.error),
              onRetry: _retry,
            );
          }

          if (snapshot.hasData) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              final childId = widget.payload['child_id'];
              final tanggalUkur = widget.payload['tanggal_ukur'];
              if (childId is int && tanggalUkur is String) {
                SgiziAppState.instance.updateChildMeasurementSnapshot(
                  childId: childId,
                  latestStatus: snapshot.data!.statusGabungan,
                  latestMeasurementAt: tanggalUkur,
                );
              }
              if (!mounted) return;
              Navigator.of(context).pushReplacement(
                fadeRoute(ResultScreen(result: snapshot.data!)),
              );
            });
          }

          return const _LoadingContent();
        },
      ),
    );
  }

  String _friendlyErrorMessage(Object? error) {
    final raw = error?.toString() ?? '';
    if (raw.contains('Data terlalu ekstrem')) {
      return 'Data pengukuran berada di luar batas normal WHO. Periksa kembali berat dan tinggi badan, lalu coba hitung lagi.';
    }
    if (raw.contains('Umur hasil perhitungan')) {
      return 'Umur anak harus berada pada rentang 0 sampai 60 bulan untuk perhitungan WHO.';
    }
    if (raw.contains('Tanggal ukur')) {
      return 'Tanggal pengukuran tidak valid. Pastikan tanggal ukur tidak sebelum tanggal lahir.';
    }
    if (raw.contains('BB/TB') || raw.contains('Berat badan')) {
      return 'Data berat badan atau tinggi badan belum valid. Periksa kembali angka yang dimasukkan.';
    }
    return 'S-Gizi belum berhasil menghitung data. Periksa koneksi atau server API, lalu coba lagi.';
  }
}

class _LoadingContent extends StatefulWidget {
  const _LoadingContent();

  @override
  State<_LoadingContent> createState() => _LoadingContentState();
}

class _LoadingContentState extends State<_LoadingContent>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compactHeight = constraints.maxHeight < 560;
          final iconSize = compactHeight ? 76.0 : 104.0;
          final outerPadding = compactHeight ? 20.0 : 32.0;

          return SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: EdgeInsets.all(outerPadding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: (constraints.maxHeight - outerPadding * 2)
                    .clamp(0, double.infinity)
                    .toDouble(),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      RotationTransition(
                        turns: Tween<double>(
                          begin: 0,
                          end: 1,
                        ).animate(_controller),
                        child: Container(
                          width: iconSize,
                          height: iconSize,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF8F7),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: const Color(0xFFE2F1EF),
                              width: compactHeight ? 5 : 7,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: SgColors.primary.withValues(alpha: 0.12),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.auto_awesome_rounded,
                            color: SgColors.primary,
                            size: compactHeight ? 30 : 38,
                          ),
                        ),
                      ),
                      SizedBox(height: compactHeight ? 18 : 28),
                      Text(
                        'Sedang menghitung status gizi...',
                        style: AppTypography.h1.copyWith(
                          fontSize: compactHeight ? 20 : 24,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: compactHeight ? 10 : 14),
                      const Text(
                        'Mohon tunggu sebentar, sistem S-Gizi sedang menganalisis data pertumbuhan si Kecil berdasarkan standar kesehatan.',
                        style: AppTypography.body,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: compactHeight ? 22 : 34),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: AnimatedBuilder(
                          animation: _controller,
                          builder: (context, _) {
                            final value = 0.18 + (_controller.value * 0.72);
                            return LinearProgressIndicator(
                              value: value,
                              minHeight: 8,
                              backgroundColor: const Color(0xFFEFF4F2),
                              valueColor: const AlwaysStoppedAnimation(
                                SgColors.primary,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      AnimatedBuilder(
                        animation: _controller,
                        builder: (context, _) {
                          final percent = (20 + (_controller.value * 70))
                              .round();
                          return FittedBox(
                            child: Text(
                              'MEMPROSES DATA $percent%',
                              style: AppTypography.caption.copyWith(
                                letterSpacing: 1.2,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
