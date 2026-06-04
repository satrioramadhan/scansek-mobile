import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Custom elevated button dengan 3 variants: primary, outline, text
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isOutlined;
  final bool isText;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final double borderRadius;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.isOutlined = false,
    this.isText = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 52,
    this.borderRadius = 12,
  });

  /// Primary solid button
  const CustomButton.primary({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 52,
    this.borderRadius = 12,
  })  : isOutlined = false,
        isText = false,
        backgroundColor = null,
        textColor = null;

  /// Outlined button
  const CustomButton.outlined({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 52,
    this.borderRadius = 12,
  })  : isOutlined = true,
        isText = false,
        backgroundColor = null,
        textColor = null;

  /// Text button (no border, no background)
  const CustomButton.text({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.width,
    this.height = 48,
    this.borderRadius = 12,
  })  : isOutlined = false,
        isText = true,
        backgroundColor = null,
        textColor = null;

  @override
  Widget build(BuildContext context) {
    if (isText) {
      return _buildTextButton();
    } else if (isOutlined) {
      return _buildOutlinedButton();
    } else {
      return _buildPrimaryButton();
    }
  }

  Widget _buildPrimaryButton() {
    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor ?? AppColors.primary,
          foregroundColor: textColor ?? AppColors.textWhite,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: _buildButtonChild(),
      ),
    );
  }

  Widget _buildOutlinedButton() {
    return SizedBox(
      width: width,
      height: height,
      child: OutlinedButton(
        onPressed: isLoading ? null : onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: textColor ?? AppColors.primary,
          side: BorderSide(
            color: textColor ?? AppColors.primary,
            width: 1.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
        child: _buildButtonChild(isOutlined: true),
      ),
    );
  }

  Widget _buildTextButton() {
    return SizedBox(
      width: width,
      height: height,
      child: TextButton(
        onPressed: isLoading ? null : onPressed,
        style: TextButton.styleFrom(
          foregroundColor: textColor ?? AppColors.primary,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: _buildButtonChild(isText: true),
      ),
    );
  }

  Widget _buildButtonChild({bool isOutlined = false, bool isText = false}) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(
            isOutlined || isText
                ? (textColor ?? AppColors.primary)
                : AppColors.textWhite,
          ),
        ),
      );
    }

    final textWidget = Text(
      text,
      style: isText
          ? AppTextStyles.buttonMedium.copyWith(
              color: textColor ?? AppColors.primary,
            )
          : AppTextStyles.buttonLarge.copyWith(
              color: isOutlined
                  ? (textColor ?? AppColors.primary)
                  : (textColor ?? AppColors.textWhite),
            ),
    );

    if (icon != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 8),
          textWidget,
        ],
      );
    }

    return textWidget;
  }
}
