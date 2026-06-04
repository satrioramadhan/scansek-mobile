import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// OTP input widget with individual boxes for each digit
class OtpInput extends StatefulWidget {
  final TextEditingController controller;
  final int length;
  final ValueChanged<String>? onCompleted;
  final bool autoFocus;

  const OtpInput({
    super.key,
    required this.controller,
    this.length = 6,
    this.onCompleted,
    this.autoFocus = true,
  });

  @override
  State<OtpInput> createState() => _OtpInputState();
}

class _OtpInputState extends State<OtpInput> {
  late List<FocusNode> _focusNodes;
  late List<TextEditingController> _controllers;

  @override
  void initState() {
    super.initState();
    _focusNodes = List.generate(widget.length, (_) => FocusNode());
    _controllers = List.generate(widget.length, (_) => TextEditingController());

    // Auto focus first box
    if (widget.autoFocus) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (mounted) {
          _focusNodes[0].requestFocus();
        }
      });
    }

    // Listen to main controller changes
    widget.controller.addListener(_updateBoxes);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateBoxes);
    for (var node in _focusNodes) {
      node.dispose();
    }
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateBoxes() {
    final text = widget.controller.text;
    for (var i = 0; i < widget.length; i++) {
      _controllers[i].text = i < text.length ? text[i] : '';
    }
  }

  void _onChanged(int index, String value) {
    // Update main controller
    final currentText = widget.controller.text;
    final chars = currentText.split('');

    if (value.isEmpty) {
      // Backspace
      if (chars.length > index) {
        chars.removeAt(index);
      }
      widget.controller.text = chars.join('');
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
    } else {
      // Input
      if (index < chars.length) {
        chars[index] = value;
      } else {
        chars.add(value);
      }
      widget.controller.text = chars.join('');

      // Move to next
      if (index < widget.length - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        // Call onCompleted if all filled
        if (widget.controller.text.length == widget.length) {
          widget.onCompleted?.call(widget.controller.text);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(widget.length, (index) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              right: index < widget.length - 1 ? 8 : 0,
            ),
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: AppTextStyles.h2.copyWith(
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.borderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppColors.focusBorderColor,
                    width: 2,
                  ),
                ),
              ),
              onChanged: (value) => _onChanged(index, value),
            ),
          ),
        );
      }),
    );
  }
}
