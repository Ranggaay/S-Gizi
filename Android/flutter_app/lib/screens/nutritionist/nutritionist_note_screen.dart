import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/providers/nutritionist_note_provider.dart';

class NutritionistNoteScreen extends StatefulWidget {
  const NutritionistNoteScreen({super.key, required this.childId});

  final int childId;

  @override
  State<NutritionistNoteScreen> createState() => _NutritionistNoteScreenState();
}

class _NutritionistNoteScreenState extends State<NutritionistNoteScreen> {
  final _controller = TextEditingController();
  late final NutritionistNoteProvider _provider;

  @override
  void initState() {
    super.initState();
    _provider = NutritionistNoteProvider();
  }

  @override
  void dispose() {
    _controller.dispose();
    _provider.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    final ok = await _provider.saveNote(
      childId: widget.childId,
      note: _controller.text,
    );
    if (!mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Catatan berhasil disimpan.')),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_provider.errorMessage ?? 'Gagal menyimpan catatan.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7FAFA),
      appBar: AppBar(title: const Text('Catatan Ahli Gizi')),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _provider,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              children: [
                const Text(
                  'Tambahkan catatan singkat untuk memudahkan monitoring berikutnya.',
                  style: AppTypography.body,
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _controller,
                  minLines: 6,
                  maxLines: 10,
                  textInputAction: TextInputAction.newline,
                  decoration: const InputDecoration(
                    hintText: 'Tulis catatan ahli gizi...',
                  ),
                ),
                const SizedBox(height: 16),
                PrimaryButton(
                  label: _provider.isSaving ? 'Menyimpan...' : 'Simpan Catatan',
                  onPressed: _provider.isSaving ? null : _save,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
