import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:myapp/controllers/lang/lang_controller.dart';
import 'package:myapp/core/utils.dart';
import 'package:myapp/models/user/user.dart';
import 'package:myapp/services/responsiveness/responsiveness_service.dart';

enum SmartTextType {
  heading, // For headings - uses NotoSans for English
  body, // For body text - uses SharpSans for English
}

class LangText extends ConsumerWidget {
  final String? hindi;
  final String? hinglish;
  final String? text; // Single text option
  final SmartTextType textType;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const LangText({
    super.key,
    this.hindi,
    this.hinglish,
    this.text,
    this.textType = SmartTextType.body,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : assert(
         (hindi != null && hinglish != null && text == null) || (hindi == null && hinglish == null && text != null),
         'Either provide both hindi and hinglish, or provide text only',
       );

  /// Convenience constructor for headings with language-specific text
  const LangText.heading({
    super.key,
    required this.hindi,
    required this.hinglish,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : textType = SmartTextType.heading,
       text = null;

  /// Convenience constructor for body text with language-specific text
  const LangText.body({
    super.key,
    required this.hindi,
    required this.hinglish,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  }) : textType = SmartTextType.body,
       text = null;

  /// Convenience constructor for headings with single text
  const LangText.headingText({super.key, required this.text, this.style, this.textAlign, this.maxLines, this.overflow})
    : textType = SmartTextType.heading,
      hindi = null,
      hinglish = null;

  /// Convenience constructor for body text with single text
  const LangText.bodyText({super.key, required this.text, this.style, this.textAlign, this.maxLines, this.overflow})
    : textType = SmartTextType.body,
      hindi = null,
      hinglish = null;

  String _getFontFamily(PrefLang lang, SmartTextType textType) {
    switch (lang) {
      case PrefLang.hindi:
        return 'Hind';
      case PrefLang.hinglish:
        switch (textType) {
          case SmartTextType.heading:
            return 'NotoSans';
          case SmartTextType.body:
            return 'SharpSans';
        }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLang = ref.watch(langControllerProvider);
    final responsiveness = ResponsivenessService(context);

    final displayText = text ?? choose(hindi: hindi!, hinglish: hinglish!, lang: currentLang);

    final fontFamily = _getFontFamily(currentLang, textType);

    // Set default styles based on text type
    final defaultStyle =
        (() {
          switch (textType) {
            case SmartTextType.heading:
              return TextStyle(
                fontSize: responsiveness.getResponsiveValues(mobile: 20, tablet: 22, largeTablet: 24),
                fontWeight: FontWeight.w600,
              );
            case SmartTextType.body:
              return TextStyle(
                fontSize: responsiveness.getResponsiveValues(mobile: 14, tablet: 18, largeTablet: 20),
                fontWeight: FontWeight.w500,
              );
          }
        })();

    // Merge defaults, font family, and provided style
    final mergedStyle = defaultStyle.copyWith(fontFamily: fontFamily).merge(style);

    return Text(displayText, style: mergedStyle, textAlign: textAlign, maxLines: maxLines, overflow: overflow);
  }
}
