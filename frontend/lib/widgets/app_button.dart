import 'package:flutter/material.dart';
import 'package:frontend/res/res.dart';
import 'package:frontend/utils/utils.dart';
import 'package:get/get.dart';

class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    this.onTap,
    required this.label,
  }) : _small = false;

  const AppButton.small({
    super.key,
    this.onTap,
    required this.label,
  }) : _small = true;

  final VoidCallback? onTap;
  final String label;
  final bool _small;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _small ? 40 : 48,
      width: _small ? null : double.maxFinite,
      child: ElevatedButton(
        style: ButtonStyle(
          padding: MaterialStateProperty.all(
            const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
          ),
          shape: MaterialStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          backgroundColor: MaterialStateColor.resolveWith(
            (states) {
              if (states.isDisabled) {
                return Colors.grey;
              }
              return AppColors.primary;
            },
          ),
          foregroundColor: MaterialStateColor.resolveWith(
            (states) {
              if (states.isDisabled) {
                return Colors.black;
              }
              return Colors.white;
            },
          ),
          textStyle: MaterialStateProperty.all(context.textTheme.bodyMedium),
        ),
        onPressed: onTap,
        child: Text(label),
      ),
    );
  }
}
