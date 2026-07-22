import 'package:flutter/material.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/app_state.dart';
import 'package:s_gizi/models/mobile_child_model.dart';
import 'package:s_gizi/models/riwayat_response_model.dart';
import 'package:s_gizi/services/api_service.dart';
import 'package:s_gizi/utils/age_helper.dart';
import 'package:s_gizi/features/auth/screens/loading_screen.dart';
import 'package:s_gizi/features/children/screens/children_screen.dart';

class InputScreen extends StatefulWidget {
  const InputScreen({super.key});

  @override
  State<InputScreen> createState() => _InputScreenState();
}

class _InputScreenState extends State<InputScreen> {
  final _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _measurementDateController = TextEditingController();
  final _weightController = TextEditingController();
  final _heightController = TextEditingController();

  String _caraUkur = 'standing';
  DateTime? _measurementDate;
  RiwayatItemModel? _latestMeasurement;
  String? _realtimeWarning;

  @override
  void initState() {
    super.initState();
    _weightController.addListener(_updateRealtimeWarning);
    _heightController.addListener(_updateRealtimeWarning);
    _loadLatestMeasurement();
  }

  @override
  void dispose() {
    _weightController.removeListener(_updateRealtimeWarning);
    _heightController.removeListener(_updateRealtimeWarning);
    _measurementDateController.dispose();
    _weightController.dispose();
    _heightController.dispose();
    super.dispose();
  }

  Future<void> _loadLatestMeasurement() async {
    final childId = SgiziAppState.instance.activeChildId;
    if (childId == null) return;
    try {
      final history = await _api.getRiwayat(childId: childId);
      if (!mounted || history.riwayat.isEmpty) return;
      setState(() => _latestMeasurement = history.riwayat.last);
      _updateRealtimeWarning();
    } catch (_) {}
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    final measurementDate = _measurementDate;
    final child = SgiziAppState.instance.activeChild;
    final childId = SgiziAppState.instance.activeChildId;
    if (measurementDate == null || childId == null || child == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Anak aktif dan tanggal ukur wajib dipilih.'),
        ),
      );
      return;
    }

    final validationMessage = _validateWhoInput(
      birthDateRaw: child.tanggalLahir,
      measurementDate: measurementDate,
      weight: _parseNumber(_weightController.text),
      height: _parseNumber(_heightController.text),
    );
    if (validationMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationMessage)));
      return;
    }

    final warnings = _buildMeasurementWarnings(
      measurementDate: measurementDate,
      weight: _parseNumber(_weightController.text),
      height: _parseNumber(_heightController.text),
    );
    final blockingDate = warnings
        .where((item) => item.isBlocking)
        .map((item) => item.message)
        .firstOrNull;
    if (blockingDate != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(blockingDate)));
      return;
    }

    var isAnomaly = false;
    var validationStatus = 'valid';
    var monitoringStatus = 'normal';
    var validationNote = '';
    var isConfirmedByParent = false;
    final softWarnings = warnings.where((item) => !item.isBlocking).toList();
    if (softWarnings.isNotEmpty) {
      final warning = softWarnings.firstWhere(
        (item) => item.type == _MeasurementWarningType.remeasure,
        orElse: () => softWarnings.first,
      );
      final keepSaving = await _showMeasurementWarningDialog(warning);
      if (!mounted) return;
      if (keepSaving != true) return;
      validationStatus = warning.type == _MeasurementWarningType.remeasure
          ? 'perlu_ukur_ulang'
          : 'valid';
      monitoringStatus = warning.type == _MeasurementWarningType.monitor
          ? 'perlu_dipantau'
          : 'normal';
      isAnomaly = validationStatus == 'perlu_ukur_ulang';
      isConfirmedByParent = true;
      validationNote = warning.note;
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
            'is_anomaly': isAnomaly,
            'validation_status': validationStatus,
            'monitoring_status': monitoringStatus,
            'validation_note': validationNote,
            'is_confirmed_by_parent': isConfirmedByParent,
          },
        ),
      ),
    );
  }

  void _updateRealtimeWarning() {
    if (!mounted || _latestMeasurement == null) return;
    final weightText = _weightController.text.trim().replaceAll(',', '.');
    final heightText = _heightController.text.trim().replaceAll(',', '.');
    final weight = double.tryParse(weightText);
    final height = double.tryParse(heightText);
    final messages = <String>[];
    if (height != null &&
        height >= 45 &&
        (_latestMeasurement!.tinggi - height) > 2) {
      messages.add('Tinggi badan turun lebih dari 2 cm dari data terakhir.');
    }
    if (weight != null &&
        weightText.length >= 2 &&
        _latestMeasurement!.berat > 0) {
      final dropRatio =
          (_latestMeasurement!.berat - weight) / _latestMeasurement!.berat;
      if (dropRatio > 0.10) {
        messages.add('Berat badan turun lebih dari 10% dari data terakhir.');
      }
    }
    final next = messages.isEmpty ? null : messages.first;
    if (_realtimeWarning != next) {
      setState(() => _realtimeWarning = next);
    }
  }

  List<_MeasurementWarning> _buildMeasurementWarnings({
    required DateTime measurementDate,
    required double weight,
    required double height,
  }) {
    final latest = _latestMeasurement;
    if (latest == null) return const [];
    final warnings = <_MeasurementWarning>[];
    final latestDate = DateTime.tryParse(latest.tanggalUkur);
    if (latestDate != null && measurementDate.isBefore(latestDate)) {
      warnings.add(
        const _MeasurementWarning(
          type: _MeasurementWarningType.blocking,
          title: 'Tanggal pengukuran tidak valid',
          message:
              'Tanggal pengukuran baru tidak boleh lebih lama dari pengukuran sebelumnya.',
          note: 'Tanggal pengukuran lebih lama dari data terakhir.',
          previousLabel: 'Tanggal sebelumnya',
          currentLabel: 'Tanggal sekarang',
          previousValue: '-',
          currentValue: '-',
          confirmLabel: 'Tetap Lanjutkan',
          isBlocking: true,
        ),
      );
    }
    if ((latest.tinggi - height) > 2) {
      warnings.add(
        _MeasurementWarning(
          type: _MeasurementWarningType.remeasure,
          title: 'Perlu Ukur Ulang',
          message:
              'Tinggi badan anak lebih rendah dari pengukuran sebelumnya. Mohon periksa kembali data pengukuran agar hasil status gizi lebih akurat.',
          note:
              'Tinggi badan anak lebih rendah dari pengukuran sebelumnya dan perlu dicek ulang.',
          previousLabel: 'Tinggi sebelumnya',
          currentLabel: 'Tinggi sekarang',
          previousValue: '${latest.tinggi.toStringAsFixed(0)} cm',
          currentValue: '${height.toStringAsFixed(0)} cm',
          confirmLabel: 'Tetap Lanjutkan',
        ),
      );
    }
    if (latest.berat > 0) {
      final dropRatio = (latest.berat - weight) / latest.berat;
      if (dropRatio > 0.15) {
        warnings.add(
          _MeasurementWarning(
            type: _MeasurementWarningType.monitor,
            title: 'Perlu Dipantau',
            message:
                'Berat badan anak turun cukup besar dari pengukuran sebelumnya. Jika data sudah benar, hasil akan disimpan dan anak ditandai sebagai perlu dipantau.',
            note:
                'Berat badan anak turun signifikan dari pengukuran sebelumnya dan sudah dikonfirmasi oleh orang tua.',
            previousLabel: 'BB sebelumnya',
            currentLabel: 'BB sekarang',
            previousValue: '${latest.berat.toStringAsFixed(1)} kg',
            currentValue: '${weight.toStringAsFixed(1)} kg',
            confirmLabel: 'Data Sudah Benar',
          ),
        );
      }
    }
    return warnings;
  }

  Future<bool?> _showMeasurementWarningDialog(_MeasurementWarning warning) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          icon: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: SgColors.warning.withValues(alpha: 0.14),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              color: SgColors.warning,
              size: 30,
            ),
          ),
          title: Text(warning.title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(warning.message, style: AppTypography.body),
                const SizedBox(height: 14),
                _ComparisonRow(
                  label: warning.previousLabel,
                  value: warning.previousValue,
                ),
                const SizedBox(height: 8),
                _ComparisonRow(
                  label: warning.currentLabel,
                  value: warning.currentValue,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Perbaiki Data'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(warning.confirmLabel),
            ),
          ],
        );
      },
    );
  }

  double _parseNumber(String input) {
    return double.parse(input.trim().replaceAll(',', '.'));
  }

  String? _validateWhoInput({
    required String birthDateRaw,
    required DateTime measurementDate,
    required double weight,
    required double height,
  }) {
    final birthDate = DateTime.tryParse(birthDateRaw);
    if (birthDate == null) return 'Tanggal lahir anak tidak valid.';
    if (measurementDate.isBefore(birthDate)) {
      return 'Tanggal pengukuran tidak boleh sebelum tanggal lahir.';
    }

    final age = calculateAgeParts(birthDate, measurementDate);
    final ageMonths = (age.years * 12) + age.months;
    if (ageMonths > 60) {
      return 'Perhitungan hanya tersedia untuk anak usia 0–5 tahun sesuai standar WHO.';
    }

    if (weight <= 0 || height <= 0) {
      return 'Berat dan tinggi harus lebih dari 0.';
    }

    final impossibleWeight = weight > 45 || (ageMonths < 24 && weight > 25);
    final impossibleHeight = height < 45 || height > 125;
    if (impossibleWeight || impossibleHeight) {
      return 'Data berada di luar standar WHO. Periksa kembali pengukuran anak.';
    }
    return null;
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
                dense: true,
                padding: const EdgeInsets.all(16),
                color: const Color(0xFFF9FCFB),
                borderColor: const Color(0xFFDCEBE8),
                child: AnimatedBuilder(
                  animation: SgiziAppState.instance,
                  builder: (context, _) => _ChildInfoCard(
                    child: SgiziAppState.instance.activeChild,
                    showSwitchButton:
                        SgiziAppState.instance.children.length > 1,
                    onSwitchChild: () => Navigator.of(
                      context,
                    ).push(fadeRoute(const ChildrenScreen())),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_realtimeWarning != null) ...[
                _RealtimeAnomalyHint(message: _realtimeWarning!),
                const SizedBox(height: 14),
              ],
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

String _genderLabel(String raw) {
  final value = raw.trim().toUpperCase();
  if (value == 'P' || value.contains('PEREMPUAN')) return 'Perempuan';
  return 'Laki-laki';
}

String _formatAgeYearsMonths(DateTime birthDate, DateTime referenceDate) {
  final age = calculateAgeParts(birthDate, referenceDate);
  final parts = <String>[];
  if (age.years > 0) parts.add('${age.years} Tahun');
  if (age.months > 0 || parts.isEmpty) parts.add('${age.months} Bulan');
  return parts.join(' ');
}

String _formatIndonesianDate(DateTime date) {
  const months = [
    'Januari',
    'Februari',
    'Maret',
    'April',
    'Mei',
    'Juni',
    'Juli',
    'Agustus',
    'September',
    'Oktober',
    'November',
    'Desember',
  ];
  return '${date.day} ${months[date.month - 1]} ${date.year}';
}

class _ChildInfoCard extends StatelessWidget {
  const _ChildInfoCard({
    required this.child,
    required this.showSwitchButton,
    required this.onSwitchChild,
  });

  final MobileChildModel? child;
  final bool showSwitchButton;
  final VoidCallback onSwitchChild;

  @override
  Widget build(BuildContext context) {
    if (child == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const _ChildInitialAvatar(name: 'A'),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  'Belum ada anak aktif',
                  style: AppTypography.h2.copyWith(fontSize: 19),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          PrimaryButton(
            label: 'Pilih Anak',
            icon: Icons.switch_account_rounded,
            onPressed: onSwitchChild,
          ),
        ],
      );
    }

    final genderLabel = _genderLabel(child!.jenisKelamin);
    final genderIcon = genderLabel == 'Perempuan'
        ? Icons.face_3_rounded
        : Icons.face_rounded;
    final birthDate = DateTime.tryParse(child!.tanggalLahir);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 340;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ChildInitialAvatar(name: child!.nama),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        child!.nama,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.h1.copyWith(
                          fontSize: compact ? 20 : 22,
                          height: 1.18,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _InfoPill(
                            icon: genderIcon,
                            text: genderLabel,
                            color: genderLabel == 'Perempuan'
                                ? const Color(0xFFE06F91)
                                : SgColors.primary,
                          ),
                          _InfoPill(
                            icon: Icons.cake_outlined,
                            text: birthDate == null
                                ? '-'
                                : _formatAgeYearsMonths(
                                    birthDate,
                                    DateTime.now(),
                                  ),
                            color: const Color(0xFF5B8DEF),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE4EEEB)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.calendar_month_outlined,
                    color: SgColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Tanggal Lahir',
                          style: AppTypography.caption.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          birthDate == null
                              ? child!.tanggalLahir
                              : _formatIndonesianDate(birthDate),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.h3.copyWith(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (showSwitchButton) ...[
              const SizedBox(height: 14),
              PrimaryButton(
                label: 'Ganti Anak',
                icon: Icons.swap_horiz_rounded,
                isOutlined: true,
                onPressed: onSwitchChild,
              ),
            ],
          ],
        );
      },
    );
  }
}

enum _MeasurementWarningType { blocking, remeasure, monitor }

class _MeasurementWarning {
  const _MeasurementWarning({
    required this.type,
    required this.title,
    required this.message,
    required this.note,
    required this.previousLabel,
    required this.previousValue,
    required this.currentLabel,
    required this.currentValue,
    required this.confirmLabel,
    this.isBlocking = false,
  });

  final _MeasurementWarningType type;
  final String title;
  final String message;
  final String note;
  final String previousLabel;
  final String previousValue;
  final String currentLabel;
  final String currentValue;
  final String confirmLabel;
  final bool isBlocking;
}

class _ComparisonRow extends StatelessWidget {
  const _ComparisonRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF7FAFA),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: SgColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTypography.caption)),
          Text(value, style: AppTypography.h3.copyWith(fontSize: 14)),
        ],
      ),
    );
  }
}

class _RealtimeAnomalyHint extends StatelessWidget {
  const _RealtimeAnomalyHint({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: SgColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: SgColors.warning.withValues(alpha: 0.24)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: SgColors.warning,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: AppTypography.caption.copyWith(
                color: const Color(0xFF9A5B00),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChildInitialAvatar extends StatelessWidget {
  const _ChildInitialAvatar({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return SgAvatar(name: name, radius: 34);
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({
    required this.icon,
    required this.text,
    required this.color,
  });

  final IconData icon;
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTypography.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
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
