import 'package:flutter/material.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/utils/utils.dart';
import 'package:get/get.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    this.onTap,
    this.color,
    required this.label,
  }) : _small = false;

  const AppButton.small({
    super.key,
    this.onTap,
    this.color,
    required this.label,
  }) : _small = true;

  final VoidCallback? onTap;
  final Color? color;
  final String label;
  final bool _small;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _small ? 40 : 48,
      width: _small ? null : double.maxFinite,
      child: ElevatedButton(
        style: ButtonStyle(
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          backgroundColor: WidgetStateColor.resolveWith(
            (states) {
              if (states.isDisabled) {
                return Colors.grey;
              }
              return color ?? AppColors.primary;
            },
          ),
          foregroundColor: WidgetStateColor.resolveWith(
            (states) {
              if (states.isDisabled) {
                return Colors.black;
              }
              return Colors.white;
            },
          ),
          textStyle: WidgetStateProperty.all(context.textTheme.bodyMedium),
        ),
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}
