import 'package:flutter/material.dart';
import '../constants/brand_colors.dart';

/// Reusable primary button conforming to DineFlow brand standards.
class PrimaryButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  const PrimaryButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height = 48,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg = backgroundColor ?? BrandColors.primaryOrange;
    final effectiveFg = textColor ?? Colors.white;
    final effectiveRadius = borderRadius ?? BorderRadius.circular(10);

    return SizedBox(
      width: width,
      height: height,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: effectiveBg,
          foregroundColor: effectiveFg,
          disabledBackgroundColor: effectiveBg.withValues(alpha: 0.6),
          disabledForegroundColor: effectiveFg.withValues(alpha: 0.8),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: effectiveRadius),
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        onPressed: isLoading ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  valueColor: AlwaysStoppedAnimation<Color>(effectiveFg),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: effectiveFg),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    text,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: effectiveFg,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
