import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isOutline;
  final Widget? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final Gradient? gradient;
  final List<BoxShadow>? boxShadow;
  final double height;
  final double? width;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isOutline = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.gradient,
    this.boxShadow,
    this.height = 52.0,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBgColor =
        backgroundColor ?? (isOutline ? Colors.white : AppColors.primaryButton);
    final effectiveTextColor =
        textColor ?? (isOutline ? AppColors.textDark : Colors.white);
    final buttonTextStyle = AppTextStyles.buttonLabel.copyWith(
      color: effectiveTextColor,
    );

    Widget buttonChild;
    if (icon != null) {
      buttonChild = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          icon!,
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: buttonTextStyle,
            ),
          ),
        ],
      );
    } else {
      buttonChild = Text(
        text,
        textAlign: TextAlign.center,
        style: buttonTextStyle,
      );
    }

    if (isOutline) {
      return SizedBox(
        width: width ?? double.infinity,
        height: height,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: effectiveBgColor,
            foregroundColor: effectiveTextColor,
            overlayColor: AppColors.primary.withValues(alpha: 0.06),
            side: BorderSide(
              color: AppColors.outlineVariant.withValues(alpha: 0.9),
            ),
            shape: const StadiumBorder(),
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 18),
          ),
          child: buttonChild,
        ),
      );
    }

    final button = SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: gradient == null
              ? effectiveBgColor
              : Colors.transparent,
          foregroundColor: effectiveTextColor,
          overlayColor: Colors.white.withValues(alpha: 0.12),
          shape: const StadiumBorder(),
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 18),
        ),
        child: buttonChild,
      ),
    );

    if (gradient == null && boxShadow == null) {
      return button;
    }

    return Container(
      width: width ?? double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: gradient,
        color: gradient == null ? effectiveBgColor : null,
        borderRadius: BorderRadius.circular(height / 2),
        boxShadow: boxShadow,
      ),
      child: button,
    );
  }
}
