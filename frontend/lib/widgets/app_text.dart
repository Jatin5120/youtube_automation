import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppText extends StatelessWidget {
  const AppText(
    this.data, {
    super.key,
    this.style,
    this.textAlign,
    this.isSelectable = true,
    this.softWrap,
    this.overflow,
    this.maxLines,
  });

  final String data;
  final TextStyle? style;
  final bool isSelectable;
  final TextAlign? textAlign;
  final bool? softWrap;
  final TextOverflow? overflow;
  final int? maxLines;

  @override
  Widget build(BuildContext context) => isSelectable
      ? SelectableText(
          data,
          style: style,
          textAlign: textAlign,
          semanticsLabel: data,
          selectionControls: kIsWeb ? DesktopTextSelectionControls() : MaterialTextSelectionControls(),
          scrollPhysics: const NeverScrollableScrollPhysics(),
          maxLines: maxLines,
        )
      : Text(
          data,
          style: style,
          textAlign: textAlign,
          semanticsLabel: data,
          softWrap: softWrap,
          overflow: overflow,
          maxLines: maxLines,
        );
}
