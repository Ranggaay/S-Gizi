import 'package:flutter/material.dart';

import '../app_design.dart';
import '../app_state.dart';
import '../models/api_result_model.dart';
import '../services/api_service.dart';
import 'result_screen.dart';

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
              message:
                  'S-Gizi belum berhasil menghitung data. Periksa koneksi atau server API, lalu coba lagi.',
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
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              RotationTransition(
                turns: Tween<double>(begin: 0, end: 1).animate(_controller),
                child: Container(
                  width: 112,
                  height: 112,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF8F7),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE2F1EF),
                      width: 8,
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: SgColors.primary,
                    size: 38,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Sedang menghitung status gizi...',
                style: AppTypography.h1,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                'Mohon tunggu sebentar, sistem S-Gizi sedang menganalisis data pertumbuhan si Kecil berdasarkan standar kesehatan.',
                style: AppTypography.body,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
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
                  final percent = (20 + (_controller.value * 70)).round();
                  return Text(
                    'MEMPROSES DATA $percent%',
                    style: AppTypography.caption.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w800,
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
