import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:s_gizi/app_design.dart';
import 'package:s_gizi/app_state.dart';
import 'package:s_gizi/models/mobile_child_model.dart';
import 'package:s_gizi/services/api_service.dart';
import 'package:s_gizi/utils/nutrition_display_utils.dart';
import 'package:s_gizi/features/navigation/screens/app_shell.dart';

class AddChildScreen extends StatefulWidget {
  const AddChildScreen({
    super.key,
    bool isFirstSetup = false,
    @Deprecated('Gunakan isFirstSetup') bool? isMandatory,
  }) : isFirstSetup = isMandatory ?? isFirstSetup;

  final bool isFirstSetup;

  @override
  State<AddChildScreen> createState() => _AddChildScreenState();
}

class _AddChildScreenState extends State<AddChildScreen>
    with SingleTickerProviderStateMixin {
  final _api = ApiService();
  final _nameController = TextEditingController();
  final _dateController = TextEditingController();
  final _appState = SgiziAppState.instance;
  late final AnimationController _shakeController;

  DateTime? _birthDate;
  String? _gender;
  bool _loading = false;
  bool _showValidation = false;
  String? _error;
  int? _selectedExistingChildId;

  @override
  void initState() {
    super.initState();
    _selectedExistingChildId = _appState.activeChildId;
    _nameController.addListener(_refreshAvatar);
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
  }

  @override
  void dispose() {
    _nameController.removeListener(_refreshAvatar);
    _nameController.dispose();
    _dateController.dispose();
    _shakeController.dispose();
    super.dispose();
  }

  void _refreshAvatar() {
    if (mounted) setState(() {});
  }

  bool get _isValid {
    return _nameController.text.trim().isNotEmpty &&
        _birthDate != null &&
        _gender != null;
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();
    if (!_isValid) {
      setState(() {
        _showValidation = true;
        _error = 'Nama lengkap, jenis kelamin, dan tanggal lahir wajib diisi.';
      });
      _shakeController.forward(from: 0);
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final child = await _api.createChild({
        'nama': _nameController.text.trim(),
        'tanggal_lahir': _toApiDate(_birthDate!),
        'jenis_kelamin': _gender,
      });

      final state = SgiziAppState.instance;
      state.setChildren([...state.children, child]);
      state.setActiveChild(child.id);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(fadeRoute(const AppShell()));
    } catch (error) {
      setState(() => _error = error.toString());
      _shakeController.forward(from: 0);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthDate ?? DateTime(now.year - 3, now.month, now.day),
      firstDate: DateTime(now.year - 18, now.month, now.day),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(
              context,
            ).colorScheme.copyWith(primary: const Color(0xFF0B7A86)),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;

    setState(() {
      _birthDate = picked;
      _dateController.text = _formatIndonesiaDate(picked);
      _showValidation = false;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final children = _appState.children;
    return PopScope(
      canPop: !widget.isFirstSetup,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F7F6),
        resizeToAvoidBottomInset: true,
        appBar: AppBar(
          automaticallyImplyLeading: !widget.isFirstSetup,
          backgroundColor: const Color(0xFFF5F7F6),
          title: Text(widget.isFirstSetup ? 'Data Anak' : 'Tambah Anak'),
          actions: [
            IconButton(
              onPressed: () {},
              icon: const Icon(Icons.more_vert_rounded),
            ),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ANAK TERDAFTAR',
                  style: AppTypography.caption.copyWith(
                    letterSpacing: 1,
                    color: SgColors.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                _ChildSelectorRow(
                  children: children,
                  selectedId: _selectedExistingChildId,
                  onSelect: (id) {
                    setState(() => _selectedExistingChildId = id);
                    _appState.setActiveChild(id);
                  },
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),
                const SizedBox(height: 18),
                AnimatedBuilder(
                  animation: _shakeController,
                  builder: (context, child) {
                    final t = _shakeController.value;
                    final dx = math.sin(t * math.pi * 4) * (1 - t) * 8;
                    return Transform.translate(
                      offset: Offset(dx, 0),
                      child: child,
                    );
                  },
                  child:
                      HealthCard(
                            padding: const EdgeInsets.fromLTRB(18, 20, 18, 18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Detail Data Anak',
                                  style: AppTypography.h2,
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Lengkapi informasi untuk analisis gizi tepat.',
                                  style: AppTypography.body,
                                ),
                                const SizedBox(height: 18),
                                Center(
                                  child: Column(
                                    children: [
                                      SgAvatar(
                                            name: _nameController.text,
                                            gender: _gender,
                                            radius: 55,
                                            icon: Icons.child_care_rounded,
                                          )
                                          .animate(
                                            onPlay: (c) =>
                                                c.repeat(reverse: true),
                                          )
                                          .scale(
                                            begin: const Offset(0.98, 0.98),
                                            end: const Offset(1.02, 1.02),
                                            duration: 2.seconds,
                                          ),
                                      const SizedBox(height: 10),
                                      Text(
                                        getInitialName(_nameController.text),
                                        style: AppTypography.h3.copyWith(
                                          color: const Color(0xFF0B7A86),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 18),
                                _FieldLabel('NAMA LENGKAP'),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _nameController,
                                  textInputAction: TextInputAction.next,
                                  onChanged: (_) {
                                    if (_showValidation) setState(() {});
                                  },
                                  decoration: _inputDecoration(
                                    hint: 'Contoh: Arkan Syahputra',
                                    icon: PhosphorIconsRegular.user,
                                    showError:
                                        _showValidation &&
                                        _nameController.text.trim().isEmpty,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _FieldLabel('JENIS KELAMIN'),
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _GenderOption(
                                        label: 'Laki-laki',
                                        active: _gender == 'L',
                                        onTap: () =>
                                            setState(() => _gender = 'L'),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _GenderOption(
                                        label: 'Perempuan',
                                        active: _gender == 'P',
                                        onTap: () =>
                                            setState(() => _gender = 'P'),
                                      ),
                                    ),
                                  ],
                                ),
                                if (_showValidation && _gender == null)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      'Pilih jenis kelamin.',
                                      style: AppTypography.caption.copyWith(
                                        color: SgColors.danger,
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 16),
                                _FieldLabel('TANGGAL LAHIR'),
                                const SizedBox(height: 8),
                                TextField(
                                  controller: _dateController,
                                  readOnly: true,
                                  onTap: _pickDate,
                                  decoration: _inputDecoration(
                                    hint: 'Pilih tanggal lahir',
                                    icon: LucideIcons.calendarDays,
                                    showError:
                                        _showValidation && _birthDate == null,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                if (_birthDate != null)
                                  Text(
                                    'Umur: ${formatAgeFromBirthDate(_toApiDate(_birthDate!), source: 'add_child_birthdate_preview')}',
                                    style: AppTypography.caption.copyWith(
                                      color: const Color(0xFF0B7A86),
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                if (_error != null) ...[
                                  const SizedBox(height: 10),
                                  Text(
                                    _error!,
                                    style: AppTypography.caption.copyWith(
                                      color: SgColors.danger,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 18),
                                _SaveButton(
                                  loading: _loading,
                                  onTap: _loading ? null : _save,
                                ),
                              ],
                            ),
                          )
                          .animate()
                          .fadeIn(delay: 100.ms, duration: 320.ms)
                          .slideY(begin: 0.1, end: 0),
                ),
                const SizedBox(height: 14),
                HealthCard(
                  color: const Color(0xFFEFFAF4),
                  borderColor: const Color(0xFFD5EFD8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFDFF5E6),
                        child: Icon(
                          PhosphorIconsFill.shieldCheck,
                          size: 18,
                          color: const Color(0xFF28A66D),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Informasi Keamanan', style: AppTypography.h3),
                            SizedBox(height: 4),
                            Text(
                              'Data anak Anda tersimpan aman dan hanya digunakan untuk analisis standar WHO.',
                              style: AppTypography.body,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 170.ms, duration: 320.ms),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    required bool showError,
  }) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF4F7F6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: showError ? SgColors.danger : const Color(0xFFE3E9E7),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(
          color: showError ? SgColors.danger : const Color(0xFFE3E9E7),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: Color(0xFF0B7A86), width: 1.5),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.caption.copyWith(
        letterSpacing: 0.8,
        fontWeight: FontWeight.w800,
        color: SgColors.textPrimary,
      ),
    );
  }
}

class _GenderOption extends StatelessWidget {
  const _GenderOption({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active
              ? const Color(0xFF0B7A86).withValues(alpha: 0.10)
              : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: active ? const Color(0xFF0B7A86) : const Color(0xFFE0E7E4),
          ),
        ),
        child: Text(
          label,
          style: AppTypography.h3.copyWith(
            color: active ? const Color(0xFF0B7A86) : SgColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SaveButton extends StatefulWidget {
  const _SaveButton({required this.loading, required this.onTap});
  final bool loading;
  final VoidCallback? onTap;

  @override
  State<_SaveButton> createState() => _SaveButtonState();
}

class _SaveButtonState extends State<_SaveButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapCancel: () => setState(() => _pressed = false),
          onTapUp: (_) => setState(() => _pressed = false),
          child: AnimatedScale(
            scale: _pressed ? 0.98 : 1,
            duration: const Duration(milliseconds: 160),
            child: Container(
              width: double.infinity,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0B7A86), Color(0xFF1597A4)],
                ),
                borderRadius: BorderRadius.circular(999),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0B7A86).withValues(alpha: 0.28),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(999),
                  onTap: widget.onTap,
                  child: Center(
                    child: widget.loading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Simpan & Lanjutkan',
                                style: AppTypography.h2.copyWith(
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Icon(
                                LucideIcons.arrowRight,
                                color: Colors.white,
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
          ),
        )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: 0, end: -2, duration: 1800.ms);
  }
}

class _ChildSelectorRow extends StatelessWidget {
  const _ChildSelectorRow({
    required this.children,
    required this.selectedId,
    required this.onSelect,
  });

  final List<MobileChildModel> children;
  final int? selectedId;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: children.length + 1,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          if (index == children.length) {
            return Container(
              width: 88,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2EAE7)),
              ),
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(LucideIcons.plus, color: Color(0xFF0B7A86)),
                  SizedBox(height: 6),
                  Text('Tambah', style: AppTypography.caption),
                ],
              ),
            );
          }

          final child = children[index];
          final active = child.id == selectedId;
          return InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => onSelect(child.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 92,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: active
                      ? const Color(0xFF0B7A86)
                      : const Color(0xFFE2EAE7),
                  width: active ? 1.8 : 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: active ? 0.08 : 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      ChildAvatar(
                        name: child.nama,
                        gender: child.jenisKelamin,
                        radius: 22,
                      ),
                      if (active)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: Color(0xFF0B7A86),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    child.nama,
                    style: AppTypography.caption.copyWith(
                      color: SgColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    formatAgeFromBirthDate(
                      child.tanggalLahir,
                      source: 'add_child_existing_child_card',
                    ),
                    style: AppTypography.caption,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

String _toApiDate(DateTime value) {
  return '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

String _formatIndonesiaDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'Mei',
    'Jun',
    'Jul',
    'Agu',
    'Sep',
    'Okt',
    'Nov',
    'Des',
  ];
  return '${value.day.toString().padLeft(2, '0')} ${months[value.month - 1]} ${value.year}';
}
