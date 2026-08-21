import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/colors.dart';
import '../theme/spacing.dart';

/// 6-box Native-feeling OTP Input Row
///
/// Features auto-advance focus, backspace auto-focus reversal,
/// paste handling, and Fraunces / Convocation gold styling.
class OtpInputRow extends StatefulWidget {
  final int length;
  final ValueChanged<String> onCompleted;
  final ValueChanged<String>? onChanged;
  final bool hasError;

  const OtpInputRow({
    super.key,
    this.length = 6,
    required this.onCompleted,
    this.onChanged,
    this.hasError = false,
  });

  @override
  State<OtpInputRow> createState() => _OtpInputRowState();
}

class _OtpInputRowState extends State<OtpInputRow> {
  late final List<TextEditingController> _controllers;
  late final List<FocusNode> _focusNodes;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(widget.length, (_) => TextEditingController());
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  String get _currentOtp => _controllers.map((c) => c.text).join();

  void _onChanged(int index, String value) {
    if (value.length > 1) {
      // Handle pasted text (e.g. 6-digit code pasted into one box)
      final cleanDigits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < widget.length; i++) {
        if (i < cleanDigits.length) {
          _controllers[i].text = cleanDigits[i];
        } else {
          _controllers[i].clear();
        }
      }
      final otp = _currentOtp;
      widget.onChanged?.call(otp);
      if (otp.length == widget.length) {
        _focusNodes.last.unfocus();
        widget.onCompleted(otp);
      } else if (cleanDigits.length < widget.length) {
        _focusNodes[cleanDigits.length].requestFocus();
      }
      return;
    }

    if (value.isNotEmpty) {
      // Advance to next box
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
      }
    }

    final otp = _currentOtp;
    widget.onChanged?.call(otp);
    if (otp.length == widget.length) {
      widget.onCompleted(otp);
    }
  }

  void _handleKeyEvent(int index, RawKeyEvent event) {
    if (event is RawKeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_controllers[index].text.isEmpty && index > 0) {
        _focusNodes[index - 1].requestFocus();
        _controllers[index - 1].clear();
        widget.onChanged?.call(_currentOtp);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        return RawKeyboardListener(
          focusNode: FocusNode(), // Dummy node for key events
          onKey: (event) => _handleKeyEvent(index, event),
          child: Container(
            width: 46,
            height: 54,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppSpacing.radiusXs),
              border: Border.all(
                color: widget.hasError
                    ? AppColors.error
                    : (_focusNodes[index].hasFocus
                        ? AppColors.secondary
                        : (_controllers[index].text.isNotEmpty
                            ? AppColors.primary
                            : AppColors.border)),
                width: _focusNodes[index].hasFocus || widget.hasError ? 2.0 : 1.0,
              ),
              boxShadow: [
                if (_focusNodes[index].hasFocus)
                  BoxShadow(
                    color: AppColors.secondary.withOpacity(0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Center(
              child: TextField(
                controller: _controllers[index],
                focusNode: _focusNodes[index],
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 1,
                autofillHints: const [AutofillHints.oneTimeCode],
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                style: GoogleFonts.fraunces(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  counterText: '',
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                ),
                onChanged: (val) => _onChanged(index, val),
              ),
            ),
          ),
        );
      }),
    );
  }
}
