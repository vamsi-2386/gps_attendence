import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Display Large Text
class DisplayLargeText extends StatelessWidget {
  final String text;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Color? color;
  final FontWeight? fontWeight;
  final double? fontSize;

  const DisplayLargeText(
    this.text, {
    Key? key,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.color,
    this.fontWeight,
    this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: AppTheme.displayLarge.copyWith(
        color: color,
        fontWeight: fontWeight,
        fontSize: fontSize,
      ),
    );
  }
}

/// Display Medium Text
class DisplayMediumText extends StatelessWidget {
  final String text;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Color? color;
  final FontWeight? fontWeight;
  final double? fontSize;

  const DisplayMediumText(
    this.text, {
    Key? key,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.color,
    this.fontWeight,
    this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: AppTheme.displayMedium.copyWith(
        color: color,
        fontWeight: fontWeight,
        fontSize: fontSize,
      ),
    );
  }
}

/// Heading Large Text
class HeadingLargeText extends StatelessWidget {
  final String text;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Color? color;
  final FontWeight? fontWeight;
  final double? fontSize;

  const HeadingLargeText(
    this.text, {
    Key? key,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.color,
    this.fontWeight,
    this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: AppTheme.headingLarge.copyWith(
        color: color,
        fontWeight: fontWeight,
        fontSize: fontSize,
      ),
    );
  }
}

/// Heading Medium Text
class HeadingMediumText extends StatelessWidget {
  final String text;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Color? color;
  final FontWeight? fontWeight;
  final double? fontSize;

  const HeadingMediumText(
    this.text, {
    Key? key,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.color,
    this.fontWeight,
    this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: AppTheme.headingMedium.copyWith(
        color: color,
        fontWeight: fontWeight,
        fontSize: fontSize,
      ),
    );
  }
}

/// Body Large Text
class BodyLargeText extends StatelessWidget {
  final String text;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Color? color;
  final FontWeight? fontWeight;
  final double? fontSize;

  const BodyLargeText(
    this.text, {
    Key? key,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.color,
    this.fontWeight,
    this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: AppTheme.bodyLarge.copyWith(
        color: color,
        fontWeight: fontWeight,
        fontSize: fontSize,
      ),
    );
  }
}

/// Body Medium Text
class BodyMediumText extends StatelessWidget {
  final String text;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Color? color;
  final FontWeight? fontWeight;
  final double? fontSize;

  const BodyMediumText(
    this.text, {
    Key? key,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.color,
    this.fontWeight,
    this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: AppTheme.bodyMedium.copyWith(
        color: color,
        fontWeight: fontWeight,
        fontSize: fontSize,
      ),
    );
  }
}

/// Body Small Text
class BodySmallText extends StatelessWidget {
  final String text;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Color? color;
  final FontWeight? fontWeight;
  final double? fontSize;

  const BodySmallText(
    this.text, {
    Key? key,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.color,
    this.fontWeight,
    this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: AppTheme.bodySmall.copyWith(
        color: color,
        fontWeight: fontWeight,
        fontSize: fontSize,
      ),
    );
  }
}

/// Label Text
class LabelText extends StatelessWidget {
  final String text;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;
  final Color? color;
  final FontWeight? fontWeight;
  final double? fontSize;
  final bool isSmall;

  const LabelText(
    this.text, {
    Key? key,
    this.textAlign,
    this.maxLines,
    this.overflow,
    this.color,
    this.fontWeight,
    this.fontSize,
    this.isSmall = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
      style: (isSmall ? AppTheme.labelSmall : AppTheme.labelLarge).copyWith(
        color: color,
        fontWeight: fontWeight,
        fontSize: fontSize,
      ),
    );
  }
}
