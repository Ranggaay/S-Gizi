import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/providers/quick_validation_provider.dart';

class QuickValidationScreen extends StatefulWidget {
  const QuickValidationScreen({super.key, required this.measurementId});

  final int measurementId;

  @override
  State<QuickValidationScreen> createState() => _QuickValidationScreenState();
}

class _QuickValidationScreenState extends State<QuickValidationScreen> {
  final _note = TextEditingController();
  late final QuickValidationProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = QuickValidationProvider();
  }

  @override
  void dispose() {
    _note.dispose();
    _provider.dispose();
    super.dispose();
  }

  Future<void> _submit(bool accepted) async {
    final ok = await _provider.validate(
      measurementId: widget.measurementId,
      accepted: accepted,
      note: _note.text,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            accepted
                ? 'Data ditandai valid.'
                : 'Data ditandai perlu verifikasi.',
          ),
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_provider.errorMessage ?? 'Validasi gagal.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      appBar: AppBar(title: const Text('Validasi Data')),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _provider,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              children: [
                HealthCard(
                  dense: true,
                  color: const Color(0xFFFFFBEB),
                  borderColor: const Color(0xFFFFE2A8),
                  child: Text(
                    'Validasi cepat hanya menandai data untuk monitoring. Pemeriksaan lengkap tetap dilakukan di website ahli gizi.',
                    style: AppTypography.body,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _note,
                  minLines: 4,
                  maxLines: 8,
                  decoration: const InputDecoration(
                    hintText: 'Catatan validasi opsional...',
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: _provider.isSaving ? 'Memproses...' : 'Data Valid',
                  onPressed: _provider.isSaving ? null : () => _submit(true),
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: 'Perlu Verifikasi',
                  isOutlined: true,
                  onPressed: _provider.isSaving ? null : () => _submit(false),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
