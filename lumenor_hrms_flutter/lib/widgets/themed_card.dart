import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Themed Card Widget
class ThemedCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double? borderRadius;
  final VoidCallback? onTap;
  final List<BoxShadow>? shadow;
  final Border? border;

  const ThemedCard({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
    this.borderRadius,
    this.onTap,
    this.shadow,
    this.border,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(AppTheme.spacingMedium),
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.white,
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppTheme.radiusMedium,
        ),
        border: border ??
            (borderWidth > 0
                ? Border.all(
                    color: borderColor ?? AppTheme.lightGray,
                    width: borderWidth,
                  )
                : null),
        boxShadow: shadow ?? AppTheme.cardShadow(),
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}

/// Elevated Card Widget
class ElevatedThemedCard extends StatefulWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? borderRadius;
  final VoidCallback? onTap;
  final bool isClickable;

  const ElevatedThemedCard({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.borderRadius,
    this.onTap,
    this.isClickable = true,
  }) : super(key: key);

  @override
  State<ElevatedThemedCard> createState() => _ElevatedThemedCardState();
}

class _ElevatedThemedCardState extends State<ElevatedThemedCard> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.isClickable && widget.onTap != null
          ? (_) => setState(() => _isPressed = true)
          : null,
      onTapUp: widget.isClickable && widget.onTap != null
          ? (_) => setState(() => _isPressed = false)
          : null,
      onTapCancel: widget.isClickable && widget.onTap != null
          ? () => setState(() => _isPressed = false)
          : null,
      onTap: widget.onTap,
      child: Transform.translate(
        offset: _isPressed ? const Offset(0, 2) : Offset.zero,
        child: Container(
          width: widget.width,
          height: widget.height,
          padding: widget.padding ?? const EdgeInsets.all(AppTheme.spacingMedium),
          margin: widget.margin,
          decoration: BoxDecoration(
            color: widget.backgroundColor ?? AppTheme.white,
            borderRadius: BorderRadius.circular(
              widget.borderRadius ?? AppTheme.radiusMedium,
            ),
            boxShadow: _isPressed
                ? AppTheme.cardShadow()
                : AppTheme.elevatedShadow(),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

/// Gradient Card Widget
class GradientThemedCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final List<Color>? colors;
  final AlignmentGeometry? begin;
  final AlignmentGeometry? end;
  final double? borderRadius;
  final VoidCallback? onTap;

  const GradientThemedCard({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.colors,
    this.begin,
    this.end,
    this.borderRadius,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(AppTheme.spacingMedium),
      margin: margin,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors ?? [AppTheme.primaryColor, AppTheme.secondaryColor],
          begin: begin ?? Alignment.topLeft,
          end: end ?? Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppTheme.radiusMedium,
        ),
        boxShadow: AppTheme.cardShadow(),
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}

/// Outlined Card Widget
class OutlinedThemedCard extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? borderColor;
  final double borderWidth;
  final double? borderRadius;
  final VoidCallback? onTap;

  const OutlinedThemedCard({
    Key? key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderColor,
    this.borderWidth = 2,
    this.borderRadius,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      height: height,
      padding: padding ?? const EdgeInsets.all(AppTheme.spacingMedium),
      margin: margin,
      decoration: BoxDecoration(
        color: AppTheme.white,
        border: Border.all(
          color: borderColor ?? AppTheme.primaryColor,
          width: borderWidth,
        ),
        borderRadius: BorderRadius.circular(
          borderRadius ?? AppTheme.radiusMedium,
        ),
      ),
      child: child,
    );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        child: card,
      );
    }

    return card;
  }
}
