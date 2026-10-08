import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';

enum DineFlowMarkStyle {
  /// Standard mark with orange cloche and deep green arrow
  standard,

  /// App icon style: orange rounded square container with white cloche & green arrow
  appTile,

  /// Dark surface style: orange cloche and vibrant green arrow for dark backgrounds
  dark,

  /// Pure monochrome for receipt printing
  monochrome,
}

/// A pixel-perfect vector painter for the official DineFlow serving cloche & directional flow arrow logo mark.
class DineFlowMarkPainter extends CustomPainter {
  final DineFlowMarkStyle style;
  final Color? clocheColorOverride;
  final Color? arrowColorOverride;

  const DineFlowMarkPainter({
    this.style = DineFlowMarkStyle.standard,
    this.clocheColorOverride,
    this.arrowColorOverride,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 100.0;

    // Color definitions based on style
    final (clocheColor, arrowColor) = switch (style) {
      DineFlowMarkStyle.appTile => (
          clocheColorOverride ?? Colors.white,
          arrowColorOverride ?? const Color(0xFF0E5A3D),
        ),
      DineFlowMarkStyle.dark => (
          clocheColorOverride ?? AppColors.primary,
          arrowColorOverride ?? const Color(0xFF10B981),
        ),
      DineFlowMarkStyle.monochrome => (
          clocheColorOverride ?? Colors.black,
          arrowColorOverride ?? Colors.black,
        ),
      DineFlowMarkStyle.standard => (
          clocheColorOverride ?? AppColors.primary,
          arrowColorOverride ?? const Color(0xFF107C55),
        ),
    };

    final clocheStroke = Paint()
      ..color = clocheColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7.5 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final clocheFill = Paint()
      ..color = clocheColor
      ..style = PaintingStyle.fill;

    // 1. Cloche Top Knob
    canvas.drawCircle(
      Offset(50 * scale, 24 * scale),
      4.5 * scale,
      clocheFill,
    );

    // 2. Cloche Main Dome Arc
    final domePath = Path();
    domePath.moveTo(18 * scale, 58 * scale);
    domePath.cubicTo(
      18 * scale, 30 * scale,
      82 * scale, 30 * scale,
      82 * scale, 58 * scale,
    );
    canvas.drawPath(domePath, clocheStroke);

    // 3. Cloche Base Brim Line
    canvas.drawLine(
      Offset(12 * scale, 58 * scale),
      Offset(88 * scale, 58 * scale),
      clocheStroke,
    );

    // 4. Directional Forward Flow Arrow
    final arrowPaint = Paint()
      ..color = arrowColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8.5 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // Arrow shaft
    canvas.drawLine(
      Offset(24 * scale, 76 * scale),
      Offset(72 * scale, 76 * scale),
      arrowPaint,
    );

    // Arrow Head (Chevron pointing right)
    final headPath = Path();
    headPath.moveTo(63 * scale, 66 * scale);
    headPath.lineTo(76 * scale, 76 * scale);
    headPath.lineTo(63 * scale, 86 * scale);
    canvas.drawPath(headPath, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant DineFlowMarkPainter oldDelegate) {
    return oldDelegate.style != style ||
        oldDelegate.clocheColorOverride != clocheColorOverride ||
        oldDelegate.arrowColorOverride != arrowColorOverride;
  }
}

/// Standalone DineFlow Brand Mark Widget (Serving Cloche + Forward Arrow)
class DineFlowMark extends StatelessWidget {
  final double size;
  final DineFlowMarkStyle style;
  final Color? clocheColor;
  final Color? arrowColor;

  const DineFlowMark({
    super.key,
    this.size = 40,
    this.style = DineFlowMarkStyle.standard,
    this.clocheColor,
    this.arrowColor,
  });

  @override
  Widget build(BuildContext context) {
    if (style == DineFlowMarkStyle.appTile) {
      final borderRadius = size * 0.22;
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE55934), Color(0xFFEA580C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.35),
              blurRadius: size * 0.2,
              offset: Offset(0, size * 0.08),
            ),
          ],
        ),
        child: Center(
          child: CustomPaint(
            size: Size(size * 0.78, size * 0.78),
            painter: DineFlowMarkPainter(
              style: DineFlowMarkStyle.appTile,
              clocheColorOverride: clocheColor,
              arrowColorOverride: arrowColor,
            ),
          ),
        ),
      );
    }

    return CustomPaint(
      size: Size(size, size),
      painter: DineFlowMarkPainter(
        style: style,
        clocheColorOverride: clocheColor,
        arrowColorOverride: arrowColor,
      ),
    );
  }
}

/// Complete Brand Lockup Widget: [Mark] DineFlow + optional Tagline
class DineFlowLogo extends StatelessWidget {
  final double markSize;
  final double fontSize;
  final bool isDark;
  final bool useAppTile;
  final String? tagline;
  final MainAxisSize mainAxisSize;
  final CrossAxisAlignment crossAxisAlignment;

  const DineFlowLogo({
    super.key,
    this.markSize = 36,
    this.fontSize = 22,
    this.isDark = false,
    this.useAppTile = false,
    this.tagline,
    this.mainAxisSize = MainAxisSize.min,
    this.crossAxisAlignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : AppColors.textPrimary;
    final markStyle = useAppTile
        ? DineFlowMarkStyle.appTile
        : (isDark ? DineFlowMarkStyle.dark : DineFlowMarkStyle.standard);

    final brandRow = Row(
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        DineFlowMark(
          size: markSize,
          style: markStyle,
        ),
        SizedBox(width: markSize * 0.32),
        RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Dine',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: textColor,
                  fontFamily: 'Inter',
                ),
              ),
              TextSpan(
                text: 'Flow',
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppColors.primary,
                  fontFamily: 'Inter',
                ),
              ),
            ],
          ),
        ),
      ],
    );

    if (tagline == null || tagline!.isEmpty) {
      return brandRow;
    }

    return Column(
      mainAxisSize: mainAxisSize,
      crossAxisAlignment: crossAxisAlignment,
      children: [
        brandRow,
        const SizedBox(height: 4),
        Text(
          tagline!,
          style: TextStyle(
            fontSize: fontSize * 0.48,
            color: isDark ? const Color(0xFF94A3B8) : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }
}
