import 'package:flutter/material.dart';

class TapHandler extends StatelessWidget {
  const TapHandler({
    super.key,
    this.child,
    this.onTap,
    this.onHover,
    this.mouseCursor,
    this.showArrowCursor = false,
    this.showSplash = true,
  });

  final Widget? child;
  final VoidCallback? onTap;
  final void Function(bool)? onHover;
  final MouseCursor? mouseCursor;
  final bool showArrowCursor;
  final bool showSplash;

  @override
  Widget build(BuildContext context) => InkWell(
        hoverColor: showArrowCursor
            ? Colors.transparent
            : showSplash
                ? null
                : Colors.transparent,
        focusColor: showArrowCursor
            ? Colors.transparent
            : showSplash
                ? null
                : Colors.transparent,
        splashColor: showArrowCursor
            ? Colors.transparent
            : showSplash
                ? null
                : Colors.transparent,
        highlightColor: showArrowCursor
            ? Colors.transparent
            : showSplash
                ? null
                : Colors.transparent,
        overlayColor: showArrowCursor
            ? MaterialStateProperty.all(Colors.transparent)
            : showSplash
                ? null
                : MaterialStateProperty.all(Colors.transparent),
        mouseCursor: mouseCursor ?? (showArrowCursor ? SystemMouseCursors.basic : null),
        onHover: onHover,
        onTap: onHover == null ? onTap : onTap ?? () {},
        child: child,
      );
}
