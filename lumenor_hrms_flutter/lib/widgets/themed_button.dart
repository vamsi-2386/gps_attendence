import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Themed Primary Button
class ThemedButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isEnabled;
  final double? width;
  final double height;
  final TextStyle? textStyle;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final MainAxisAlignment? iconAlignment;

  const ThemedButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.isEnabled = true,
    this.width,
    this.height = 50,
    this.textStyle,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.iconAlignment,
  }) : super(key: key);

  @override
  State<ThemedButton> createState() => _ThemedButtonState();
}

class _ThemedButtonState extends State<ThemedButton> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width ?? double.infinity,
      height: widget.height,
      child: ElevatedButton(
        onPressed: widget.isEnabled && !widget.isLoading ? widget.onPressed : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: widget.backgroundColor ?? AppTheme.primaryColor,
          disabledBackgroundColor: AppTheme.lightGray,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
        child: widget.isLoading
            ? SizedBox(
                height: 24,
                width: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    widget.textColor ?? AppTheme.white,
                  ),
                ),
              )
            : Row(
                mainAxisAlignment: widget.iconAlignment ?? MainAxisAlignment.center,
                children: [
                  if (widget.icon != null) ...[
                    Icon(widget.icon, color: widget.textColor ?? AppTheme.white),
                    const SizedBox(width: AppTheme.spacingSmall),
                  ],
                  Text(
                    widget.label,
                    style: widget.textStyle ??
                        TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: widget.textColor ?? AppTheme.white,
                        ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Themed Secondary (Outline) Button
class ThemedOutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isEnabled;
  final double? width;
  final double height;
  final TextStyle? textStyle;
  final Color? borderColor;
  final Color? textColor;
  final IconData? icon;

  const ThemedOutlineButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.isEnabled = true,
    this.width,
    this.height = 50,
    this.textStyle,
    this.borderColor,
    this.textColor,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: isEnabled ? onPressed : null,
        style: OutlinedButton.styleFrom(
          side: BorderSide(
            color: borderColor ?? AppTheme.primaryColor,
            width: 2,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, color: textColor ?? AppTheme.primaryColor),
              const SizedBox(width: AppTheme.spacingSmall),
            ],
            Text(
              label,
              style: textStyle ??
                  TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: textColor ?? AppTheme.primaryColor,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Themed Text Button
class ThemedTextButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final TextStyle? textStyle;
  final Color? textColor;
  final IconData? icon;

  const ThemedTextButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.textStyle,
    this.textColor,
    this.icon,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.spacingMedium,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: textColor ?? AppTheme.primaryColor),
            const SizedBox(width: AppTheme.spacingSmall),
          ],
          Text(
            label,
            style: textStyle ??
                TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textColor ?? AppTheme.primaryColor,
                ),
          ),
        ],
      ),
    );
  }
}
