import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:s_gizi/app_design.dart';

class IndonesiaPhoneFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    while (digits.startsWith('0')) {
      digits = digits.substring(1);
    }
    if (digits.startsWith('62')) {
      digits = digits.substring(2);
    }
    if (digits.length > 13) {
      digits = digits.substring(0, 13);
    }
    return TextEditingValue(
      text: digits,
      selection: TextSelection.collapsed(offset: digits.length),
    );
  }
}

String fullIndonesiaPhone(String localNumber) {
  final digits = localNumber.replaceAll(RegExp(r'\D'), '');
  return '+62$digits';
}

bool isValidIndonesiaPhone(String localNumber) {
  final digits = localNumber.replaceAll(RegExp(r'\D'), '');
  return RegExp(r'^8\d{8,12}$').hasMatch(digits);
}

class IndonesiaPhoneField extends StatelessWidget {
  const IndonesiaPhoneField({
    super.key,
    required this.controller,
    required this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      enabled: enabled,
      onChanged: onChanged,
      keyboardType: TextInputType.number,
      textInputAction: TextInputAction.next,
      inputFormatters: [
        FilteringTextInputFormatter.digitsOnly,
        IndonesiaPhoneFormatter(),
      ],
      decoration: InputDecoration(
        labelText: 'Nomor Telepon',
        hintText: '8123456789',
        prefixIcon: const Icon(Icons.phone_iphone_rounded),
        prefixText: '+62 | ',
        prefixStyle: AppTypography.body.copyWith(
          color: SgColors.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class OtpCodeInput extends StatefulWidget {
  const OtpCodeInput({
    super.key,
    required this.onChanged,
    this.enabled = true,
    this.length = 6,
  });

  final ValueChanged<String> onChanged;
  final bool enabled;
  final int length;

  @override
  State<OtpCodeInput> createState() => _OtpCodeInputState();
}

class _OtpCodeInputState extends State<OtpCodeInput> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.enabled) _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void clear() {
    for (final controller in _controllers) {
      controller.clear();
    }
    _emit();
  }

  void _emit() {
    widget.onChanged(_controllers.map((c) => c.text).join());
  }

  void _handleChanged(int index, String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      for (var i = 0; i < widget.length; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final nextIndex = digits.length.clamp(0, widget.length - 1).toInt();
      _focusNodes[nextIndex].requestFocus();
      _emit();
      return;
    }

    _controllers[index].text = digits;
    _controllers[index].selection = TextSelection.collapsed(
      offset: digits.length,
    );

    if (digits.isNotEmpty && index < widget.length - 1) {
      _focusNodes[index + 1].requestFocus();
    }
    _emit();
  }

  void _handleBackspace(int index) {
    if (_controllers[index].text.isEmpty && index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      _emit();
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = constraints.maxWidth < 330 ? 6.0 : 8.0;
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(widget.length, (index) {
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  left: index == 0 ? 0 : gap / 2,
                  right: index == widget.length - 1 ? 0 : gap / 2,
                ),
                child: Focus(
                  onKeyEvent: (_, event) {
                    if (event is KeyDownEvent &&
                        event.logicalKey == LogicalKeyboardKey.backspace) {
                      _handleBackspace(index);
                    }
                    return KeyEventResult.ignored;
                  },
                  child: TextField(
                    controller: _controllers[index],
                    focusNode: _focusNodes[index],
                    enabled: widget.enabled,
                    onChanged: (value) => _handleChanged(index, value),
                    keyboardType: TextInputType.number,
                    textInputAction: index == widget.length - 1
                        ? TextInputAction.done
                        : TextInputAction.next,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(widget.length),
                    ],
                    textAlign: TextAlign.center,
                    style: AppTypography.h2.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                    decoration: InputDecoration(
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      filled: true,
                      fillColor: Colors.white,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: SgColors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(
                          color: SgColors.primary,
                          width: 1.8,
                        ),
                      ),
                      disabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: SgColors.border),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
