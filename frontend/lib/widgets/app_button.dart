import 'package:flutter/material.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/utils/utils.dart';
import 'package:get/get.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    this.onTap,
    this.color,
    this.borderColor,
    this.foregroundColor,
    this.icon,
    required this.label,
  }) : _small = false;

  const AppButton.small({
    super.key,
    this.onTap,
    this.color,
    this.borderColor,
    this.foregroundColor,
    this.icon,
    required this.label,
  }) : _small = true;

  final VoidCallback? onTap;
  final Color? color;
  final Color? foregroundColor;
  final Color? borderColor;
  final String label;
  final bool _small;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => SizedBox(
        height: _small ? 32 : 40,
        width: _small ? null : double.maxFinite,
        child: ElevatedButton.icon(
          style: ButtonStyle(
            padding: WidgetStateProperty.all(
              const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ).copyWith(
                left: icon != null ? 12 : null,
              ),
            ),
            shape: WidgetStateProperty.resolveWith(
              (states) {
                var borderColor0 = borderColor ?? color ?? AppColors.primary;
                var width = 1.0;
                if (states.isDisabled) {
                  borderColor0 = borderColor0.withValues(alpha: 0.5);
                  width = 0.0;
                }
                return RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(
                    color: borderColor0,
                    width: width,
                  ),
                );
              },
            ),
            backgroundColor: WidgetStateColor.resolveWith(
              (states) {
                final backgroundColor = color ?? AppColors.primary;
                if (states.isDisabled) {
                  return backgroundColor.withValues(alpha: 0.5);
                }
                return backgroundColor;
              },
            ),
            foregroundColor: WidgetStateColor.resolveWith(
              (states) {
                final foregroundColor0 = foregroundColor ?? Colors.white;
                if (states.isDisabled) {
                  return foregroundColor0.withValues(alpha: 0.5);
                }
                return foregroundColor0;
              },
            ),
            textStyle: WidgetStateProperty.all(
              context.textTheme.bodyMedium?.copyWith(
                fontSize: _small ? 12 : null,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          onPressed: onTap,
          icon: icon != null ? Icon(icon, size: _small ? 16 : 24) : null,
          label: Text(label),
        ),
      );
}
