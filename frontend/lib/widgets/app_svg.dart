import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AppSvg extends StatelessWidget {
  const AppSvg(
    this.iconPath, {
    super.key,
    this.color,
    this.height,
    this.width,
    this.dimension,
  });

  final String iconPath;
  final Color? color;
  final double? height;
  final double? width;
  final double? dimension;

  @override
  Widget build(BuildContext context) => SvgPicture.asset(
        iconPath,
        colorFilter: color == null
            ? null
            : ColorFilter.mode(
                color!,
                BlendMode.srcIn,
              ),
        height: height ?? dimension,
        width: width ?? dimension,
      );
}
