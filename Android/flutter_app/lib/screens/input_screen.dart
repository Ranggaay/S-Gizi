import 'package:flutter/material.dart';

import '../app_design.dart';
import '../app_state.dart';
import 'loading_screen.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _formKey = GlobalKey<FormState>();
  final _birthDateController = TextEditingController();
  final _measurementDateController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  final String _jenisKelamin = 'L';
  String _caraUkur = 'standing';
  DateTime? _birthDate;
  DateTime? _measurementDate;

  @override
  void dispose() {
    _birthDateController.dispose();
    _measurementDateController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final measurementDate = _measurementDate;
    final childId = SgiziAppState.instance.activeChildId;
    if (measurementDate == null || childId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anak aktif dan tanggal ukur wajib dipilih.'),
        ),
      );
      return;
    }

    Navigator.of(context).push(
      fadeRoute(
        LoadingScreen(
          payload: {
            'child_id': childId,
            'tanggal_ukur': _formatDateApi(measurementDate),
            'berat_badan': _parseNumber(_weightController.text),
            'tinggi_badan': _parseNumber(_heightController.text),
            'cara_ukur': _caraUkur,
          },
        ),
      ),
    );
  }

  double _parseNumber(String input) {
    return double.parse(input.trim().replaceAll(',', '.'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SgColors.background,
      appBar: AppBar(title: const Text('Input Data Gizi')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 112),
            children: [
              Row(
                children: [
                  Text(
                    'LANGKAH 1 DARI 2',
                    style: AppTypography.caption.copyWith(
                      color: SgColors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Informasi Fisik',
                    style: AppTypography.caption.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: const LinearProgressIndicator(
                  value: 0.5,
                  minHeight: 8,
                  backgroundColor: Color(0xFFE9EEEC),
                  valueColor: AlwaysStoppedAnimation(SgColors.primary),
                ),
              ),
              const SizedBox(height: 24),
              HealthCard(
                child: AnimatedBuilder(
                  animation: SgiziAppState.instance,
                  builder: (context, _) {
                    final child = SgiziAppState.instance.activeChild;
                    return Row(
                      children: [
                        const CircleAvatar(
                          radius: 26,
                          backgroundColor: Color(0xFFE9F6F2),
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
                              const Text(
                                'Anak Aktif',
                                style: AppTypography.caption,
                              ),
                              Text(
                                child?.nama ?? 'Belum ada anak aktif',
                                style: AppTypography.h2,
                              ),
                              Text(
                                child?.tanggalLahir ?? '-',
                                style: AppTypography.body,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Tanggal Pengukuran',
                style: AppTypography.h3.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 8),
              _buildDateField(
                controller: _measurementDateController,
                label: 'Pilih tanggal',
                onTap: _pickTanggalUkur,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildNumberCard(
                      controller: _weightController,
                      label: 'Berat Badan',
                      unit: 'kg',
                      icon: Icons.monitor_weight_outlined,
                      hint: '0.0',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildNumberCard(
                      controller: _heightController,
                      label: 'Tinggi Badan',
                      unit: 'cm',
                      icon: Icons.straighten_rounded,
                      hint: '0.0',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Cara Pengukuran Tinggi',
                style: AppTypography.h3.copyWith(fontSize: 16),
              ),
              const SizedBox(height: 12),
              _MeasureToggle(
                value: _caraUkur,
                onChanged: (value) => setState(() => _caraUkur = value),
              ),
              const SizedBox(height: 24),
              HealthCard(
                color: const Color(0xFFEFF9F8),
                borderColor: const Color(0xFFD8F0ED),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CircleAvatar(
                      radius: 22,
                      backgroundColor: Color(0xFFD7F0EF),
                      child: Icon(
                        Icons.info_outline_rounded,
                        color: SgColors.primary,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text('Tips Akurasi:', style: AppTypography.h3),
                          SizedBox(height: 6),
                          Text(
                            'Gunakan timbangan digital dan pastikan anak tidak menggunakan alas kaki saat pengukuran tinggi badan.',
                            style: AppTypography.body,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomSheet: Container(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.96),
          border: const Border(top: BorderSide(color: SgColors.border)),
        ),
        child: SafeArea(
          top: false,
          child: PrimaryButton(
            label: 'Hitung Sekarang',
            icon: Icons.chevron_right_rounded,
            onPressed: _submit,
          ),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required TextEditingController controller,
    required String label,
    required VoidCallback onTap,
  }) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      style: AppTypography.h3.copyWith(fontSize: 16),
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_month_outlined),
      ),
      validator: (value) =>
          (value ?? '').trim().isEmpty ? '$label wajib diisi.' : null,
      onTap: onTap,
    );
  }

  Widget _buildNumberCard({
    required TextEditingController controller,
    required String label,
    required String unit,
    required IconData icon,
    required String hint,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.h3),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: AppTypography.h2.copyWith(fontSize: 20),
          decoration: InputDecoration(
            prefixText: '$unit  ',
            hintText: hint,
            suffixIcon: Icon(icon, size: 20),
          ),
          validator: (value) => _validatePositiveNumber(value, label: label),
        ),
      ],
    );
  }

  String? _validatePositiveNumber(String? value, {required String label}) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return '$label wajib diisi.';

    final number = double.tryParse(text.replaceAll(',', '.'));
    if (number == null) return '$label harus berupa angka.';
    if (number <= 0) return '$label harus lebih dari 0.';

    return null;
  }

  Future<void> _pickTanggalLahir() async {
    final now = DateTime.now();
    final initialDate =
        _birthDate ?? DateTime(now.year - 3, now.month, now.day);

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 6),
      lastDate: now,
    );

    if (pickedDate == null) return;

    setState(() {
      _birthDate = pickedDate;
      _birthDateController.text = _formatDateDisplay(pickedDate);
    });
  }

  Future<void> _pickTanggalUkur() async {
    final now = DateTime.now();
    final initialDate = _measurementDate ?? now;

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 1),
    );

    if (pickedDate == null) return;

    setState(() {
      _measurementDate = pickedDate;
      _measurementDateController.text = _formatDateDisplay(pickedDate);
    });
  }

  String _formatDateDisplay(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    final year = date.year.toString();
    return '$year-$month-$day';
  }

  String _formatDateApi(DateTime date) => _formatDateDisplay(date);
}

class _MeasureToggle extends StatelessWidget {
  const _MeasureToggle({required this.value, required this.onChanged});

  final String value;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEEEE),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          _ToggleItem(
            selected: value == 'standing',
            label: 'Berdiri',
            icon: Icons.accessible_forward_rounded,
            onTap: () => onChanged('standing'),
          ),
          _ToggleItem(
            selected: value == 'lying',
            label: 'Terlentang',
            icon: Icons.bed_outlined,
            onTap: () => onChanged('lying'),
          ),
        ],
      ),
    );
  }
}

class _ToggleItem extends StatelessWidget {
  const _ToggleItem({
    required this.selected,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final bool selected;
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? SgColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: selected
                ? [
                    BoxShadow(
                      color: SgColors.primary.withValues(alpha: 0.22),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : SgColors.textSecondary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: AppTypography.h3.copyWith(
                  color: selected ? Colors.white : SgColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
